import { z } from 'zod';

export const verifyResponderSchema = z.object({
  reason: z.string().max(500).optional().default(''),
});

export const revokeResponderSchema = z.object({
  reason: z.string().min(1, 'Revocation reason is required').max(500),
});

export type VerifyResponderInput = z.infer<typeof verifyResponderSchema>;
export type RevokeResponderInput = z.infer<typeof revokeResponderSchema>;
