# ClientPulse — Business Brief

## The Problem

Service agencies waste hours every week on status communication. Clients ask "what's the update?" over WhatsApp, email, and calls — repeatedly. Project managers write the same updates across multiple channels with no single source of truth.

Current alternatives are too heavy (Jira, Asana — clients won't use them) or too light (WhatsApp — no structure, no history). The gap: a simple, professional update layer between agency and client.

---

## The Solution

**ClientPulse** is a white-label client update portal. Agencies post structured project updates; clients access them through a branded link — no login, no app install required.

Clients get a clean, mobile-friendly page showing their project's progress, milestones, and updates. They can leave comments. The agency gets notified instantly.

---

## Target Market

**Primary:** Project managers and team leads at service agencies — dev studios, design firms, marketing agencies, CA firms — with 5–50 employees.

**Secondary:** Their clients — founders, marketing heads, product owners — who receive updates passively via email and magic link.

**Geography:** India (large TAM in agency density) + global English-speaking markets.

---

## Core Features

- **Agency Dashboard** — project management, structured update posting (rich text, file attachments, category tags), milestone tracking, team member management
- **Client Portal** — branded public page with updates timeline, progress bar, milestone overview, comment box; accessible via magic link
- **Notifications** — email client on new update, email agency on client comment (via Resend)
- **Workspace Branding** — agency name + logo on every client-facing portal

---

## Business Model

**SaaS, per workspace:**

| Tier | Price | Limit |
|------|-------|-------|
| Starter | ₹999/month | Up to 5 active projects |
| Growth | ₹2,499/month | Up to 20 projects + custom domain *(Post-MVP)* |
| Agency | ₹5,999/month | Unlimited projects + white-label |

Annual pricing at 20% discount to reduce churn.

---

## Revenue Potential

| Scenario | Workspaces | MRR |
|----------|-----------|-----|
| Conservative | 500 (Starter avg) | ₹5L |
| Target | 1,000 (mixed tiers) | ₹12–15L |
| Optimistic | 3,000 | ₹40L+ |

*Target scenario assumes ~600 Starter + 300 Growth + 100 Agency = ~₹14.4L MRR.*

India has 50,000+ registered digital agencies. Even 2% penetration at Starter tier = ₹5L MRR. Global expansion (USD pricing) multiplies this significantly.

---

## Competitive Differentiation

Closest alternatives and why they fall short:

| Tool | Gap |
|------|-----|
| Notion shared pages | Clients need an account to comment; no milestone tracking or category tags |
| Basecamp messages | Full project management tool — clients overwhelmed; no magic-link access |
| Clientjoy / Agency Handy | CRM-heavy, complex onboarding; not built for passive client consumption |
| WhatsApp / email | No structure, no history, no branding, no audit trail |

ClientPulse wins on: **magic-link access** (zero friction for clients), **agency branding** on every page, **structured updates** with categories and milestones, and a **purpose-built UX** for the agency → client relationship — not repurposed project management.

---

## Go-To-Market

- **Seed users:** Direct outreach to 50 agency founders via LinkedIn + IndieHackers; offer 3-month free trial for feedback
- **Community:** Post launch in agency Slack groups, IndieHackers, Product Hunt
- **Freemium hook:** 1 active project free forever — converts when agencies win a second client
- **Referral loop:** Clients who see the portal often run their own agencies — built-in word-of-mouth channel

---

## Why Now

- Post-COVID, client relationships are increasingly remote — agencies need async communication tools
- WhatsApp Business has made clients comfortable with chat-based updates; ClientPulse gives agencies a structured, branded alternative
- Supabase + stateless Node.js architecture is horizontally scalable from day one — no expensive rearchitecting at growth

---

## Tech Scalability

Stack designed to scale without rearchitecting:

- **Database:** Supabase Postgres — managed, RLS policies isolate workspace data, scales to millions of rows
- **Backend:** Stateless Node.js — horizontal scaling behind a load balancer, no session state server
- **Storage:** Supabase Storage — CDN-backed, handles file delivery at scale
- **Frontend:** Flutter Web — same Dart codebase adapted to iOS and Android apps in V2 with minimal rearchitecting

---

## Post-MVP Roadmap

| Feature | Tier Impact |
|---------|------------|
| Custom domain mapping | Growth/Agency upsell |
| Slack / WhatsApp notifications | Growth feature |
| Client file uploads (feedback docs) | Growth feature |
| Analytics (portal views, engagement) | Agency feature |
| Approval workflows (formal sign-off) | Agency feature |
| Billing + subscription management | All tiers |
| Flutter mobile apps (iOS + Android) | Expand to mobile-first agencies |
| API access for integrations | Agency tier |

---

## Sprint Outcome

Built in 2 weeks (solo, AI-assisted):

- Live deployed URL — Flutter Web on Firebase Hosting + Node.js on Render *(finalize after deploy day)*
- Complete feature set: auth, projects, updates, milestones, portal, comments, email notifications
- Real agency data loaded — usable as a demo or day-1 production tool
- Clean, professional UI — not a hackathon project
- Comprehensive automated test suite across backend (Jest) and frontend (Flutter test)

---

## Demo Flow

1. **Open with the pain:** "Our PMs spend hours every week answering 'what's the status?' on WhatsApp. Our clients deserve better, and our team deserves their time back."
2. **Create a project** → post an update with a screenshot → show the client portal link
3. **Open portal on a phone** — show mobile responsiveness
4. **Client leaves a comment** → agency gets email notification in real time
5. **Close:** "Every service agency with 5+ clients has this problem. At ₹999–₹2,499/month per workspace, even 1,000 agencies puts us at ₹10–15L MRR. The TAM in India alone is massive — and this works globally."
