import { Request, Response, NextFunction } from 'express';
import { emergencyService } from './emergencies.service';
import {
  createEmergencySchema,
  resolveEmergencySchema,
  escalateEmergencySchema,
} from './emergencies.validation';

export class EmergenciesController {
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      const input = createEmergencySchema.parse(req.body);
      const result = await emergencyService.create(req.user!, input);
      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  }

  async getNearby(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await emergencyService.getNearby(req.user!);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }

  async getById(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await emergencyService.getById(req.user!, req.params.id as string);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }

  async cancel(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await emergencyService.cancel(req.user!, req.params.id as string);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }

  async accept(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await emergencyService.accept(req.user!, req.params.id as string);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }

  async decline(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await emergencyService.decline(req.user!, req.params.id as string);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }

  async arrive(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await emergencyService.arrive(req.user!, req.params.id as string);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }

  async resolve(req: Request, res: Response, next: NextFunction) {
    try {
      const input = resolveEmergencySchema.parse(req.body);
      const result = await emergencyService.resolve(req.user!, req.params.id as string, input);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }

  async escalate(req: Request, res: Response, next: NextFunction) {
    try {
      const input = escalateEmergencySchema.parse(req.body);
      const result = await emergencyService.escalate(req.user!, req.params.id as string, input);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }
}

export const emergenciesController = new EmergenciesController();
