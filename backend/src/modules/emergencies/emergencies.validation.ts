import { z } from 'zod';
import { EmergencyCategory, ResolutionOutcome } from '../../shared/enums';

export const createEmergencySchema = z.object({
  category: z.nativeEnum(EmergencyCategory),
  location: z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
  }),
  notes: z.string().max(500).optional().default(''),
});

export const createGuestEmergencySchema = z.object({
  category: z.nativeEnum(EmergencyCategory),
  location: z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
  }),
  notes: z.string().max(500).optional().default(''),
  displayName: z.string().trim().min(1).max(100).optional(),
  contactPhone: z.string().trim().max(20).optional(),
});

export const resolveEmergencySchema = z.object({
  outcome: z.nativeEnum(ResolutionOutcome),
  note: z.string().max(500).optional().default(''),
});

export const escalateEmergencySchema = z.object({
  reason: z.string().min(1, 'Escalation reason is required').max(500),
});

export type CreateEmergencyInput = z.infer<typeof createEmergencySchema>;
export type CreateGuestEmergencyInput = z.infer<typeof createGuestEmergencySchema>;
export type ResolveEmergencyInput = z.infer<typeof resolveEmergencySchema>;
export type EscalateEmergencyInput = z.infer<typeof escalateEmergencySchema>;
