# ClientPulse — Incident Runbook

What to do when something is on fire. Optimised for one founder, alone, at 2 AM.

For end-to-end correctness verification after recovery, run [`SMOKE_TEST.md`](../SMOKE_TEST.md).

---

## 0. Severity ladder

| Sev | Definition | Response time | Comms |
|-----|-----------|---------------|-------|
| P0 | Site down, data loss risk, magic links broken, sign-up broken | 15 min | Status page + Twitter/X + pinned PH/IH thread comment |
| P1 | Feature broken for some users (e.g. comments not sending email), no data risk | 1 hour | Status page |
| P2 | Cosmetic / non-blocking (slow load, layout bug, low-volume error) | Same day | Internal note only |
| P3 | Backlog | This week | None |

When unsure, treat as one severity higher.

---

## 1. Incident response loop

The same five steps every time. Don't skip in panic.

1. **Detect** — alert fires, user reports, or you spot it.
2. **Acknowledge** — post on status page within 5 min: "investigating {symptom}". Buys you time and goodwill.
3. **Mitigate** — restore service, even if root cause unknown. Rollback > forward-fix in P0.
4. **Diagnose** — only after service is up. Read logs, reproduce, identify root cause.
5. **Postmortem** — within 24h: what failed, why, what changes (process or code). Public if customers were affected.

---

## 2. Quick-reference commands

### Render (backend)

```bash
# Latest deploys + status
render deploys list --service clientpulse-api

# Roll back to a specific previous deploy
render deploys rollback --service clientpulse-api --deploy <deploy-id>

# Tail live logs
render logs --service clientpulse-api --tail

# Restart service (last resort, ~30s downtime)
render services restart clientpulse-api
```

If `render` CLI not authenticated, the dashboard at https://dashboard.render.com → ClientPulse API → Deploys → "Rollback" achieves the same in 3 clicks.

### Firebase Hosting (frontend)

```bash
cd client

# List recent releases
firebase hosting:releases:list

# Roll back to previous release
firebase hosting:rollback

# Force a fresh deploy from local build
fvm flutter build web --release
firebase deploy --only hosting
```

### Supabase (database / auth / storage)

```bash
# List migrations
supabase migration list

# Connect to prod DB (read-only investigation)
supabase db remote --project-ref <prod-ref>

# Backup before any destructive change
supabase db dump --project-ref <prod-ref> --file /tmp/backup_$(date +%Y%m%d_%H%M).sql
```

Never run a destructive SQL statement in prod without dumping first. Three letters: D-U-M-P.

### Resend (email)

- Dashboard: https://resend.com/emails — view sent/bounced/complained per recipient.
- If bounce rate > 5%, pause sending and investigate before quota gets capped.
- If a single recipient is suppressed (hard bounce), unsuppress only after confirming address is valid.

---

## 3. Common failure modes & response

### F1. Render cold start kills launch-day conversion

**Symptom:** First request after idle returns in 8–30s. Users bounce.

**Mitigate:**
- Confirm service tier is at least Starter ($7/mo) for launch month. Free tier sleeps after 15 min idle.
- Set up a cron-based warm ping every 10 minutes: GitHub Actions or `cron-job.org` hitting `/api/v1/health`.
- If on free tier and need immediate fix: upgrade in dashboard, ~30s downtime during scaling.

### F2. Supabase free-tier limits hit

| Limit | Free tier | Symptom | Fix |
|-------|-----------|---------|-----|
| Database size | 500 MB | Inserts fail, errors in logs | Upgrade to Pro ($25/mo); attachments are usually the bloat — audit storage |
| Storage | 1 GB | File upload fails with 413 | Upgrade to Pro; clean orphaned files |
| Concurrent connections | 60 | "too many connections" errors | Add PgBouncer (Supavisor) connection pooling — already enabled by default on Pro |
| Egress | 5 GB / month | Throttled responses | Upgrade; check for hot endpoints lacking caching |

Alert thresholds: configure email at 80% utilisation on each. Supabase dashboard → Reports.

### F3. Magic-link spam / abuse

**Symptom:** Spike in `magic_links` table inserts from one IP or email.

**Mitigate:**
1. Identify offending IP / email from logs.
2. Add to Cloudflare WAF block list (or hardcode in Render env `BLOCKED_IPS`).
3. Confirm rate limits in `src/middleware/portal.middleware.ts` are firing — check log lines.

**Permanent:** ensure rate limits are: 10 generations/IP/hour, 5/email/hour, captcha required for unauthenticated public endpoints.

### F4. Resend quota exceeded

**Symptom:** Magic-link emails not arriving. Users complain. Resend dashboard shows "quota exceeded".

**Mitigate:**
1. Upgrade Resend plan in dashboard (effective immediately).
2. Re-send recently failed emails: query `magic_links` for last 1h `email_sent = false`, re-trigger send job.
3. Post status update.

**Permanent:** monitor Resend daily volume, alert at 80% of quota.

### F5. Auth tokens leaked / compromised

**Symptom:** Suspicious sign-ins reported, JWT validation logs show unfamiliar IPs en masse.

**Mitigate:**
1. Rotate `JWT_SECRET` and `COOKIE_SECRET` in Render env vars (forces all sessions to log out — accept this).
2. Revoke all active magic-link tokens: `UPDATE magic_links SET expires_at = now() WHERE expires_at > now();`
3. Force agency-side password resets via Supabase Auth dashboard if any specific account is suspected.
4. Review Supabase Auth logs for IPs / sign-in patterns.
5. Public disclosure within 72 hours per standard breach response — even if scope is small.

### F6. Bad migration shipped to prod

**Symptom:** Schema mismatch, queries failing, errors referencing missing columns.

**Mitigate:**
1. Roll back code first (Render rollback) so app stops hitting the bad schema.
2. If migration is destructive (dropped column / table), restore from latest Supabase backup. Daily PITR available on Pro.
3. If migration is additive (added column with bad default), write a forward-fix migration.

**Never** run an unreviewed migration directly against prod. Always: dev → staging → prod, with `supabase db diff` between each.

### F7. Sign-up flooded by bots

**Symptom:** Sign-up rate jumps 20×, no real referrer, low-quality emails.

**Mitigate:**
1. Toggle hCaptcha on if not already enabled.
2. Add a sign-up cooldown: 1 sign-up / IP / 5 minutes.
3. Soft-disable: redirect to waitlist instead of immediate provisioning.
4. Audit: query `users` for last 1h, look for patterns (e.g. all `+fake@gmail.com`).

### F8. Frontend deploy ships broken build

**Symptom:** Prod URL loads white screen or JS errors in console.

**Mitigate:**
1. `firebase hosting:rollback` — instant.
2. Verify by hard-refresh (browser may cache old SW).
3. Diagnose locally: `fvm flutter build web --release` + serve to reproduce.

### F9. Customer reports lost data

**Symptom:** "My update is gone." or "All my projects disappeared."

**Mitigate:**
1. Don't panic-write anything.
2. Read-only query Supabase: confirm what's actually in the table for that workspace.
3. If genuinely deleted: restore from PITR backup to a temp database, extract just that workspace's rows, replay.
4. Communicate transparently. Customers forgive accidents; they don't forgive cover-ups.

---

## 4. Communication templates

### Status-page incident (P0/P1)

> **{Title} — investigating** | Posted {time}
> We're seeing {symptom}. Investigating. Next update in 15 min.

### Status-page resolution

> **{Title} — resolved** | {time}
> Root cause: {one-sentence summary}. Fix deployed at {time}. Total impact: {X minutes / Y users}. Postmortem follows within 24h.

### Pinned thread comment (PH / IH / HN during launch)

> **Heads up — we're seeing {symptom} for some users since {time}.** Mitigation deployed at {time}. Updates: {status page link}. Apologies — chasing it now.

### Customer email — data incident

> Hi {name},
>
> On {date} we discovered that {what happened, plain language, no jargon}. Your account was affected.
>
> What we've done: {action 1}, {action 2}, {action 3}.
> What you should do: {action — usually nothing or a password reset}.
>
> Full postmortem: {link}.
>
> I'm available to talk this through directly — reply to this email or book at {calendly link}.
>
> {Founder name}, ClientPulse

---

## 5. Tools & accounts

| Tool | Purpose | Account |
|------|---------|---------|
| Render | Backend host | Founder personal |
| Firebase Hosting | Frontend host | Founder Google account |
| Supabase | DB / Auth / Storage | Founder personal |
| Resend | Transactional email | Founder personal |
| Cloudflare | DNS, WAF | Founder personal |
| GitHub | Source + CI | `ketulmobilions-hub` |
| Better Stack / UpStatus | Status page | TBD by T-1 (2026-05-17) |
| Sentry | Error monitoring | TBD by T-1 (2026-05-17) |

Recovery passwords + 2FA backup codes: stored in 1Password vault `clientpulse-prod`. Founder is the only holder. Single-founder bus factor — accept and document.

---

## 6. Postmortem template

Use after any P0/P1 incident. File under `docs/postmortems/YYYY-MM-DD-<slug>.md`.

```markdown
# Postmortem — {title}

**Date:** {YYYY-MM-DD}
**Severity:** {P0/P1}
**Duration:** {minutes}
**Customer impact:** {N workspaces, M users, what they saw}

## Timeline (UTC)
- HH:MM — {event}
- HH:MM — {detection}
- HH:MM — {mitigation}
- HH:MM — {resolution}

## Root cause
{One paragraph — be specific. "A bug" is not a root cause.}

## What went well
- ...

## What went poorly
- ...

## Action items
- [ ] {fix} — owner — due date
- [ ] {process change} — owner — due date
```

Publish to `clientpulse.dev/postmortems/...` if customers were impacted. Transparency compounds trust faster than perfection.
