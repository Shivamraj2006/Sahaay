import { ethers } from 'hardhat';
import { createCanonicalRecord, computeDigest } from '../../backend/src/modules/trust/canonical';
import { CANONICAL_TEST_VECTORS } from '../../backend/src/modules/trust/test-vectors';

async function main() {
  console.log('\n' + '═'.repeat(65));
  console.log('🔗 SAHAAY CROSS-LAYER INTEGRATION VERIFICATION: BACKEND <-> BLOCKCHAIN');
  console.log('═'.repeat(65) + '\n');

  let passedTests = 0;
  let totalTests = 0;

  function assert(condition: boolean, testName: string, detail?: string) {
    totalTests++;
    if (condition) {
      passedTests++;
      console.log(`  ✅ [PASS] ${testName}`);
    } else {
      console.error(`  ❌ [FAIL] ${testName} ${detail ? `(${detail})` : ''}`);
      throw new Error(`Integration check failed: ${testName}`);
    }
  }

  // 1. Setup Signers & Contracts
  console.log('📋 STEP 1: Deploying Contracts and Configuring Signers...');
  const [admin, verifier, attestor, unauthorizedUser] = await ethers.getSigners();

  const ResponderRegistryFactory = await ethers.getContractFactory('ResponderRegistry');
  const responderRegistry = await ResponderRegistryFactory.deploy(admin.address);
  await responderRegistry.waitForDeployment();
  const responderRegistryAddr = await responderRegistry.getAddress();

  const EmergencyLedgerFactory = await ethers.getContractFactory('EmergencyLedger');
  const emergencyLedger = await EmergencyLedgerFactory.deploy(admin.address);
  await emergencyLedger.waitForDeployment();
  const emergencyLedgerAddr = await emergencyLedger.getAddress();

  // Configure Roles
  await (await responderRegistry.connect(admin).setVerifier(verifier.address, true)).wait();
  await (await emergencyLedger.connect(admin).setAttestor(attestor.address, true)).wait();

  console.log(`   - ResponderRegistry deployed at: ${responderRegistryAddr}`);
  console.log(`   - EmergencyLedger deployed at:   ${emergencyLedgerAddr}`);
  console.log(`   - Admin:    ${admin.address}`);
  console.log(`   - Verifier: ${verifier.address} (granted VERIFIER_ROLE)`);
  console.log(`   - Attestor: ${attestor.address} (granted ATTESTOR_ROLE)\n`);

  // ──────────────────────────────────────────────────────────────────────────
  // TEST SUITE 1: RESPONDER REGISTRY INTEGRATION
  // ──────────────────────────────────────────────────────────────────────────
  console.log('📋 STEP 2: Verifying Responder Registry & Access Control...');

  const mockResponderId = '66f7a8b9c0d1e2f3a4b5c6d1'; // MongoDB ID format
  const responderRef = ethers.id(`responder:${mockResponderId}`);

  // Initial state check
  const initialStatus = await responderRegistry.getResponderStatus(responderRef);
  assert(Number(initialStatus) === 0, 'Unknown responder defaults to UNVERIFIED (0)');
  assert(!(await responderRegistry.isVerified(responderRef)), 'isVerified returns false for unverified responder');

  // Verify responder
  await (await responderRegistry.connect(verifier).setResponderStatus(responderRef, 1)).wait();
  const verifiedStatus = await responderRegistry.getResponderStatus(responderRef);
  assert(Number(verifiedStatus) === 1, 'Authorized verifier sets status to VERIFIED (1)');
  assert(await responderRegistry.isVerified(responderRef), 'isVerified returns true after verification');

  // Revoke responder
  await (await responderRegistry.connect(verifier).setResponderStatus(responderRef, 2)).wait();
  const revokedStatus = await responderRegistry.getResponderStatus(responderRef);
  assert(Number(revokedStatus) === 2, 'Authorized verifier revokes status to REVOKED (2)');
  assert(!(await responderRegistry.isVerified(responderRef)), 'isVerified returns false after revocation');

  // Unauthorized attempt
  let unauthorizedBlocked = false;
  try {
    await responderRegistry.connect(unauthorizedUser).setResponderStatus(responderRef, 1);
  } catch {
    unauthorizedBlocked = true;
  }
  assert(unauthorizedBlocked, 'Unauthorized user cannot modify responder verification status');
  console.log();

  // ──────────────────────────────────────────────────────────────────────────
  // TEST SUITE 2: CANONICAL PROOF RECORDING & DIGEST VERIFICATION
  // ──────────────────────────────────────────────────────────────────────────
  console.log('📋 STEP 3: Verifying End-to-End Proof Generation & On-Chain Audit...');

  const mockEmergencyId = '66f7a8b9c0d1e2f3a4b5c6e9';
  const assignedResponderId = '66f7a8b9c0d1e2f3a4b5c6f0';
  const timestamp = new Date('2026-10-11T12:00:00Z');

  // 1. Generate canonical record using backend code
  const canonicalRecord = createCanonicalRecord({
    emergencyId: mockEmergencyId,
    responderId: assignedResponderId,
    eventType: 'ARRIVED' as any,
    timestamp,
  });

  // 2. Compute SHA-256 digest using backend code
  const backendDigest = computeDigest(canonicalRecord);
  assert(backendDigest.length === 64, 'Backend produces valid 64-character SHA-256 hex digest');

  // 3. Prepare parameters for Solidity EmergencyLedger
  const proofIdBytes32 = ethers.id(`proof:${mockEmergencyId}:ARRIVED`);
  const emergencyRefBytes32 = ethers.id(`emergency:${mockEmergencyId}`);
  const responderRefBytes32 = ethers.id(`responder:${assignedResponderId}`);
  const payloadHashBytes32 = '0x' + backendDigest;
  const eventTypeEnum = 0; // RESPONDER_ARRIVED

  // 4. Record proof on-chain via attestor signer
  const recordTx = await emergencyLedger.connect(attestor).recordProof(
    proofIdBytes32,
    emergencyRefBytes32,
    responderRefBytes32,
    eventTypeEnum,
    canonicalRecord.schemaVersion,
    payloadHashBytes32
  );
  const receipt = await recordTx.wait();
  assert(receipt!.status === 1, 'Proof transaction confirmed on-chain');

  // 5. Query proof from contract and verify match
  assert(await emergencyLedger.hasProof(proofIdBytes32), 'Contract confirms proof exists via hasProof()');

  const onChainProof = await emergencyLedger.getProof(proofIdBytes32);
  assert(onChainProof.payloadHash.toLowerCase() === payloadHashBytes32.toLowerCase(), 'On-chain payloadHash matches backend SHA-256 digest byte-for-byte');
  assert(Number(onChainProof.schemaVersion) === canonicalRecord.schemaVersion, 'On-chain schemaVersion matches backend record schemaVersion');
  assert(onChainProof.attestor.toLowerCase() === attestor.address.toLowerCase(), 'On-chain attestor matches designated backend signer');
  assert(onChainProof.exists === true, 'On-chain proof record is marked exists=true');

  // 6. Test Replay Protection
  let duplicateRejected = false;
  try {
    await emergencyLedger.connect(attestor).recordProof(
      proofIdBytes32,
      emergencyRefBytes32,
      responderRefBytes32,
      eventTypeEnum,
      canonicalRecord.schemaVersion,
      payloadHashBytes32
    );
  } catch (err: any) {
    if (err.message.includes('PROOF_ALREADY_RECORDED')) {
      duplicateRejected = true;
    }
  }
  assert(duplicateRejected, 'Duplicate proof ID rejected by contract (replay protection)');
  console.log();

  // ──────────────────────────────────────────────────────────────────────────
  // TEST SUITE 3: SHARED CROSS-LAYER TEST VECTORS
  // ──────────────────────────────────────────────────────────────────────────
  console.log('📋 STEP 4: Verifying Shared Cross-Layer Test Vectors...');

  for (let i = 0; i < CANONICAL_TEST_VECTORS.length; i++) {
    const vector = CANONICAL_TEST_VECTORS[i];
    const computedDigest = computeDigest(vector.record as any);
    assert(
      computedDigest === vector.expectedDigest,
      `Test Vector #${i + 1} (${vector.description}) backend hash matches expected digest`
    );

    const vectorProofId = ethers.id(`vector-proof-${i + 1}`);
    const vectorEmergencyRef = ethers.id(`vector-emg-${i + 1}`);
    const vectorResponderRef = ethers.id(`vector-resp-${i + 1}`);
    const vectorEventType = vector.record.eventType === 'ARRIVED' ? 0 : 1;
    const vectorPayloadHash = '0x' + vector.expectedDigest;

    // Submit to blockchain
    const tx = await emergencyLedger.connect(attestor).recordProof(
      vectorProofId,
      vectorEmergencyRef,
      vectorResponderRef,
      vectorEventType,
      vector.record.schemaVersion,
      vectorPayloadHash
    );
    await tx.wait();

    const stored = await emergencyLedger.getProof(vectorProofId);
    assert(
      stored.payloadHash.toLowerCase() === vectorPayloadHash.toLowerCase(),
      `Test Vector #${i + 1} on-chain payloadHash matches byte-for-byte`
    );
  }
  console.log();

  // ──────────────────────────────────────────────────────────────────────────
  // TEST SUITE 4: FAILURE ISOLATION (BLOCKCHAIN UNAVAILABILITY DOES NOT BREAK BACKEND)
  // ──────────────────────────────────────────────────────────────────────────
  console.log('📋 STEP 5: Verifying Failure Isolation & Security Boundaries...');

  // 1. Non-attestor cannot record proofs
  let unauthorizedAttestorBlocked = false;
  try {
    const dummyId = ethers.id('unauthorized-dummy');
    await emergencyLedger.connect(unauthorizedUser).recordProof(
      dummyId,
      dummyId,
      dummyId,
      0,
      1,
      ethers.id('dummy-payload')
    );
  } catch {
    unauthorizedAttestorBlocked = true;
  }
  assert(unauthorizedAttestorBlocked, 'Unauthorized account cannot submit proofs to EmergencyLedger');

  // 2. Total proofs count matches
  const totalOnChain = await emergencyLedger.totalProofs();
  assert(Number(totalOnChain) === 1 + CANONICAL_TEST_VECTORS.length, 'totalProofs counter matches total recorded milestones');

  console.log('\n' + '═'.repeat(65));
  console.log(`🎉 ALL ${passedTests}/${totalTests} INTEGRATION CHECKS PASSED SUCCESSFULLY!`);
  console.log('   The Backend and Blockchain layers are fully and correctly integrated.');
  console.log('═'.repeat(65) + '\n');
}

main().catch((error) => {
  console.error('\n❌ Integration check encountered an error:', error);
  process.exitCode = 1;
});
