import { Request, Response, NextFunction } from 'express';
import { ResponderProfile } from '../../models/ResponderProfile';
import { VerificationAudit } from '../../models/VerificationAudit';
import {
  VerificationAction,
  VerificationStatus,
} from '../../shared/enums';
import { ConflictError, NotFoundError } from '../../shared/errors';
import {
  verifyResponderSchema,
  revokeResponderSchema,
} from './admin.validation';

export class AdminController {
  /** GET /admin/responders/pending — List responders awaiting verification. */
  async getPending(req: Request, res: Response, next: NextFunction) {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
      const skip = (page - 1) * limit;

      const [items, total] = await Promise.all([
        ResponderProfile.find({
          verificationStatus: {
            $in: [VerificationStatus.UNVERIFIED, VerificationStatus.PENDING],
          },
        })
          .populate('userId', 'displayName phone role')
          .sort({ createdAt: 1 })
          .skip(skip)
          .limit(limit),
        ResponderProfile.countDocuments({
          verificationStatus: {
            $in: [VerificationStatus.UNVERIFIED, VerificationStatus.PENDING],
          },
        }),
      ]);

      res.json({
        items: items.map((i) => i.toJSON()),
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      });
    } catch (err) {
      next(err);
    }
  }

  /** POST /admin/responders/:id/verify — Verify a responder. */
  async verify(req: Request, res: Response, next: NextFunction) {
    try {
      const input = verifyResponderSchema.parse(req.body);
      const responderId = req.params.id as string;
      const profile = await ResponderProfile.findById(responderId);
      if (!profile) throw new NotFoundError('Responder profile', responderId);

      if (profile.verificationStatus === VerificationStatus.VERIFIED) {
        throw new ConflictError(
          'ALREADY_VERIFIED',
          'Responder is already verified.',
        );
      }

      const statusBefore = profile.verificationStatus;
      profile.verificationStatus = VerificationStatus.VERIFIED;
      await profile.save();

      // Create audit trail
      await VerificationAudit.create({
        responderId: profile._id,
        actorId: req.user!.userId,
        action: VerificationAction.VERIFY,
        statusBefore,
        statusAfter: VerificationStatus.VERIFIED,
        reason: input.reason,
      });

      res.json(profile.toJSON());
    } catch (err) {
      next(err);
    }
  }

  /** POST /admin/responders/:id/revoke — Revoke a responder's verification. */
  async revoke(req: Request, res: Response, next: NextFunction) {
    try {
      const input = revokeResponderSchema.parse(req.body);
      const responderId = req.params.id as string;
      const profile = await ResponderProfile.findById(responderId);
      if (!profile) throw new NotFoundError('Responder profile', responderId);

      if (profile.verificationStatus === VerificationStatus.REVOKED) {
        throw new ConflictError(
          'ALREADY_REVOKED',
          'Responder verification is already revoked.',
        );
      }

      const statusBefore = profile.verificationStatus;
      profile.verificationStatus = VerificationStatus.REVOKED;
      profile.available = false; // Revoked responders should not be available
      await profile.save();

      // Create audit trail
      await VerificationAudit.create({
        responderId: profile._id,
        actorId: req.user!.userId,
        action: VerificationAction.REVOKE,
        statusBefore,
        statusAfter: VerificationStatus.REVOKED,
        reason: input.reason,
      });

      res.json(profile.toJSON());
    } catch (err) {
      next(err);
    }
  }
}

export const adminController = new AdminController();
