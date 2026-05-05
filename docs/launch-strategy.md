# ClientPulse — Launch Strategy

## TL;DR

A staged, four-phase launch from sprint demo day to T+90, run by a single founder with zero ad budget. Pre-launch (now → 2026-05-11) locks in 3–5 design partners and a real eat-our-own-dogfood project. Soft launch (T-0 → T+7) opens to ~50 LinkedIn-warmed agencies on a 3-month free trial. Public launch on **2026-05-25 (T+14)** stacks Product Hunt + IndieHackers + community drops on the same day. Post-launch (T+30 → T+90) converts beta to paid and activates the "Powered by ClientPulse" growth loop.

This document is the operational playbook. Strategy and pricing live in [`business-brief.md`](./business-brief.md).

---

## 1. Goals & Success Metrics

The launch is a success if, by **2026-08-09 (T+90)**, ClientPulse has:

| Metric | Definition | T+7 target | T+30 target | T+90 target |
|--------|-----------|-----------|------------|------------|
| Sign-ups | Workspace created | 25 | 150 | 500 |
| Activated workspaces | ≥1 project + ≥1 update posted + ≥1 client portal opened | 10 | 60 | 200 |
| Paying workspaces | ≥1 paid month (Starter or above) | 0 | 5 | 30 |
| Design-partner testimonials | Recorded video or written, with logo permission | 3 | 5 | 8 |
| Public launch surface | Live PH + IH + 1 long-form post | — | Yes | Sustained weekly |
| MRR (proxy) | Sum of active paid plans | ₹0 | ₹15K | ₹90K+ |

Activation, not sign-up, is the headline number. A workspace that never posts an update is a churned user pretending to be a customer.

---

## 2. Phased Timeline

### Phase 0 — Pre-launch (T-6 → T-0, **now → 2026-05-11**)

Goal: ship the product, line up day-one social proof, eliminate launch-day surprises.

| Day | Owner action | Deliverable |
|-----|-------------|-------------|
| T-6 (today, 2026-05-05) | Finalise feature freeze list | Issue #41 closed in `dev` |
| T-5 → T-3 | Onboard 3–5 design partners from existing agency network | Each has a workspace + 1 live project + ≥3 real updates |
| T-4 | Build single-page landing site (re-use Flutter Web build, route `/`) | Hero pulled from `project_brief.md` lines 11–19; waitlist email capture |
| T-3 | Record 60-second demo video — agency POV → portal POV → comment loop | MP4 in `docs/assets/`, also embedded on landing |
| T-2 | Write demo-day pitch script (see §6) and rehearse 3× | Script in `docs/demo-script.md` (separate doc) |
| T-1 | Production deploy + smoke test (use `SMOKE_TEST.md`) | Green check on Render + Firebase |
| T-0 (2026-05-11) | Demo day → judge presentation → soft launch goes live same evening | Recorded talk + signed-off business brief |

Exit criteria for Phase 0: prod URL live, 3+ design-partner workspaces with real data, demo video shot, no P0 bugs in last 24h.

### Phase 1 — Soft launch / private beta (T-0 → T+7, **2026-05-11 → 2026-05-18**)

Goal: 10 activated workspaces, 3 testimonials, all P0/P1 bugs surfaced and fixed before the public spotlight.

- Send 50 personalised LinkedIn DMs to agency PMs (template in [`marketing-strategy.md`](./marketing-strategy.md) §3.1). Cap: 10/day to stay under LinkedIn limits.
- Offer: 3 months free, white-glove onboarding call, locked-in 50% discount on Starter for life when they upgrade.
- Daily ritual: 30-min "support hour" where founder personally onboards the day's signups via Loom or Google Meet.
- End-of-week: 1:1 30-min interview with each activated workspace. Record (with consent), transcribe, mine for testimonial quotes and feature gaps.
- Hard rule: no public posts about ClientPulse during this week. Beta is invite-only on purpose — scarcity primes the public-launch story.

Exit criteria for Phase 1: 10 activated workspaces, ≥3 quotable testimonials, zero open P0 bugs, public-launch assets ready (see Phase 2 checklist).

### Phase 2 — Public launch (T+14, **Monday 2026-05-25 IST → Tuesday 2026-05-26 PT, coordinated**)

Goal: top-5 Product Hunt finish in the day's "Productivity" or "SaaS" category, 500+ landing-page visitors, 100+ sign-ups in 24 hours.

Choose **Tuesday 2026-05-26, 12:01 AM PT** as Product Hunt go-live (highest historical engagement window). All other channels coordinated to that timestamp.

**Launch-day stack (rank-ordered by effort/reward):**

| Rank | Channel | Effort | Expected reach | Notes |
|------|---------|--------|---------------|-------|
| 1 | Product Hunt | 1 day prep + 12h day-of support | 5K–20K visitors | Use a hunter with track record; first comment within 5 min of go-live |
| 2 | IndieHackers Milestone post | 1 hr | 1K–3K | Title: "Shipped ClientPulse in 14 days — 10 agencies onboarded" |
| 3 | LinkedIn founder post | 30 min | 2K–10K | Native video, story format, ICP tagged in comments |
| 4 | r/SaaS + r/Entrepreneur | 30 min each | 1K–5K | Story format only; Reddit punishes promo |
| 5 | r/agency + r/digital_marketing | 30 min each | 500–2K | Lead with the pain, not the product |
| 6 | BetaList submission | 1 hr (apply 1 week prior) | 500–1K | Slow drip, evergreen |
| 7 | Hacker News "Show HN" | 30 min (post 8 AM PT) | 500–10K (variance is huge) | Plain title, plain link, plain text body |
| 8 | India agency communities (Headstart, NASSCOM 10K, founder Slack/Discord groups) | 1 hr total | 200–500 | India-time post, native language where possible |
| 9 | Twitter/X #BuildInPublic thread | 1 hr | 500–2K | Coordinate with PH go-live |
| 10 | Personal newsletter / past-clients email | 30 min | 50–200 | Highest conversion, smallest reach |

**Launch-day checklist (review at T-1, T-0 morning, and T-0 hour zero):**

Technical readiness:
- [ ] Render service on paid tier or warm-pinged so first request after cold start ≤ 1s.
- [ ] Supabase project upgraded if free-tier connection limit (60) at risk; alert at 80%.
- [ ] Status page up at `status.clientpulse.dev` (use UpStatus or Better Stack free tier).
- [ ] Sentry (or equivalent) capturing both client and server errors with Slack alert wiring.
- [ ] Magic-link rate limit set: ≤10 generations / IP / hour. Block obvious abuse patterns.
- [ ] Sign-up captcha enabled (hCaptcha free tier) — switch off after T+7 if no abuse seen.
- [ ] Resend daily quota raised from free 100 → paid tier the day prior.
- [ ] Backup: nightly Supabase dump to S3-compatible storage (or Backblaze B2).

Comms readiness:
- [ ] Pre-written replies for the 6 most likely PH/HN questions (security, pricing rationale, why-not-Notion, India-only?, white-label trust, single-founder concerns) — draft in `docs/launch-faq.md`.
- [ ] Founder available 12 hours on launch day. No meetings. Single-tasking.
- [ ] Auto-responder on email/Slack: "On launch day — replies within 6 hours." Sets expectation.
- [ ] Screenshots and the demo video pre-loaded on PH/IH/LinkedIn — no broken thumbnails.

Rollback plan:
- [ ] Last-known-good Render deploy tag noted; revert command in `docs/runbook.md`.
- [ ] If sign-up surge breaks Supabase free tier: auto-throttle sign-ups via feature flag; show waitlist instead of error.
- [ ] If a P0 bug ships: pin a transparent "we're fixing X — ETA Y" comment on every active thread within 30 min. Do not delete the threads.

### Phase 3 — Post-launch / scale (T+30 → T+90, **2026-06-10 → 2026-08-09**)

Goal: convert beta to paid, prove retention, activate the product-led loop.

- Convert design partners to paid by T+45 (offer locked-in discount expires at T+60).
- Ship two upsell features from the post-MVP backlog ([`business-brief.md`](./business-brief.md) lines 109–121) — pick the two that beta interviews flagged most: best candidates are **custom domain mapping** (Growth-tier upsell) and **client file uploads**.
- Switch on the **"Powered by ClientPulse"** footer on free tier portals (toggle off on Agency tier). This is the central viral surface — see [`marketing-strategy.md`](./marketing-strategy.md) §3.5.
- Publish the first paid case study (one design partner) by T+60.
- Weekly content cadence kicks in — see marketing doc §4.

---

## 3. Distribution Channels Reference

Detailed playbook lives in `marketing-strategy.md` §3. Launch-day uses the rank-ordered stack in §2 Phase 2. Post-launch shifts to the sustained calendar in marketing §4.

---

## 4. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Render free-tier cold starts kill PH conversion | High | High | Upgrade to paid Starter tier ($7/mo) for launch month; warm with cron ping |
| Supabase free-tier hit (500MB DB / 60 connections / 1GB storage) | Medium | High | Upgrade to Pro ($25/mo) before T+14; alert at 80% utilisation |
| Magic-link spam / abuse on public launch | Medium | Medium | IP rate limit + captcha + per-email cooldown; monitor Resend bounce rate |
| Single-founder bus factor on launch day | Low | Catastrophic | Pre-record FAQ video; designate one trusted peer as backup commenter on PH |
| Sign-up surge hits but activation collapses | Medium | High | White-glove onboarding for first 50 sign-ups; activation email sequence shipped before T-0 |
| Negative HN/PH critique on tech/UX | High | Low | Pre-written constructive replies; never argue, always thank-and-fix; document fixes publicly |
| Premature paid push before retention proven | Medium | High | Free for all on launch day; paid gates only switch on at T+30 once 3-week retention measured |
| Privacy / data residency objection from India enterprise prospects | Low | Medium | Document Supabase region + DPA; add to launch FAQ |
| Demo-day judges don't see the business case | Low | High | Pitch script in §6 maps every demo beat to a money beat |

---

## 5. Demo-Day Narrative

Maps 1:1 to [`business-brief.md`](./business-brief.md) lines 137–143 so the verbal pitch and the launch story are the same story. Total runtime: 4 minutes + 1 minute Q&A.

| Beat | Time | What happens | What the judge thinks |
|------|------|-------------|----------------------|
| 1. Open with pain | 0:00–0:30 | "Our PMs spend hours every week answering 'what's the status?' on WhatsApp. Our clients deserve better, and our team deserves their time back." | "I have this exact problem." |
| 2. Live: create project | 0:30–1:00 | Open agency dashboard, create project, post update with screenshot attachment | "That was three clicks." |
| 3. Live: client portal on phone | 1:00–1:45 | Tap magic link on phone, show portal: timeline, milestones, progress bar, comment box | "It's actually beautiful on mobile." |
| 4. Live: comment loop | 1:45–2:15 | Client leaves comment → agency Gmail pings live on screen | "End-to-end loop in real time." |
| 5. Business case | 2:15–3:15 | "50,000+ Indian agencies. ₹999 Starter to ₹5,999 Agency. 1,000 workspaces = ₹12–15L MRR. Works globally on USD." (Reference [`business-brief.md`](./business-brief.md) §Revenue Potential) | "This isn't a project, it's a P&L." |
| 6. Close | 3:15–4:00 | "Live URL is online. Three real agencies are using it today. We could sell this on Monday." | "We should sell this on Monday." |

Backup: pre-recorded screen capture of the same flow, ready to switch to if live demo fails.

---

## 6. After Launch — Reporting Cadence

- Daily during Phase 1 (T-0 → T+7): one-line public update on Twitter/X + IndieHackers showing sign-ups and activations. Builds the build-in-public flywheel.
- Weekly during Phase 3 (T+30 onwards): Friday newsletter to all sign-ups with "what shipped this week" + 1 customer quote.
- Monthly: post the metrics table (§1) publicly on IndieHackers. Transparent metrics earn trust and force discipline.

---

## 7. References

- [`business-brief.md`](./business-brief.md) — pricing, TAM, competitive table.
- [`project_brief.md`](../project_brief.md) — full feature list and ICP definition.
- [`marketing-strategy.md`](./marketing-strategy.md) — sustained channel playbook, content calendar, retention.
- `docs/launch-faq.md` — to be created during Phase 0, T-2.
- `docs/runbook.md` — to be created during Phase 0, T-1.
