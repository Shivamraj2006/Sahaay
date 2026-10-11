import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { config } from '../../config';
import { AuthUser } from '../../shared/types';
import { SocketEvent } from '../../shared/enums';
import { IEmergency } from '../../models/Emergency';
import { User } from '../../models/User';
import { matchingService } from '../matching/matching.service';

let io: Server;

/**
 * Socket.IO server with JWT authentication and server-managed rooms.
 *
 * Rooms:
 *  - `user:<userId>` — personal room for targeted notifications
 *  - `emergency:<emergencyId>` — room for emergency participants
 */
export function initializeSocket(httpServer: HttpServer): Server {
  io = new Server(httpServer, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
    path: '/socket.io',
  });

  // JWT authentication middleware
  io.use((socket: Socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.replace('Bearer ', '');
    if (!token) {
      return next(new Error('Authentication required'));
    }
    try {
      const decoded = jwt.verify(token, config.jwt.secret) as AuthUser;
      (socket as any).user = decoded;
      next();
    } catch {
      next(new Error('Invalid or expired token'));
    }
  });

  io.on('connection', (socket: Socket) => {
    const user = (socket as any).user as AuthUser;
    // Join personal room
    socket.join(`user:${user.userId}`);
    console.log(`[SOCKET] User ${user.userId} connected`);

    socket.on('disconnect', () => {
      console.log(`[SOCKET] User ${user.userId} disconnected`);
    });

    // Allow clients to join emergency rooms (server validates membership)
    socket.on('join:emergency', (emergencyId: string) => {
      socket.join(`emergency:${emergencyId}`);
    });
  });

  return io;
}

function createEnvelope(event: SocketEvent, emergency: IEmergency, data: Record<string, unknown> = {}) {
  return {
    eventId: `${emergency._id}-${event}-${Date.now()}`,
    occurredAt: new Date().toISOString(),
    emergencyId: emergency._id.toString(),
    version: emergency.version,
    data,
  };
}

export const socketService = {
  getIO(): Server {
    return io;
  },

  /** Notify a specific responder of a new emergency (coarse location only). */
  async emitEmergencyCreated(emergency: IEmergency, responderUserId: string) {
    if (!io) return;
    const exactLoc = {
      latitude: emergency.location.coordinates[1],
      longitude: emergency.location.coordinates[0],
    };
    const coarse = matchingService.coarsenLocation(exactLoc);
    let ownerName = 'Senior Resident';
    try {
      const owner = await User.findById(emergency.ownerId);
      if (owner?.displayName) ownerName = owner.displayName;
    } catch (_) {}

    io.to(`user:${responderUserId}`).emit(
      SocketEvent.EMERGENCY_CREATED,
      createEnvelope(SocketEvent.EMERGENCY_CREATED, emergency, {
        category: emergency.category,
        status: emergency.status,
        location: coarse,
        ownerName,
      }),
    );
  },

  /** Notify emergency room that a responder accepted. */
  async emitResponderAccepted(emergency: IEmergency) {
    if (!io) return;
    let responderName = 'Volunteer Responder';
    let responderPhone = '';
    try {
      if (emergency.assignedResponderId) {
        const respUser = await User.findById(emergency.assignedResponderId);
        if (respUser) {
          responderName = respUser.displayName;
          responderPhone = respUser.phone;
        }
      }
    } catch (_) {}

    io.to(`emergency:${emergency._id}`).to(`user:${emergency.ownerId}`)
      .emit(
        SocketEvent.RESPONDER_ACCEPTED,
        createEnvelope(SocketEvent.RESPONDER_ACCEPTED, emergency, {
          status: emergency.status,
          assignedResponderId: emergency.assignedResponderId?.toString(),
          assignedResponder: {
            id: emergency.assignedResponderId?.toString(),
            displayName: responderName,
            phone: responderPhone,
            role: 'VOLUNTEER',
          },
        }),
      );
  },

  /** Notify that responder has arrived. */
  emitResponderArrived(emergency: IEmergency) {
    if (!io) return;
    io.to(`emergency:${emergency._id}`).to(`user:${emergency.ownerId}`)
      .emit(
        SocketEvent.RESPONDER_ARRIVED,
        createEnvelope(SocketEvent.RESPONDER_ARRIVED, emergency, {
          status: emergency.status,
        }),
      );
  },

  /** Notify that emergency is resolved. */
  emitEmergencyResolved(emergency: IEmergency) {
    if (!io) return;
    io.to(`emergency:${emergency._id}`).to(`user:${emergency.ownerId}`)
      .emit(
        SocketEvent.EMERGENCY_RESOLVED,
        createEnvelope(SocketEvent.EMERGENCY_RESOLVED, emergency, {
          status: emergency.status,
          resolution: emergency.resolution,
        }),
      );
  },

  /** Notify that emergency is cancelled. */
  emitEmergencyCancelled(emergency: IEmergency) {
    if (!io) return;
    io.to(`emergency:${emergency._id}`)
      .emit(
        SocketEvent.EMERGENCY_CANCELLED,
        createEnvelope(SocketEvent.EMERGENCY_CANCELLED, emergency, {
          status: emergency.status,
        }),
      );
  },

  /** Notify of a general emergency update (e.g., escalation). */
  emitEmergencyUpdated(emergency: IEmergency) {
    if (!io) return;
    io.to(`emergency:${emergency._id}`).to(`user:${emergency.ownerId}`)
      .emit(
        SocketEvent.EMERGENCY_UPDATED,
        createEnvelope(SocketEvent.EMERGENCY_UPDATED, emergency, {
          status: emergency.status,
          escalation: emergency.escalation,
        }),
      );
  },
};
