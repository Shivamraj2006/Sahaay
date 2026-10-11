import { expect } from 'chai';
import { ethers } from 'hardhat';
import { ResponderRegistry } from '../typechain-types';
import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers';

describe('ResponderRegistry', () => {
  let registry: ResponderRegistry;
  let admin: SignerWithAddress;
  let verifier: SignerWithAddress;
  let unauthorized: SignerWithAddress;

  const responderRef = ethers.encodeBytes32String('responder-1');

  beforeEach(async () => {
    [admin, verifier, unauthorized] = await ethers.getSigners();

    const factory = await ethers.getContractFactory('ResponderRegistry');
    registry = await factory.deploy(admin.address);
    await registry.waitForDeployment();

    // Grant verifier role
    await registry.connect(admin).setVerifier(verifier.address, true);
  });

  describe('Access Control', () => {
    it('grants DEFAULT_ADMIN_ROLE to the initial admin', async () => {
      const DEFAULT_ADMIN_ROLE = await registry.DEFAULT_ADMIN_ROLE();
      expect(await registry.hasRole(DEFAULT_ADMIN_ROLE, admin.address)).to.be.true;
    });

    it('allows admin to grant and revoke VERIFIER_ROLE', async () => {
      const VERIFIER_ROLE = await registry.VERIFIER_ROLE();
      expect(await registry.hasRole(VERIFIER_ROLE, verifier.address)).to.be.true;

      // Revoke
      await registry.connect(admin).setVerifier(verifier.address, false);
      expect(await registry.hasRole(VERIFIER_ROLE, verifier.address)).to.be.false;
    });

    it('rejects non-admin calling setVerifier', async () => {
      await expect(
        registry.connect(unauthorized).setVerifier(unauthorized.address, true)
      ).to.be.revertedWithCustomError(registry, 'AccessControlUnauthorizedAccount');
    });

    it('rejects zero address for admin in constructor', async () => {
      const factory = await ethers.getContractFactory('ResponderRegistry');
      await expect(factory.deploy(ethers.ZeroAddress)).to.be.revertedWith('INVALID_ADMIN_ADDRESS');
    });

    it('rejects zero address in setVerifier', async () => {
      await expect(
        registry.connect(admin).setVerifier(ethers.ZeroAddress, true)
      ).to.be.revertedWith('INVALID_ACCOUNT_ADDRESS');
    });
  });

  describe('Verification Management', () => {
    it('defaults unknown responder to UNVERIFIED (0)', async () => {
      const status = await registry.getResponderStatus(responderRef);
      expect(status).to.equal(0); // UNVERIFIED
      expect(await registry.isVerified(responderRef)).to.be.false;
    });

    it('allows authorized verifier to mark a responder as VERIFIED (1) and emits event', async () => {
      const tx = await registry.connect(verifier).setResponderStatus(responderRef, 1);
      const receipt = await tx.wait();

      expect(await registry.getResponderStatus(responderRef)).to.equal(1);
      expect(await registry.isVerified(responderRef)).to.be.true;

      await expect(tx)
        .to.emit(registry, 'ResponderStatusChanged')
        .withArgs(responderRef, 1, verifier.address, (await ethers.provider.getBlock(receipt!.blockNumber))!.timestamp);
    });

    it('allows authorized verifier to mark a responder as REVOKED (2)', async () => {
      // First verify
      await registry.connect(verifier).setResponderStatus(responderRef, 1);
      expect(await registry.isVerified(responderRef)).to.be.true;

      // Then revoke
      await registry.connect(verifier).setResponderStatus(responderRef, 2);
      expect(await registry.getResponderStatus(responderRef)).to.equal(2);
      expect(await registry.isVerified(responderRef)).to.be.false;
    });

    it('rejects unauthorized accounts calling setResponderStatus', async () => {
      await expect(
        registry.connect(unauthorized).setResponderStatus(responderRef, 1)
      ).to.be.revertedWithCustomError(registry, 'AccessControlUnauthorizedAccount');
    });

    it('rejects setting status back to UNVERIFIED (0)', async () => {
      await expect(
        registry.connect(verifier).setResponderStatus(responderRef, 0)
      ).to.be.revertedWith('CANNOT_SET_TO_UNVERIFIED');
    });

    it('rejects zero bytes32 responder reference', async () => {
      await expect(
        registry.connect(verifier).setResponderStatus(ethers.ZeroHash, 1)
      ).to.be.revertedWith('INVALID_RESPONDER_REF');
    });
  });
});
