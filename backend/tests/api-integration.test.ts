import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../src/app';

describe('Express App Endpoints (Supertest)', () => {
  const app = createApp();

  it('GET /api/v1/health returns 200 with service health info', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.version).toBe('1.0.0');
    expect(res.body.timestamp).toBeDefined();
    expect(res.headers['x-request-id']).toBeDefined();
  });

  it('GET /api/v1/openapi.json serves the published OpenAPI specification', async () => {
    const res = await request(app).get('/api/v1/openapi.json');
    expect(res.status).toBe(200);
    expect(res.body.openapi).toBe('3.0.3');
    expect(res.body.info.title).toContain('Sahaay');
    expect(res.body.paths).toBeDefined();
    expect(res.body.paths['/emergencies']).toBeDefined();
  });

  it('GET /api/v1/non-existent returns 404 with standard error shape', async () => {
    const res = await request(app).get('/api/v1/non-existent-route');
    expect(res.status).toBe(404);
    expect(res.body.error).toBeDefined();
    expect(res.body.error.code).toBe('NOT_FOUND');
    expect(res.body.error.message).toBeDefined();
    expect(res.headers['x-request-id']).toBeDefined();
  });

  it('protected routes reject unauthenticated requests with 401', async () => {
    const res = await request(app).get('/api/v1/users/me');
    expect(res.status).toBe(401);
    expect(res.body.error).toBeDefined();
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('emergency routes reject unauthenticated requests with 401', async () => {
    const res = await request(app).get('/api/v1/emergencies/nearby');
    expect(res.status).toBe(401);
    expect(res.body.error).toBeDefined();
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });
});
