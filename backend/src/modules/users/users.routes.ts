import { Router } from 'express';
import { authenticate } from '../../middleware/auth';
import { usersController } from './users.controller';

const router = Router();

router.use(authenticate);

router.get('/me', (req, res, next) => usersController.getMe(req, res, next));
router.patch('/me', (req, res, next) => usersController.updateMe(req, res, next));

export const usersRoutes = router;
