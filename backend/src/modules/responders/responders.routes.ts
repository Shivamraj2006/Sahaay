import { Router } from 'express';
import { authenticate } from '../../middleware/auth';
import { authorize } from '../../middleware/authorize';
import { Role } from '../../shared/enums';
import { respondersController } from './responders.controller';

const router = Router();

router.use(authenticate);
router.use(
  authorize(
    Role.VOLUNTEER,
    Role.MEDICAL_PROFESSIONAL,
    Role.ORGANIZATION_COORDINATOR,
  ),
);

router.get('/me', (req, res, next) => respondersController.getMe(req, res, next));
router.patch('/me/availability', (req, res, next) =>
  respondersController.updateAvailability(req, res, next),
);
router.get('/me/history', (req, res, next) =>
  respondersController.getHistory(req, res, next),
);
router.get('/me/reputation', (req, res, next) =>
  respondersController.getReputation(req, res, next),
);

export const respondersRoutes = router;
