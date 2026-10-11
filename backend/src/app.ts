import express from 'express';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import { config } from './config';
import { requestIdMiddleware } from './middleware/requestId';
import { errorHandler } from './middleware/errorHandler';
import { authLimiter } from './middleware/rateLimit';
import { authRoutes } from './modules/auth/auth.routes';
import { usersRoutes } from './modules/users/users.routes';
import { respondersRoutes } from './modules/responders/responders.routes';
import { emergenciesRoutes } from './modules/emergencies/emergencies.routes';
import { adminRoutes } from './modules/admin/admin.routes';
import path from 'path';
import fs from 'fs';

export function createApp() {
  const app = express();

  // ─── Global Middleware ──────────────────────────────────────────────
  app.use(cors());
  app.use(express.json({ limit: '1mb' }));
  app.use(requestIdMiddleware);

  // ─── Health Check & Docs ────────────────────────────────────────────
  app.get('/api/v1/health', (_req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
    });
  });

  app.get('/api/v1/openapi.json', (_req, res) => {
    const specPath = path.join(__dirname, '../openapi.json');
    if (fs.existsSync(specPath)) {
      res.sendFile(specPath);
    } else {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'OpenAPI specification not found.' } });
    }
  });

  // ─── Routes ─────────────────────────────────────────────────────────
  app.use('/api/v1/auth', authLimiter, authRoutes);
  app.use('/api/v1/users', usersRoutes);
  app.use('/api/v1/responders', respondersRoutes);
  app.use('/api/v1/emergencies', emergenciesRoutes);
  app.use('/api/v1/admin', adminRoutes);

  // ─── 404 Handler ────────────────────────────────────────────────────
  app.use((_req, res) => {
    res.status(404).json({
      error: {
        code: 'NOT_FOUND',
        message: 'The requested resource was not found.',
      },
    });
  });

  // ─── Global Error Handler ───────────────────────────────────────────
  app.use(errorHandler);

  return app;
}
