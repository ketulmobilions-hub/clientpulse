import { env } from './config/env';
import app from './app';

process.on('uncaughtException', (err) => {
  console.error('[FATAL] Uncaught exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  console.error('[FATAL] Unhandled rejection:', reason);
  process.exit(1);
});

const server = app.listen(env.port, () => {
  console.log(JSON.stringify({ level: 'info', msg: `ClientPulse API running`, port: env.port, env: env.nodeEnv }));
});

process.on('SIGTERM', () => {
  console.log(JSON.stringify({ level: 'info', msg: 'SIGTERM received, shutting down gracefully' }));
  server.close(() => process.exit(0));
});
