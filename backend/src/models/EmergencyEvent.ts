import mongoose, { Schema, Document, Types } from 'mongoose';
import { EmergencyEventType, EmergencyStatus } from '../shared/enums';

export interface IEmergencyEvent extends Document {
  emergencyId: Types.ObjectId;
  actorId: Types.ObjectId;
  actorRole: string;
  eventType: EmergencyEventType;
  previousStatus: EmergencyStatus | null;
  nextStatus: EmergencyStatus;
  version: number;
  correlationId: string;
  metadata: Record<string, unknown>;
  createdAt: Date;
}

const emergencyEventSchema = new Schema<IEmergencyEvent>(
  {
    emergencyId: {
      type: Schema.Types.ObjectId,
      ref: 'Emergency',
      required: true,
      index: true,
    },
    actorId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    actorRole: { type: String, required: true },
    eventType: {
      type: String,
      enum: Object.values(EmergencyEventType),
      required: true,
    },
    previousStatus: {
      type: String,
      enum: [...Object.values(EmergencyStatus), null],
      default: null,
    },
    nextStatus: {
      type: String,
      enum: Object.values(EmergencyStatus),
      required: true,
    },
    version: { type: Number, required: true },
    correlationId: { type: String, required: true },
    metadata: { type: Schema.Types.Mixed, default: {} },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
    toJSON: {
      transform(_doc, ret: any) {
        ret.id = ret._id.toString();
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  },
);

// Append-only: compound index for efficient emergency history queries
emergencyEventSchema.index({ emergencyId: 1, version: 1 });

export const EmergencyEvent = mongoose.model<IEmergencyEvent>(
  'EmergencyEvent',
  emergencyEventSchema,
);
