# ClientPulse — Launch FAQ

Pre-written replies for the most likely questions on Product Hunt, Hacker News, IndieHackers, LinkedIn, and email during launch week (2026-05-25 → 2026-06-01).

**Rules:**
- Reply within 30 minutes during launch day. Slower kills momentum.
- Never argue. Thank-and-fix is the default register.
- Edit responses to match the channel — Reddit/HN tolerate sharper voice; Product Hunt rewards warmth.
- If a question isn't here, draft an answer in this file *before* posting it publicly. Today's improv is tomorrow's contradiction.

---

## 1. "How is this different from Notion / Basecamp / Linear?"

**Short reply:**

> Notion needs a login, has no milestone tracking, no category tags, no email-on-update — clients ignore the page. Basecamp is a full PM tool clients won't learn. Linear is for engineers. ClientPulse is purpose-built for the agency → client relationship: branded portal, magic-link access, structured updates, mobile-first. One link. No login.

**Long reply (when prompt warrants):**

> The closest tools we get compared to are Notion shared pages and Basecamp messages. Both fail in the same place: the client.
>
> - Notion: clients need an account to comment, and there's no concept of update categories or milestones. The page becomes a doc dump.
> - Basecamp: powerful, but you're handing a client a full project management product and asking them to learn it. They won't.
> - Linear: built for engineers tracking issues, not for client communication.
>
> ClientPulse is the layer between agency PM and client. Agency posts structured updates (categories: progress / milestone / deliverable / blocker / input-needed). Client opens one mobile-friendly portal via magic link, sees timeline + milestones + progress bar, leaves comments. That's the whole loop.

---

## 2. "Why pay when WhatsApp is free?"

> WhatsApp has no structure, no history search, no audit trail, no branding, and no mobile-friendly view of milestones. PMs typing the same update across 4 client chats burns 5+ hours/week. At ₹2,000/hr blended PM cost that's ₹40K/month. ClientPulse Starter is ₹999/month. ROI in week one. WhatsApp stays for chat — ClientPulse owns structured updates.

---

## 3. "I could build this myself in a weekend."

> Sure — magic-link auth + signed file uploads + email infra + mobile-responsive portal + workspace branding + comment loop + onboarding flow. That's ~6–8 weeks of solo dev. Or ₹999/month.
>
> The honest version: most agencies won't build it. They'll keep using WhatsApp because it's "good enough" until a client churns and they realise it wasn't.

---

## 4. "Is my client data safe? Where is it stored?"

> Hosted on Supabase (PostgreSQL) in `ap-south-1` (Mumbai) for Indian workspaces, `us-east-1` for US/EU workspaces. Encrypted at rest, TLS in transit. Magic-link tokens expire in 24 hours. Workspace data is row-level isolated.
>
> DPA available on request. Open data export (CSV + JSON) from day one — zero lock-in by design. If we shut down tomorrow you take all your data with you.

---

## 5. "Are you India-only?"

> No — the team is in India and we built for India first because the agency density is huge (50,000+ registered service agencies). Pricing is ₹ for India, USD for global. Magic-link emails work anywhere. Hosting region picked per workspace at sign-up. Roughly 30% of waitlist is already non-India.

---

## 6. "You're a single founder. What if you disappear?"

> Fair. Three answers:
>
> 1. Open data export from day one. You can leave with everything.
> 2. The product runs on standard, replaceable infrastructure (Postgres + Node.js + Resend). No proprietary lock-in.
> 3. I'm building in public on IndieHackers + Twitter — full metrics, weekly. If things wobble, you'll know before you're surprised.
>
> Single-founder is a real risk for any SaaS at this stage. We don't pretend otherwise. We compensate by making leaving cheap.

---

## 7. "What's missing in the MVP?"

Be honest. Listing is not weakness — it's credibility.

> Today (T+0) ClientPulse covers the core loop: agency dashboard → projects → updates with attachments → milestones → client portal → comments → email notifications.
>
> What's deliberately not in MVP and is on the public roadmap:
>
> - Custom domain mapping (`updates.youragency.com`) — Q3 2026
> - Slack / WhatsApp notifications — Q3 2026
> - Client file uploads (feedback docs from client side) — Q3 2026
> - Portal analytics (which updates clients actually opened) — Q4 2026
> - Approval workflows (formal sign-off on deliverables) — Q4 2026
> - Mobile apps (Flutter mobile, same codebase) — Q1 2027
>
> Roadmap lives at `clientpulse.dev/roadmap` (public).

---

## 8. "Why magic links and not passwords?"

> Clients hate passwords. Every password your agency asks a client to set is a chance for them to abandon the portal. Magic links remove the friction entirely — click email, you're in. Token expires in 24 hours. Re-request is one click.
>
> For agency-side accounts (PMs, admins) we use email + password because they're daily users and benefit from a persistent login.

---

## 9. "How do you prevent magic-link abuse / spam?"

> Three layers:
>
> 1. Per-IP rate limit on magic-link generation (10/hour).
> 2. Per-email cooldown (1 link / 5 minutes).
> 3. hCaptcha on public sign-up flows during launch month.
>
> Tokens are single-use, 24-hour expiry, signed with `JWT_SECRET`. No magic link works after click + session start.

---

## 10. "Pricing feels expensive for India."

> ₹999/month is roughly $12. The buyer is an agency PM whose time is worth ₹2,000/hr. The break-even point is one PM hour saved per month — most agencies save 5+. We tested ₹499 with 5 design partners; the response was "this is too cheap, I don't trust it." Pricing signals seriousness.
>
> If ₹999 is genuinely a blocker, the free tier (1 active project) covers small shops indefinitely.

---

## 11. "Can I white-label this entirely?"

> Agency tier (₹5,999/month) hides all "Powered by ClientPulse" branding and lets you customise the workspace name + logo on the public portal. Custom domain mapping (`updates.youragency.com`) ships in Q3 2026 on the same tier.
>
> Below Agency tier: agency name + logo on portal header, but a small "Powered by ClientPulse" footer link remains. It keeps the free tier free.

---

## 12. "How are you different from Clientjoy / Agency Handy / Bonsai?"

> Those are agency CRMs — invoicing, contracts, proposals, time tracking, all the back-office workflow. They're heavy onboarding for both agency and client.
>
> ClientPulse does one thing: the client-facing update portal. We're a layer you'd add *next to* a CRM, not *instead of* one. Many of our beta agencies use Clientjoy + ClientPulse together — Clientjoy for billing, ClientPulse for what the client actually opens daily.

---

## 13. "Can I integrate with [tool]?"

> Today: no API. Roadmap: API access on Agency tier in Q4 2026, plus webhooks for new-update / new-comment events. Most-requested integrations: Slack (Q3), Gmail (Q4), Linear (Q4), Notion (Q1 2027). Vote on the public roadmap.

---

## 14. "What happens at the end of the 3-month free trial?"

> Trial converts to free tier (1 active project). Existing data stays. You upgrade when you outgrow it. No card on file required to start, no surprise charge, no dark patterns. We've seen what those look like and we're not doing it.

---

## 15. Negative-feedback templates

When a comment is critical (HN especially), use one of these:

**Bug report:**
> Thanks — that's a real issue. Reproducing now. Will post the fix here within {hours}. Track at {GitHub issue link}.

**UX critique:**
> Good catch. {X} is on the immediate-fix list — currently {current state}, target {fixed state} by {date}. We'll DM you when it ships.

**"I don't see the value" comment:**
> Fair — ClientPulse only makes sense if you have ≥3 active client projects and weekly status communication overhead. If you're solo with 1 client, there's nothing to solve here. Saying so honestly is more useful than convincing.

**"This is just X with extra steps":**
> You're right that the building blocks aren't novel. The bet is on the configuration: branded magic-link portal + structured updates + mobile-first + zero client login, packaged for the agency PM. Each piece exists somewhere; the combination doesn't.

---

## Maintenance

- Append new questions and answers as they appear in the wild.
- Date-stamp answers when product reality changes (e.g. when custom domains ship, edit Q7 + Q11).
- Re-read this doc top-to-bottom every Monday during launch month.
