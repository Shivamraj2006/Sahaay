import { createApp } from '../src/app';
import { connectDatabase } from '../src/config/database';
import type { Request, Response } from 'express';

const app = createApp();

export default async function handler(req: Request, res: Response) {
  try {
    await connectDatabase();
  } catch (err) {
    console.error('[VERCEL] DB connection failed:', err);
  }
  return app(req, res);
}
