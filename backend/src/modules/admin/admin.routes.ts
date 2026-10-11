import { Router } from 'express';
import { authenticate } from '../../middleware/auth';
import { authorize } from '../../middleware/authorize';
import { Role } from '../../shared/enums';
import { adminController } from './admin.controller';

const router = Router();

router.use(authenticate);
router.use(authorize(Role.VERIFIER, Role.ADMIN));

router.get('/responders/pending', (req, res, next) =>
  adminController.getPending(req, res, next),
);
router.post('/responders/:id/verify', (req, res, next) =>
  adminController.verify(req, res, next),
);
router.post('/responders/:id/revoke', (req, res, next) =>
  adminController.revoke(req, res, next),
);

export const adminRoutes = router;
