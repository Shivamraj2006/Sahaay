import { z } from 'zod';

export const updateUserSchema = z.object({
  displayName: z.string().trim().min(1).max(100).optional(),
}).strict();

export type UpdateUserInput = z.infer<typeof updateUserSchema>;
