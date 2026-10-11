import { z } from 'zod';
import { Role } from '../../shared/enums';

export const registerSchema = z.object({
  displayName: z.string().trim().min(1, 'Display name is required').max(100),
  phone: z
    .string()
    .trim()
    .regex(/^\+91\d{10}$/, 'Phone must be a valid Indian number: +91XXXXXXXXXX'),
  password: z.string().min(8, 'Password must be at least 8 characters').max(128),
  requestedRole: z.nativeEnum(Role).optional().default(Role.ELDERLY_USER),
});

export const loginSchema = z.object({
  phone: z.string().trim().min(1, 'Phone is required'),
  password: z.string().min(1, 'Password is required'),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
