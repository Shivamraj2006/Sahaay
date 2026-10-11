import { z } from 'zod';
import { Role } from '../../shared/enums';

export const registerSchema = z.object({
  displayName: z.string().trim().min(1, 'Display name is required').max(100),
  phone: z
    .string()
    .trim()
    .min(1, 'Phone is required')
    .transform((val) => {
      if (!val) return val;
      const digits = val.replace(/\D/g, '');
      if (digits.length === 10) return `+91${digits}`;
      if (digits.length === 12 && digits.startsWith('91')) return `+${digits}`;
      return val.startsWith('+') ? val : `+${val}`;
    })
    .refine((val) => /^\+91\d{10}$/.test(val), {
      message: 'Phone must be a valid 10-digit Indian number (+91XXXXXXXXXX)',
    }),
  password: z.string().min(8, 'Password must be at least 8 characters').max(128),
  requestedRole: z
    .preprocess(
      (val) => (typeof val === 'string' ? val.toUpperCase() : val),
      z.nativeEnum(Role),
    )
    .optional()
    .default(Role.ELDERLY_USER),
});

export const loginSchema = z.object({
  phone: z
    .string()
    .trim()
    .min(1, 'Phone is required')
    .transform((val) => {
      if (!val) return val;
      const digits = val.replace(/\D/g, '');
      if (digits.length === 10) return `+91${digits}`;
      if (digits.length === 12 && digits.startsWith('91')) return `+${digits}`;
      return val.startsWith('+') ? val : `+${val}`;
    }),
  password: z.string().min(1, 'Password is required'),
});

export const guestLoginSchema = z.object({
  displayName: z.string().trim().min(1).max(100).optional(),
  deviceId: z.string().trim().max(100).optional(),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type GuestLoginInput = z.infer<typeof guestLoginSchema>;
