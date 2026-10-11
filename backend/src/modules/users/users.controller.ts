import { Request, Response, NextFunction } from 'express';
import { User } from '../../models/User';
import { NotFoundError } from '../../shared/errors';
import { updateUserSchema } from './users.validation';

export class UsersController {
  /** GET /users/me — Return the authenticated user's profile. */
  async getMe(req: Request, res: Response, next: NextFunction) {
    try {
      const user = await User.findById(req.user!.userId);
      if (!user) throw new NotFoundError('User');
      res.json(user.toJSON());
    } catch (err) {
      next(err);
    }
  }

  /** PATCH /users/me — Update permitted profile fields. */
  async updateMe(req: Request, res: Response, next: NextFunction) {
    try {
      const input = updateUserSchema.parse(req.body);
      const user = await User.findByIdAndUpdate(
        req.user!.userId,
        { $set: input },
        { new: true, runValidators: true },
      );
      if (!user) throw new NotFoundError('User');
      res.json(user.toJSON());
    } catch (err) {
      next(err);
    }
  }
}

export const usersController = new UsersController();
