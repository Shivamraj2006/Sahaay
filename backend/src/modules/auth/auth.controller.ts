import { Request, Response, NextFunction } from 'express';
import { authService } from './auth.service';
import { registerSchema, loginSchema, guestLoginSchema } from './auth.validation';

export class AuthController {
  async register(req: Request, res: Response, next: NextFunction) {
    try {
      const input = registerSchema.parse(req.body);
      const result = await authService.register(input);
      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  }

  async login(req: Request, res: Response, next: NextFunction) {
    try {
      const input = loginSchema.parse(req.body);
      const result = await authService.login(input);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }

  async guest(req: Request, res: Response, next: NextFunction) {
    try {
      const input = guestLoginSchema.parse(req.body || {});
      const result = await authService.guestLogin(input);
      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  }
}

export const authController = new AuthController();
