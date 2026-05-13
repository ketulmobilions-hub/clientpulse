import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import cookieParser from 'cookie-parser';
import { env } from './config/env';
import router from './routes';
import { errorHandler, notFound } from './middleware/errorHandler';
import { ErrorCodes } from './errors/codes';
import { requestId } from './middleware/requestId';

const app = express();

// Trust exactly one proxy hop (Render's load balancer) so req.ip is the real client IP,
// not the proxy's internal address. Without this, all users share a single rate-limit bucket.
app.set('trust proxy', 1);

app.use(helmet());

app.use(cors({
  // Dev reflects the request origin (browsers reject wildcard `*` paired with
  // credentials). Test/prod use the explicit allowlist. NODE_ENV is validated
  // in env.ts against an enum, so a typo throws at startup rather than silently
  // enabling origin reflection in prod.
  origin: env.nodeEnv === 'development'
    ? true
    : env.allowedOrigins.length > 0 ? env.allowedOrigins : false,
  credentials: true,
}));

// Cookie parser before all custom middleware so req.signedCookies is available everywhere
app.use(cookieParser(env.cookieSecret));

app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: ErrorCodes.RATE_LIMITED, message: 'Too many requests, please try again later.' } },
}));

// Tighter auth limiter applied before body parsing — prevents large-body floods from consuming parse resources
app.use('/api/v1/auth', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: ErrorCodes.RATE_LIMITED, message: 'Too many attempts, please try again later.' } },
}));

// Per-email throttle on /auth/login. The IP-level limiter above caps probes
// from a single source, but credential-stuffing attacks distribute across IPs.
// The requires_verification response shape is also a positive existence oracle
// for (email + correct-password) pairs — capping retries per email blunts that.
// Body must be parsed BEFORE this fires to extract the email.
app.use('/api/v1/auth/login', express.json(), rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    const raw = (req.body as { email?: unknown } | undefined)?.email;
    const email = typeof raw === 'string' ? raw.toLowerCase().trim() : '';
    // Fall back to IP if no email — never use empty key (would lump all
    // missing-email requests together and 429 every legitimate caller).
    return email || `ip:${req.ip ?? 'unknown'}`;
  },
  message: { success: false, error: { code: ErrorCodes.RATE_LIMITED, message: 'Too many login attempts for this account, please try again later.' } },
}));

// Tighter portal limiter to reduce share_token brute-force window
app.use('/api/v1/portal', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: ErrorCodes.RATE_LIMITED, message: 'Too many requests, please try again later.' } },
}));

// Fix #10: invite limiter — each call creates a Supabase Auth user + sends a Resend email
app.use('/api/v1/workspace/invite', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: ErrorCodes.RATE_LIMITED, message: 'Too many invite attempts, please try again later.' } },
}));

// Storage signed-URL limiter — each call allocates a Supabase Storage upload slot
app.use('/api/v1/storage', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: ErrorCodes.RATE_LIMITED, message: 'Too many upload requests, please try again later.' } },
}));

app.use(requestId);
app.use(express.json({ limit: '10kb' }));

app.use('/api/v1', router);

app.use(notFound);
app.use(errorHandler);

export default app;
