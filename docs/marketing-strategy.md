# ClientPulse — Marketing Strategy

## TL;DR

Founder-led, organic-only marketing for the first six months. Positioning: a purpose-built status layer between agencies and their clients — not a project management tool, not a chat app. Five channels work together: LinkedIn outbound, SEO long-form, agency communities, partnerships, and a built-in product-led loop ("Powered by ClientPulse" footer on every client portal). The product-led loop is the central growth engine — every client portal page is a marketing surface seen by the people most likely to need ClientPulse themselves. Pricing, ICP, and competitor framing reference [`business-brief.md`](./business-brief.md). Launch sequencing lives in [`launch-strategy.md`](./launch-strategy.md).

---

## 1. Positioning

**Statement (one sentence):**

> For project managers at service agencies (5–50 staff) who waste hours every week answering "what's the status?", ClientPulse is a branded client update portal that — unlike Notion shared pages, Basecamp, or WhatsApp — gives clients a structured, mobile-friendly view of progress with zero login, zero install, and zero friction.

**Job to be done:**

> *"Hire me to stop the WhatsApp ping-pong and make my agency look professional without making the client learn another tool."*

**ICP firmographics (must match all):**

| Dimension | Fit |
|-----------|-----|
| Org type | Service agency: dev studio, design firm, marketing agency, CA/legal/consulting firm |
| Size | 5–50 employees |
| Project model | Fixed-scope or retainer with external clients (not internal product teams) |
| Geography | India primary, US/UK/AU/SG English secondary |
| Buyer | Project manager, team lead, agency founder/partner |
| Pain frequency | ≥3 active client projects, weekly status communication overhead |

**Anti-personas (do not market to):**

- In-house product teams (they already use Linear/Jira and don't have external clients).
- Solo freelancers with one client (no compounding pain — overkill).
- Enterprise consulting firms (they have procurement, security review cycles, and won't move on a SaaS link in DM).
- Agencies whose clients are technical (they're fine with Jira/Linear access).

---

## 2. Messaging

**Three pillars** — every piece of marketing copy traces back to one of these:

1. **Zero friction for the client.** No login, no install, no app, no password. One link. Works on a phone.
2. **Structured, not chatty.** Categories, milestones, and progress bars beat a WhatsApp scroll.
3. **Branded, not white-labelled-feeling.** The client sees the agency's name and logo, not the SaaS.

**Tagline candidates** (test on landing-page A/B):

| Tagline | Pillar emphasis |
|---------|----------------|
| "Stop chasing client status. Show it." | 1 + 2 |
| "Client updates that don't get lost in WhatsApp." | 1 |
| "Your agency. Their portal. One link." | 1 + 3 |
| "The status page your clients will actually open." | 1 + 2 |
| "Clients see progress. You stop writing emails." | 2 |

**Landing-page hero variants to test:**

- A: "Stop chasing client status. Show it." → demo video → CTA: Start free.
- B: "The client update portal your clients will actually open." → screenshot of mobile portal → CTA: Start free.
- C: "Every agency has the same problem. Clients ask 'what's the status?' We fixed it." → ICP testimonial → CTA: Start free.

Default to A for launch. Switch to whichever wins by T+30.

---

## 3. Channel Playbook

Five channels, each with: who, what, cadence, template, metric. Run all five concurrently — none alone is enough.

### 3.1 LinkedIn founder-led outbound

**Who:** Project managers, agency founders, ops leads at India-based service agencies (Apollo filter: India + 5–50 employees + service-industry SIC codes + title contains "PM" or "founder" or "ops").

**What:** Personalised DM, no pitch deck. Two-step: connection request → if accepted, DM in 48 hours.

**Cadence:** 10 DMs/day during Phase 1 (T-0 → T+7), then 5/day sustained. Above 20/day risks LinkedIn jail.

**DM template (Phase 1, design-partner ask):**

> Hi {first}, saw {agency} works with {industry} clients — quick question. How does your team currently handle weekly status updates to clients? We just shipped ClientPulse — agencies post structured updates, clients see a branded mobile-friendly portal via magic link, no login. Looking for 5 design partners in {city}: 3 months free + locked-in 50% off Starter for life when you upgrade. Worth a 15-min look? — {founder}

**DM template (post-launch, sustained):**

> Hi {first}, noticed {agency} on {Clutch / DesignRush / GoodFirms / LinkedIn}. We built ClientPulse for agencies your size — branded client update portal, magic-link access, no client login. Free Starter tier for up to 5 active projects. Want me to send the demo URL?

**Metric:** Reply rate. Healthy = 12–18% on cold; 30%+ on warm/referred. If <8%, rewrite the opening.

**List sources:**

- Clutch.co / DesignRush / GoodFirms (filter India, agency size, vertical)
- LinkedIn Sales Navigator free trial during launch month
- AgencyAnalytics blog comment sections (low-volume, high-fit)
- Existing personal network of past colleagues at agencies

### 3.2 Content / SEO

**Who:** Agency owners and PMs Googling their pain at 11pm.

**What:** Long-form, opinionated, search-intent-matched posts. Each post owns one query.

**Cadence:** 1 long-form post / week, every Tuesday (best B2B publish day per HubSpot benchmarks). Cluster into pillars over 90 days.

**Topic backlog (12 titles, ranked by search intent + ease):**

| # | Title | Target query | Funnel stage |
|---|-------|-------------|-------------|
| 1 | How to send weekly client status updates without writing a novel | "client status update template" | Top |
| 2 | Why your clients ignore your project updates (and what to do about it) | "clients ignore updates" | Top |
| 3 | Notion vs Basecamp vs ClientPulse: client portal comparison for agencies | "best client portal for agencies" | Mid |
| 4 | The agency PM's guide to milestone tracking that clients actually understand | "milestone tracking for clients" | Mid |
| 5 | Stop using WhatsApp for client work. Here's the framework that replaced it. | "alternative to whatsapp for client communication" | Top |
| 6 | A teardown of 7 client portals — what works, what doesn't | "client portal examples" | Mid |
| 7 | Client portal pricing in India: what agencies actually pay (2026) | "client portal pricing India" | Mid |
| 8 | The 5 update categories every agency should use (and why) | "types of client update" | Top |
| 9 | How {design partner agency} cut status meetings by 60% with ClientPulse | case study | Bottom |
| 10 | White-label client portals: what agencies should look for | "white label client portal" | Mid |
| 11 | Magic-link auth: why your clients shouldn't need a password | "magic link client login" | Top |
| 12 | The full ClientPulse build-in-public log: 14 days, solo, ₹0 budget | "build in public agency saas" | Brand |

**On-page SEO basics:** unique H1 matching target query, internal link to 2 other posts, schema markup for Article + FAQ, image alt text, no thin content under 1,200 words. Use Cloudflare Pages or Hashnode as the blog platform; cheap, fast, indexable.

**Metric:** Organic sessions / month, query rank for target term, time-on-page > 2:30.

### 3.3 Community

**Who:** Agency owners hanging out in places they trust more than ads.

**What:** Show up as a peer who happens to have shipped this. Lead with the pain, not the product. Never drop a link in the first message of a thread you didn't start.

**Cadence:** Daily skim, weekly post, monthly substantive contribution.

**Targeted communities:**

| Community | India / Global | Posting cadence | Tone |
|-----------|---------------|-----------------|------|
| IndieHackers | Global | Weekly milestone post + comments daily | Build-in-public, transparent metrics |
| r/agency | Global / US-skewed | Weekly comment, monthly thread | Pain-first, never sales-y |
| r/SaaS, r/Entrepreneur | Global | Monthly contribution | Story format only |
| Headstart slack groups (India) | India | Weekly | Native voice, founder-to-founder |
| NASSCOM 10K Startups community | India | Monthly | Formal, India-context |
| Agency Owners Association FB groups | Global | Monthly | Helpful, not promotional |
| Twitter/X #BuildInPublic + #SaaS + #IndieDev | Global | 2 posts/week + 1 thread/week | Loose, daily-life-of-founder |
| Bring Your Own Laptop / agency founder Discords | Global | Weekly | Conversational |

**Twitter/X format:** Lead with one specific number. "Day 14: 3 agencies onboarded. Combined they sent 47 client updates this week. Last quarter they sent 0 because they were typing them by hand on WhatsApp." More compelling than any feature list.

**Metric:** Referral traffic from each source, vibes (qualitative — are people quoting you back?).

### 3.4 Partnerships

**Who:** People who already have the audience.

**What:** Three plays.

1. **Agency-owner podcast guesting.** Pitch 10 podcasts in T+30 → T+60 (e.g., Agency Hour, Smart Agency Masterclass, Indian agency podcasts on Spotify). Pitch angle: "How I shipped a SaaS in 14 days solo while running an agency — and what I learned about agency client communication."
2. **Newsletter sponsorships / cross-promos.** Trade a feature mention with newsletter authors in the agency-ops space (e.g., DesignerNewsletter, Built In, India-specific agency newsletters). Cross-promo > paid for first six months.
3. **White-label resellers in tier-2 India cities.** Recruit 3 freelance consultants in Pune / Jaipur / Indore who already sell to local agencies. Offer 25% recurring revenue share for any workspace they bring on Agency tier.

**Metric:** Attributed sign-ups via tracked links (`?utm_source=`).

### 3.5 Product-led growth loop — "Powered by ClientPulse" *(central engine)*

**Why this is the most important channel:** every client portal page is a marketing surface seen by the exact ICP. When agency A's client opens their portal, that client is often a founder, marketing head, or product owner — many of whom *also run agencies* or know agencies. Each portal view = one impression on a hand-selected high-fit prospect.

**Mechanic:**

- Free and Starter tiers: a small "Powered by ClientPulse — start free" footer link on the public portal. Toggle: off.
- Growth tier: footer hidden by default, can be re-enabled.
- Agency tier: footer hidden, full white-label.

**Why agencies tolerate it:** the link is small, low-contrast, on a portal that — without ClientPulse — wouldn't exist at all. The framing in onboarding: "It's how we keep the free tier free."

**Click model assumptions (sanity-check after T+30 with real data):**

| Lever | Conservative | Target |
|-------|-------------|--------|
| Avg portal views per active workspace per month | 30 | 80 |
| Footer click-through rate | 0.3% | 1.0% |
| Click → signup conversion | 8% | 15% |
| Signup → activated workspace | 25% | 40% |
| Active workspaces (post-launch month) | 50 | 200 |
| **Net new activated workspaces / month from loop** | ~0.3 | ~10 |

Even in the conservative case, the loop compounds quietly. In the target case, it's a meaningful share of acquisition by T+90.

**Metric:** Footer impressions, click-through rate, attributed sign-ups (utm-tagged).

---

## 4. 90-Day Content Calendar

Sustained weekly cadence starting T+14 (post public launch). One owner. Batch-produce on weekends.

| Week of (Mon) | Long-form blog (Tue) | LinkedIn (Mon, Thu) | Twitter/X thread (Wed) | Community post (Fri) |
|--------------|---------------------|--------------------|-----------------------|---------------------|
| 2026-06-01 | Topic #1 (status update template) | Launch recap + ask for feedback | Behind the launch: 14-day build log | IndieHackers milestone |
| 2026-06-08 | Topic #5 (alternative to WhatsApp) | Design-partner story #1 | "What I learned shipping in 14 days" | r/agency thread on client comms |
| 2026-06-15 | Topic #2 (clients ignore updates) | India agency landscape post | Mobile-first portal demo (video) | Headstart Slack post |
| 2026-06-22 | Topic #11 (magic-link auth) | Founder lessons | One real client portal anonymised | r/SaaS metrics transparency post |
| 2026-06-29 | Topic #3 (Notion vs Basecamp vs ClientPulse) | Pricing rationale | Pricing decisions thread | Twitter/X #BuildInPublic |
| 2026-07-06 | Topic #8 (5 update categories) | First paid customer story | Activation lessons | IndieHackers monthly metrics |
| 2026-07-13 | Topic #4 (milestone tracking) | Agency case study #1 (full) | Behind a feature: file uploads | NASSCOM 10K post |
| 2026-07-20 | Topic #6 (portal teardowns) | Hot take: "Most client portals are bad" | Teardown thread | r/agency teardown |
| 2026-07-27 | Topic #7 (India pricing reality) | India market reflections | Pricing in INR vs USD | Headstart deep-dive |
| 2026-08-03 | Topic #9 (case study) | Customer hero story | Customer quote highlights | IndieHackers update |
| 2026-08-10 | Topic #10 (white-label) | Agency tier launch | Building white-label | Founder Discord drops |
| 2026-08-17 (T+90 wrap) | Topic #12 (90-day post-mortem) | Public retrospective | Metrics: what worked | All channels — what shipped |

Each week: 4 hours total of marketing labour. Discipline > volume.

---

## 5. Acquisition Funnel & Conversion Targets

**Funnel stages and definitions:**

| Stage | Definition | Target conversion (T+30) | Target (T+90) |
|-------|-----------|------------------------|--------------|
| Visit | Unique landing-page visitor | 100% | 100% |
| Sign-up | Workspace created | 5% of visits | 8% |
| Activated | ≥1 project + ≥1 update + ≥1 portal view | 40% of sign-ups | 55% |
| Retained | ≥2 updates posted in week 2 | 50% of activated | 65% |
| Paid | ≥1 paid month | 8% of activated | 15% |

**Activation = the wow moment.** The "wow moment" hypothesis: an agency PM activates the moment they see *their first real client open the portal on a phone*. Onboarding should funnel them to that moment as fast as possible — pre-fill a sample project, prompt them to send a real update to a real client within 5 minutes.

**Onboarding flow goal:** time-to-first-portal-view < 10 minutes from sign-up.

---

## 6. Pricing Comms & Objection Handling

Pricing tiers as defined in [`business-brief.md`](./business-brief.md) §Business Model. Do not restate.

**Top six anticipated objections:**

| # | Objection | Response |
|---|-----------|---------|
| 1 | "We already use Notion shared pages." | Notion needs an account to comment, has no milestone tracking, no category tags, no email-on-update. Show side-by-side. |
| 2 | "Why pay when WhatsApp is free?" | "What's the cost of your PM's 5 hours/week typing the same updates four times? At ₹2,000/hr blended, that's ₹40K/month per PM. ClientPulse Starter is ₹999. ROI in week one." |
| 3 | "We could build this ourselves." | "Sure — magic-link auth, file storage, email infra, mobile-responsive design, 8 weeks of dev. Or ₹999/mo." |
| 4 | "Can I trust a small/new tool with my client data?" | DPA available on request. Supabase region documented. Encrypted at rest. India-hosted region option in Q3 2026. Show the [`SMOKE_TEST.md`](../SMOKE_TEST.md) and security posture page. |
| 5 | "We're an Indian agency — is data in India?" | Currently in Supabase AP-South-1 (Mumbai) for Indian workspaces. Document on landing page. |
| 6 | "What if you shut down?" | Open data export from day one. CSV + JSON dump of every project, update, comment. Lock-in is zero by design. |

---

## 7. Retention Plays

**Onboarding email sequence (Day 0 → Day 14):**

| Day | Email subject | Goal |
|-----|--------------|------|
| 0 | "Welcome to ClientPulse — let's get your first portal live in 5 minutes" | Activation: post first update |
| 1 | "Your client just got their first ClientPulse update. Here's what they saw." | Show client perspective |
| 3 | "How {design partner} runs their weekly update cadence" | Borrow workflow |
| 7 | "Your portal so far — and 3 things to try next" | Feature discovery |
| 10 | "What clients are saying about ClientPulse portals" | Social proof |
| 14 | "Quick favour — 2-min feedback?" | Voice of customer |

**Churn-trigger detection:**

| Signal | Definition | Action |
|--------|-----------|--------|
| Cold workspace | No update posted in 7 days | Trigger re-engagement email + founder DM if Growth+ tier |
| Single-project workspace at day 14 | Only 1 project ever created | Email: "Add your second client — here's why most agencies start with 3" |
| Portal-no-views | Update posted but client never opened portal | Email PM: "Your client may not have received the email — quick check" |
| Drop in updates | ≥30% week-over-week decline in updates posted | Founder DM at Growth+ tier |

**Win-back sequence (after 30 days inactive):**

- Day 30: "We rolled out X feature you'll like" (tied to roadmap shipment)
- Day 45: "Honest question — what's missing?"
- Day 60: "Here's a 50%-off-3-months link if you want to retry"

---

## 8. Brand Voice & Visual

**Voice:**

- Confident, not cocky.
- Specific, not vague. Numbers > adjectives. ("3 agencies, 47 updates this week" > "lots of activity".)
- Founder-as-narrator, not corporate-we.
- Pro-client. We talk about *making the client's life easier* as the path to making the agency's life easier. Not the other way around.

**Do / don't:**

| Do | Don't |
|----|-------|
| "Your client gets a clean mobile portal." | "Best-in-class client engagement solution." |
| "Three real agencies use this today." | "Trusted by leading agencies worldwide." |
| "₹999/mo. No annual contract." | "Flexible pricing tiers to suit your needs." |
| "We shipped this in 14 days." | "Years of engineering excellence." |

**Visual (minimal, ties to product theme):**

- Primary: **Indigo** (Material `Colors.indigo` — matches `client/lib/core/theme/app_theme.dart` seed)
- Background: **`#F8F9FC`** (off-white, same as app)
- Surfaces: white, soft 12px radius cards, hairline grey borders (no heavy shadows)
- Error/destructive: `#E53935`
- Type: Inter, 2 weights (Regular, Semibold)
- Imagery: real screenshots of the product. No illustrations of generic businesspeople. No stock photography.

The marketing site should feel like the product — not louder, not flashier. The same calm, trust-first tone.

---

## 9. Metrics Dashboard

Weekly review every Friday morning. One spreadsheet, no fancy BI tool until T+90.

**Top-of-funnel:**
- Landing-page sessions (by source)
- Sign-ups / week
- Sign-up → activated conversion %
- Activated → paid conversion %
- LinkedIn DM reply rate

**Product-led loop:**
- Total client portal views
- Footer impressions vs. clicks
- Sign-ups attributed to the loop (`utm_source=portal_footer`)

**Retention:**
- 7-day retention (% of activated still posting in week 2)
- 30-day retention
- Logo churn (workspaces that delete or stop renewing)

**Revenue:**
- MRR
- ARPU
- Paid → cancelled within first 30 days (early-churn flag)

**Success threshold by phase:**

| Horizon | Pass mark |
|---------|----------|
| T+30 | 5 paying workspaces, ≥40% sign-up→activation, 1 published case study |
| T+60 | 15 paying workspaces, working product-led loop (≥1 attributed sign-up/week), 4 case studies |
| T+90 | 30 paying workspaces, ₹90K+ MRR, ≥10% of new sign-ups from product-led loop |

If T+30 misses on activation %, the problem is onboarding, not acquisition. Fix activation before scaling channels.

---

## 10. References

- [`business-brief.md`](./business-brief.md) — pricing, TAM, competitor table.
- [`launch-strategy.md`](./launch-strategy.md) — launch sequencing and day-of stack.
- [`project_brief.md`](../project_brief.md) — full feature set and ICP definition.
- `client/lib/core/theme/app_theme.dart` — visual design tokens (indigo seed, `#F8F9FC` bg).
