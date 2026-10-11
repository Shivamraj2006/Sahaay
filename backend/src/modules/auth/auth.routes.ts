import { Router } from 'express';
import { authController } from './auth.controller';

const router = Router();

router.post('/register', (req, res, next) => authController.register(req, res, next));
router.post('/login', (req, res, next) => authController.login(req, res, next));
router.post('/guest', (req, res, next) => authController.guest(req, res, next));

export const authRoutes = router;
