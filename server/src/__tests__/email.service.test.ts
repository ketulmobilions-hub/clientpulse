const mockSend = jest.fn();

jest.mock('resend', () => ({
  Resend: jest.fn().mockImplementation(() => ({
    emails: { send: mockSend },
  })),
}));

const mockEnvObj = {
  resendApiKey: 're_test_key',
  resendFromEmail: 'ClientPulse <noreply@clientpulse.dev>',
  appBaseUrl: 'http://localhost:3000',
  jwtSecret: 'test-secret-that-is-long-enough-32chars',
  nodeEnv: 'test',
};

jest.mock('../config/env', () => ({ get env() { return mockEnvObj; } }));

import { sendMagicLinkEmail, sendClientCommentNotificationEmail } from '../services/email.service';

beforeEach(() => jest.clearAllMocks());

describe('sendMagicLinkEmail', () => {
  const LINK_URL = 'https://clientpulse.dev/p/verify?token=abc123';

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

  it('includes clientName verbatim in the greeting', async () => {
    mockSend.mockResolvedValue({ data: { id: 'email-id' }, error: null });

    await sendMagicLinkEmail('client@example.com', 'Jordan', LINK_URL);

    const call = mockSend.mock.calls[0][0] as { html: string };
    expect(call.html).toContain('Hi Jordan');
  });

  it('throws INTERNAL_ERROR for non-https URL', async () => {
    await expect(
      sendMagicLinkEmail('client@example.com', 'Alice', 'http://example.com/verify'),
    ).rejects.toMatchObject({ code: 'INTERNAL_ERROR', statusCode: 500 });
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

describe('sendClientCommentNotificationEmail', () => {
  const DASHBOARD_URL = 'http://localhost:3000/dashboard';
  const ARGS = {
    to: 'agent@agency.com',
    projectName: 'Acme Website',
    updateTitle: 'Design Review',
    clientName: 'Bob',
    commentBody: 'Looks great!',
    dashboardUrl: DASHBOARD_URL,
  } as const;

  it('sends email with correct recipient, subject, and content', async () => {
    mockSend.mockResolvedValue({ data: { id: 'email-id' }, error: null });

    await sendClientCommentNotificationEmail(
      ARGS.to, ARGS.projectName, ARGS.updateTitle,
      ARGS.clientName, ARGS.commentBody, ARGS.dashboardUrl,
    );

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        to: ARGS.to,
        subject: `New comment from ${ARGS.clientName} on "${ARGS.updateTitle}"`,
        html: expect.stringContaining(ARGS.projectName),
      }),
    );
    const call = mockSend.mock.calls[0][0] as { html: string };
    expect(call.html).toContain(ARGS.updateTitle);
    expect(call.html).toContain(ARGS.clientName);
    expect(call.html).toContain(ARGS.commentBody);
    expect(call.html).toContain(DASHBOARD_URL);
  });

  it('HTML-escapes all inputs to prevent injection', async () => {
    mockSend.mockResolvedValue({ data: { id: 'email-id' }, error: null });

    await sendClientCommentNotificationEmail(
      ARGS.to,
      '<b>Project</b>',
      '<script>alert(1)</script>',
      '<img src=x>',
      '<evil>body</evil>',
      DASHBOARD_URL,
    );

    const call = mockSend.mock.calls[0][0] as { html: string };
    expect(call.html).not.toContain('<b>Project</b>');
    expect(call.html).not.toContain('<script>');
    expect(call.html).not.toContain('<img');
    expect(call.html).not.toContain('<evil>');
    expect(call.html).toContain('&lt;script&gt;');
  });

  it('truncates comment body longer than 500 characters', async () => {
    mockSend.mockResolvedValue({ data: { id: 'email-id' }, error: null });
    const longBody = 'a'.repeat(600);

    await sendClientCommentNotificationEmail(
      ARGS.to, ARGS.projectName, ARGS.updateTitle,
      ARGS.clientName, longBody, DASHBOARD_URL,
    );

    const call = mockSend.mock.calls[0][0] as { html: string };
    expect(call.html).not.toContain('a'.repeat(600));
    expect(call.html).toContain('…');
  });

  it('throws EMAIL_ERROR when Resend returns an error object', async () => {
    mockSend.mockResolvedValue({ data: null, error: { message: 'rate limit' } });

    await expect(
      sendClientCommentNotificationEmail(
        ARGS.to, ARGS.projectName, ARGS.updateTitle,
        ARGS.clientName, ARGS.commentBody, DASHBOARD_URL,
      ),
    ).rejects.toMatchObject({ code: 'EMAIL_ERROR', statusCode: 502 });
  });

  it('throws EMAIL_ERROR when Resend SDK rejects (network failure)', async () => {
    mockSend.mockRejectedValue(new Error('network error'));

    await expect(
      sendClientCommentNotificationEmail(
        ARGS.to, ARGS.projectName, ARGS.updateTitle,
        ARGS.clientName, ARGS.commentBody, DASHBOARD_URL,
      ),
    ).rejects.toMatchObject({ code: 'EMAIL_ERROR', statusCode: 502 });
  });

  it('throws INTERNAL_ERROR for non-localhost http URLs in non-production', async () => {
    await expect(
      sendClientCommentNotificationEmail(
        ARGS.to, ARGS.projectName, ARGS.updateTitle,
        ARGS.clientName, ARGS.commentBody, 'http://example.com/dashboard',
      ),
    ).rejects.toMatchObject({ code: 'INTERNAL_ERROR', statusCode: 500 });
  });

  it('throws INTERNAL_ERROR for http://localhost URL in production', async () => {
    mockEnvObj.nodeEnv = 'production';
    await expect(
      sendClientCommentNotificationEmail(
        ARGS.to, ARGS.projectName, ARGS.updateTitle,
        ARGS.clientName, ARGS.commentBody, 'http://localhost:3000/dashboard',
      ),
    ).rejects.toMatchObject({ code: 'INTERNAL_ERROR', statusCode: 500 });
    mockEnvObj.nodeEnv = 'test';
  });
});
