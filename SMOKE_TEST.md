# ClientPulse — E2E Production Smoke Test

Run this top-to-bottom on production URLs before demo day. All checkpoints must pass. Estimated time: ~30 min.

---

## Prerequisites

| Item | Value |
|------|-------|
| Prod frontend | Firebase Hosting URL (e.g. `https://client-pulse-9b146.web.app`) |
| Prod API | Render URL (e.g. `https://clientpulse-api.onrender.com`) |
| Agency test email | An inbox you can check in real time |
| Client test email | A second inbox you control (Gmail `+alias` works) |
| Browser | Chrome (authenticated session) + Chrome Incognito window |
| Mobile viewport | DevTools → 375×812 (iPhone SE preset) |

Confirm before starting:
- [ ] Render deploy is green (`GET /api/v1/health` returns `{"success":true}`)
- [ ] Firebase Hosting deploy is live (prod URL loads the Flutter app)
- [ ] Render env vars are set: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`, `JWT_SECRET`, `FRONTEND_BASE_URL`

---

## Journey 1 — Register → Workspace → Project

**Browser:** Chrome (authenticated session, no prior ClientPulse login)

1. Navigate to prod URL → should land on `/login`
2. Click "Register" → navigate to `/register`
3. Fill form:
   - Full Name: `Smoke Test Agency`
   - Workspace Name: `Smoke Test Workspace`
   - Email: your agency test email
   - Password: 12+ chars
4. Submit
   - [ ] **Checkpoint:** Redirects to `/dashboard`
   - [ ] **Checkpoint:** No error toast/snackbar
5. Navigate to `/projects/new`
6. Fill form:
   - Project Name: `Smoke Test Project`
   - Client Name: `Test Client`
   - Client Email: your client test email
   - Description: `E2E smoke test project`
   - Status: `Active`
   - Start Date: today
   - End Date: 2 weeks from today
7. Submit
   - [ ] **Checkpoint:** Redirects to `/projects/{id}`
   - [ ] **Checkpoint:** Project appears in dashboard list

---

## Journey 2 — Post Update with Attachment → Verify Client Email

**Browser:** Chrome (agency session, inside the test project)

1. Click "New Update" (or navigate to create update screen)
2. Fill form:
   - Title: `First Status Update`
   - Body: `## Progress\n\nSmoke test update body.` (markdown)
   - Category: `Progress`
3. Attach one file ≤ 10 MB (PDF or image)
   - [ ] **Checkpoint:** Upload progress bar appears and completes
4. Click Publish
   - [ ] **Checkpoint:** Update card appears in project detail with "Published" status
   - [ ] **Checkpoint:** Attachment link is visible on the card
5. Check agency test inbox
   - [ ] **Email checkpoint:** Client notification email received from `RESEND_FROM_EMAIL`
   - [ ] **Email checkpoint:** Subject references project or update name
   - [ ] **Email checkpoint:** Email body is not empty/broken HTML

---

## Journey 3 — Portal Link in Incognito

**Browser:** Chrome Incognito (no session)

1. In agency view, copy the portal share link for the test project (`/p/{share_token}`)
2. Paste into incognito window and open
   - [ ] **Checkpoint:** Portal loads without redirecting to `/login`
   - [ ] **Checkpoint:** Project name and status badge visible in header
   - [ ] **Checkpoint:** Workspace branding header displayed
3. Scroll to updates section
   - [ ] **Checkpoint:** "First Status Update" card is visible
4. Click attachment link
   - [ ] **Checkpoint:** File opens or downloads (no 403/404)

---

## Journey 4 — Client Comment → Agency Email Notification

**Browser:** Chrome Incognito (portal session from Journey 3)

1. Open the "First Status Update" card/detail
2. Fill comment form:
   - Name: `Test Client`
   - Message: `This is a smoke test client comment.`
3. Submit
   - [ ] **Checkpoint:** Comment appears in list with name "Test Client"
   - [ ] **Checkpoint:** No error shown
4. Check agency test inbox
   - [ ] **Email checkpoint:** Comment notification email received
   - [ ] **Email checkpoint:** Email contains "Test Client" and comment body
   - [ ] **Email checkpoint:** "View on Dashboard" link present and points to prod domain

---

## Journey 5 — Agency Reply → Verify on Portal

**Browser:** Chrome (agency session)

1. Navigate to the test project → open "First Status Update"
2. Scroll to Comments section
   - [ ] **Checkpoint:** Client comment from Journey 4 is visible
3. Type reply: `Thanks for the feedback — noted!`
4. Submit
   - [ ] **Checkpoint:** Reply appears threaded under client comment with agency author label
5. Switch to Incognito window → refresh portal update
   - [ ] **Checkpoint:** Agency reply is visible on portal (displayed differently from client comment)

---

## Journey 6 — Milestones → Progress Bar Updates

**Browser:** Chrome (agency session, test project)

1. Navigate to Milestones tab (or section) in the test project
2. Add 3 milestones:
   - `Design` — due date: +3 days
   - `Development` — due date: +7 days
   - `QA` — due date: +10 days
   - [ ] **Checkpoint:** All 3 appear in list
   - [ ] **Checkpoint:** Progress bar shows 0%
3. Mark `Design` as complete
   - [ ] **Checkpoint:** Progress bar updates to ~33%
   - [ ] **Checkpoint:** `Design` shows completed status pill
4. Switch to Incognito portal → scroll to milestones section
   - [ ] **Checkpoint:** Shows "1 of 3 • 33%"
   - [ ] **Checkpoint:** Progress bar renders correctly
5. Back in agency view: drag `QA` above `Development` to reorder
6. Refresh page
   - [ ] **Checkpoint:** Reordered position persists

---

## Journey 7 — Mobile 375px

**Browser:** Chrome DevTools → Device toolbar → iPhone SE (375×812)

1. Visit `/register`
   - [ ] **Checkpoint:** Form card fits screen (no horizontal overflow)
   - [ ] **Checkpoint:** All fields and submit button visible without scrolling beyond the form
2. Log in → visit `/dashboard`
   - [ ] **Checkpoint:** Project cards are full-width, no clipping
3. Visit portal link `/p/{share_token}` in same 375px viewport
   - [ ] **Checkpoint:** Branding header readable, no text clipped
   - [ ] **Checkpoint:** Milestone progress bar renders full-width
   - [ ] **Checkpoint:** Update cards are full-width
   - [ ] **Checkpoint:** Comment form is usable (fields and button accessible)

---

## Post-Run Cleanup (optional)

- Archive test project via project settings (soft delete)
- Delete test Supabase Auth user via Supabase Dashboard → Authentication → Users

---

## Quick API Health Check (curl)

Run before the UI journey to confirm backend is alive:

```bash
# Health
curl https://clientpulse-api.onrender.com/api/v1/health
# Expected: {"success":true}

# Auth (will 401 — confirms auth middleware active)
curl https://clientpulse-api.onrender.com/api/v1/workspace
# Expected: {"success":false,"error":"Unauthorized",...}
```
