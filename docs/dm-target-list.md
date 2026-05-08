# ClientPulse — LinkedIn DM Target List Playbook

How to build, qualify, and work the 50-prospect list for soft-launch outreach (Phase 1: 2026-05-18 → 2026-05-25).

This is a **playbook**, not a static list. Real names go into a separate spreadsheet (`linkedin-outreach.xlsx` — local only, never committed) so personal data isn't tracked in git.

---

## 1. Goal

50 personalised LinkedIn DMs, sent over 5 working days at 10/day max. Target: 5–9 design partners onboarded (12–18% reply × 60% conversion of replies).

Quality > volume. A 50-person list of perfect-fit ICPs beats a 500-person blast every time.

---

## 2. ICP filter (must match all)

| Dimension | Filter |
|-----------|--------|
| Company type | Service agency: dev studio / design firm / marketing / branding / CA / legal / consulting |
| Headcount | 5–50 employees |
| Geography | India (priority) or US/UK/AU/SG English markets |
| Person's title | Project Manager / Account Manager / Operations Lead / Founder / Partner / Co-founder |
| Person's seniority | Decision-maker or strong influencer (not an intern, not a CEO of 200-person firm) |
| Activity | Posted on LinkedIn within the last 90 days (warm audience signal) |
| Mutual connection | At least one shared connection if possible (boosts reply rate ~3×) |

Reject: in-house product team PMs (no external clients), enterprise consulting partners (procurement cycles), solo freelancers (no compounding pain).

---

## 3. Sourcing channels

Rank-ordered by signal quality.

### 3.1 Existing personal network (target: 10 of 50)

The highest-conversion 10. Anyone the founder has worked with directly or through one degree.

- Past colleagues at agencies
- College / bootcamp alumni now at agencies
- Slack/Discord contacts from agency communities
- Twitter mutuals who run agencies

These get the warmest version of the DM (see template W).

### 3.2 Clutch.co / DesignRush / GoodFirms (target: 20 of 50)

Public agency directories. Filter:

- Clutch.co → Services → "Web Development" / "Digital Marketing" / "Branding" → Location: India → Employees: 10–49
- DesignRush → Agency Listings → similar filters
- GoodFirms → Top Agencies → India

For each agency in results: open their LinkedIn page, find a PM/Founder, qualify against ICP filter. Skip if anyone on the team is currently using a competitor product (Clientjoy, Agency Handy) — they're a harder sell.

### 3.3 LinkedIn Sales Navigator free trial (target: 10 of 50)

Sign up for the 1-month free trial during launch month. Filters:

- Industry: Marketing & Advertising / Design / IT Services / Consumer Services
- Headcount: 11–50
- Geography: India / United States / United Kingdom
- Title: contains "Project Manager" OR "Account Manager" OR "Operations" OR "Founder"

Save searches. Export weekly activity (who posted, who changed jobs). Cancel before day 30.

### 3.4 Community lurkers (target: 5 of 50)

People posting in r/agency, r/digital_marketing, IndieHackers, Headstart Slack. They're already actively thinking about agency-ops problems. Reply helpfully on their posts first; DM second.

### 3.5 Referrals from design partners (target: 5 of 50)

Once first 1–2 design partners are onboarded (T+2 ish), ask each: *"who else in your network has the same pain?"* Two warm intros per partner = 4–6 high-fit prospects.

---

## 4. Spreadsheet schema

Local spreadsheet `linkedin-outreach.xlsx`. Never commit.

| Column | Example | Notes |
|--------|---------|-------|
| `name` | Priya Sharma | First + last |
| `title` | Project Manager | From LinkedIn |
| `agency` | Northpoint Studio | Company name |
| `agency_size` | 22 | From Clutch / LinkedIn |
| `agency_url` | northpoint.studio | Website |
| `linkedin_url` | linkedin.com/in/priyas | Profile URL |
| `source` | Clutch | Or `network`, `nav`, `community`, `referral` |
| `mutual` | Rahul K | Shared connection if any |
| `personalisation_hook` | Posted 3 days ago about losing a retainer to bad comms | One specific reason this DM isn't generic |
| `status` | not-sent / connect-sent / accepted / dm-sent / replied / call-booked / activated / passed | State machine |
| `connect_sent_at` | 2026-05-19 | Date |
| `dm_sent_at` | 2026-05-21 | Date |
| `reply_at` | 2026-05-22 | If replied |
| `outcome` | activated / not-fit / no-reply / circle-back-T+30 | Final state |
| `notes` | wants Slack integration first | Free text |

Dashboard: pivot table — count of each `status` and `outcome` value. Updated daily.

---

## 5. The two-step contact flow

Send a connection request first; only DM after acceptance. LinkedIn punishes cold InMail and rewards organic flow.

### Step 1 — Connection request (within 300 chars)

**Template — warm (network):**

> Hi {first}, {founder name} here — we crossed paths at {context}. Building something for service agencies right now and would love to keep in touch.

**Template — cold (Clutch / Sales Nav):**

> Hi {first}, came across {agency} via {Clutch / a portfolio piece / a recent post}. Building a tool for agency PMs and would love to learn how you handle weekly client updates. Open to connecting?

Personalise the *one* `{personalisation_hook}` field. Generic connection requests have a ~20% acceptance rate; specific ones hit 50–70%.

### Step 2 — DM after connection accepted (send 24–48 hours after accept, not immediately)

**Template W — warm (existing network, design-partner ask):**

> Hey {first}, good to reconnect. Quick context — I just shipped ClientPulse, a client update portal for service agencies. Agencies post structured updates, clients see a branded mobile portal via magic link, no login.
>
> Looking for 5 design partners in your space. Offer: 3 months free + locked-in 50% off Starter for life. In exchange: candid feedback + permission to quote you when it's ready.
>
> Worth a 15-min call this week? — {founder}

**Template C — cold (Clutch / Sales Nav, design-partner ask):**

> Hi {first}, thanks for connecting. Saw {agency} works with {industry} clients — quick question. How does your team currently handle weekly status updates to clients?
>
> Reason I ask: I just shipped ClientPulse — agencies post structured updates, clients see a branded portal via magic link, no login. Looking for 5 design partners in {city}: 3 months free + locked-in 50% off Starter for life when you upgrade.
>
> Worth a 15-min look? Live URL + 60-second demo: {link}.
>
> — {founder}

**Template R — referred:**

> Hi {first}, {referrer name} suggested I reach out. Just shipped ClientPulse — branded client update portal for service agencies, magic-link access. {Referrer} mentioned {agency} runs into the same client-status pain we're solving.
>
> Open to a 15-min look? 3 months free + 50% off Starter for life as a design partner.
>
> — {founder}

### Follow-up — single nudge, 5 days later

> Hey {first}, no pressure — just bumping this in case it slipped. Demo URL is {link} if you want to look without booking a call. Happy to slot in 15 mins anytime this week. — {founder}

If still no reply 7 days after follow-up: mark `status = no-reply`, `outcome = circle-back-T+30`, move on. Never triple-message.

---

## 6. Cadence and capacity

| Day | Action | Volume |
|-----|--------|--------|
| 2026-05-18 (T-0) | Send 10 connection requests | 10 |
| 2026-05-19 | Send 10 + DM accepted from yesterday | 10 + 3–5 DMs |
| 2026-05-20 | Send 10 + DM accepted | 10 + 3–5 DMs |
| 2026-05-21 | Send 10 + DM accepted + 1st follow-ups | 10 + 5 DMs + 2 nudges |
| 2026-05-22 | Send 10 + DM + follow-ups | 10 + 5 + 3 |
| 2026-05-23 (Sat) | Reply triage only | — |
| 2026-05-24 (Sun) | Reply triage + book Mon calls | — |
| 2026-05-25 (T+7) | Final follow-ups; tally outcomes | nudges only |

**Hard caps** (LinkedIn limits — exceeding triggers restrictions):

- ≤ 100 connection requests/week
- ≤ 30 DMs/day to non-connections (we avoid this entirely by connecting first)
- ≤ 50 profile views/day in rapid succession (use Sales Nav saved searches instead of manual browsing)

---

## 7. Reply triage

Replies fall into four buckets. Respond within 4 hours during work hours.

| Reply pattern | Example | Action |
|---------------|---------|--------|
| Curious / open | "Sure, send me a link" | Send demo URL + Calendly link. Don't push for the call yet. |
| Interested / qualified | "We have exactly this problem — when can we talk?" | Book a 15-min call same week. Send Loom of the product the night before. |
| Polite no | "Looks cool but we use {tool}" | "Totally — would love to circle back at T+30 with the comparison teardown if useful?" Move to `circle-back-T+30`. |
| Hard no / hostile | "Not interested" or no reply | Mark and move on. Never argue. |

---

## 8. The design-partner call (15 minutes)

When a reply turns into a booked call.

| Time | Action |
|------|--------|
| 0:00–2:00 | Their context: agency size, project mix, current update workflow. Listen 80%. |
| 2:00–7:00 | Show: live URL on screen-share, walk through agency dashboard → portal → comment loop. Same flow as demo script. |
| 7:00–11:00 | Ask: "If this were free for 3 months, would you actually try it on a real client?" If yes, get the client name + project name on the call. Set up workspace live. |
| 11:00–14:00 | Address objections; commit to a follow-up touchpoint at day 7 (Loom of how they're using it). |
| 14:00–15:00 | Ask: "Two more agencies in your network with the same pain?" Get names + permission to use them as referrer. |

If they convert: change spreadsheet `status = activated`, log workspace ID, schedule day-7 + day-21 follow-ups.

---

## 9. What success looks like by T+7

| Metric | Target |
|--------|--------|
| Connection requests sent | 50 |
| Connections accepted | 25–35 (50–70% acceptance) |
| DMs sent | 25–35 |
| Replies | 4–7 |
| Calls booked | 3–5 |
| Activated workspaces from this list | 3–5 |
| Referrals captured | 5–10 |

If accept rate is below 30%, the connection-request opener is wrong — rewrite. If reply rate is below 8%, the DM template is wrong — rewrite. Diagnose the funnel stage before rewriting downstream.

---

## 10. Post-list followup (T+30)

Everyone marked `circle-back-T+30` gets one more touch:

> Hi {first}, {founder} from ClientPulse. We talked back in May — wanted to share where we are now: {N} agencies onboarded, {feature/case study highlight}. Worth a fresh look? Demo URL: {link}.

Never resurface someone marked `hard-no`. Respect goes a long way.
