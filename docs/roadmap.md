# ClientPulse — Public Roadmap

What's shipped, what's next, and what's on the cutting-room floor.

This file is **public** — referenced from launch FAQ, landing page footer, and every "what's missing in MVP?" customer reply. Update on every Friday during launch quarter, monthly thereafter.

**Last updated:** 2026-05-12.

---

## Shipped (MVP — 2026-05-18)

The full sprint scope, live at clientpulse.dev.

| Feature | Why it shipped first |
|---------|---------------------|
| Agency dashboard (workspace + projects CRUD) | Core agency workflow |
| Updates with categories, markdown body, file attachments | The product is updates |
| Milestone tracking with progress bar | Most-checked thing on the portal |
| Magic-link client portal (no client login) | The "wow" moment |
| Branded portal (agency name + logo) | Trust + differentiation |
| Client comments with email notifications back to agency | Closes the feedback loop |
| Email notifications on update post (via Resend) | Makes the portal feel alive |
| Multi-tenant workspace isolation (Supabase RLS) | Foundation for paid tiers |
| Open data export (CSV + JSON) | Zero-lock-in commitment, day one |

---

## In progress (Q3 2026 — June through August)

Order is roughly priority-by-customer-demand from beta interviews.

### Custom domain mapping
**Why:** "We want updates to feel native, not third-party."
**Who:** Growth + Agency tiers.
**Status:** API design in review. Backend + DNS verification flow scoped.
**Target ship:** 2026-07-15.

### Slack integration
**Why:** Agency teams already live in Slack — not on email.
**What:** New-update + new-comment events post to a configurable Slack channel. Inbound: post a Slack message → create a ClientPulse update.
**Who:** All paid tiers.
**Target ship:** 2026-08-01.

### Client file uploads
**Why:** Clients want to send feedback docs, not write them in a comment box.
**What:** Comment field on the public portal accepts file attachments (10MB max, 3 per comment) — same upload flow as agency-side.
**Who:** All tiers.
**Target ship:** 2026-08-15.

---

## Next (Q4 2026 — September through November)

Order may shift based on Q3 customer feedback.

### Portal analytics
**Why:** "I want to know which updates clients actually read."
**What:** Per-update views + reading time, surfaced in the agency dashboard.
**Who:** Growth + Agency tiers (privacy-conscious; clients see a transparent "this portal records views" notice).
**Target ship:** 2026-10-15.

### Approval workflows
**Why:** Most agencies still email Word docs for sign-off. Bad.
**What:** Mark an update as "Approval Required". Client clicks "Approve" or "Request changes" — both logged with timestamp + IP. Result reflected on the agency dashboard.
**Who:** Agency tier.
**Target ship:** 2026-11-01.

### WhatsApp Business notifications
**Why:** India-specific. Many agency clients prefer WhatsApp over email.
**What:** Outbound new-update WhatsApp messages via WhatsApp Business API (Twilio or Karix integration).
**Who:** Growth + Agency tiers.
**Target ship:** 2026-11-30.

---

## Later (Q1 2027 onwards)

Lower confidence on dates; reflects intent rather than commitment.

### API access + webhooks
**What:** Public REST API for third-party integrations. Webhooks for `update.created`, `comment.created`, `milestone.completed`.
**Who:** Agency tier.
**Target ship:** 2027-01.

### Mobile apps (Flutter mobile)
**What:** iOS + Android agency-side apps. Client portal stays web-first (the magic-link flow is the value).
**Why later:** Mobile dashboards are a "nice to have" before they're essential. Web works on phones today.
**Target ship:** 2027-02.

### Multi-language portal
**What:** Client portal renders in client's language preference. Agency dashboard remains English-only initially.
**Languages first:** Hindi, Marathi, Tamil, Telugu, then European languages.
**Target ship:** 2027-03.

### Native integrations
**What:** Linear / Notion / Google Drive / Figma (auto-pull deliverable links).
**Order TBD:** dictated by which integration unlocks the most retention.
**Target ship:** 2027-Q2.

---

## Considering (no commitment, signal welcome)

Things on the wall, not on the calendar. Customer feedback shifts these.

- **AI update drafting** — auto-generate draft updates from project activity (Linear / GitHub / Slack signals). High demand, high risk of feeling impersonal.
- **Recurring update templates** — "Monday weekly recap" boilerplate the agency can save and re-use.
- **Multi-workspace switcher** — for agencies running both their own work and white-labelled sub-agency work.
- **Read receipts on individual update emails** — already partially covered by portal analytics.
- **Embedded portal** — iframe-friendly portal embed for agencies' own websites.
- **Time tracking** — would compete with full PM tools; deliberate hesitation.

If any of these matter to you, reply to a launch email or DM the founder. The roadmap is influenced by signal, not voted on.

---

## Cut from MVP (won't ship without strong demand)

Honest list of what we considered and chose against. Not "coming soon" — actively decided no.

- **Built-in invoicing / billing** — Clientjoy and similar already do this well. Outside our scope.
- **CRM features (deal pipeline, contacts)** — same reason.
- **Time tracking + timesheets** — same reason.
- **Native chat / messaging** — clients have WhatsApp; we replace status updates, not chat.
- **Granular permissions matrix** — adds complexity faster than it adds value at our scale.
- **SAML / SSO for agencies** — only relevant for 100+ employee agencies, which aren't our ICP.

---

## How priorities are set

In order of weight:

1. **Beta and early-customer interviews.** What did they ask for in our 1:1 calls? What did they say was the single thing missing?
2. **Activation / retention impact.** Will this feature get more workspaces past the activation moment, or keep them past day 30?
3. **Tier-upsell logic.** Does this feature create a clean reason to move from Starter to Growth, or Growth to Agency?
4. **Effort-to-value ratio.** A 2-week feature that 80% of users will use beats a 6-week feature 30% will.
5. **Founder gut.** Used last, not first. But used.

---

## Feedback channels

- **Email:** ketul@clientpulse.dev — read by founder, no AI summaries.
- **Twitter/X:** @clientpulse — public requests welcome.
- **In-product:** "Suggest a feature" link in the agency dashboard footer (logs to Supabase `feedback` table).
- **Office hours:** open 30-min slot every Friday on the founder's Calendly during launch quarter.

---

## Versioning

This document gets a `Last updated` stamp at the top on every change. Major roadmap shifts (e.g. cutting a Q3 commitment) get a separate "Changelog" section appended at the bottom of this file.

### Changelog

- 2026-05-05 — Initial public version, sprint launch prep.
- 2026-05-12 — Launch dates shifted +7 days (sprint slip). Soft launch 2026-05-18, public launch 2026-06-02.
