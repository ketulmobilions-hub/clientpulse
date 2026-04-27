import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { env } from './config/env';
import router from './routes';
import { errorHandler, notFound } from './middleware/errorHandler';
import { requestId } from './middleware/requestId';

const app = express();

app.use(helmet());

app.use(cors({
  origin: env.allowedOrigins.length > 0 ? env.allowedOrigins : false,
  credentials: true,
}));

app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMITED', message: 'Too many requests, please try again later.' } },
}));

app.use(requestId);
app.use(express.json({ limit: '10kb' }));

app.use('/api/v1', router);

app.use(notFound);
app.use(errorHandler);

export default app;
