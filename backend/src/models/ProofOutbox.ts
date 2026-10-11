import mongoose, { Schema, Document, Types } from 'mongoose';
import { EmergencyEventType, ProofStatus } from '../shared/enums';

export interface IProofOutbox extends Document {
  emergencyId: Types.ObjectId;
  eventType: EmergencyEventType;
  schemaVersion: number;
  digest: string;
  proofStatus: ProofStatus;
  retryCount: number;
  transactionHash: string | null;
  failureCode: string | null;
  lastAttemptAt: Date | null;
  confirmedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

const proofOutboxSchema = new Schema<IProofOutbox>(
  {
    emergencyId: {
      type: Schema.Types.ObjectId,
      ref: 'Emergency',
      required: true,
      index: true,
    },
    eventType: {
      type: String,
      enum: Object.values(EmergencyEventType),
      required: true,
    },
    schemaVersion: { type: Number, default: 1 },
    digest: { type: String, required: true },
    proofStatus: {
      type: String,
      enum: Object.values(ProofStatus),
      default: ProofStatus.NOT_SUBMITTED,
      index: true,
    },
    retryCount: { type: Number, default: 0 },
    transactionHash: { type: String, default: null },
    failureCode: { type: String, default: null },
    lastAttemptAt: { type: Date, default: null },
    confirmedAt: { type: Date, default: null },
  },
  {
    timestamps: true,
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

// Unique constraint to prevent duplicate proof submissions for the same event
proofOutboxSchema.index({ emergencyId: 1, eventType: 1 }, { unique: true });

export const ProofOutbox = mongoose.model<IProofOutbox>(
  'ProofOutbox',
  proofOutboxSchema,
);
