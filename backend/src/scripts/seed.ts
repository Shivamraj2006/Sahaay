import mongoose from 'mongoose';
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';

dotenv.config();

import { User } from '../models/User';
import { ResponderProfile } from '../models/ResponderProfile';
import { Role, VerificationStatus } from '../shared/enums';

const SALT_ROUNDS = 12;

/**
 * Seed script: creates demo accounts for local development and demos.
 *
 * Accounts:
 *  1. Elderly user (Kamla Devi) — SOS sender
 *  2. Verified volunteer responder (Rahul Sharma) — can accept emergencies
 *  3. Unverified volunteer (Priya Patel) — for testing ineligible responder
 *  4. Admin/Verifier (Admin User) — can verify/revoke responders
 *
 * All passwords: "password123"
 */
async function seed() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('MONGODB_URI is not set. Copy .env.example to .env and configure it.');
    process.exit(1);
  }

  await mongoose.connect(uri);
  console.log('[SEED] Connected to MongoDB');

  // Clear existing data
  await User.deleteMany({});
  await ResponderProfile.deleteMany({});
  console.log('[SEED] Cleared existing users and responder profiles');

  const passwordHash = await bcrypt.hash('password123', SALT_ROUNDS);

  // 1. Elderly User
  const elderlyUser = await User.create({
    displayName: 'Kamla Devi',
    phone: '+919876543210',
    passwordHash,
    role: Role.ELDERLY_USER,
  });
  console.log(`[SEED] Created elderly user: ${elderlyUser.displayName} (${elderlyUser.phone})`);

  // 2. Verified Volunteer Responder
  const responder1 = await User.create({
    displayName: 'Rahul Sharma',
    phone: '+919876543211',
    passwordHash,
    role: Role.VOLUNTEER,
  });
  await ResponderProfile.create({
    userId: responder1._id,
    verificationStatus: VerificationStatus.VERIFIED,
    capabilities: ['FIRST_AID', 'CPR'],
    available: true,
    location: {
      type: 'Point',
      coordinates: [77.6268, 12.9378], // Koramangala, Bengaluru (~350m from Kamla Devi) — [lng, lat]
    },
    locationUpdatedAt: new Date(),
    completedCount: 5,
    reputationScore: 5,
  });
  console.log(`[SEED] Created verified responder: ${responder1.displayName} (${responder1.phone})`);

  // 3. Verified Volunteer Responder 2 (for assignment race testing)
  const responder2 = await User.create({
    displayName: 'Amit Verma',
    phone: '+919876543213',
    passwordHash,
    role: Role.VOLUNTEER,
  });
  await ResponderProfile.create({
    userId: responder2._id,
    verificationStatus: VerificationStatus.VERIFIED,
    capabilities: ['FIRST_AID'],
    available: true,
    location: {
      type: 'Point',
      coordinates: [77.6280, 12.9390], // Koramangala, Bengaluru (~500m away) — [lng, lat]
    },
    locationUpdatedAt: new Date(),
    completedCount: 2,
    reputationScore: 2,
  });
  console.log(`[SEED] Created second verified responder: ${responder2.displayName} (${responder2.phone})`);

  // 4. Unverified Volunteer (for testing ineligible responder)
  const responder3 = await User.create({
    displayName: 'Priya Patel',
    phone: '+919876543212',
    passwordHash,
    role: Role.VOLUNTEER,
  });
  await ResponderProfile.create({
    userId: responder3._id,
    verificationStatus: VerificationStatus.UNVERIFIED,
    capabilities: [],
    available: true,
    location: {
      type: 'Point',
      coordinates: [79.0900, 21.1470], // Nearby Nagpur
    },
    locationUpdatedAt: new Date(),
  });
  console.log(`[SEED] Created unverified responder: ${responder3.displayName} (${responder3.phone})`);

  // 5. Admin / Verifier
  const admin = await User.create({
    displayName: 'Admin User',
    phone: '+919876543200',
    passwordHash,
    role: Role.ADMIN,
  });
  console.log(`[SEED] Created admin: ${admin.displayName} (${admin.phone})`);

  console.log(`
╔═══════════════════════════════════════════════════════════════╗
║                   🌱 Seed Complete!                          ║
╠═══════════════════════════════════════════════════════════════╣
║  All passwords: password123                                  ║
╠───────────────────────────────────────────────────────────────╣
║  Elderly User:         +919876543210 (Kamla Devi)             ║
║  Verified Responder 1: +919876543211 (Rahul Sharma)           ║
║  Verified Responder 2: +919876543213 (Amit Verma)             ║
║  Unverified Responder: +919876543212 (Priya Patel)            ║
║  Admin:                +919876543200 (Admin User)             ║
╚═══════════════════════════════════════════════════════════════╝
  `);

  await mongoose.disconnect();
  process.exit(0);
}

seed().catch((err) => {
  console.error('[SEED] Error:', err);
  process.exit(1);
});
