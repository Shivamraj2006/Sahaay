import dotenv from 'dotenv';
dotenv.config();

function required(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

function optional(key: string, fallback: string): string {
  return process.env[key] || fallback;
}

export const config = {
  port: parseInt(optional('PORT', '3000'), 10),
  nodeEnv: optional('NODE_ENV', 'development'),

  mongodb: {
    uri: required('MONGODB_URI'),
  },

  jwt: {
    secret: required('JWT_SECRET'),
    expiresIn: optional('JWT_EXPIRES_IN', '24h'),
  },

  matching: {
    initialRadiusM: parseInt(optional('MATCHING_INITIAL_RADIUS_M', '500'), 10),
    secondRadiusM: parseInt(optional('MATCHING_SECOND_RADIUS_M', '1000'), 10),
    maxRadiusM: parseInt(optional('MATCHING_MAX_RADIUS_M', '3000'), 10),
    locationFreshnessMin: parseInt(optional('MATCHING_LOCATION_FRESHNESS_MIN', '5'), 10),
    expansionDelayMs: parseInt(optional('MATCHING_EXPANSION_DELAY_MS', '10000'), 10),
  },

  blockchain: {
    rpcUrl: optional('BLOCKCHAIN_RPC_URL', ''),
    privateKey: optional('BLOCKCHAIN_PRIVATE_KEY', ''),
    emergencyLedgerAddress: optional('BLOCKCHAIN_EMERGENCY_LEDGER_ADDRESS', ''),
    responderRegistryAddress: optional('BLOCKCHAIN_RESPONDER_REGISTRY_ADDRESS', ''),
    reputationAddress: optional('BLOCKCHAIN_REPUTATION_ADDRESS', ''),
    chainId: parseInt(optional('BLOCKCHAIN_CHAIN_ID', '31337'), 10),
  },

  rateLimit: {
    windowMs: parseInt(optional('RATE_LIMIT_WINDOW_MS', '900000'), 10),
    maxRequests: parseInt(optional('RATE_LIMIT_MAX_REQUESTS', '100'), 10),
  },

  get isBlockchainConfigured(): boolean {
    return !!(this.blockchain.rpcUrl && this.blockchain.privateKey && this.blockchain.emergencyLedgerAddress);
  },
} as const;
