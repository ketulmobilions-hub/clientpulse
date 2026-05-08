# ClientPulse — Demo-Day Pitch Script

**Date:** 2026-05-18 (T-0)
**Runtime:** 4 minutes pitch + 1 minute Q&A buffer
**Audience:** Internal "Zero to Product" sprint judges + observing leadership
**Goal:** judges leave thinking *"we should sell this on Monday."*

Maps 1:1 to [`launch-strategy.md`](./launch-strategy.md) §5 and [`business-brief.md`](./business-brief.md) lines 137–143.

---

## Setup checklist (before the room)

- [ ] Laptop charged. External monitor cable in bag.
- [ ] Phone hotspot enabled — backup network if venue WiFi flakes.
- [ ] Two browser windows pre-staged, side-by-side:
  - Left: agency dashboard, logged in as `demo@clientpulse.dev`, on a project named "Acme Co — Q2 Brand Refresh" with 2 prior updates already posted.
  - Right: empty Chrome incognito window (will become the client portal).
- [ ] Phone open to Gmail of a second test inbox (the "client" — `client@clientpulse.dev`), unlocked.
- [ ] Phone screen mirrored to laptop via QuickTime (Mac) or scrcpy (Android) so projector shows phone live.
- [ ] One pre-loaded screenshot of a sample design mockup ready in `~/Desktop/demo-mockup.png`.
- [ ] Backup video (60-second screencast of the entire flow) on Desktop, named `demo-backup.mp4`, ready to play if anything live breaks.
- [ ] Drink water 5 min before. Phone on Do Not Disturb. Slack quit.

---

## The pitch (4 minutes)

### 0:00–0:30 — The pain (open cold, no slide)

> "Every project manager at our company spends about five hours a week answering one question: *what's the status?*
>
> Clients ask it on WhatsApp. They ask it on email. They ask it on calls. The same question, four channels, three times a week, fifty clients.
>
> Our PMs deserve their time back. Our clients deserve a real answer."

**Tone:** quiet, slow. Eye contact. Don't rush.

---

### 0:30–1:00 — The product, in three clicks (live)

> "ClientPulse is the layer between agency and client. Watch."

**Action:** on the agency dashboard (left window):

1. Click "+ New Update" on the "Acme Co — Q2 Brand Refresh" project.
2. Title: "Logo concepts ready for review."
3. Category: "Deliverable Shared".
4. Body: paste pre-typed `Three logo concepts attached. Looking for feedback by Friday — leave comments below.`
5. Attach `demo-mockup.png`.
6. Click Post.

> "Three clicks. The update is live. Now watch what the client sees."

---

### 1:00–1:45 — The client experience, on a phone (live)

**Action:** pick up the phone (already mirrored to projector). Open the magic-link email that just arrived. Tap the link.

> "No login. No app. No password. One tap from email to portal — on the device they actually use."

**Walk through the portal verbally as you scroll on the phone:**
- "Project name, agency logo, status badge — all branded for our agency, not for ClientPulse."
- "Progress bar — driven by milestone completion."
- "Timeline of updates, newest first. The one I just posted is at the top."
- "Categories: progress, milestone, deliverable, blocker, input-needed. Clients can scan in three seconds what would take five minutes on WhatsApp."

---

### 1:45–2:15 — The loop closes (live)

**Action:** still on the phone, scroll to the new update, tap the comment field, type:

> "Love concept #2. Approved — let's move forward."

Tap Post.

**Action:** put the phone down. Switch focus to the laptop. Refresh Gmail in a corner of the dashboard window. The notification email arrives.

> "Client commented. PM gets emailed. End-to-end loop. Total time from update posted to feedback received: thirty seconds. On WhatsApp this would have been three days of follow-ups."

---

### 2:15–3:15 — The business case (slide or whiteboard)

**Slide / whiteboard content** (one slide, 6 lines max):

```
Service agencies in India: 50,000+
Avg active client projects per agency: 8
Pricing:
  Starter   ₹999/mo   (5 projects)
  Growth    ₹2,499/mo (20 projects + custom domain)
  Agency    ₹5,999/mo (unlimited + white-label)

1,000 workspaces (mixed tiers) → ₹12–15L MRR
```

**Spoken:**

> "Every service agency with five-plus active clients has this problem. Dev studios. Design firms. Marketing. Even CA firms.
>
> Pricing: ₹999 to ₹5,999 per workspace per month. India alone has fifty thousand registered agencies. We need a fraction of one percent to hit fifteen lakh MRR. And this works globally — pricing is dollarised for the US, UK, Australia, Singapore.
>
> Stack is Supabase plus stateless Node.js. Horizontally scalable from day one. No expensive rearchitecting at growth."

---

### 3:15–4:00 — Close (no slide, eye contact)

> "The URL is live right now. Three real agencies are using it today — those updates you just saw came from a real Q2 brand refresh project, not a demo file.
>
> The product works. The market exists. The pricing makes sense.
>
> We could sell this on Monday."

Pause. Wait for questions. Resist filling the silence.

---

## Q&A — anticipated questions

Pre-loaded answers — keep replies under 30 seconds.

| Q | A |
|---|---|
| "How is this different from Notion / Basecamp?" | "Notion needs a login, no milestones, no categories. Basecamp is a full PM tool clients won't learn. ClientPulse is purpose-built for the agency-client relationship — branded magic-link portal, mobile-first." |
| "Why pay when WhatsApp is free?" | "PMs spend 5 hours a week typing the same updates four times. At ₹2,000/hr blended cost, that's ₹40K/month per PM. ClientPulse Starter is ₹999. ROI in week one." |
| "What's the moat?" | "Two things. One: the product-led loop — every client portal page shows 'Powered by ClientPulse', and clients of agencies are often agency owners themselves. Free marketing surface. Two: speed of iteration. Solo founder, two-week MVP — we ship faster than incumbents react." |
| "What if Notion ships this?" | "They won't. Notion's mental model is documents, not status pages. The features required — magic-link auth, structured update categories, mobile-first portal, no-login client view — would conflict with their core product. We've watched two years of Notion roadmap; this isn't on it." |
| "How big can this realistically get?" | "Conservative: ₹5L MRR at 500 workspaces. Target: ₹12–15L at 1,000. Optimistic: ₹40L+ at 3,000. India is the wedge; global English markets are the multiplier." |
| "Why you?" | "I built this solo in fourteen days with AI assistance while shipping production code at my day job. The thesis was: can one person ship a real B2B SaaS in a sprint? Answer: yes, and three agencies are paying customers ready to convert at T+30. The next twelve weeks compound." |
| "What's the biggest risk?" | "Single-founder bus factor. We address it with full data export from day one and standard infrastructure — no proprietary lock-in. Any acquirer or successor can keep it running." |

For anything else, see [`launch-faq.md`](./launch-faq.md).

---

## Failure modes during demo

| If… | Then… |
|-----|-------|
| Internet drops mid-demo | Switch to phone hotspot (already on). 5-second pause max. |
| Magic-link email is slow (Resend lag) | Have the link pre-copied to clipboard from a test run 5 min before. Use it without saying so. |
| Live demo silently breaks (e.g. 500 from API) | Smile, say "let me skip the live part — here's what it looks like" and play `demo-backup.mp4` from Desktop. Don't apologise twice. |
| Projector won't mirror phone | Pick up the phone, walk into the audience holding it up. More memorable than the slide anyway. |
| Audience interrupts mid-flow | Answer briefly, say "I'll come back to that in 90 seconds", continue. Reset the rhythm. |

---

## Post-demo

- Capture immediate judge reactions in a notes file within 10 minutes (memory fades fast).
- Send the live URL + a 1-paragraph follow-up email to anyone who asked a question or seemed engaged. Same evening.
- Post the demo recording to LinkedIn within 24 hours with caption: "Day 14: shipped ClientPulse. Three real agencies onboarded. Live URL in comments."

---

## Practice schedule

- T-3 (2026-05-15): full dry run, timed, recorded on phone. Watch back. Identify pacing issues.
- T-2 (2026-05-16): second dry run with one trusted reviewer (peer or family member who's never seen it). Note where their attention drifts.
- T-1 (2026-05-17): final run-through, no audience, just to internalise the rhythm. Don't change anything after this.
- T-0 morning: don't rehearse the morning of. Trust the work.
