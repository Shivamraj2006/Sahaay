import mongoose, { Schema, Document, Types } from 'mongoose';
import { EmergencyCategory, EmergencyStatus, ProofStatus, ResolutionOutcome } from '../shared/enums';

export interface IEmergency extends Document {
  ownerId: Types.ObjectId;
  category: EmergencyCategory;
  status: EmergencyStatus;
  location: {
    type: 'Point';
    coordinates: [number, number]; // [longitude, latitude] — GeoJSON
  };
  notes: string;
  assignedResponderId: Types.ObjectId | null;
  version: number;
  escalation: {
    isEscalated: boolean;
    reason: string | null;
    previousStatus: EmergencyStatus | null;
  };
  resolution: {
    outcome: ResolutionOutcome | null;
    note: string | null;
    resolvedAt: Date | null;
  };
  proof: {
    status: ProofStatus;
    transactionHash: string | null;
  };
  cancelledAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

const emergencySchema = new Schema<IEmergency>(
  {
    ownerId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    category: {
      type: String,
      enum: Object.values(EmergencyCategory),
      required: true,
    },
    status: {
      type: String,
      enum: Object.values(EmergencyStatus),
      default: EmergencyStatus.ACTIVE,
      index: true,
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        required: true,
      },
      coordinates: {
        type: [Number],
        required: true,
      },
    },
    notes: { type: String, default: '', maxlength: 500 },
    assignedResponderId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    version: { type: Number, default: 1 },
    escalation: {
      isEscalated: { type: Boolean, default: false },
      reason: { type: String, default: null },
      previousStatus: {
        type: String,
        enum: [...Object.values(EmergencyStatus), null],
        default: null,
      },
    },
    resolution: {
      outcome: {
        type: String,
        enum: [...Object.values(ResolutionOutcome), null],
        default: null,
      },
      note: { type: String, default: null, maxlength: 500 },
      resolvedAt: { type: Date, default: null },
    },
    proof: {
      status: {
        type: String,
        enum: Object.values(ProofStatus),
        default: ProofStatus.NOT_SUBMITTED,
      },
      transactionHash: { type: String, default: null },
    },
    cancelledAt: { type: Date, default: null },
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

// Geospatial index for nearby queries
emergencySchema.index({ location: '2dsphere' });
// Compound index for active emergency lookups
emergencySchema.index({ status: 1, ownerId: 1 });

export const Emergency = mongoose.model<IEmergency>('Emergency', emergencySchema);
