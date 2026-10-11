import { z } from 'zod';

export const updateAvailabilitySchema = z.object({
  available: z.boolean(),
  location: z
    .object({
      latitude: z.number().min(-90).max(90),
      longitude: z.number().min(-180).max(180),
    })
    .optional(),
});

export type UpdateAvailabilityInput = z.infer<typeof updateAvailabilitySchema>;
