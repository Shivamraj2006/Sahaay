import { ResponderProfile } from '../../models/ResponderProfile';
import { EmergencyEvent } from '../../models/EmergencyEvent';
import { NotFoundError } from '../../shared/errors';
import { EmergencyEventType } from '../../shared/enums';
import { UpdateAvailabilityInput } from './responders.validation';

export class ResponderService {
  async getProfile(userId: string) {
    const profile = await ResponderProfile.findOne({ userId });
    if (!profile) throw new NotFoundError('Responder profile');
    return profile.toJSON();
  }

  async updateAvailability(userId: string, input: UpdateAvailabilityInput) {
    const update: Record<string, unknown> = {
      available: input.available,
    };

    if (input.location) {
      update.location = {
        type: 'Point',
        coordinates: [input.location.longitude, input.location.latitude],
      };
      update.locationUpdatedAt = new Date();
    }

    const profile = await ResponderProfile.findOneAndUpdate(
      { userId },
      { $set: update },
      { new: true, runValidators: true },
    );
    if (!profile) throw new NotFoundError('Responder profile');
    return profile.toJSON();
  }

  async getHistory(userId: string, page = 1, limit = 20) {
    const profile = await ResponderProfile.findOne({ userId });
    if (!profile) throw new NotFoundError('Responder profile');

    const skip = (page - 1) * limit;
    const events = await EmergencyEvent.find({
      actorId: userId,
      eventType: { $in: [EmergencyEventType.ACCEPTED, EmergencyEventType.ARRIVED, EmergencyEventType.RESOLVED] },
    })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await EmergencyEvent.countDocuments({
      actorId: userId,
      eventType: { $in: [EmergencyEventType.ACCEPTED, EmergencyEventType.ARRIVED, EmergencyEventType.RESOLVED] },
    });

    return {
      items: events.map((e) => e.toJSON()),
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getReputation(userId: string) {
    const profile = await ResponderProfile.findOne({ userId });
    if (!profile) throw new NotFoundError('Responder profile');

    return {
      completedCount: profile.completedCount,
      reputationScore: profile.reputationScore,
      verificationStatus: profile.verificationStatus,
    };
  }
}

export const responderService = new ResponderService();
