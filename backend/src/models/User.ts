import mongoose, { Schema, Document } from 'mongoose';
import { Role } from '../shared/enums';

export interface IUser extends Document {
  displayName: string;
  phone: string;
  passwordHash?: string;
  role: Role;
  isGuest: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    displayName: { type: String, required: true, trim: true },
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      index: true,
    },
    passwordHash: {
      type: String,
      required: function (this: IUser) {
        return !this.isGuest;
      },
      select: false,
    },
    role: {
      type: String,
      enum: Object.values(Role),
      required: true,
      default: Role.ELDERLY_USER,
    },
    isGuest: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(_doc, ret: any) {
        ret.id = ret._id.toString();
        ret.isGuest = ret.isGuest ?? false;
        delete ret._id;
        delete ret.__v;
        delete ret.passwordHash;
        return ret;
      },
    },
  },
);

export const User = mongoose.model<IUser>('User', userSchema);
