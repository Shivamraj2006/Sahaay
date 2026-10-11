import mongoose, { Schema, Document, Types } from 'mongoose';
import { VerificationAction, VerificationStatus } from '../shared/enums';

export interface IVerificationAudit extends Document {
  responderId: Types.ObjectId;
  actorId: Types.ObjectId;
  action: VerificationAction;
  statusBefore: VerificationStatus;
  statusAfter: VerificationStatus;
  reason: string;
  createdAt: Date;
}

const verificationAuditSchema = new Schema<IVerificationAudit>(
  {
    responderId: {
      type: Schema.Types.ObjectId,
      ref: 'ResponderProfile',
      required: true,
      index: true,
    },
    actorId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    action: {
      type: String,
      enum: Object.values(VerificationAction),
      required: true,
    },
    statusBefore: {
      type: String,
      enum: Object.values(VerificationStatus),
      required: true,
    },
    statusAfter: {
      type: String,
      enum: Object.values(VerificationStatus),
      required: true,
    },
    reason: { type: String, default: '' },
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

export const VerificationAudit = mongoose.model<IVerificationAudit>(
  'VerificationAudit',
  verificationAuditSchema,
);
