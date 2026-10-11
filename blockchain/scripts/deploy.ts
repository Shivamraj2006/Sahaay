import { ethers, network } from 'hardhat';
import * as fs from 'fs';
import * as path from 'path';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('═'.repeat(60));
  console.log(`🚀 Deploying Sahaay Smart Contracts on network: ${network.name}`);
  console.log(`👤 Deployer / Admin: ${deployer.address}`);
  console.log(`💰 Balance: ${ethers.formatEther(await ethers.provider.getBalance(deployer.address))} ETH`);
  console.log('═'.repeat(60));

  // 1. Deploy ResponderRegistry
  console.log('\nDeploying ResponderRegistry...');
  const ResponderRegistryFactory = await ethers.getContractFactory('ResponderRegistry');
  const responderRegistry = await ResponderRegistryFactory.deploy(deployer.address);
  await responderRegistry.waitForDeployment();
  const responderRegistryAddress = await responderRegistry.getAddress();
  console.log(`✅ ResponderRegistry deployed to: ${responderRegistryAddress}`);

  // 2. Deploy EmergencyLedger
  console.log('\nDeploying EmergencyLedger...');
  const EmergencyLedgerFactory = await ethers.getContractFactory('EmergencyLedger');
  const emergencyLedger = await EmergencyLedgerFactory.deploy(deployer.address);
  await emergencyLedger.waitForDeployment();
  const emergencyLedgerAddress = await emergencyLedger.getAddress();
  console.log(`✅ EmergencyLedger deployed to: ${emergencyLedgerAddress}`);

  // 3. Configure Roles from Environment
  const verifierAddress = process.env.ADMIN_VERIFIER_ADDRESS || deployer.address;
  const attestorAddress = process.env.BACKEND_ATTESTOR_ADDRESS || deployer.address;

  console.log('\nConfiguring roles...');
  if (verifierAddress !== deployer.address) {
    const tx = await responderRegistry.setVerifier(verifierAddress, true);
    await tx.wait();
    console.log(`🔑 Granted VERIFIER_ROLE to: ${verifierAddress}`);
  } else {
    const tx = await responderRegistry.setVerifier(deployer.address, true);
    await tx.wait();
    console.log(`🔑 Granted VERIFIER_ROLE to deployer: ${deployer.address}`);
  }

  if (attestorAddress !== deployer.address) {
    const tx = await emergencyLedger.setAttestor(attestorAddress, true);
    await tx.wait();
    console.log(`🔑 Granted ATTESTOR_ROLE to: ${attestorAddress}`);
  } else {
    const tx = await emergencyLedger.setAttestor(deployer.address, true);
    await tx.wait();
    console.log(`🔑 Granted ATTESTOR_ROLE to deployer: ${deployer.address}`);
  }

  // 4. Save Deployment Summary
  const deploymentDir = path.join(__dirname, '../deployments');
  if (!fs.existsSync(deploymentDir)) {
    fs.mkdirSync(deploymentDir, { recursive: true });
  }

  const deploymentData = {
    network: network.name,
    chainId: network.config.chainId,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      ResponderRegistry: {
        address: responderRegistryAddress,
      },
      EmergencyLedger: {
        address: emergencyLedgerAddress,
      },
    },
    roles: {
      verifier: verifierAddress,
      attestor: attestorAddress,
    },
  };

  const deploymentFile = path.join(deploymentDir, `${network.name}.json`);
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentData, null, 2));
  console.log(`\n📄 Deployment info saved to: ${deploymentFile}`);

  // 5. Export Contract ABIs for Backend consumption
  const backendContractsDir = path.join(__dirname, '../../backend/src/contracts');
  if (!fs.existsSync(backendContractsDir)) {
    fs.mkdirSync(backendContractsDir, { recursive: true });
  }

  const responderRegistryArtifact = await import(
    '../artifacts/contracts/ResponderRegistry.sol/ResponderRegistry.json'
  );
  const emergencyLedgerArtifact = await import(
    '../artifacts/contracts/EmergencyLedger.sol/EmergencyLedger.json'
  );

  fs.writeFileSync(
    path.join(backendContractsDir, 'ResponderRegistry.json'),
    JSON.stringify(responderRegistryArtifact.abi, null, 2)
  );
  fs.writeFileSync(
    path.join(backendContractsDir, 'EmergencyLedger.json'),
    JSON.stringify(emergencyLedgerArtifact.abi, null, 2)
  );

  // Also write addresses file for backend
  fs.writeFileSync(
    path.join(backendContractsDir, 'addresses.json'),
    JSON.stringify(
      {
        responderRegistry: responderRegistryAddress,
        emergencyLedger: emergencyLedgerAddress,
        network: network.name,
        chainId: network.config.chainId,
      },
      null,
      2
    )
  );
  console.log(`📦 ABIs & contract addresses exported to: ${backendContractsDir}`);

  console.log('\n🎉 Deployment completed successfully!');
}

main().catch((error) => {
  console.error('Deployment error:', error);
  process.exitCode = 1;
});
