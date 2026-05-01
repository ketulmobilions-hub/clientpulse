# ClientPulse — Testing Guide (Phase 1, Issues #1–#9)

> Covers: Express scaffold, Supabase schema, agency auth, magic links, portal middleware, Flutter scaffold, GoRouter, Riverpod DI, auth screens.

---

## Prerequisites

### Backend
- [ ] Supabase project created — grab `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Supabase migrations applied (issue #2 — run migration files in `server/supabase/migrations/`)
- [ ] Resend account created — grab `RESEND_API_KEY` and a verified sender email
- [ ] `server/.env` populated from `server/.env.example`
- [ ] Node.js 18+ installed

Required `.env` values:
```
NODE_ENV=development
PORT=3000
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
RESEND_API_KEY=<resend-api-key>
RESEND_FROM_EMAIL=noreply@yourdomain.com
JWT_SECRET=<min-32-chars>
COOKIE_SECRET=<min-32-chars>
APP_BASE_URL=http://localhost:3000
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:57450
```

### Flutter
- [ ] FVM installed (`fvm --version`)
- [ ] Backend running (at minimum `/auth/login` and `/auth/register`)
- [ ] Flutter SDK resolved via FVM (`fvm flutter --version`)

---

## 1. Run the Backend

```bash
cd server
npm install
npm run dev
```

Expected output:
```
[server] ClientPulse API running on port 3000
```

Verify health:
```bash
curl http://localhost:3000/health
```
Expected: `{"success":true}`

---

## 2. Run the Flutter App

```bash
cd client
fvm flutter pub get        # install dependencies
fvm dart run build_runner build -d   # generate freezed/riverpod code
fvm flutter run -d chrome  # run on Chrome (Web)
```

First load: browser shows a centered `CircularProgressIndicator` (the `/loading` route) for ~1 second, then redirects to `/login` since no session exists.

---

## 3. Automated Tests

### Backend (Jest)

```bash
cd server
npm test
```

Test files and what each covers:

| File | What it tests |
|------|---------------|
| `health.test.ts` | `GET /health` returns `{ success: true }` |
| `auth.service.test.ts` | `registerUser` (success + rollback on workspace failure), `loginUser` (success + wrong password), `generateMagicLink` (sends email, validates ownership), `verifyMagicLink` (marks used_at, returns 7-day JWT) |
| `auth.routes.test.ts` | `POST /auth/register` and `POST /auth/login` — validation errors, duplicate email, success responses |
| `magic-link.routes.test.ts` | `POST /auth/magic-link` (requires auth, UUID validation), `GET /auth/magic-link/verify` (valid + expired + missing token) |
| `auth.middleware.test.ts` | `requireAuth` — valid Bearer token sets `req.user`, missing/invalid token returns 401 |
| `portal.middleware.test.ts` | `requirePortal` — Bearer JWT (valid, expired, wrong type), signed cookie, `share_token` query param (valid, not found, malformed), no auth → 401 |
| `email.service.test.ts` | `sendMagicLinkEmail` calls Resend API with correct params |
| `errorHandler.test.ts` | `AppError` serialized as `{ success, error: { code, message } }`, unknown errors return 500, 404 handler |

Run a single file:
```bash
cd server
npm test -- --testPathPattern=auth.routes
```

### Flutter (widget + unit tests)

```bash
cd client
fvm flutter test
```

Test files and what each covers:

| File | What it tests |
|------|---------------|
| `shared/services/auth_service_test.dart` | `getToken()` retrieves raw token, `isTokenExpired()` parses JWT exp (includes 30s skew, handles malformed), `getUser()` returns null on partial corruption, `logout()` clears all 6 stored keys |
| `shared/providers/auth_state_provider_test.dart` | `isAuthenticatedProvider` false when no token / expired / missing fields; true with valid session. `currentUserProvider` returns user when session valid. |
| `core/router/app_router_test.dart` | Unauthenticated: `/dashboard` → `/login`, `/login` stays, `/p/token` bypasses guard, `/p/%20` (whitespace) → `/login`. Authenticated: `/login` → `/dashboard`, `/dashboard` stays. Loading state shows `/loading`. |
| `features/auth/presentation/screens/login_screen_test.dart` | Renders all fields, validates required + email format, does NOT validate password length (login-only behavior), trims email, shows SnackBar on `AuthServiceException`, password visibility toggle |
| `features/auth/presentation/screens/register_screen_test.dart` | Renders all 5 fields, validates name (max 100), workspace (max 100), email format, password (8–128), confirm match, trims name/workspace/email, shows SnackBar on error/auto-login failure, 2 visibility toggles, login link |

Run a single file:
```bash
cd client
fvm flutter test test/features/auth/presentation/screens/login_screen_test.dart
```

---

## 4. Manual Test Scenarios

### A. Backend API

Replace `TOKEN` with the JWT returned from login.

#### Health Check
```bash
curl http://localhost:3000/health
```
**Expected:** `{"success":true}`

---

#### Register — Valid
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"you@agency.com","password":"mypassword1","name":"Your Name","workspaceName":"Your Agency"}'
```
**Expected:** `{"success":true,"data":{"user":{...},"workspaceId":"<uuid>"}}`  
**Verify in Supabase:** `auth.users`, `public.users`, and `public.workspaces` all have matching rows.

#### Register — Duplicate Email
Same command, run twice.  
**Expected:** `{"success":false,"error":{"code":"EMAIL_EXISTS","message":"..."}}`

#### Register — Short Password
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"you@agency.com","password":"short","name":"Name","workspaceName":"Agency"}'
```
**Expected:** `{"success":false,"error":{"code":"VALIDATION_ERROR","message":"password must be at most ..."}}`

#### Register — Missing Field
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"you@agency.com","password":"mypassword1"}'
```
**Expected:** `{"success":false,"error":{"code":"VALIDATION_ERROR","message":"name is required"}}`

---

#### Login — Valid
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@agency.com","password":"mypassword1"}'
```
**Expected:** `{"success":true,"data":{"token":"<jwt>","user":{...}}}`  
Save the `token` value — you'll need it for authenticated requests below.

#### Login — Wrong Password
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@agency.com","password":"wrongpassword"}'
```
**Expected:** `{"success":false,"error":{"code":"INVALID_CREDENTIALS","message":"..."}}`

#### Login — Non-existent User
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"nobody@agency.com","password":"mypassword1"}'
```
**Expected:** `{"success":false,"error":{"code":"INVALID_CREDENTIALS","message":"..."}}`

---

#### Magic Link — Generate (requires auth + a valid project UUID)
```bash
curl -X POST http://localhost:3000/api/v1/auth/magic-link \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"projectId":"<project-uuid>","email":"client@example.com","clientName":"Client Co"}'
```
**Expected:** `{"success":true,"data":{"sent":true}}`  
**Verify:** Resend dashboard shows sent email; `public.magic_links` row has `email_sent_at` populated.

#### Magic Link — No Auth
Same command without the `Authorization` header.  
**Expected:** `{"success":false,"error":{"code":"UNAUTHORIZED","message":"..."}}`

#### Magic Link — Invalid UUID
```bash
curl -X POST http://localhost:3000/api/v1/auth/magic-link \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"projectId":"not-a-uuid","email":"client@example.com"}'
```
**Expected:** `{"success":false,"error":{"code":"VALIDATION_ERROR","message":"projectId must be a valid UUID"}}`

#### Magic Link — Verify (from email link)
Copy the `?token=...` from the magic link URL in the email:
```bash
curl "http://localhost:3000/api/v1/auth/magic-link/verify?token=<magic-link-token>"
```
**Expected:** `{"success":true,"data":{"token":"<portal-jwt>"}}`  
**Verify:** `public.magic_links` row has `used_at` populated.

#### Magic Link — Verify Used Token
Run the verify command again with the same token.  
**Expected:** `{"success":false,"error":{"code":"LINK_ALREADY_USED","message":"..."}}`

#### Magic Link — Verify Missing Token
```bash
curl "http://localhost:3000/api/v1/auth/magic-link/verify"
```
**Expected:** `{"success":false,"error":{"code":"VALIDATION_ERROR","message":"token query param is required"}}`

---

#### Portal Middleware — Bearer JWT
Use the portal JWT from magic link verify step. Apply to any route that uses `requirePortal` middleware:
```bash
curl http://localhost:3000/api/v1/portal/... \
  -H "Authorization: Bearer <portal-jwt>"
```
**Expected:** 200 with portal data (once portal routes are implemented — currently tests cover this).

#### Portal Middleware — share_token
```bash
curl "http://localhost:3000/api/v1/portal/...?share_token=<32-char-hex-token>"
```
Token must exist in `public.projects.share_token` column.  
**Expected:** 200

#### Portal Middleware — Invalid Token
```bash
curl "http://localhost:3000/api/v1/portal/...?share_token=invalid"
```
**Expected:** `{"success":false,"error":{"code":"INVALID_TOKEN","message":"Invalid or expired token"}}`

#### Portal Middleware — No Auth
```bash
curl http://localhost:3000/api/v1/portal/...
```
**Expected:** `{"success":false,"error":{"code":"UNAUTHORIZED","message":"Authentication required"}}`

---

### B. Flutter Auth Screens

Open Chrome to `http://localhost:57450` (port may differ — check `fvm flutter run` output).

---

#### Register — Valid Flow

1. App opens → loading spinner → redirected to `/login`
2. Click "Don't have an account? Register"
3. URL changes to `/register`, form shows: Full Name, Agency / Workspace Name, Email, Password, Confirm Password
4. Fill in:
   - Full Name: `Test User`
   - Agency / Workspace Name: `Test Agency`
   - Email: `you@agency.com`
   - Password: `mypassword1`
   - Confirm Password: `mypassword1`
5. Click "Create Account"
6. Button shows spinner while request is in flight
7. On success: auto-login triggers → router redirects to `/dashboard` (stub: plain "Dashboard" text)

---

#### Register — Field Validations

Submit the form empty or with invalid values to see inline errors:

| Field | Bad Input | Expected Error |
|-------|-----------|----------------|
| Full Name | _(empty)_ | `Name is required` |
| Full Name | 101-char string | `Name must be under 100 characters` |
| Agency / Workspace Name | _(empty)_ | `Workspace name is required` |
| Agency / Workspace Name | 101-char string | `Workspace name must be under 100 characters` |
| Email | _(empty)_ | `Email is required` |
| Email | `notanemail` | `Enter a valid email address` |
| Email | `user@` | `Enter a valid email address` |
| Email | `user@domain` | `Enter a valid email address` |
| Email | `user@domain.` | `Enter a valid email address` |
| Password | _(empty)_ | `Password is required` |
| Password | `short` (< 8 chars) | `Password must be at least 8 characters` |
| Confirm Password | _(empty)_ | `Please confirm your password` |
| Confirm Password | different value | `Passwords do not match` |

#### Register — Duplicate Email (Server Error)

1. Register with `you@agency.com` once successfully
2. Register again with same email
3. **Expected:** SnackBar with the server's error message (floating, appears at bottom)

---

#### Login — Valid Flow

1. Open `/login` (or click "Already have an account? Sign in" from register)
2. Fill in:
   - Email: `you@agency.com`
   - Password: `mypassword1`
3. Click "Sign In" (or press Enter in password field)
4. Button shows spinner → redirects to `/dashboard`

---

#### Login — Field Validations

| Field | Bad Input | Expected Error |
|-------|-----------|----------------|
| Email | _(empty)_ | `Email is required` |
| Email | `notanemail` | `Enter a valid email address` |
| Password | _(empty)_ | `Password is required` |

Note: Login does NOT validate password length (no min/max). Only `required` is checked.

#### Login — Wrong Password

1. Enter `you@agency.com` + `wrongpassword`
2. Click "Sign In"
3. **Expected:** SnackBar with credentials error message

---

#### Password Visibility Toggle

- Login screen: one eye icon on password field
- Register screen: two eye icons (password + confirm)
- Click icon → field switches from `••••••` to plain text
- Icon changes from `visibility_outlined` to `visibility_off_outlined`
- Click again → reverts

---

#### Auth Guard — Unauthenticated

1. With no session active (not logged in), navigate directly to `http://localhost:<port>/dashboard`
2. **Expected:** immediately redirected to `/login`

Same for `/settings`, `/projects/anything`.

---

#### Auth Guard — Authenticated

1. Log in successfully → land on `/dashboard`
2. Navigate directly to `http://localhost:<port>/login`
3. **Expected:** immediately redirected back to `/dashboard`

Same for `/register`.

---

#### Portal Route — Auth Bypass

1. With no session active, navigate to `http://localhost:<port>/p/sometoken`
2. **Expected:** no redirect to `/login`; stays on `/p/sometoken` route (shows portal stub: "Portal: sometoken")

This confirms the portal route bypasses the top-level auth guard.

#### Portal Route — Whitespace Token

1. Navigate to `http://localhost:<port>/p/%20` (URL-encoded space)
2. **Expected:** redirected to `/login` (whitespace token is rejected at route level)

---

#### Loading Screen

1. Open the app cold (clear localStorage: DevTools → Application → Local Storage → clear all)
2. Refresh the page
3. **Expected:** briefly see the loading spinner at center of screen
4. Then: redirected to `/login` (unauthenticated)

---

#### 404 / Unknown Route

1. Navigate to `http://localhost:<port>/nonexistent`
2. **Expected:** "Page not found" text with "Go home" button
3. Click "Go home" → navigates to `/dashboard` (or `/login` if unauthenticated)

---

## 5. Supabase Dashboard Verification

After running the backend tests above, verify state in Supabase:

| Action | Table | What to check |
|--------|-------|---------------|
| Register | `auth.users` | New row with matching email |
| Register | `public.users` | New row with `id`, `email`, `name`, `role=admin`, `workspace_id` |
| Register | `public.workspaces` | New row with `name = workspaceName` |
| Magic link send | `public.magic_links` | Row with `project_id`, `email`, `token` (hashed), `email_sent_at` populated |
| Magic link verify | `public.magic_links` | `used_at` populated on first verify; same row unchanged on second verify |

---

## 6. Not Yet Implemented (Stubs)

These routes exist in the router but are placeholder screens — do not expect real functionality:

| Route | Screen | Status |
|-------|--------|--------|
| `/dashboard` | DashboardScreen | Stub — plain "Dashboard" text |
| `/projects/:id` | ProjectDetailScreen | Stub — "Project: {id}" text |
| `/settings` | SettingsScreen | Stub — "Settings" text |
| `/p/:token` | PortalScreen | Stub — "Portal: {token}" text |

Phase 2 (issues #10+) will add workspace + project CRUD to replace these stubs.
