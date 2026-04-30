import request from 'supertest';
import express from 'express';
import { errorHandler, notFound, AppError } from '../middleware/errorHandler';

// Env vars are set in setup.ts before this module loads

function makeApp(handler: express.RequestHandler) {
  const app = express();
  app.use(express.json());
  app.get('/test', handler);
  app.use(notFound);
  app.use(errorHandler);
  return app;
}

afterAll(() => {
  // Restore any env vars mutated in this file
  delete process.env['EXTRA_TEST_VAR'];
});

describe('errorHandler middleware', () => {
  it('formats AppError with correct statusCode, code, and message', async () => {
    const app = makeApp((_req, _res, next) => {
      next(new AppError('Invalid input', 422, 'VALIDATION_ERROR'));
    });
    const res = await request(app).get('/test');
    expect(res.status).toBe(422);
    expect(res.body).toEqual({
      success: false,
      error: { code: 'VALIDATION_ERROR', message: 'Invalid input' },
    });
  });

  it('hides internal details for non-AppError (generic Error)', async () => {
    const app = makeApp((_req, _res, next) => {
      next(new Error('SELECT * FROM users — internal db error'));
    });
    const res = await request(app).get('/test');
    expect(res.status).toBe(500);
    expect(res.body).toEqual({
      success: false,
      error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' },
    });
  });

  it('supports instanceof check on AppError', () => {
    const err = new AppError('Test', 400, 'TEST');
    expect(err instanceof AppError).toBe(true);
    expect(err instanceof Error).toBe(true);
  });
});

describe('notFound handler', () => {
  it('returns 404 with NOT_FOUND code', async () => {
    const app = makeApp((_req, _res, next) => next());
    const res = await request(app).get('/test');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});
