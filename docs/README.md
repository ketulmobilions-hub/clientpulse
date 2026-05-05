# ClientPulse — Docs Index

All non-code documentation for the ClientPulse sprint and post-launch operations.

For codebase / setup instructions, see the [project root README](../README.md).
For the engineering operating model, see [`CLAUDE.md`](../CLAUDE.md).

---

## Strategy

| Doc | Purpose | Read when |
|-----|---------|-----------|
| [`business-brief.md`](./business-brief.md) | Pricing, TAM, competitive positioning, revenue model, post-MVP roadmap. The single source of truth for *what we sell, to whom, for how much*. | Pitching, fundraising, hiring conversations, sales calls. |
| [`launch-strategy.md`](./launch-strategy.md) | 4-phase launch playbook anchored to sprint deadline 2026-05-11. Day-of channel stack, technical / comms readiness checklist, risk register, demo-day narrative. | Pre-launch (T-6 → T+0) and launch day (T+14, 2026-05-26). |
| [`marketing-strategy.md`](./marketing-strategy.md) | Positioning, JTBD, ICP firmographics, 5-channel playbook, 90-day content calendar, funnel targets, retention plays, voice + visual rules, metrics dashboard. | Sustained marketing post-launch. Re-read monthly. |
| [`roadmap.md`](./roadmap.md) | Public roadmap — what shipped, what's next, what's deliberately not shipping. Linked from launch FAQ and landing page. | Customer questions about features. Update on every Friday during launch quarter. |

## Launch-day operations

| Doc | Purpose | Read when |
|-----|---------|-----------|
| [`launch-posts.md`](./launch-posts.md) | Pre-written launch-day posts for Product Hunt, Hacker News, IndieHackers, Reddit, LinkedIn, Twitter/X, BetaList, India communities, and email. | Launch day morning (2026-05-26). Edit lightly before posting; copy verbatim only on PH. |
| [`launch-faq.md`](./launch-faq.md) | 15 pre-written replies for the most-likely PH/HN/IH/LinkedIn questions. Negative-feedback templates included. | During launch week. Append new questions as they appear. |
| [`demo-script.md`](./demo-script.md) | 4-minute demo-day pitch with minute-by-minute beats, Q&A, and failure fallbacks. Maps 1:1 to business-brief talking points. | Demo day (2026-05-11). Practice T-3, T-2, T-1. |
| [`runbook.md`](./runbook.md) | Incident response — severity ladder, rollback commands, 9 common failure modes, comms templates, postmortem format. | When something is on fire. Read once before launch so it's familiar. |

## Outreach + marketing assets

| Doc | Purpose | Read when |
|-----|---------|-----------|
| [`dm-target-list.md`](./dm-target-list.md) | LinkedIn DM playbook — ICP filter, 5 sourcing channels, 3 DM templates, cadence rules, reply triage, design-partner call structure. | Building the soft-launch list (T-3 onwards). |
| [`landing-copy.md`](./landing-copy.md) | Landing page copy — 3 hero variants, 8 sections, comparison table, FAQ subset, waitlist form, voice + visual notes. | Building the landing page (T-4, by 2026-05-07). |
| [`onboarding-emails.md`](./onboarding-emails.md) | 6-email onboarding sequence over 14 days. Day 0 / 1 / 3 / 7 / 10 / 14. Includes branched variants for activated vs. silent users. | Implementing Resend templates before launch. Re-read when product surface changes. |
| [`case-study-template.md`](./case-study-template.md) | Case study lifecycle, 23-question interview guide, frontmatter + markdown template, approval flow, promotion plan. | First case study at T+30; subsequent at T+60 and T+90. |

## Master checklist

| Doc | Purpose | Read when |
|-----|---------|-----------|
| [`launch-checklist.md`](./launch-checklist.md) | Single timeline-ordered checklist consolidating every action item across all docs. T-6 through T+90, with hard escalation triggers. | Daily during launch week. Tick boxes as you go. |

---

## Cross-doc anchor dates

| Date | Day | Milestone |
|------|-----|-----------|
| 2026-05-05 | Tue | Today (T-6). Strategy docs landed. |
| 2026-05-07 | Thu | Landing page live (T-4). |
| 2026-05-09 | Sat | Launch FAQ + demo script reviewed (T-2). |
| 2026-05-10 | Sun | Runbook + status page wired (T-1). Final dry run. |
| 2026-05-11 | Mon | Sprint demo day (T-0). Soft launch begins same evening. |
| 2026-05-18 | Mon | Soft launch ends (T+7). Tally activations + testimonials. |
| 2026-05-25 | Mon | Public launch IST (T+14 IST). |
| 2026-05-26 | Tue | Public launch PT (T+14 PT). PH go-live 12:01 AM PT. |
| 2026-06-10 | Wed | Post-launch evaluation (T+30). Conversion gates open. |
| 2026-08-09 | Sun | Quarterly review (T+90). Roadmap re-baselined. |

---

## Maintenance

- Strategy docs (top section): re-read monthly. Update on material shifts (new pricing, new ICP).
- Operations docs (middle section): consult on demand. Append-only during launch week.
- Outreach assets (bottom section): edit as templates evolve from real-world results.
- This index: update on every new doc added.

---

## Conventions

- Currency: ₹ for India, USD for global. Always state which.
- Dates: absolute (`2026-05-11`), never relative (`next Monday`).
- Tables for any list with > 3 items.
- Voice: founder-to-founder. No buzzwords. Numbers > adjectives.
- File names: `kebab-case.md`. No spaces. No timestamps in filenames (use frontmatter or content for dates).
