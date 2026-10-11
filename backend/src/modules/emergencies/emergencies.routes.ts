import { Router } from 'express';
import { authenticate } from '../../middleware/auth';
import { sosLimiter } from '../../middleware/rateLimit';
import { emergenciesController } from './emergencies.controller';

const router = Router();

router.use(authenticate);

router.post('/', sosLimiter, (req, res, next) => emergenciesController.create(req, res, next));
router.get('/nearby', (req, res, next) => emergenciesController.getNearby(req, res, next));
router.get('/:id', (req, res, next) => emergenciesController.getById(req, res, next));
router.post('/:id/cancel', (req, res, next) => emergenciesController.cancel(req, res, next));
router.post('/:id/accept', (req, res, next) => emergenciesController.accept(req, res, next));
router.post('/:id/decline', (req, res, next) => emergenciesController.decline(req, res, next));
router.post('/:id/arrive', (req, res, next) => emergenciesController.arrive(req, res, next));
router.post('/:id/resolve', (req, res, next) => emergenciesController.resolve(req, res, next));
router.post('/:id/escalate', (req, res, next) => emergenciesController.escalate(req, res, next));

export const emergenciesRoutes = router;
