# ClientPulse — Case Study Template + Interview Guide

The format for capturing, writing, and shipping case studies. Used at T+30 (first design partner), T+60 (second), and T+90 (case study #3 + #4).

Why case studies matter at this stage: by T+30, organic discovery doesn't have brand recognition yet. A well-told case study from a real Indian agency does more for conversion than any landing page tweak.

---

## 1. Case study lifecycle

| Stage | When | Who runs it | Output |
|-------|------|-------------|--------|
| Identify | Day workspace activates | Founder | "Candidate" tag in CRM |
| Qualify | T+14 (2 weeks of usage) | Founder | Decision: pursue or pass |
| Schedule | T+21–T+25 | Founder | 45-min video interview booked |
| Interview | T+25–T+30 | Founder + agency contact | Recorded transcript |
| Draft | T+25–T+35 | Founder | Markdown draft, sent to agency for approval |
| Approve | T+35–T+40 | Agency contact | Edits + final sign-off + logo permission |
| Publish | T+40 | Founder | Lives at `clientpulse.dev/customers/{slug}` |
| Promote | T+40 + 30 days | Founder | LinkedIn post, X thread, newsletter, sales-call references |

---

## 2. Qualification — who's a case-study candidate?

A workspace qualifies if at least 4 of 6 are true:

| Criterion | Why it matters |
|-----------|---------------|
| Active for ≥14 days | Long enough to have a real story |
| ≥10 updates posted | Pattern, not anecdote |
| ≥3 active projects | Shows compounding adoption |
| Client portal viewed ≥20 times | Real client engagement, not just internal use |
| Agency willing to be quoted by name + logo | Public attribution is the whole point |
| Either (a) Indian agency or (b) clearly relatable to Indian agencies | Geographic match for our primary market |

If fewer than 4: not a fit yet. Tag, revisit at T+60.

---

## 3. Interview guide — 45 minutes

Record (with consent) on Google Meet or Zoom with cloud recording. Auto-transcribe via Whisper or Otter.ai.

### Opening (3 min)

> "Thanks for the time. I'm going to ask you about how your team worked before ClientPulse and how it's working now. There are no wrong answers — the more specific you are, the more useful the case study is. Anything you don't want quoted publicly, just say 'off the record' and I'll skip it. Cool?"

### Section 1 — Before (8 min)

Goal: surface the specific pain, not a generic one. Specificity is what makes case studies persuasive.

1. "Tell me about your agency — size, what you do, who your clients are."
2. "Walk me through how a typical week looked for client communication before ClientPulse."
3. "How many channels were you using? WhatsApp, email, calls, Slack — what was actually in use?"
4. "How much time did your PMs spend per week on status communication, ballpark?"
5. "Was there a specific incident — a missed update, an escalation, a churned client — that stood out?"

### Section 2 — Discovery + decision (5 min)

6. "How did you first hear about ClientPulse?"
7. "What made you actually try it instead of bookmarking it?"
8. "What were you skeptical about? What concerns did you have?"
9. "How did you make the call to add it to your stack — was it a quick yes, or did it take debate?"

### Section 3 — During (10 min)

Goal: capture the activation moment + onboarding experience.

10. "Walk me through your first day with ClientPulse. Did you set up a real client project, or did you test with a fake one first?"
11. "What was the moment when you knew this would actually work? Was it your first update? Your first client comment? Something else?"
12. "How did you introduce ClientPulse to your clients? Did you send them a link with no context, or warn them first?"
13. "What was your clients' first reaction?"
14. "Was there anything that surprised you — good or bad — in the first two weeks?"

### Section 4 — After (10 min)

Goal: extract specific, quantifiable change. Numbers > adjectives.

15. "How does your team's week look now compared to before?"
16. "Any specific number you can share — hours saved, response times, number of WhatsApp messages, anything quantifiable?"
17. "Have any of your clients said something unprompted about the portal?"
18. "Has it changed anything beyond communication — like client retention, project velocity, internal team morale?"
19. "What would you say if a fellow agency owner asked whether ClientPulse is worth it?"

### Section 5 — Forward (5 min)

20. "What's missing for you in ClientPulse today?"
21. "What's the one feature you'd build next if you could?"
22. "If we had to charge you 2× what you pay today, would you stay?"
23. "Anything I didn't ask that I should have?"

### Close (4 min)

> "Three quick admin questions:
>
> – I'd like to publish this with your name, your role, and your agency name + logo. Is that okay? (Get explicit verbal yes; follow up in writing.)
> – Are there any specific things from the conversation you want kept off the record?
> – Can I send you a draft for approval before publishing? (Yes, always.)"

---

## 4. The case study format

Target length: 800–1,200 words. Scannable. Pull-quotes prominent. One screenshot of their actual portal (anonymised if needed).

Lives at `clientpulse.dev/customers/{agency-slug}` and is also distributed as a downloadable PDF for outbound use.

### Template

```markdown
---
title: "How {agency name} replaced their weekly client status calls with ClientPulse"
agency: "{Agency name}"
agency_size: "{N employees}"
agency_location: "{City, Country}"
industry: "{Design / Dev / Marketing / etc.}"
published: "{YYYY-MM-DD}"
hero_quote: "{The single best quote from the interview, ≤30 words}"
hero_attribution: "{Name, Role, Agency}"
metrics:
  - label: "PM hours saved per week"
    value: "{N}"
  - label: "Client portal views per project"
    value: "{N}"
  - label: "Active projects on ClientPulse"
    value: "{N}"
---

# How {agency name} replaced their weekly client status calls with ClientPulse

> "{hero quote — same as frontmatter, large pull-quote}"
> — {hero attribution}

## At a glance

- **Agency:** {name} — {size} people, based in {city}.
- **Industry:** {industry}.
- **On ClientPulse since:** {YYYY-MM-DD}.
- **Active projects on ClientPulse:** {N}.

## The problem

[2–3 short paragraphs. Lead with the *specific* pain — a real story with names removed if needed. Avoid "agencies struggle with X" generality. Show, don't tell.]

> "{Quote from interview Section 1 — something specific about the before-state.}"
> — {Name, Role}

## What they tried

[1 short paragraph. List what they used before ClientPulse — be specific: WhatsApp + email, Notion shared pages, Basecamp, etc. Why each fell short for them, in their own words.]

## How they use ClientPulse

[2–3 paragraphs. Concrete: their cadence (e.g., Monday + Friday updates), their categories of choice, their milestone structure. Include 1 screenshot of their actual portal (anonymised if client info is sensitive).]

> "{Quote from Section 3 — the activation moment.}"
> — {Name, Role}

## What changed

[2–3 paragraphs. Lead with the most quantitative change available. Then the qualitative shifts: client behaviour, team morale, retention. End with an unprompted-client-quote if they have one.]

| Metric | Before | After |
|--------|--------|-------|
| {e.g. PM hours/week on status comms} | {N} | {N} |
| {e.g. avg client response time} | {duration} | {duration} |
| {e.g. messages per week per client} | {N} | {N} |

> "{Quote from Section 4 — the strongest after-state quote.}"
> — {Name, Role}

## What's next

[1 short paragraph. What features are they asking for, what's next on their roadmap with ClientPulse, any expansion plans. Forward-looking, optimistic — but honest.]

---

**Try ClientPulse.** Free Starter tier, no card required. → [clientpulse.dev](https://clientpulse.dev)
```

---

## 5. Approval flow

Never publish without explicit written approval from the agency contact. The flow:

1. Send a markdown-rendered preview link or PDF to the contact.
2. Cover email:

   > Hi {first}, here's the draft case study from our conversation. Two requests:
   >
   > 1. Edit anything that feels off, especially the quotes. I want this to sound like you.
   > 2. Confirm in writing that I can publish with your name, your role, and {agency} logo + link.
   >
   > No deadline pressure — better to get it right than fast.

3. After edits + sign-off, ship.
4. Email the contact when it's live with the URL and a "thanks" note.
5. Six months later, check in: any updated metrics worth refreshing?

---

## 6. Promotion plan per case study

Same Friday it goes live:

- Newsletter: lead item, 2-paragraph excerpt + link.
- LinkedIn: founder post quoting the hero quote, tagging the agency contact.
- Twitter/X: thread version (same beats, 5–7 tweets).
- IndieHackers: short post linking the case study.
- Cold outbound: every new LinkedIn DM that week mentions "we just published a case study from {similar agency}".

The next 30 days:

- One additional LinkedIn post weekly mentioning a different angle from the same case study (the hours-saved number, the activation moment, the unprompted client quote).
- Sales-call references: "agencies your size — like {agency name} — typically see {specific outcome} within {timeframe}." Use the case study as ammunition.

---

## 7. Anti-patterns — what *not* to do

- **No vanity metrics.** "Increased engagement by 300%" is meaningless without the absolute number.
- **No fake-sounding quotes.** Real quotes have specific names, projects, and small imperfections. Polished marketing-speak quotes destroy trust.
- **No anonymous case studies in launch quarter.** "Anonymous SaaS founder" is worse than no case study. Wait for someone willing to be named.
- **No case studies from someone using the free tier.** Always paid customers. Free-tier users have less skin in the game; their testimony is weaker.
- **No case studies before T+30.** A 5-day customer doesn't have a real story yet. Tempting, but skip.
- **No selling inside the case study.** Save the CTA for the bottom. The story is the marketing.

---

## 8. Storage

- Drafts: `docs/case-studies/draft/{agency-slug}.md` (gitignored — agency data not in public repo).
- Published: `docs/case-studies/published/{agency-slug}.md` (only after approval; sanitised).
- Recordings + transcripts: separate non-git folder (`~/Documents/clientpulse-interviews/`). Never committed.

Privacy: agency contact's contact details, internal financials, and anything they marked "off the record" never reach a committed file.
