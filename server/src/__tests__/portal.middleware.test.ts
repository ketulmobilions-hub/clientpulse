import request from 'supertest';
import express from 'express';
import cookieParser from 'cookie-parser';
import jwt from 'jsonwebtoken';
import { supabaseAdmin } from '../config/adminDb';
import { requirePortal, PortalJwtPayload } from '../middleware/portal.middleware';
import { errorHandler, notFound } from '../middleware/errorHandler';
import { requestId } from '../middleware/requestId';

jest.mock('../config/adminDb', () => ({
  supabaseAdmin: {
    from: jest.fn(),
  },
}));

jest.mock('jsonwebtoken');

const mockJwtVerify = jwt.verify as jest.Mock;
const mockFrom = supabaseAdmin.from as jest.Mock;

const COOKIE_SECRET = 'test-cookie-secret-that-is-at-least-32chars';
const JWT_SECRET_PATTERN = /.{32,}/;

// eslint-disable-next-line @typescript-eslint/no-require-imports
const cookieSig = require('cookie-signature') as { sign: (val: string, secret: string) => string };

/** Matches cookie-parser's signed cookie format exactly */
function signCookieValue(val: string, secret: string): string {
  return 's:' + cookieSig.sign(val, secret);
}

function makeApp() {
  const app = express();
  app.use(cookieParser(COOKIE_SECRET));
  app.use(requestId);
  app.use(express.json());
  app.get('/portal-resource', requirePortal, (req, res) => {
    res.json({ success: true, portal: req.portal });
  });
  app.use(notFound);
  app.use(errorHandler);
  return app;
}

function validPayload(): PortalJwtPayload {
  return {
    type: 'portal',
    projectId: 'proj-uuid-1',
    email: 'client@example.com',
    clientName: 'Acme Corp',
  };
}

function makeShareTokenQuery() {
  return {
    select: jest.fn().mockReturnValue({
      eq: jest.fn().mockReturnValue({
        is: jest.fn().mockReturnValue({
          single: jest.fn(),
        }),
      }),
    }),
  };
}

beforeEach(() => jest.resetAllMocks());

describe('requirePortal middleware', () => {
  describe('portal JWT — Authorization Bearer header', () => {
    it('attaches portal context and calls next for valid Bearer token', async () => {
      mockJwtVerify.mockReturnValueOnce(validPayload());

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', 'Bearer valid-portal-jwt');

      expect(res.status).toBe(200);
      expect(res.body.portal).toEqual({
        projectId: 'proj-uuid-1',
        email: 'client@example.com',
        clientName: 'Acme Corp',
      });
      expect(mockJwtVerify).toHaveBeenCalledWith(
        'valid-portal-jwt',
        expect.stringMatching(JWT_SECRET_PATTERN),
        expect.objectContaining({ algorithms: ['HS256'] }),
      );
    });

    it('omits undefined email and clientName from portal context', async () => {
      mockJwtVerify.mockReturnValueOnce({ type: 'portal', projectId: 'proj-uuid-1' });

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', 'Bearer minimal-jwt');

      expect(res.status).toBe(200);
      expect(res.body.portal).toEqual({ projectId: 'proj-uuid-1' });
      expect(res.body.portal).not.toHaveProperty('email');
      expect(res.body.portal).not.toHaveProperty('clientName');
    });

    it('returns 401 INVALID_TOKEN when JWT signature is invalid', async () => {
      mockJwtVerify.mockImplementationOnce(() => {
        throw new Error('invalid signature');
      });

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', 'Bearer bad-jwt');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
      expect(res.headers['www-authenticate']).toMatch(/Bearer/);
    });

    it('returns 401 INVALID_TOKEN when JWT is expired', async () => {
      const err = Object.assign(new Error('jwt expired'), { name: 'TokenExpiredError' });
      mockJwtVerify.mockImplementationOnce(() => { throw err; });

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', 'Bearer expired-jwt');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
    });

    it('returns 401 INVALID_TOKEN when JWT type is not portal', async () => {
      mockJwtVerify.mockReturnValueOnce({ type: 'agency', projectId: 'proj-uuid-1' });

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', 'Bearer wrong-type-jwt');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
    });

    it('returns 401 INVALID_TOKEN when JWT has no projectId', async () => {
      mockJwtVerify.mockReturnValueOnce({ type: 'portal' });

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', 'Bearer no-project-jwt');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
    });

    it('returns 401 INVALID_TOKEN when projectId is not a string', async () => {
      mockJwtVerify.mockReturnValueOnce({ type: 'portal', projectId: 12345 });

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', 'Bearer number-projectid-jwt');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
    });

    it('returns 401 INVALID_TOKEN when Authorization value after Bearer is empty', async () => {
      mockJwtVerify.mockImplementationOnce(() => {
        throw new Error('jwt must be provided');
      });

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', 'Bearer ');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
    });

    it('returns 401 INVALID_TOKEN when Authorization is bare "Bearer" with no trailing space', async () => {
      mockJwtVerify.mockImplementationOnce(() => {
        throw new Error('jwt must be provided');
      });

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', 'Bearer');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
    });
  });

  describe('portal JWT — signed cookie', () => {
    it('reads the portal_token cookie, passes raw value to jwt.verify, attaches portal context', async () => {
      const RAW_TOKEN = 'raw-portal-jwt-cookie-value';
      const signed = signCookieValue(RAW_TOKEN, COOKIE_SECRET);

      mockJwtVerify.mockReturnValueOnce(validPayload());

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Cookie', `portal_token=${signed}`);

      expect(res.status).toBe(200);
      expect(res.body.portal.projectId).toBe('proj-uuid-1');
      expect(mockJwtVerify).toHaveBeenCalledWith(
        RAW_TOKEN,
        expect.stringMatching(JWT_SECRET_PATTERN),
        expect.objectContaining({ algorithms: ['HS256'] }),
      );
    });

    it('ignores an unsigned portal_token cookie (cookie-parser rejects it)', async () => {
      // unsigned value goes into req.cookies, not req.signedCookies — middleware ignores it
      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Cookie', 'portal_token=unsigned-value');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
      expect(mockJwtVerify).not.toHaveBeenCalled();
    });
  });

  describe('Bearer header takes priority over cookie', () => {
    it('uses Bearer token when both Authorization header and cookie are present', async () => {
      const BEARER_TOKEN = 'bearer-token-value';
      const COOKIE_RAW = 'cookie-token-value';
      const signed = signCookieValue(COOKIE_RAW, COOKIE_SECRET);

      mockJwtVerify.mockReturnValueOnce(validPayload());

      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', `Bearer ${BEARER_TOKEN}`)
        .set('Cookie', `portal_token=${signed}`);

      expect(res.status).toBe(200);
      expect(mockJwtVerify).toHaveBeenCalledTimes(1);
      expect(mockJwtVerify).toHaveBeenCalledWith(
        BEARER_TOKEN,
        expect.any(String),
        expect.any(Object),
      );
    });
  });

  describe('share_token query param', () => {
    it('attaches portal context with projectId when share_token resolves', async () => {
      const query = makeShareTokenQuery();
      query.select().eq().is().single.mockResolvedValueOnce({
        data: { id: 'proj-uuid-2' },
        error: null,
      });
      mockFrom.mockReturnValueOnce(query);

      const TOKEN = 'a'.repeat(64);
      const res = await request(makeApp())
        .get(`/portal-resource?share_token=${TOKEN}`);

      expect(res.status).toBe(200);
      expect(res.body.portal).toEqual({ projectId: 'proj-uuid-2' });
    });

    it('returns 401 INVALID_TOKEN when share_token not found (PGRST116)', async () => {
      const query = makeShareTokenQuery();
      query.select().eq().is().single.mockResolvedValueOnce({
        data: null,
        error: { code: 'PGRST116', message: 'Row not found' },
      });
      mockFrom.mockReturnValueOnce(query);

      const TOKEN = 'b'.repeat(64);
      const res = await request(makeApp())
        .get(`/portal-resource?share_token=${TOKEN}`);

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
    });

    it('returns 500 DB_ERROR on unexpected DB error for share_token', async () => {
      const query = makeShareTokenQuery();
      query.select().eq().is().single.mockResolvedValueOnce({
        data: null,
        error: { code: 'UNKNOWN', message: 'Connection failed' },
      });
      mockFrom.mockReturnValueOnce(query);

      const TOKEN = 'c'.repeat(64);
      const res = await request(makeApp())
        .get(`/portal-resource?share_token=${TOKEN}`);

      expect(res.status).toBe(500);
      expect(res.body.error.code).toBe('DB_ERROR');
    });

    it('returns 401 INVALID_TOKEN when project row has no id', async () => {
      const query = makeShareTokenQuery();
      query.select().eq().is().single.mockResolvedValueOnce({
        data: {},
        error: null,
      });
      mockFrom.mockReturnValueOnce(query);

      const TOKEN = 'd'.repeat(64);
      const res = await request(makeApp())
        .get(`/portal-resource?share_token=${TOKEN}`);

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
    });

    it('returns 401 INVALID_TOKEN when share_token fails format check (not hex)', async () => {
      const res = await request(makeApp())
        .get('/portal-resource?share_token=not-a-valid-hex-token!!');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
      expect(mockFrom).not.toHaveBeenCalled();
    });

    it('returns 401 UNAUTHORIZED when share_token is passed as an array', async () => {
      const res = await request(makeApp())
        .get('/portal-resource?share_token=abc&share_token=def');

      // array fails typeof === 'string' guard → treated as no token
      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
      expect(mockFrom).not.toHaveBeenCalled();
    });
  });

  describe('no token provided', () => {
    it('returns 401 UNAUTHORIZED when no token of any kind is present', async () => {
      const res = await request(makeApp()).get('/portal-resource');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
      expect(res.headers['www-authenticate']).toMatch(/Bearer/);
      expect(mockJwtVerify).not.toHaveBeenCalled();
      expect(mockFrom).not.toHaveBeenCalled();
    });

    it('returns 401 UNAUTHORIZED when Authorization header is not Bearer scheme', async () => {
      const res = await request(makeApp())
        .get('/portal-resource')
        .set('Authorization', 'Token some-token');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
      expect(mockJwtVerify).not.toHaveBeenCalled();
    });
  });
});
