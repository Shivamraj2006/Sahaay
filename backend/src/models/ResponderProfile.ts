import mongoose, { Schema, Document, Types } from 'mongoose';
import { VerificationStatus } from '../shared/enums';

export interface IResponderProfile extends Document {
  userId: Types.ObjectId;
  verificationStatus: VerificationStatus;
  capabilities: string[];
  available: boolean;
  location: {
    type: 'Point';
    coordinates: [number, number]; // [longitude, latitude] — GeoJSON
  } | null;
  locationUpdatedAt: Date | null;
  completedCount: number;
  reputationScore: number;
  createdAt: Date;
  updatedAt: Date;
}

const responderProfileSchema = new Schema<IResponderProfile>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },
    verificationStatus: {
      type: String,
      enum: Object.values(VerificationStatus),
      default: VerificationStatus.UNVERIFIED,
    },
    capabilities: {
      type: [String],
      default: [],
    },
    available: {
      type: Boolean,
      default: false,
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
      },
      coordinates: {
        type: [Number],
      },
    },
    locationUpdatedAt: { type: Date, default: null },
    completedCount: { type: Number, default: 0, min: 0 },
    reputationScore: { type: Number, default: 0, min: 0 },
  },
  {
    timestamps: true,
    toJSON: {
      transform(_doc, ret: any) {
        ret.id = ret._id.toString();
        delete ret._id;
        delete ret.__v;
        // Convert GeoJSON to API-friendly { latitude, longitude }
        if (ret.location?.coordinates) {
          ret.location = {
            latitude: ret.location.coordinates[1],
            longitude: ret.location.coordinates[0],
          };
        }
        return ret;
      },
    },
  },
);

// Geospatial index for proximity queries
responderProfileSchema.index({ location: '2dsphere' });

export const ResponderProfile = mongoose.model<IResponderProfile>(
  'ResponderProfile',
  responderProfileSchema,
);
