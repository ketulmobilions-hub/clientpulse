# ClientPulse — Launch Day Post Copy

Pre-written, channel-tuned launch posts. All scheduled for **2026-05-26 Tuesday, 12:01 AM PT** (Product Hunt go-live), with the rest staggered to match each channel's prime engagement window.

Channel-specific tone matters: Product Hunt rewards warmth, Hacker News punishes marketing voice, Reddit punishes anything that smells like a pitch, IndieHackers loves transparent metrics, LinkedIn loves narrative.

Edit lightly before posting — copying verbatim is fine for PH, fatal for HN/Reddit. Always read once aloud to catch awkward phrasing before posting.

---

## 1. Product Hunt — main listing

**Tagline (60 char max):**

> The client update portal your clients will actually open

**Description (260 char max):**

> Service agencies waste hours every week answering "what's the status?". ClientPulse is a branded client update portal — agencies post structured updates, clients see a mobile-friendly page via magic link. No login, no install. Made for agencies, loved by their clients.

**Topics:** Productivity, SaaS, Marketing, Project Management

**Gallery (in order):**
1. Hero screenshot — agency dashboard with a real project
2. Mobile screenshot — client portal on iPhone
3. Comparison table — ClientPulse vs Notion / Basecamp / WhatsApp
4. Pricing card
5. 60-second demo video

### Maker's first comment (post within 5 min of go-live)

> Hi everyone — Ketul here, founder of ClientPulse 👋 (single emoji OK on PH; not elsewhere)
>
> I built this in 14 days, solo, while running an agency on the side. The pain is one I lived for years: every PM on our team was burning 5+ hours every week just answering "what's the status?" on WhatsApp.
>
> The current options are too heavy (Jira, Asana — clients won't use them) or too light (WhatsApp — no structure, no history, no branding). ClientPulse is the layer in between: agencies post structured updates from a dashboard, clients see a branded mobile-friendly portal via magic link — no login, no install.
>
> Three real agencies are using it today. The product-led loop is interesting too: every client portal page renders a small "Powered by ClientPulse" link, and clients of agencies are often agency owners themselves. Free marketing surface that compounds.
>
> Free Starter tier (1 active project) forever. Paid plans start at ₹999/month (~$12). Open data export from day one — zero lock-in.
>
> Happy to answer any questions on tech, pricing, India market, single-founder risk, or where I think this goes next. Roadmap is public.

---

## 2. Hacker News — Show HN

**Title (no all-caps, no emoji, no exclamation):**

> Show HN: ClientPulse – a client update portal for service agencies

**Body:**

> Hi HN. I built ClientPulse in 14 days, solo, while running an agency.
>
> The problem: service agencies (dev studios, design firms, marketing) waste hours every week answering "what's the status?" from clients. Existing options are either too heavy (Jira, Asana — clients won't use them) or too light (WhatsApp — no structure, no history). I wanted a thin, purpose-built status layer for the agency-client relationship.
>
> Agencies post structured updates from a dashboard (categories: progress / milestone / deliverable / blocker / input-needed). Clients receive a magic-link email and see a branded mobile-friendly portal — no login, no install, no app. Comments + email notifications close the loop.
>
> Stack: Flutter Web frontend, Node.js + Express + TypeScript backend, Supabase for Postgres + Auth + Storage, Resend for email, Render and Firebase Hosting. Stateless backend behind a load balancer; standard infrastructure with no proprietary lock-in. Open data export (CSV + JSON) from day one.
>
> Three real agencies are using it today. Free tier covers 1 active project; paid starts at ₹999/month (~$12).
>
> Live URL: clientpulse.dev
>
> What I'd love feedback on: the magic-link UX (worth the friction tradeoff vs. passwords?), pricing for non-India markets, and whether the "purpose-built status layer" framing actually lands or feels like a feature of a bigger product.

**Reply rules during HN window:**

- Reply to every comment within 60 minutes for the first 6 hours, then within 4 hours for the next 24.
- Never argue. "Good point — you're right that {X}." → fix or commit to fixing publicly.
- For "this is just X with extra steps" comments: agree on the building blocks, defend the configuration. See [`launch-faq.md`](./launch-faq.md) §15.
- For trolls: don't engage. Other readers will downvote them.

---

## 3. IndieHackers — Milestone post

**Title:**

> Day 14: shipped ClientPulse — solo, ₹0 budget, 3 agencies onboarded

**Body:**

> Two weeks ago I started "Zero to Product" — an internal company sprint to ship a real B2B SaaS in 14 days, solo. Today I'm posting the live URL.
>
> **What I built:** ClientPulse — a branded client update portal for service agencies. Agencies post structured updates from a dashboard; clients see a mobile-friendly portal via magic link, no login.
>
> **Why this problem:** I've worked at and around agencies for years. Every PM I know burns 5+ hours a week answering "what's the status?" in three different chat tools. Existing alternatives are either too heavy (Jira) or too light (WhatsApp). Nothing thin and purpose-built exists.
>
> **Stack:** Flutter Web + Node.js + Supabase + Resend. Hosting: Firebase + Render. Total infra cost during sprint: $0. Total monthly cost at 0–500 users: ~$32 (Render Starter + Supabase Pro). I'll publish a full cost breakdown at T+90.
>
> **Numbers so far:**
>
> - 14 days end-to-end (idea → live URL)
> - 3 design partners onboarded during sprint, all with real client projects
> - 47 real client updates posted across those 3 agencies in week 2
> - 12 client comments received → 100% of those agencies got their first ever "client commented before being asked" experience
> - $0 spent on marketing
>
> **What I'm doing next:**
>
> - Soft launch this week → 50 LinkedIn-warmed agencies on a 3-month free trial (10 activations target)
> - Public launch on Product Hunt 2026-05-26
> - Will post weekly metrics here (transparent or it didn't happen)
>
> **What I'd love help with:** if you run an agency or know someone who does, I'd love a candid 15-minute call. 3 months free + 50% off Starter for life as a design partner. Reply or DM.
>
> Live URL: clientpulse.dev. Full build-in-public log at clientpulse.dev/blog (publishing this week).
>
> Happy to answer anything — stack choices, pricing, single-founder risk, going from 14 days to a real product.

---

## 4. Reddit — r/SaaS

**Title:**

> Shipped a SaaS in 14 days solo — here's what worked, what didn't, and what I'm doing differently in the next 14

**Body (no link in title or first paragraph; Reddit ranks links low):**

> Two weeks ago I started a sprint: 14 days to ship a real B2B SaaS, solo, while keeping my day job. Today I'm posting what I learned, what's live, and what's broken.
>
> **The product:** A branded client update portal for service agencies. Agencies post structured updates; clients open a mobile-friendly portal via magic link, no login. Replaces the WhatsApp-and-email chaos most agency PMs live in.
>
> **What worked:**
>
> 1. Reusing components hard. Shared Flutter widgets across 7 features cut build time by ~30%.
> 2. Magic-link auth instead of passwords. Made the client experience genuinely zero-friction.
> 3. Recruiting 3 design partners on day 4. They surfaced 80% of my real bugs before launch.
> 4. Hosting on Supabase + Render free tier kept infra cost at $0 during sprint.
>
> **What didn't:**
>
> 1. I spent day 1–2 over-architecting state management. Refactored on day 6, lost ~10 hours.
> 2. Underestimated email deliverability. Resend default rate limits bit me on day 9.
> 3. Tried to build a "cool" landing page from scratch. Should have shipped a single-section page on day 1 and iterated.
> 4. Skipped writing a runbook until day 13. Production cold-start surprise on day 14.
>
> **What I'm doing differently next 14:**
>
> 1. Soft launch first (50 invited agencies), public launch second.
> 2. Weekly metrics in public — IndieHackers + Twitter.
> 3. One feature shipped per week max. Compounding > sprinting now.
>
> Live URL in the comments if anyone wants to look. Happy to answer questions on tech, pricing, India market specifics, design-partner recruiting, or anything else.

**First comment (self-replied 5 min after posting):**

> Live URL: clientpulse.dev — let me know if anything looks broken, this is a real launch.

---

## 5. Reddit — r/agency

**Title:**

> I built a tool for our PMs because they were burning 5+ hours a week answering "what's the status?". Sharing the lessons + the tool.

**Body:**

> Posting from one PM's perspective, not as a sales thing. If the tool's not for you, hopefully the lessons are.
>
> Every PM I know has the same week:
>
> - Monday: write the same status update across 4 client WhatsApp threads
> - Tuesday: re-explain what was said in Monday's update on a call
> - Wednesday: dig through Slack to find a screenshot you sent two weeks ago
> - Thursday: write a "weekly recap" email that 3 of 5 clients won't open
> - Friday: client texts asking what the status is
>
> The good options are too heavy (Asana, Jira — clients won't learn them). The cheap options are too light (WhatsApp — no structure, history, or branding). For two years I assumed someone would build the in-between. They didn't, so I did.
>
> ClientPulse is a thin layer: agency posts structured updates, client opens a branded mobile portal via magic link. No login. No install. The whole thing is the timeline + milestones + comments. That's it.
>
> What I learned recruiting 3 design-partner agencies before launch:
>
> 1. The pain is universal but the framing isn't. Some agencies call it "client comms", some call it "transparency", some call it "weekly reporting" — all the same thing.
> 2. The magic-link experience is the single biggest "wow" moment. Two of three partners said "I didn't know clients would actually open it."
> 3. Pricing tolerance is higher than I expected. ₹999/month felt cheap to all 3.
>
> If you run an agency or work as a PM, I'd love feedback on the framing — is "structured client updates" the right pitch, or should I lead with something else?
>
> Live URL in comments. Free Starter tier covers 1 project forever. No card.

**No first-comment self-link if subreddit rules disallow.** Check r/agency rules before posting.

---

## 6. LinkedIn — founder post

**Format:** native video (60-second demo) + text caption.

**Caption:**

> 14 days ago I started a sprint to ship a real SaaS, solo, while keeping my day job.
>
> Today, ClientPulse is live.
>
> Three real agencies use it.
> Forty-seven client updates posted in week 2.
> Twelve client comments — one of them said "this is the first time I've felt informed without asking".
>
> The problem: every agency PM I know burns 5+ hours a week answering "what's the status?" on WhatsApp. The current options are too heavy (Jira) or too light (WhatsApp). Nothing thin and purpose-built exists.
>
> ClientPulse is the layer in between. Agencies post structured updates; clients see a branded mobile portal via magic link. No login. No install.
>
> Free Starter tier forever. Paid starts at ₹999/month.
>
> If you run an agency or know a PM who lives this pain — I'd love 15 minutes. 3 months free + 50% off for life as a design partner.
>
> Live URL in comments 👇

**First comment (immediately after post goes live):**

> https://clientpulse.dev — let me know what's broken, this is a real launch.

**Tag in comments:** 5–10 connections in the agency space, individually relevant. Never tag people who didn't ask.

---

## 7. Twitter/X — launch thread

**Tweet 1 (hook):**

> Day 14. Solo. ₹0 budget.
>
> Just shipped ClientPulse — a branded client update portal for service agencies. Magic-link access, no client login.
>
> 3 real agencies are using it today. 47 real client updates posted in week 2.
>
> Live URL + thread on what I learned 👇

**Tweet 2 (problem):**

> The problem is universal:
>
> Every agency PM burns 5+ hours/week answering "what's the status?" on WhatsApp.
>
> Existing tools are too heavy (Jira) or too light (WhatsApp).
>
> Nothing thin + purpose-built for the agency → client loop existed. So I built it.

**Tweet 3 (product, with screenshot):**

> Three things make ClientPulse different:
>
> → Structured updates (categories: progress / milestone / deliverable / blocker)
> → Magic-link client access (no login, no install)
> → Branded mobile portal (your agency's name + logo on every page)
>
> [screenshot: mobile portal]

**Tweet 4 (stack):**

> Stack:
>
> – Flutter Web (frontend)
> – Node.js + Express + TypeScript (backend)
> – Supabase (Postgres + Auth + Storage)
> – Resend (email)
> – Firebase Hosting + Render
>
> Total infra cost during sprint: $0. Cost at 500 users: ~$32/mo.

**Tweet 5 (lessons):**

> What worked:
>
> 1. Recruiting design partners on day 4
> 2. Shipping a thin landing page on day 1, not day 13
> 3. Magic-link auth instead of passwords
>
> What didn't:
>
> 1. Day 1–2 over-architected state management. Lost 10 hours.
> 2. Skipped writing a runbook until day 13.

**Tweet 6 (numbers):**

> Numbers:
>
> – 14 days idea to live URL
> – 3 design-partner agencies onboarded
> – 47 real client updates posted in week 2
> – 12 client comments
> – 0 burned out (somehow)

**Tweet 7 (ask + URL):**

> If you run an agency or know a PM who lives this pain:
>
> – Free Starter tier forever
> – 3 months free + 50% off for life as a design partner
> – DMs open
>
> Live URL: clientpulse.dev
>
> Will post weekly metrics from here. Building in public, transparently.

---

## 8. BetaList submission

**Tagline:**

> Branded client update portal for service agencies — magic-link access, no client login.

**Description (300–500 words is fine for BetaList):**

> ClientPulse is a thin, purpose-built client update portal for service agencies (dev studios, design firms, marketing, CA firms) with 5–50 employees.
>
> The pain: every agency PM wastes 5+ hours a week answering "what's the status?" across WhatsApp, email, and calls. The current alternatives are too heavy (Jira, Asana — clients won't use them) or too light (WhatsApp — no structure, no history, no branding).
>
> ClientPulse is the layer in between. Agencies post structured updates from a dashboard (with categories like progress, milestone, deliverable, blocker). Clients receive a magic-link email and see a branded mobile-friendly portal — no login, no install. Comments + email notifications close the loop.
>
> Free Starter tier: 1 active project, forever. Paid plans from ₹999/month. Open data export from day one — zero lock-in.
>
> Built in 14 days, solo. Three real agencies onboarded as design partners during the sprint. Live now at clientpulse.dev.

**Logo:** square 600×600, indigo on `#F8F9FC`.

---

## 9. Headstart / NASSCOM 10K (India agency communities)

**Tone:** founder-to-founder, India-context, mention specific Indian agency hubs (Mumbai, Bangalore, Pune).

**Post:**

> Hi all — sharing something I just shipped that's specifically built for the Indian agency landscape.
>
> Most of us run service agencies (5–50 people) where PMs lose hours every week to client status updates on WhatsApp. The problem isn't unique to India but our context is — Indian clients communicate primarily through chat, agencies are price-sensitive, and most existing tools are priced for Western markets.
>
> ClientPulse is a thin client update portal: agencies post structured updates, clients open a branded mobile portal via magic link, no login. Pricing in INR (₹999 / ₹2,499 / ₹5,999 per month). Hosted in Mumbai (`ap-south-1`).
>
> Built in 14 days while keeping my day job. 3 design-partner agencies in Bangalore, Pune, and Delhi onboarded during the sprint.
>
> If anyone here runs or works at a service agency — I'd love 15 minutes. Free 3 months + 50% off Starter for life as a design partner.
>
> Live URL: clientpulse.dev. Happy to answer anything on tech, pricing, single-founder risk, or India-market specifics.

---

## 10. Email — past clients / personal newsletter

**Subject:**

> I built something for agency PMs and I'd love your eyes on it

**Body:**

> Hi {first},
>
> Quick one — I just shipped ClientPulse, a tool I've been wanting to build for years.
>
> It's a thin client update portal for service agencies. Agency posts structured updates from a dashboard; client opens a branded mobile portal via magic link, no login. Replaces the WhatsApp + email chaos most PMs live in.
>
> If you (or someone you work with) runs an agency, I'd love 15 minutes of your time. 3 months free + 50% off for life as a design partner.
>
> Live URL: clientpulse.dev
>
> No pressure. If it's not relevant, just hit reply with "nope" and I'll know.
>
> {Founder}

---

## 11. Posting schedule — launch day

| IST time | PT time | Channel | Action |
|----------|---------|---------|--------|
| 12:31 PM | 12:01 AM | Product Hunt | Listing goes live; maker comment within 5 min |
| 12:35 PM | 12:05 AM | Twitter/X | Launch thread (7 tweets) |
| 12:40 PM | 12:10 AM | LinkedIn | Founder post + native video |
| 1:00 PM | 12:30 AM | IndieHackers | Milestone post |
| 7:30 PM | 7:00 AM | Hacker News | Show HN |
| 7:35 PM | 7:05 AM | Reddit r/SaaS | Story-format post |
| 8:00 PM | 7:30 AM | Reddit r/agency | Pain-first post |
| 9:00 PM | 8:30 AM | BetaList | Submission (already scheduled prior week) |
| 10:00 PM | 9:30 AM | Headstart Slack / NASSCOM | India community post |
| 10:30 PM | 10:00 AM | Email — past clients + personal | Send |

Reply windows:

- Product Hunt: every 5 min for the first hour, then every 30 min for 12 hours.
- HN: every 30 min for the first 6 hours, every 4 hours for next 24.
- Reddit: every 30 min for the first 4 hours.
- LinkedIn / IH / Twitter: hourly for the first 12 hours.
- Email: within 4 hours.

If a P0 bug surfaces during the day, pin a transparent fix-ETA comment on every active thread within 30 minutes per [`runbook.md`](./runbook.md) §F8.
