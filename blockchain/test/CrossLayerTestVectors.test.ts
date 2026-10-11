import { expect } from 'chai';
import { ethers } from 'hardhat';
import crypto from 'crypto';
import { EmergencyLedger } from '../typechain-types';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';

describe('Cross-Layer Test Vectors (Backend <-> Solidity)', () => {
  let ledger: EmergencyLedger;
  let admin: SignerWithAddress;
  let attestor: SignerWithAddress;

  // Exact canonical test vectors agreed with backend
  const TEST_VECTORS = [
    {
      description: 'Vector 1: Responder arrived event without outcome',
      record: {
        schemaVersion: 1,
        proofId: 'e9f50cb90e7a1e0b',
        emergencyRef: '8f6828b1e4277b94',
        responderRef: 'a52e25fa9e4210bc',
        eventType: 'ARRIVED',
        occurredAt: '2026-10-11T08:30:00Z',
      },
      canonicalJson:
        '{"emergencyRef":"8f6828b1e4277b94","eventType":"ARRIVED","occurredAt":"2026-10-11T08:30:00Z","proofId":"e9f50cb90e7a1e0b","responderRef":"a52e25fa9e4210bc","schemaVersion":1}',
      expectedDigestHex:
        'fc51fa0c305722c7df633eb469c789d82377844d7c953f9e7ec913903f25bd6e',
      solidityEventType: 0, // RESPONDER_ARRIVED
    },
    {
      description: 'Vector 2: Emergency resolved event with ASSISTED outcome',
      record: {
        schemaVersion: 1,
        proofId: '7c11f42d8a55e109',
        emergencyRef: '8f6828b1e4277b94',
        responderRef: 'a52e25fa9e4210bc',
        eventType: 'RESOLVED',
        occurredAt: '2026-10-11T08:45:00Z',
        outcome: 'ASSISTED',
      },
      canonicalJson:
        '{"emergencyRef":"8f6828b1e4277b94","eventType":"RESOLVED","occurredAt":"2026-10-11T08:45:00Z","outcome":"ASSISTED","proofId":"7c11f42d8a55e109","responderRef":"a52e25fa9e4210bc","schemaVersion":1}',
      expectedDigestHex:
        'bbfa86f776e82df9bc0044bb781d2cc5bb4935c7c1aac23abca1c51ec56d257f',
      solidityEventType: 1, // EMERGENCY_RESOLVED
    },
    {
      description: 'Vector 3: Emergency resolved with REFERRED_TO_EMERGENCY_SERVICES',
      record: {
        schemaVersion: 1,
        proofId: '1b9a2c3d4e5f6071',
        emergencyRef: '3e4f5a6b7c8d9e0f',
        responderRef: 'f0e1d2c3b4a59687',
        eventType: 'RESOLVED',
        occurredAt: '2026-10-11T09:15:30Z',
        outcome: 'REFERRED_TO_EMERGENCY_SERVICES',
      },
      canonicalJson:
        '{"emergencyRef":"3e4f5a6b7c8d9e0f","eventType":"RESOLVED","occurredAt":"2026-10-11T09:15:30Z","outcome":"REFERRED_TO_EMERGENCY_SERVICES","proofId":"1b9a2c3d4e5f6071","responderRef":"f0e1d2c3b4a59687","schemaVersion":1}',
      expectedDigestHex:
        'f9716dd6c2b72cd61a71bb46ec73e76340a5cd0a53f727f033a4783435418460',
      solidityEventType: 1, // EMERGENCY_RESOLVED
    },
  ];

  beforeEach(async () => {
    [admin, attestor] = await ethers.getSigners();
    const factory = await ethers.getContractFactory('EmergencyLedger');
    ledger = await factory.deploy(admin.address);
    await ledger.waitForDeployment();
    await ledger.connect(admin).setAttestor(attestor.address, true);
  });

  it('validates canonical serialization and SHA-256 hash byte-for-byte across layers', async () => {
    for (const vector of TEST_VECTORS) {
      // 1. Verify JSON key sorting matches canonicalJson
      const sortedJson = JSON.stringify(
        vector.record,
        Object.keys(vector.record).sort()
      );
      expect(sortedJson).to.equal(vector.canonicalJson);

      // 2. Verify SHA-256 calculation
      const calculatedHashHex = crypto
        .createHash('sha256')
        .update(sortedJson, 'utf-8')
        .digest('hex');
      expect(calculatedHashHex).to.equal(vector.expectedDigestHex);

      // 3. Verify format for Solidity bytes32 parameter
      const payloadHashBytes32 = '0x' + calculatedHashHex;
      expect(payloadHashBytes32).to.have.length(66); // '0x' + 64 hex chars

      // 4. Encode opaque reference strings as bytes32
      const proofIdBytes32 = ethers.encodeBytes32String(vector.record.proofId);
      const emergencyRefBytes32 = ethers.encodeBytes32String(vector.record.emergencyRef);
      const responderRefBytes32 = ethers.encodeBytes32String(vector.record.responderRef);

      // 5. Submit to EmergencyLedger contract
      const tx = await ledger.connect(attestor).recordProof(
        proofIdBytes32,
        emergencyRefBytes32,
        responderRefBytes32,
        vector.solidityEventType,
        vector.record.schemaVersion,
        payloadHashBytes32
      );
      await tx.wait();

      // 6. Query from contract and verify payloadHash matches byte-for-byte
      const record = await ledger.getProof(proofIdBytes32);
      expect(record.payloadHash).to.equal(payloadHashBytes32);
      expect(record.schemaVersion).to.equal(vector.record.schemaVersion);
      expect(record.eventType).to.equal(vector.solidityEventType);
      expect(record.exists).to.be.true;
    }

    expect(await ledger.totalProofs()).to.equal(TEST_VECTORS.length);
  });
});
