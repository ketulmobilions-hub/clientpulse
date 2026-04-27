// Runs before any test module is imported — sets required env vars
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] = 'test-service-key';
process.env['RESEND_API_KEY'] = 'test-resend-key';
process.env['JWT_SECRET'] = 'test-jwt-secret-32-chars-minimum!!';
process.env['ALLOWED_ORIGINS'] = 'http://localhost:5000';
process.env['PORT'] = '3000';
