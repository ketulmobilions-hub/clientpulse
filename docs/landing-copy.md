# ClientPulse — Landing Page Copy

Single-page landing site copy. Implementation: Flutter Web route `/` (or static Cloudflare Pages site if speed > consistency wins). Required live by **2026-05-07 (T-4)**.

Three hero variants for A/B testing. Default to **Variant A** at launch; switch by T+30 to whichever wins.

---

## SEO meta

```html
<title>ClientPulse — Client Update Portal for Service Agencies</title>
<meta name="description" content="Stop chasing client status. Post structured project updates; clients see a branded mobile-friendly portal via magic link. No login, no install. Built for service agencies." />
<meta property="og:title" content="ClientPulse — Show clients what's happening." />
<meta property="og:description" content="A branded client update portal for service agencies. Magic link, no login, mobile-first." />
<meta property="og:image" content="/og.png" />
```

---

## Hero — Variant A *(default)*

> # Stop chasing client status. Show it.
>
> ClientPulse is a branded client update portal for service agencies. Post structured project updates from your dashboard; clients see them on a mobile-friendly page via magic link. No login. No install. No app to learn.
>
> [Start free] [See a live portal →]

CTA #1: primary indigo button → `/register`
CTA #2: ghost link → opens public demo workspace `/p/demo123`

---

## Hero — Variant B

> # The client update portal your clients will actually open.
>
> Branded, mobile-first, magic-link access. Built for project managers who are tired of typing the same update four times across WhatsApp, email, and calls.
>
> [Start free] [Watch the 60-second demo →]

---

## Hero — Variant C

> # Every agency has the same problem.
>
> Clients ask "what's the status?" on WhatsApp, email, and calls. Project managers spend hours every week answering the same question.
>
> We fixed it.
>
> [Start free]

---

## Section 1 — The pain (under hero)

> ## You know this story.
>
> - Your client asks for a status update on WhatsApp. Again.
> - Your PM writes the same paragraph in three Slack threads, two emails, and one call.
> - Your shared Google Drive is a graveyard of unlabelled files.
> - Updates get lost. Trust erodes. Clients escalate.
>
> The current alternatives are too heavy (Jira, Asana — clients won't use them) or too light (WhatsApp — no structure, no history, no branding).
>
> ClientPulse is the layer in between.

---

## Section 2 — How it works (3 steps with screenshots)

> ## Three steps. That's the product.
>
> **1. Post a structured update.**
> Title, body, category (progress / milestone / deliverable / blocker / input-needed), file attachments. Two minutes from your dashboard.
>
> *[screenshot: agency dashboard "New Update" form]*
>
> **2. Client gets a link.**
> Magic-link email lands in their inbox. They tap once and they're in. No password. No app. Works on the phone they're already holding.
>
> *[screenshot: phone showing email + portal opening]*
>
> **3. Client sees the whole project.**
> Branded portal with timeline, milestones, progress bar, file downloads, and a comment box. They reply — you get notified instantly.
>
> *[screenshot: mobile portal with timeline + comment]*

---

## Section 3 — Feature grid (4×2)

> ## What you get on every plan
>
> | | |
> |---|---|
> | **Branded client portal** — your name and logo on every page | **Magic-link access** — no client passwords, ever |
> | **Structured updates** — categories, file attachments, markdown | **Milestone tracking** — auto progress bar from completion % |
> | **Email notifications** — clients on new update; you on new comment | **Mobile-first portal** — clients open on phones, not laptops |
> | **Multi-project workspace** — one account, every client | **Open data export** — CSV + JSON, day one, zero lock-in |

---

## Section 4 — Comparison table

> ## Why not just use {tool you already have}?
>
> | | ClientPulse | Notion shared page | Basecamp | WhatsApp |
> |---|---|---|---|---|
> | No client login | ✅ | ❌ | ❌ | ✅ |
> | Branded for your agency | ✅ | ❌ | ❌ | ❌ |
> | Structured update categories | ✅ | ❌ | Partial | ❌ |
> | Milestone tracker + progress bar | ✅ | ❌ | ❌ | ❌ |
> | Mobile-first portal UX | ✅ | Partial | ❌ | N/A |
> | Email-on-update notifications | ✅ | ❌ | ✅ | N/A |
> | Designed for the agency-client loop | ✅ | ❌ | ❌ | ❌ |

---

## Section 5 — Testimonial / social proof (post-launch, Phase 1+)

Placeholder until first design partner is quotable. By T+14, replace with:

> ## Three agencies are using ClientPulse today.
>
> > "We replaced our weekly update Loom + WhatsApp messages with one ClientPulse link. Our clients open it. They didn't open the Loom."
> > — {name}, {role}, {agency}
>
> > "The first time a client commented on a portal update I knew this was different. They never commented in WhatsApp."
> > — {name}, {role}, {agency}

---

## Section 6 — Pricing

> ## Pricing
>
> | | Starter | Growth | Agency |
> |---|---|---|---|
> | Price | ₹999/mo | ₹2,499/mo | ₹5,999/mo |
> | Active projects | 5 | 20 | Unlimited |
> | Team members | 3 | 10 | Unlimited |
> | Custom domain | — | ✅ | ✅ |
> | White-label (no "Powered by") | — | — | ✅ |
> | Priority support | — | — | ✅ |
>
> **Free forever** — 1 active project, 1 team member. Card not required.
> Annual pricing at 20% off. Pay in INR or USD. Cancel anytime, take your data with you.
>
> [Start free →]

---

## Section 7 — FAQ (top 6, link to launch-faq.md for the rest)

> ## Common questions
>
> **Is this different from Notion or Basecamp?**
> Yes. Notion needs a login and has no milestone or category tracking. Basecamp is a full project management tool — clients won't learn it. ClientPulse is a thin, purpose-built layer for the agency → client loop.
>
> **Where is my data stored?**
> Supabase Postgres in `ap-south-1` (Mumbai) for Indian workspaces, `us-east-1` for US/EU. Encrypted at rest, TLS in transit. Open data export from day one.
>
> **Can I use a custom domain like `updates.myagency.com`?**
> Custom domain mapping ships in Q3 2026 on Growth and Agency tiers. Until then, your portal lives at `clientpulse.dev/p/{token}` with your logo and name on the page.
>
> **What if you shut down?**
> Open data export, day one. CSV + JSON of every project, update, file URL, and comment. Zero lock-in by design.
>
> **Do my clients need to install anything?**
> No. The portal is a webpage that opens via magic link. Phone or laptop, any browser, no app.
>
> **Why magic links instead of passwords?**
> Clients hate passwords. Every password you ask a client to set is a chance for them to abandon the portal. Magic links remove the friction entirely.
>
> [See full FAQ →](https://clientpulse.dev/faq)

---

## Section 8 — Footer CTA

> ## Built for agencies. Loved by their clients.
>
> Free forever on the Starter tier. Two-minute setup. No credit card.
>
> [Start free →]
>
> ---
>
> ClientPulse · Built in Mumbai · [Twitter/X](https://twitter.com/clientpulse) · [IndieHackers](https://indiehackers.com/product/clientpulse) · [Status](https://status.clientpulse.dev) · [Privacy](https://clientpulse.dev/privacy)

---

## Waitlist form (pre-launch, replaces "Start free" until T-0)

Until 2026-05-11, the primary CTA captures email instead of provisioning a workspace.

> Want early access?
>
> [email input] [Notify me on launch →]
>
> 50 design-partner spots. 3 months free + 50% off Starter for life.

Storage: Supabase `waitlist` table — `email`, `referrer`, `utm_source`, `created_at`. Manual outreach to first 50 from this list.

---

## Voice & tone reminders

- Numbers > adjectives. "Three agencies are using ClientPulse today" beats "trusted by leading agencies".
- Founder-as-narrator. "We" is fine; "our company" feels corporate.
- Pro-client framing. Talk about *making the client's life easier* as the path to making the agency's life easier.
- No buzzwords: avoid "best-in-class", "seamless", "end-to-end", "leverage", "synergy", "AI-powered" (unless a real LLM feature ships).
- Match the product surface — calm, indigo, trust-first. Not loud, not flashy.

---

## Visual notes

- Background: `#F8F9FC` (matches `client/lib/core/theme/app_theme.dart` scaffold).
- Cards: white, 12px radius, hairline grey border (`Colors.grey.shade200`), no heavy shadow.
- Primary action: indigo (Material seed).
- Type: Inter — Regular for body, Semibold for headings. Two weights only.
- Hero screenshot: real product, not a generic illustration.
- One CTA per scroll viewport — overload kills conversion.
