import { Request, Response, NextFunction } from 'express';
import { responderService } from './responders.service';
import { updateAvailabilitySchema } from './responders.validation';

export class RespondersController {
  async getMe(req: Request, res: Response, next: NextFunction) {
    try {
      const profile = await responderService.getProfile(req.user!.userId);
      res.json(profile);
    } catch (err) {
      next(err);
    }
  }

  async updateAvailability(req: Request, res: Response, next: NextFunction) {
    try {
      const input = updateAvailabilitySchema.parse(req.body);
      const profile = await responderService.updateAvailability(req.user!.userId, input);
      res.json(profile);
    } catch (err) {
      next(err);
    }
  }

  async getHistory(req: Request, res: Response, next: NextFunction) {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
      const result = await responderService.getHistory(req.user!.userId, page, limit);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }

  async getReputation(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await responderService.getReputation(req.user!.userId);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }
}

export const respondersController = new RespondersController();
