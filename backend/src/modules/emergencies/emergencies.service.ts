import { Emergency, IEmergency } from '../../models/Emergency';
import { EmergencyEvent } from '../../models/EmergencyEvent';
import { ResponderProfile } from '../../models/ResponderProfile';
import { User } from '../../models/User';
import {
  EmergencyCategory,
  EmergencyEventType,
  EmergencyStatus,
  ProofStatus,
  Role,
  VerificationStatus,
  TERMINAL_STATUSES,
} from '../../shared/enums';
import {
  ConflictError,
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from '../../shared/errors';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { config } from '../../config';
import { AuthUser, LatLng } from '../../shared/types';
import { matchingService } from '../matching/matching.service';
import { trustService } from '../trust/trust.service';
import { socketService } from '../realtime/socket';
import {
  CreateEmergencyInput,
  CreateGuestEmergencyInput,
  ResolveEmergencyInput,
  EscalateEmergencyInput,
} from './emergencies.validation';

export class EmergencyService {
  // ─── Create SOS ───────────────────────────────────────────────────────

  async create(user: AuthUser, input: CreateEmergencyInput) {
    const emergency = await Emergency.create({
      ownerId: user.userId,
      category: input.category,
      status: EmergencyStatus.ACTIVE,
      location: {
        type: 'Point',
        coordinates: [input.location.longitude, input.location.latitude],
      },
      notes: input.notes || '',
      version: 1,
    });

    // Append creation event
    await this.appendEvent(
      emergency,
      user,
      EmergencyEventType.CREATED,
      null,
      EmergencyStatus.ACTIVE,
    );

    // Notify nearby responders (async — don't block response)
    this.notifyNearbyResponders(emergency).catch((err) =>
      console.error('[MATCHING] Notification error:', err),
    );

    return this.formatForOwner(emergency);
  }

  // ─── Create Guest SOS (Bypass without login) ─────────────────────────

  /**
   * Bypass route: Create emergency directly without prior login.
   * Auto-provisions a guest user record with ELDERLY_USER role, creates the active emergency,
   * dispatches notifications to responders, and returns the emergency along with a guest JWT token
   * so the frontend client can track status and cancel if needed.
   */
  async createGuestEmergency(input: CreateGuestEmergencyInput) {
    const guestSuffix = uuidv4().slice(0, 8);
    const displayName = input.displayName?.trim() || `Guest User ${guestSuffix}`;
    const phone = `guest_${Date.now()}_${guestSuffix}`;

    const guestUser = await User.create({
      displayName,
      phone,
      role: Role.ELDERLY_USER,
      isGuest: true,
    });

    const token = jwt.sign(
      { userId: guestUser._id.toString(), role: guestUser.role, isGuest: true },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn as string | number } as jwt.SignOptions,
    );

    const guestAuthUser: AuthUser = {
      userId: guestUser._id.toString(),
      role: guestUser.role,
      isGuest: true,
    };

    const notesParts: string[] = [];
    if (input.contactPhone) {
      notesParts.push(`Contact: ${input.contactPhone}`);
    }
    if (input.notes) {
      notesParts.push(input.notes);
    }
    const combinedNotes = notesParts.join(' | ');

    const emergency = await Emergency.create({
      ownerId: guestUser._id,
      category: input.category,
      status: EmergencyStatus.ACTIVE,
      location: {
        type: 'Point',
        coordinates: [input.location.longitude, input.location.latitude],
      },
      notes: combinedNotes,
      version: 1,
    });

    // Append creation event
    await this.appendEvent(
      emergency,
      guestAuthUser,
      EmergencyEventType.CREATED,
      null,
      EmergencyStatus.ACTIVE,
    );

    // Notify nearby responders (async — don't block response)
    this.notifyNearbyResponders(emergency).catch((err) =>
      console.error('[MATCHING] Notification error:', err),
    );

    return {
      emergency: this.formatForOwner(emergency),
      user: guestUser.toJSON(),
      token,
    };
  }

  // ─── Get Emergency (permission-filtered) ──────────────────────────────

  async getById(user: AuthUser, emergencyId: string) {
    const emergency = await Emergency.findById(emergencyId);
    if (!emergency) throw new NotFoundError('Emergency', emergencyId);

    const isOwner = emergency.ownerId.toString() === user.userId;
    const isAssigned = emergency.assignedResponderId?.toString() === user.userId;
    const isAdmin = user.role === Role.ADMIN || user.role === Role.VERIFIER;

    if (!isOwner && !isAssigned && !isAdmin) {
      throw new ForbiddenError();
    }

    if (isOwner || isAdmin) return this.formatForOwner(emergency);
    if (isAssigned) return this.formatForAssignedResponder(emergency);
    return this.formatForResponder(emergency, null);
  }

  // ─── Nearby (responder-only, coarse location) ────────────────────────

  async getNearby(user: AuthUser) {
    if (user.isGuest) {
      throw new ForbiddenError('Guest users cannot query responder nearby emergencies.');
    }
    // Verify this user is a verified, available responder
    const profile = await ResponderProfile.findOne({ userId: user.userId });
    if (!profile) throw new ForbiddenError('No responder profile found.');
    if (profile.verificationStatus !== VerificationStatus.VERIFIED) {
      throw new ForbiddenError('Responder is not verified.');
    }
    if (!profile.available) {
      throw new ForbiddenError('Responder is not available.');
    }
    if (!profile.location) {
      throw new ValidationError('No location available for matching.');
    }

    const responderLoc: LatLng = {
      latitude: profile.location.coordinates[1],
      longitude: profile.location.coordinates[0],
    };

    // Find active emergencies within max radius
    const activeEmergencies = await Emergency.find({
      status: EmergencyStatus.ACTIVE,
      location: {
        $nearSphere: {
          $geometry: {
            type: 'Point',
            coordinates: profile.location.coordinates,
          },
          $maxDistance: 3000, // max radius
        },
      },
    }).limit(20);

    return activeEmergencies.map((e) => {
      const emergencyLoc: LatLng = {
        latitude: e.location.coordinates[1],
        longitude: e.location.coordinates[0],
      };
      const distance = matchingService.calculateDistance(responderLoc, emergencyLoc);
      return this.formatForResponder(e, distance);
    });
  }

  // ─── Cancel ───────────────────────────────────────────────────────────

  async cancel(user: AuthUser, emergencyId: string) {
    const emergency = await Emergency.findOneAndUpdate(
      {
        _id: emergencyId,
        ownerId: user.userId,
        status: EmergencyStatus.ACTIVE,
      },
      {
        $set: {
          status: EmergencyStatus.CANCELLED,
          cancelledAt: new Date(),
        },
        $inc: { version: 1 },
      },
      { new: true },
    );

    if (!emergency) {
      // Determine why: not found, not owner, or wrong status
      const existing = await Emergency.findById(emergencyId);
      if (!existing) throw new NotFoundError('Emergency', emergencyId);
      if (existing.ownerId.toString() !== user.userId) throw new ForbiddenError();
      throw new ConflictError(
        'EMERGENCY_NOT_CANCELLABLE',
        `Emergency cannot be cancelled from status '${existing.status}'.`,
      );
    }

    await this.appendEvent(
      emergency,
      user,
      EmergencyEventType.CANCELLED,
      EmergencyStatus.ACTIVE,
      EmergencyStatus.CANCELLED,
    );

    socketService.emitEmergencyCancelled(emergency);

    return this.formatForOwner(emergency);
  }

  // ─── Accept (atomic assignment) ───────────────────────────────────────

  async accept(user: AuthUser, emergencyId: string) {
    if (user.isGuest) {
      throw new ForbiddenError('Guest users cannot accept emergencies.');
    }
    // Verify responder eligibility
    const profile = await ResponderProfile.findOne({ userId: user.userId });
    if (!profile) throw new ForbiddenError('No responder profile found.');
    if (profile.verificationStatus !== VerificationStatus.VERIFIED) {
      throw new ForbiddenError('Responder is not verified.');
    }
    if (!profile.available) {
      throw new ForbiddenError('Responder is not available.');
    }

    // Atomic conditional update: assign only if ACTIVE and unassigned
    const emergency = await Emergency.findOneAndUpdate(
      {
        _id: emergencyId,
        status: EmergencyStatus.ACTIVE,
        assignedResponderId: null,
      },
      {
        $set: {
          status: EmergencyStatus.ASSIGNED,
          assignedResponderId: user.userId,
        },
        $inc: { version: 1 },
      },
      { new: true },
    );

    if (!emergency) {
      const existing = await Emergency.findById(emergencyId);
      if (!existing) throw new NotFoundError('Emergency', emergencyId);
      throw new ConflictError(
        'EMERGENCY_ALREADY_ASSIGNED',
        'This emergency has already been assigned or is no longer active.',
      );
    }

    await this.appendEvent(
      emergency,
      user,
      EmergencyEventType.ACCEPTED,
      EmergencyStatus.ACTIVE,
      EmergencyStatus.ASSIGNED,
    );

    socketService.emitResponderAccepted(emergency);

    return this.formatForAssignedResponder(emergency);
  }

  // ─── Decline ──────────────────────────────────────────────────────────

  async decline(user: AuthUser, emergencyId: string) {
    if (user.isGuest) {
      throw new ForbiddenError('Guest users cannot decline emergencies.');
    }
    const emergency = await Emergency.findById(emergencyId);
    if (!emergency) throw new NotFoundError('Emergency', emergencyId);
    if (emergency.status !== EmergencyStatus.ACTIVE) {
      throw new ConflictError(
        'EMERGENCY_NOT_ACTIVE',
        'Cannot decline an emergency that is not active.',
      );
    }

    await this.appendEvent(
      emergency,
      user,
      EmergencyEventType.DECLINED,
      EmergencyStatus.ACTIVE,
      EmergencyStatus.ACTIVE, // status doesn't change on decline
    );

    return { message: 'Declined successfully.' };
  }

  // ─── Arrive ───────────────────────────────────────────────────────────

  async arrive(user: AuthUser, emergencyId: string) {
    if (user.isGuest) {
      throw new ForbiddenError('Guest users cannot mark arrival.');
    }
    const emergency = await Emergency.findOneAndUpdate(
      {
        _id: emergencyId,
        assignedResponderId: user.userId,
        status: EmergencyStatus.ASSIGNED,
      },
      {
        $set: { status: EmergencyStatus.RESPONDER_ARRIVED },
        $inc: { version: 1 },
      },
      { new: true },
    );

    if (!emergency) {
      const existing = await Emergency.findById(emergencyId);
      if (!existing) throw new NotFoundError('Emergency', emergencyId);
      if (existing.assignedResponderId?.toString() !== user.userId) {
        throw new ForbiddenError('You are not the assigned responder.');
      }
      throw new ConflictError(
        'INVALID_STATE_TRANSITION',
        `Cannot mark arrived from status '${existing.status}'.`,
      );
    }

    await this.appendEvent(
      emergency,
      user,
      EmergencyEventType.ARRIVED,
      EmergencyStatus.ASSIGNED,
      EmergencyStatus.RESPONDER_ARRIVED,
    );

    // Enqueue proof for arrival
    trustService
      .enqueueProof(emergency, EmergencyEventType.ARRIVED)
      .catch((err) => console.error('[TRUST] Proof enqueue error:', err));

    socketService.emitResponderArrived(emergency);

    return this.formatForAssignedResponder(emergency);
  }

  // ─── Resolve ──────────────────────────────────────────────────────────

  async resolve(user: AuthUser, emergencyId: string, input: ResolveEmergencyInput) {
    if (user.isGuest) {
      throw new ForbiddenError('Guest users cannot resolve emergencies.');
    }
    const validFromStatuses = [
      EmergencyStatus.ASSIGNED,
      EmergencyStatus.RESPONDER_ARRIVED,
      EmergencyStatus.ESCALATED,
    ];

    const emergency = await Emergency.findOneAndUpdate(
      {
        _id: emergencyId,
        assignedResponderId: user.userId,
        status: { $in: validFromStatuses },
      },
      {
        $set: {
          status: EmergencyStatus.RESOLVED,
          'resolution.outcome': input.outcome,
          'resolution.note': input.note || null,
          'resolution.resolvedAt': new Date(),
        },
        $inc: { version: 1 },
      },
      { new: true },
    );

    if (!emergency) {
      const existing = await Emergency.findById(emergencyId);
      if (!existing) throw new NotFoundError('Emergency', emergencyId);
      if (existing.assignedResponderId?.toString() !== user.userId) {
        throw new ForbiddenError('You are not the assigned responder.');
      }
      throw new ConflictError(
        'INVALID_STATE_TRANSITION',
        `Cannot resolve from status '${existing.status}'.`,
      );
    }

    await this.appendEvent(
      emergency,
      user,
      EmergencyEventType.RESOLVED,
      validFromStatuses.find((s) => s !== EmergencyStatus.RESOLVED) || null,
      EmergencyStatus.RESOLVED,
      { outcome: input.outcome },
    );

    // Increment responder completed count
    await ResponderProfile.findOneAndUpdate(
      { userId: user.userId },
      { $inc: { completedCount: 1, reputationScore: 1 } },
    );

    // Enqueue proof for resolution
    trustService
      .enqueueProof(emergency, EmergencyEventType.RESOLVED)
      .catch((err) => console.error('[TRUST] Proof enqueue error:', err));

    socketService.emitEmergencyResolved(emergency);

    return this.formatForAssignedResponder(emergency);
  }

  // ─── Escalate ─────────────────────────────────────────────────────────

  async escalate(user: AuthUser, emergencyId: string, input: EscalateEmergencyInput) {
    const validFromStatuses = [
      EmergencyStatus.ACTIVE,
      EmergencyStatus.ASSIGNED,
      EmergencyStatus.RESPONDER_ARRIVED,
    ];

    const existing = await Emergency.findById(emergencyId);
    if (!existing) throw new NotFoundError('Emergency', emergencyId);

    const isOwner = existing.ownerId.toString() === user.userId;
    const isAssigned = existing.assignedResponderId?.toString() === user.userId;
    if (!isOwner && !isAssigned) {
      throw new ForbiddenError('Only the owner or assigned responder can escalate.');
    }

    if (!validFromStatuses.includes(existing.status)) {
      throw new ConflictError(
        'INVALID_STATE_TRANSITION',
        `Cannot escalate from status '${existing.status}'.`,
      );
    }

    const previousStatus = existing.status;

    const emergency = await Emergency.findOneAndUpdate(
      {
        _id: emergencyId,
        status: { $in: validFromStatuses },
      },
      {
        $set: {
          status: EmergencyStatus.ESCALATED,
          'escalation.isEscalated': true,
          'escalation.reason': input.reason,
          'escalation.previousStatus': previousStatus,
        },
        $inc: { version: 1 },
      },
      { new: true },
    );

    if (!emergency) {
      throw new ConflictError(
        'ESCALATION_RACE',
        'Emergency state changed during escalation.',
      );
    }

    await this.appendEvent(
      emergency,
      user,
      EmergencyEventType.ESCALATED,
      previousStatus,
      EmergencyStatus.ESCALATED,
      { reason: input.reason },
    );

    socketService.emitEmergencyUpdated(emergency);

    // Re-notify nearby responders for additional help
    this.notifyNearbyResponders(emergency).catch((err) =>
      console.error('[MATCHING] Escalation notification error:', err),
    );

    return this.formatForOwner(emergency);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  private async appendEvent(
    emergency: IEmergency,
    user: AuthUser,
    eventType: EmergencyEventType,
    previousStatus: EmergencyStatus | null,
    nextStatus: EmergencyStatus,
    metadata: Record<string, unknown> = {},
  ) {
    await EmergencyEvent.create({
      emergencyId: emergency._id,
      actorId: user.userId,
      actorRole: user.role,
      eventType,
      previousStatus,
      nextStatus,
      version: emergency.version,
      correlationId: `${emergency._id}-${eventType}-${Date.now()}`,
      metadata,
    });
  }

  private async notifyNearbyResponders(emergency: IEmergency) {
    const center: LatLng = {
      latitude: emergency.location.coordinates[1],
      longitude: emergency.location.coordinates[0],
    };

    const radii = matchingService.getRadii();
    const notifiedUserIds: string[] = [emergency.ownerId.toString()];

    for (let i = 0; i < radii.length; i++) {
      // Check if emergency is still ACTIVE
      const current = await Emergency.findById(emergency._id);
      if (!current || current.status !== EmergencyStatus.ACTIVE) break;

      const candidates = await matchingService.findCandidates(center, i, notifiedUserIds);
      if (candidates.length > 0) {
        for (const candidate of candidates) {
          notifiedUserIds.push(candidate.userId);
          socketService.emitEmergencyCreated(emergency, candidate.userId);
        }
        break; // Found candidates at this tier, stop expanding
      }

      // Wait before expanding radius (except on last tier)
      if (i < radii.length - 1) {
        await new Promise((resolve) =>
          setTimeout(resolve, 2000), // Short delay for demo
        );
      }
    }
  }

  /** Format for the emergency owner — includes exact location. */
  private formatForOwner(emergency: IEmergency) {
    const json = emergency.toJSON();
    json.location = {
      latitude: emergency.location.coordinates[1],
      longitude: emergency.location.coordinates[0],
    };
    return json;
  }

  /** Format for the assigned responder — includes exact location after assignment. */
  private formatForAssignedResponder(emergency: IEmergency) {
    const json = emergency.toJSON();
    json.location = {
      latitude: emergency.location.coordinates[1],
      longitude: emergency.location.coordinates[0],
    };
    return json;
  }

  /**
   * Format for a pre-acceptance responder — coarse location + approximate distance.
   * Exact coordinates and owner contact details are redacted.
   */
  private formatForResponder(emergency: IEmergency, distanceMeters: number | null) {
    const exactLoc: LatLng = {
      latitude: emergency.location.coordinates[1],
      longitude: emergency.location.coordinates[0],
    };
    const coarse = matchingService.coarsenLocation(exactLoc);

    return {
      id: emergency._id.toString(),
      category: emergency.category,
      status: emergency.status,
      createdAt: emergency.createdAt,
      updatedAt: emergency.updatedAt,
      location: coarse,
      approximateDistanceMeters: distanceMeters ? Math.round(distanceMeters) : null,
      assignedResponder: null,
      escalation: emergency.escalation,
      proof: emergency.proof,
    };
  }
}

export const emergencyService = new EmergencyService();
