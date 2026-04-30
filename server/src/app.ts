import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import cookieParser from 'cookie-parser';
import { env } from './config/env';
import router from './routes';
import { errorHandler, notFound } from './middleware/errorHandler';
import { requestId } from './middleware/requestId';

const app = express();

// Trust exactly one proxy hop (Render's load balancer) so req.ip is the real client IP,
// not the proxy's internal address. Without this, all users share a single rate-limit bucket.
app.set('trust proxy', 1);

app.use(helmet());

app.use(cors({
  origin: env.allowedOrigins.length > 0 ? env.allowedOrigins : false,
  credentials: true,
}));

// Cookie parser before all custom middleware so req.signedCookies is available everywhere
app.use(cookieParser(env.cookieSecret));

app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many requests, please try again later.' } },
}));

// Tighter auth limiter applied before body parsing — prevents large-body floods from consuming parse resources
app.use('/api/v1/auth', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many attempts, please try again later.' } },
}));

// Tighter portal limiter to reduce share_token brute-force window
app.use('/api/v1/portal', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many requests, please try again later.' } },
}));

// Fix #10: invite limiter — each call creates a Supabase Auth user + sends a Resend email
app.use('/api/v1/workspace/invite', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many invite attempts, please try again later.' } },
}));

// Storage signed-URL limiter — each call allocates a Supabase Storage upload slot
app.use('/api/v1/storage', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many upload requests, please try again later.' } },
}));

app.use(requestId);
app.use(express.json({ limit: '10kb' }));

app.use('/api/v1', router);

app.use(notFound);
app.use(errorHandler);

export default app;
