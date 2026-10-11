import { expect } from 'chai';
import { ethers } from 'hardhat';
import { EmergencyLedger } from '../typechain-types';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';

describe('EmergencyLedger', () => {
  let ledger: EmergencyLedger;
  let admin: SignerWithAddress;
  let attestor: SignerWithAddress;
  let unauthorized: SignerWithAddress;

  const proofId = ethers.encodeBytes32String('proof-001');
  const emergencyRef = ethers.encodeBytes32String('emg-001');
  const responderRef = ethers.encodeBytes32String('resp-001');
  const payloadHash = ethers.keccak256(ethers.toUtf8Bytes('canonical-json-digest'));
  const schemaVersion = 1;

  beforeEach(async () => {
    [admin, attestor, unauthorized] = await ethers.getSigners();

    const factory = await ethers.getContractFactory('EmergencyLedger');
    ledger = await factory.deploy(admin.address);
    await ledger.waitForDeployment();

    // Grant attestor role to attestor
    await ledger.connect(admin).setAttestor(attestor.address, true);
  });

  describe('Access Control', () => {
    it('grants DEFAULT_ADMIN_ROLE to the initial admin', async () => {
      const DEFAULT_ADMIN_ROLE = await ledger.DEFAULT_ADMIN_ROLE();
      expect(await ledger.hasRole(DEFAULT_ADMIN_ROLE, admin.address)).to.be.true;
    });

    it('allows admin to grant and revoke ATTESTOR_ROLE', async () => {
      const ATTESTOR_ROLE = await ledger.ATTESTOR_ROLE();
      expect(await ledger.hasRole(ATTESTOR_ROLE, attestor.address)).to.be.true;

      await ledger.connect(admin).setAttestor(attestor.address, false);
      expect(await ledger.hasRole(ATTESTOR_ROLE, attestor.address)).to.be.false;
    });

    it('rejects non-admin calling setAttestor', async () => {
      await expect(
        ledger.connect(unauthorized).setAttestor(unauthorized.address, true)
      ).to.be.revertedWithCustomError(ledger, 'AccessControlUnauthorizedAccount');
    });

    it('rejects zero address for admin in constructor', async () => {
      const factory = await ethers.getContractFactory('EmergencyLedger');
      await expect(factory.deploy(ethers.ZeroAddress)).to.be.revertedWith('INVALID_ADMIN_ADDRESS');
    });
  });

  describe('Proof Recording', () => {
    it('allows authorized attestor to record milestone proof and emits ProofRecorded', async () => {
      const eventType = 0; // RESPONDER_ARRIVED

      const tx = await ledger.connect(attestor).recordProof(
        proofId,
        emergencyRef,
        responderRef,
        eventType,
        schemaVersion,
        payloadHash
      );
      const receipt = await tx.wait();
      const blockTimestamp = (await ethers.provider.getBlock(receipt!.blockNumber))!.timestamp;

      expect(await ledger.totalProofs()).to.equal(1);
      expect(await ledger.hasProof(proofId)).to.be.true;

      const record = await ledger.getProof(proofId);
      expect(record.proofId).to.equal(proofId);
      expect(record.emergencyRef).to.equal(emergencyRef);
      expect(record.responderRef).to.equal(responderRef);
      expect(record.eventType).to.equal(eventType);
      expect(record.schemaVersion).to.equal(schemaVersion);
      expect(record.payloadHash).to.equal(payloadHash);
      expect(record.attestor).to.equal(attestor.address);
      expect(record.blockTimestamp).to.equal(blockTimestamp);
      expect(record.exists).to.be.true;

      await expect(tx)
        .to.emit(ledger, 'ProofRecorded')
        .withArgs(
          proofId,
          emergencyRef,
          responderRef,
          eventType,
          schemaVersion,
          payloadHash,
          attestor.address,
          blockTimestamp
        );
    });

    it('allows recording EMERGENCY_RESOLVED (eventType 1)', async () => {
      const proofIdResolved = ethers.encodeBytes32String('proof-002');
      await ledger.connect(attestor).recordProof(
        proofIdResolved,
        emergencyRef,
        responderRef,
        1, // EMERGENCY_RESOLVED
        schemaVersion,
        payloadHash
      );

      expect(await ledger.hasProof(proofIdResolved)).to.be.true;
      const record = await ledger.getProof(proofIdResolved);
      expect(record.eventType).to.equal(1);
    });

    it('rejects duplicate proof ID submissions with PROOF_ALREADY_RECORDED', async () => {
      await ledger.connect(attestor).recordProof(
        proofId,
        emergencyRef,
        responderRef,
        0,
        schemaVersion,
        payloadHash
      );

      await expect(
        ledger.connect(attestor).recordProof(
          proofId,
          emergencyRef,
          responderRef,
          0,
          schemaVersion,
          payloadHash
        )
      ).to.be.revertedWith('PROOF_ALREADY_RECORDED');
    });

    it('rejects unauthorized accounts calling recordProof', async () => {
      await expect(
        ledger.connect(unauthorized).recordProof(
          proofId,
          emergencyRef,
          responderRef,
          0,
          schemaVersion,
          payloadHash
        )
      ).to.be.revertedWithCustomError(ledger, 'AccessControlUnauthorizedAccount');
    });

    it('reverts getProof for non-existent proof ID', async () => {
      const fakeProofId = ethers.encodeBytes32String('non-existent');
      await expect(ledger.getProof(fakeProofId)).to.be.revertedWith('PROOF_NOT_FOUND');
    });

    it('validates input parameters (reverts on zero bytes or zero schema version)', async () => {
      // Zero proofId
      await expect(
        ledger.connect(attestor).recordProof(
          ethers.ZeroHash,
          emergencyRef,
          responderRef,
          0,
          schemaVersion,
          payloadHash
        )
      ).to.be.revertedWith('INVALID_PROOF_ID');

      // Zero emergencyRef
      await expect(
        ledger.connect(attestor).recordProof(
          proofId,
          ethers.ZeroHash,
          responderRef,
          0,
          schemaVersion,
          payloadHash
        )
      ).to.be.revertedWith('INVALID_EMERGENCY_REF');

      // Zero responderRef
      await expect(
        ledger.connect(attestor).recordProof(
          proofId,
          emergencyRef,
          ethers.ZeroHash,
          0,
          schemaVersion,
          payloadHash
        )
      ).to.be.revertedWith('INVALID_RESPONDER_REF');

      // Zero schemaVersion
      await expect(
        ledger.connect(attestor).recordProof(
          proofId,
          emergencyRef,
          responderRef,
          0,
          0, // invalid version
          payloadHash
        )
      ).to.be.revertedWith('INVALID_SCHEMA_VERSION');

      // Zero payloadHash
      await expect(
        ledger.connect(attestor).recordProof(
          proofId,
          emergencyRef,
          responderRef,
          0,
          schemaVersion,
          ethers.ZeroHash
        )
      ).to.be.revertedWith('INVALID_PAYLOAD_HASH');
    });
  });
});
