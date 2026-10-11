import http from 'http';
import { createApp } from './app';
import { config } from './config';
import { connectDatabase } from './config/database';
import { initializeSocket } from './modules/realtime/socket';
import { startProofWorker } from './modules/trust/proof.worker';

async function main() {
  // Connect to MongoDB
  await connectDatabase();

  // Create Express app and HTTP server
  const app = createApp();
  const server = http.createServer(app);

  // Initialize Socket.IO
  initializeSocket(server);

  // Start the proof outbox worker
  startProofWorker();

  // Start listening
  server.listen(config.port, () => {
    console.log(`
╔═══════════════════════════════════════════════╗
║           🚨 Sahaay Backend Server            ║
╠═══════════════════════════════════════════════╣
║  Port:       ${String(config.port).padEnd(33)}║
║  Env:        ${config.nodeEnv.padEnd(33)}║
║  Blockchain: ${config.blockchainMode.padEnd(33)}║
╚═══════════════════════════════════════════════╝
    `);
  });

  // Graceful shutdown
  const shutdown = async (signal: string) => {
    console.log(`\n[SERVER] ${signal} received. Shutting down gracefully...`);
    server.close(() => {
      console.log('[SERVER] HTTP server closed.');
      process.exit(0);
    });
    // Force close after 10s
    setTimeout(() => process.exit(1), 10000);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

main().catch((err) => {
  console.error('[SERVER] Fatal startup error:', err);
  process.exit(1);
});
