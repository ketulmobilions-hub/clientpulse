// Runs before any test module is imported — sets required env vars
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-key';
process.env['RESEND_API_KEY'] = 'test-resend-key';
process.env['RESEND_FROM_EMAIL'] = 'ClientPulse <noreply@clientpulse.dev>';
process.env['JWT_SECRET'] = 'test-jwt-secret-that-is-at-least-32-chars-long';
process.env['APP_BASE_URL'] = 'http://localhost:3000';
process.env['ALLOWED_ORIGINS'] = 'http://localhost:5000';
process.env['PORT'] = '3000';
