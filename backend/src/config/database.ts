import mongoose from 'mongoose';
import { config } from './index';
import { Emergency } from '../models/Emergency';
import { ResponderProfile } from '../models/ResponderProfile';
import { User } from '../models/User';
import { ProofOutbox } from '../models/ProofOutbox';

export async function connectDatabase(): Promise<void> {
  try {
    await mongoose.connect(config.mongodb.uri, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 8000,
      socketTimeoutMS: 45000,
    });
    console.log('[DB] Connected to MongoDB');

    // Ensure geospatial 2dsphere and unique indexes exist on hosted cluster
    try {
      await Promise.all([
        Emergency.syncIndexes(),
        ResponderProfile.syncIndexes(),
        User.syncIndexes(),
        ProofOutbox.syncIndexes(),
      ]);
      console.log('[DB] Database geospatial and unique indexes verified');
    } catch (idxErr) {
      console.warn('[DB] Index verification warning (non-fatal):', idxErr);
    }
  } catch (error) {
    console.error('[DB] MongoDB connection failed:', error);
    process.exit(1);
  }

  mongoose.connection.on('error', (err) => {
    console.error('[DB] MongoDB runtime error:', err);
  });

  mongoose.connection.on('disconnected', () => {
    console.warn('[DB] MongoDB disconnected');
  });
}

export function isDatabaseConnected(): boolean {
  return mongoose.connection.readyState === 1;
}
