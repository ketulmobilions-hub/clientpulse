# ClientPulse — Launch Readiness Checklist

Single timeline-ordered checklist consolidating every action item across all strategy and operations docs. Print this. Tick boxes as you go. If something is unchecked at its deadline, escalate (delay launch, drop scope, or reassign).

**Today:** 2026-05-05 (T-6).
**Sprint demo + soft launch:** 2026-05-11 (T-0).
**Public launch:** 2026-05-26 PT (T+14).

---

## T-6 → T-4 (2026-05-05 → 2026-05-07)

### Foundation
- [ ] All sprint feature work merged to `dev`. Issue #41 closed.
- [ ] [`runbook.md`](./runbook.md) read top-to-bottom once.
- [ ] [`launch-strategy.md`](./launch-strategy.md) read top-to-bottom once.
- [ ] [`marketing-strategy.md`](./marketing-strategy.md) read top-to-bottom once.

### Product readiness
- [ ] Production deploy green on Render (`/api/v1/health` returns `{"success":true}`).
- [ ] Production deploy green on Firebase Hosting.
- [ ] Render service upgraded to Starter tier ($7/mo) — kills cold starts.
- [ ] Cron warm-ping configured (GitHub Actions or `cron-job.org` hitting `/api/v1/health` every 10 min).
- [ ] Resend domain verified, sender email working.
- [ ] Magic-link rate limit confirmed: ≤10 generations / IP / hour.
- [ ] Magic-link cooldown confirmed: 1 link / email / 5 min.

### Design partners
- [ ] 3–5 design-partner agencies identified from existing network.
- [ ] Each has a workspace + 1 real project + ≥3 real updates posted.
- [ ] Eat-our-own-dogfood project loaded with genuine content.

### Landing page
- [ ] Domain `clientpulse.dev` active and pointed at frontend.
- [ ] Landing page live by 2026-05-07 EOD using copy from [`landing-copy.md`](./landing-copy.md).
- [ ] Hero Variant A live by default.
- [ ] Waitlist form wired to Supabase `waitlist` table.
- [ ] All hero CTAs land on a working page (`/register` for "Start free", `/p/demo123` for "See a live portal").

---

## T-3 → T-2 (2026-05-08 → 2026-05-09)

### Comms readiness
- [ ] [`launch-faq.md`](./launch-faq.md) reviewed; 6 most-likely PH/HN questions confirmed prepared.
- [ ] [`demo-script.md`](./demo-script.md) — first dry run completed and recorded; pacing reviewed.
- [ ] [`launch-posts.md`](./launch-posts.md) — every post reviewed and edited for current voice.
- [ ] [`onboarding-emails.md`](./onboarding-emails.md) — all 6 templates created in Resend.
- [ ] Onboarding emails wired to triggers (Day 0 = workspace create webhook; Day 1/3/7/10/14 = scheduled job).

### Outreach prep
- [ ] LinkedIn DM target spreadsheet started. Schema per [`dm-target-list.md`](./dm-target-list.md).
- [ ] At least 30 of 50 prospects sourced (rest can be added during week).
- [ ] [`dm-target-list.md`](./dm-target-list.md) §5 templates reviewed; founder voice applied.
- [ ] Calendly link ready for 15-min design-partner calls.

### Demo day prep
- [ ] Pitch slide prepared (single slide, business case section per demo script 2:15–3:15).
- [ ] Demo backup video shot (60-second screencast of full flow).
- [ ] Phone-mirror tested (QuickTime or scrcpy → laptop → projector).
- [ ] Phone hotspot tested as WiFi backup.
- [ ] Two-window pre-staging tested (agency dashboard left, incognito client portal right).
- [ ] Pre-loaded demo mockup file at `~/Desktop/demo-mockup.png`.

---

## T-1 (2026-05-10)

### Production hardening
- [ ] Status page live at `status.clientpulse.dev` (Better Stack or UpStatus).
- [ ] Sentry (or equivalent) capturing both client and server errors.
- [ ] Sentry → Slack alert wiring tested with a synthetic error.
- [ ] Supabase free-tier monitoring: alerts at 80% on database size + connections + storage.
- [ ] Resend daily quota raised to paid tier.
- [ ] Supabase nightly backup confirmed running.
- [ ] hCaptcha enabled on public sign-up endpoint.

### Smoke test
- [ ] Run [`SMOKE_TEST.md`](../SMOKE_TEST.md) end-to-end on production. All checkpoints pass.

### Final dress rehearsal
- [ ] Final demo dry run completed solo. No more rehearsal after this.
- [ ] Sleep schedule reset for tomorrow's demo morning.

---

## T-0 — Demo day & soft launch (2026-05-11)

### Morning (before demo)
- [ ] Laptop charged. External monitor cable in bag.
- [ ] Phone hotspot enabled.
- [ ] Both browser windows pre-staged (agency dashboard + incognito).
- [ ] Phone open to client test inbox, unlocked.
- [ ] Drink water. Phone on Do Not Disturb. Slack quit.

### Demo
- [ ] 4-minute pitch delivered per [`demo-script.md`](./demo-script.md).
- [ ] Q&A handled with prepared answers.
- [ ] Capture immediate judge reactions in notes within 10 min of finishing.

### Soft launch (same evening)
- [ ] Send first 10 LinkedIn connection requests per [`dm-target-list.md`](./dm-target-list.md).
- [ ] Post 1-line build-in-public update on Twitter/X + IndieHackers.
- [ ] Send personal email to first 3 design-partner agency contacts.

---

## T+1 → T+7 — Soft launch / private beta (2026-05-12 → 2026-05-18)

### Daily
- [ ] Send 10 LinkedIn connection requests (Mon–Fri).
- [ ] DM accepted connections from 24–48h prior.
- [ ] Hold 30-min "support hour" for the day's signups (Loom or Google Meet).
- [ ] Post 1-line public update with sign-up + activation count.
- [ ] Reply to all DMs within 4 hours during work hours.

### End of week
- [ ] 10 activated workspaces achieved (≥1 project + ≥1 update + ≥1 portal view each).
- [ ] 3 quotable testimonials captured (with logo permission).
- [ ] All P0 bugs from beta surfaced and fixed.
- [ ] Public launch assets reviewed once more (posts, FAQ, demo video).

### Public launch prep
- [ ] BetaList submission filed (slow drip — submit by T+7 to be live by T+14).
- [ ] Product Hunt hunter confirmed; listing scheduled for 2026-05-26 12:01 AM PT.
- [ ] OG image (`/og.png`) created and tested in PH preview.
- [ ] Demo video re-cut if any beta feedback warrants it.

---

## T+13 (2026-05-24, day before public launch)

### Final readiness
- [ ] All [`launch-posts.md`](./launch-posts.md) drafts copied into the relevant scheduling tools (PH listing draft, Buffer / Typefully for X, draft Reddit posts in saved drafts).
- [ ] HN "Show HN" planned for 2026-05-26 7:00 AM PT (peak engagement).
- [ ] [`launch-faq.md`](./launch-faq.md) re-read in full.
- [ ] Calendar cleared for 2026-05-26 (no meetings, no commitments).
- [ ] Auto-responder enabled: "On launch day — replies within 6 hours."
- [ ] Founder available for 12 continuous hours starting 2026-05-26 12:01 AM PT.

### Last-minute infra
- [ ] Render service capacity headroom confirmed.
- [ ] Supabase Pro upgrade decision made (recommend yes for launch month — $25 well spent).
- [ ] Final Smoke Test pass.
- [ ] Last-known-good Render deploy tag noted (rollback target if needed).

---

## T+14 — Public launch day (2026-05-26 PT / 2026-05-25 IST late evening)

### Hour zero (12:01 AM PT / 12:31 PM IST)
- [ ] Product Hunt listing goes live.
- [ ] Maker comment posted within 5 min ([`launch-posts.md`](./launch-posts.md) §1).
- [ ] Twitter/X launch thread posted.
- [ ] LinkedIn founder post + native video published.

### First hour
- [ ] IndieHackers milestone post published.
- [ ] Reply to every PH comment within 5 min.
- [ ] Live URL pinned on every social profile.

### Hour 7 (7:00 AM PT / 7:30 PM IST)
- [ ] Hacker News "Show HN" posted.
- [ ] Reddit r/SaaS post published.
- [ ] Reddit r/agency post published.

### Evening
- [ ] India community posts (Headstart Slack, NASSCOM 10K).
- [ ] Personal newsletter / past-clients email sent.
- [ ] Twitter/X recap thread (sign-ups + activations from the day).

### Overnight monitoring
- [ ] Sentry alerts watched.
- [ ] Status page kept current if any issues.
- [ ] Critical replies handled before sleep.

---

## T+15 → T+30 (2026-05-27 → 2026-06-10)

### Convert beta → paid
- [ ] Schedule day-7 follow-ups with everyone activated post-launch.
- [ ] Begin upgrade conversations with design partners (offer expires T+60).
- [ ] First case study interview scheduled (per [`case-study-template.md`](./case-study-template.md)).

### Sustained marketing
- [ ] Weekly content cadence kicks in (per [`marketing-strategy.md`](./marketing-strategy.md) §4).
- [ ] First long-form blog post published (Topic #1 — status update template).
- [ ] LinkedIn outbound continues at 5 DMs/day.

### Metrics review
- [ ] T+30 dashboard review: signups, activation %, paying workspaces.
- [ ] If activation < 40% → fix onboarding before scaling acquisition (see marketing §9 success threshold).

---

## T+30 → T+90 (2026-06-10 → 2026-08-09)

### Roadmap delivery
- [ ] Custom domain mapping shipped (target 2026-07-15) per [`roadmap.md`](./roadmap.md).
- [ ] Slack integration shipped (target 2026-08-01).
- [ ] Client file uploads shipped (target 2026-08-15).

### Growth loop activation
- [ ] "Powered by ClientPulse" footer enabled on free + Starter tier portals.
- [ ] First attributed sign-up via portal footer logged.
- [ ] Weekly metrics public on IndieHackers.

### Content cadence
- [ ] 12 weeks × (1 blog + 2 LinkedIn + 1 X thread + 1 community post) shipped per [`marketing-strategy.md`](./marketing-strategy.md) §4 calendar.

### Milestones
- [ ] T+60: 15 paying workspaces. 4 case studies published.
- [ ] T+90: 30 paying workspaces. ≥₹90K MRR. ≥10% sign-ups from product-led loop.

---

## Hard escalation triggers

If any of these happen, drop everything and act:

| Trigger | Action |
|---------|--------|
| P0 bug ships during launch hour | Pin transparent fix-ETA comment on every active thread within 30 min. Roll back per [`runbook.md`](./runbook.md) §2. |
| Render or Supabase outage | Status page update within 5 min. Activate runbook §F1 / §F2. |
| Activation rate < 40% by T+30 | Halt acquisition spend; spend the next sprint on onboarding fixes. |
| Reply rate on LinkedIn < 8% | Stop sending. Rewrite DM template. Diagnose at the funnel stage that's broken. |
| First paid customer churns within 7 days | 1:1 exit interview within 24 hours. Fix root cause before next paid signup. |
| Negative HN/PH thread reaches top of front page | Continue thank-and-fix replies. Do not engage trolls. Ride it out — even hostile attention converts at >0%. |

---

## After launch — never delete this file

When T+90 closes, re-purpose this checklist as the template for the next launch (v1.1 mobile apps, custom-domain GA, etc.). Each launch should be tighter than the last.
