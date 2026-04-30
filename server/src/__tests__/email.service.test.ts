const mockSend = jest.fn();

jest.mock('resend', () => ({
  Resend: jest.fn().mockImplementation(() => ({
    emails: { send: mockSend },
  })),
}));

jest.mock('../config/env', () => ({
  env: {
    resendApiKey: 're_test_key',
    resendFromEmail: 'ClientPulse <noreply@clientpulse.dev>',
    appBaseUrl: 'http://localhost:3000',
    jwtSecret: 'test-secret-that-is-long-enough-32chars',
  },
}));

import { sendMagicLinkEmail } from '../services/email.service';

beforeEach(() => jest.clearAllMocks());

describe('sendMagicLinkEmail', () => {
  const LINK_URL = 'http://localhost:3000/p/verify?token=abc123';

  it('calls resend.emails.send with correct to, subject, clientName, and link URL', async () => {
    mockSend.mockResolvedValue({ data: { id: 'email-id' }, error: null });

    await sendMagicLinkEmail('client@example.com', 'Alice', LINK_URL);

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        from: 'ClientPulse <noreply@clientpulse.dev>',
        to: 'client@example.com',
        subject: 'Your project update link',
        html: expect.stringContaining('Alice'),
      }),
    );
    const call = mockSend.mock.calls[0][0] as { html: string };
    expect(call.html).toContain(LINK_URL);
  });

  it('HTML-escapes clientName to prevent injection', async () => {
    mockSend.mockResolvedValue({ data: { id: 'email-id' }, error: null });

    await sendMagicLinkEmail('client@example.com', '<script>alert(1)</script>', LINK_URL);

    const call = mockSend.mock.calls[0][0] as { html: string };
    expect(call.html).not.toContain('<script>');
    expect(call.html).toContain('&lt;script&gt;');
  });

  it('uses fallback name "there" when clientName is the default', async () => {
    mockSend.mockResolvedValue({ data: { id: 'email-id' }, error: null });

    await sendMagicLinkEmail('client@example.com', 'there', LINK_URL);

    const call = mockSend.mock.calls[0][0] as { html: string };
    expect(call.html).toContain('Hi there');
  });

  it('throws EMAIL_ERROR when Resend returns an error object', async () => {
    mockSend.mockResolvedValue({ data: null, error: { message: 'rate limit exceeded' } });

    await expect(
      sendMagicLinkEmail('client@example.com', 'Alice', LINK_URL),
    ).rejects.toMatchObject({ code: 'EMAIL_ERROR', statusCode: 502 });
  });

  it('throws EMAIL_ERROR when Resend SDK rejects (network failure)', async () => {
    mockSend.mockRejectedValue(new Error('network error'));

    await expect(
      sendMagicLinkEmail('client@example.com', 'Alice', LINK_URL),
    ).rejects.toMatchObject({ code: 'EMAIL_ERROR', statusCode: 502 });
  });
});
