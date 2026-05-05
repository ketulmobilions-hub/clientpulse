# ClientPulse — Onboarding Email Sequence

Six emails over 14 days, triggered when a new workspace is created. Goal: drive activation (≥1 project + ≥1 update + ≥1 portal view) and prevent week-2 silence.

Implementation: Resend transactional template per email, triggered from backend webhook on workspace creation + scheduled jobs for Day 1, 3, 7, 10, 14. Token replacements: `{first_name}`, `{workspace_name}`, `{portal_link}`, `{first_project_name}`, `{founder_first_name}`.

Voice: founder-to-founder. Specific. No marketing-speak. Plain text where possible (HTML version mirrors plain content with minimal styling — indigo CTA button, `#F8F9FC` background, Inter font).

---

## Email 0 — Day 0, sent within 60 seconds of workspace creation

**From:** `Ketul from ClientPulse <ketul@clientpulse.dev>`

**Subject:** Welcome to ClientPulse — let's get your first portal live in 5 minutes

**Plain text body:**

```
Hi {first_name},

Ketul here, founder of ClientPulse. Your workspace ({workspace_name}) is live.

Quick path to your first "wow" moment — about 5 minutes:

1. Create your first project
   → name it after a real client; e.g. "Acme Co — Q2 Brand Refresh"
   → add the client's email; this is what magic links go to

2. Post one update
   → keep it short: "Hi {client_first_name}, here's what's done so far..."
   → add one screenshot or PDF
   → pick a category (Progress / Milestone / Deliverable)

3. Hit Post
   → your client gets an email
   → they click → land on the branded portal
   → they see a real, polished status page on their phone

That's the whole loop. The first time a real client opens the portal,
you'll know whether ClientPulse is for you. Most agencies decide in
that single moment.

→ Get started: {dashboard_link}

If anything is unclear, hit reply. This email goes to my actual inbox
— I read every reply during my first 90 days post-launch.

— Ketul
ClientPulse
```

---

## Email 1 — Day 1, sent 24 hours after workspace creation

**Trigger condition:** sent regardless of activation status.

**Subject branch (depends on whether they posted an update yet):**
- If posted: "Your client just got their first ClientPulse update. Here's what they saw."
- If not posted: "Quick nudge — your first project takes 5 minutes"

### Variant A — they activated (posted ≥1 update)

**Subject:** Your client just got their first ClientPulse update. Here's what they saw.

**Body:**

```
Hi {first_name},

You posted your first update yesterday — nicely done.

Here's the part most agencies don't see: what the client experience
actually looks like on their phone.

[screenshot embedded: their actual portal, mobile viewport, with the
update they posted at the top]

Three things to notice:

1. The portal is branded with {workspace_name}, not "ClientPulse" —
   that's why most clients don't realise they're on a third-party tool.

2. The progress bar updates automatically as you mark milestones
   complete. Most clients open the portal just to look at the bar.

3. The category tags (Progress / Milestone / Deliverable / Blocker /
   Input Needed) let clients scan a project's history in seconds —
   the thing WhatsApp can never do.

Two next steps that compound:

  → Add your second client. Most agencies say "I want to see if it
    works on this one first" — but the value is in stopping
    WhatsApp-and-email across all clients, not one.

  → Set up milestones for the project. Five seconds each. The
    progress bar is the single most-checked thing on the portal.

→ Open dashboard: {dashboard_link}

— Ketul
```

### Variant B — they haven't activated

**Subject:** Quick nudge — your first project takes 5 minutes

**Body:**

```
Hi {first_name},

You signed up for ClientPulse yesterday but haven't created a project
yet. No worries — most people don't on day one.

Quick thing: the value of ClientPulse isn't visible until you see a
real client open the portal on their phone. That's the wow moment,
and it takes about 5 minutes to reach.

Path:

1. Pick one current client. Real one. Not a test.
2. Create a project, add their email.
3. Post one short update with a screenshot.
4. They open the portal on their phone. You see it land.

If you got stuck somewhere in setup, hit reply and tell me where —
I'll fix it on my side or walk you through it personally.

→ Pick up where you left off: {dashboard_link}

— Ketul
```

---

## Email 2 — Day 3

**Trigger condition:** sent regardless of state. Goal: borrow workflow + prevent friction-quit.

**Subject:** How {design_partner_name} runs their weekly update cadence

**Body:**

```
Hi {first_name},

One question almost every new ClientPulse user asks: "how often should
I post updates?"

Answer from {design_partner_name}, a Bangalore design studio that's
been on ClientPulse since week one:

> "We post Monday and Friday. Monday is what we're doing this week,
>  Friday is what we shipped. Two updates a week per project. Our
>  clients used to message us 6+ times a week — now it's 0–1."

Their structure:

  Monday update
    Title: "Week of {date} — what we're doing"
    Category: Progress
    Body: 3–5 bullet points of this week's focus
    Attachment: usually none

  Friday update
    Title: "Shipped this week"
    Category: Deliverable
    Body: what was shipped, links to deliverables
    Attachment: 1–3 screenshots / PDFs

That's it. Thirty minutes of writing per project per week, replaces
about three hours of fragmented chat communication.

If you want, copy their template into your first project right now:

→ Open dashboard: {dashboard_link}

— Ketul
```

---

## Email 3 — Day 7

**Trigger condition:** branched on activity since signup.

**Subject branch:**
- If active (≥3 updates posted): "Your portal so far — and 3 things to try next"
- If single-project (only 1 project ever created): "Most agencies start with 3 clients. Here's why."
- If silent (no updates posted): "Honest question — what's missing?"

### Variant A — active (≥3 updates)

**Subject:** Your portal so far — and 3 things to try next

**Body:**

```
Hi {first_name},

In your first week with ClientPulse you posted {update_count} updates
across {project_count} projects, and your client portals were opened
{view_count} times.

That's working. Three things to try next that compound activation:

1. Add milestones to {first_project_name}.
   The progress bar is the single most-checked thing on the portal.
   Two minutes to set up, big visibility upgrade for the client.

2. Invite a teammate.
   ClientPulse is built for whole agencies, not solo PMs.
   Multiple people posting updates raises the cadence without raising
   anyone's individual workload.

3. Add your logo.
   On the portal it shows where the ClientPulse mark would otherwise
   be. Three-second upload, makes the page feel fully owned by your
   agency.

→ Open settings: {settings_link}

— Ketul
```

### Variant B — single-project

**Subject:** Most agencies start with 3 clients. Here's why.

**Body:**

```
Hi {first_name},

You've got one project in {workspace_name} so far. That's a fine
start, but the value compounds when there's more than one.

The reason: status communication overhead is per-client, not per-tool.
If you have one client, ClientPulse replaces a single WhatsApp thread
— useful but small. With three clients, it replaces three threads,
three weekly emails, and the mental load of remembering which client
asked what.

Most agencies hit their "this is paying for itself" moment between
client #2 and client #3 on ClientPulse.

If there's a friction in adding a second client (data import,
client-email concerns, internal workflow), reply and tell me — I'll
help.

→ Add your second client: {new_project_link}

— Ketul
```

### Variant C — silent

**Subject:** Honest question — what's missing?

**Body:**

```
Hi {first_name},

You created a workspace a week ago but haven't posted an update yet.
That's almost always one of three things, in my experience:

1. The first-update friction.
   Writing the first one feels like committing. It's not — you can
   delete or edit anytime. Treat it like a Slack message, not a press
   release.

2. The "is this for me?" question.
   ClientPulse is best for agencies with 3+ active client projects and
   weekly status communication overhead. If you don't have that yet,
   this is genuinely the wrong tool right now — and that's fine.

3. Something I haven't thought of.
   This is the most likely one, honestly. If something stopped you,
   I'd love to know what — even one sentence helps me make the
   product better.

Reply with whichever applies. Or none — and I'll stop emailing.

— Ketul
```

---

## Email 4 — Day 10

**Trigger condition:** sent regardless of state. Goal: social proof.

**Subject:** What clients are saying about ClientPulse portals

**Body:**

```
Hi {first_name},

Three quotes from clients of ClientPulse design-partner agencies, all
unprompted:

> "It's the first time I've felt informed without having to ask."
> — VP Marketing, fintech client of a Bangalore design studio

> "I open it from my phone in the Uber. That's how I know I'm
>  actually using it."
> — Co-founder, e-commerce client of a Mumbai dev agency

> "The progress bar is genuinely calming. I always thought we were
>  late on this project — turns out we're on track and I just didn't
>  know."
> — Marketing head, SaaS client of a Pune branding agency

The pattern: clients aren't praising features. They're describing how
their relationship with the agency feels different.

If your clients aren't yet at this point, two questions worth asking:

  1. Are you posting at a regular cadence? (Twice a week is the sweet
     spot per most design partners.)

  2. Are clients getting the email notifications? Check Resend
     deliverability — sometimes the first email goes to spam.

→ Verify deliverability: {settings_link}

— Ketul
```

---

## Email 5 — Day 14

**Trigger condition:** sent regardless of state. Goal: voice-of-customer + retention check.

**Subject:** Quick favour — 2-min feedback?

**Body:**

```
Hi {first_name},

You've been on ClientPulse for two weeks. I'm asking everyone the
same three questions at this point. Replies feed directly into the
roadmap — no one else sees them, no AI summarises them, I read each
one personally.

1. What's the single thing ClientPulse does well for you?
   (One sentence is fine.)

2. What's the single thing that's frustrating or missing?

3. If we shut down tomorrow, what's the closest workaround you'd
   reach for?

Reply to this email. I read every one within 24 hours.

If ClientPulse isn't working for you and you'd like to cancel, just
say so in the reply — no awkward exit flow, no retention email blast.
Open data export is one click in settings.

— Ketul
```

---

## Implementation notes

- All six emails go through Resend with `From: ketul@clientpulse.dev` and `Reply-To: ketul@clientpulse.dev`. Replies hit founder inbox directly, not a no-reply.
- Day 1 / Day 7 variants branch on activity flags computed from the `updates` and `projects` tables at trigger time.
- Unsubscribe link in footer (List-Unsubscribe header for Gmail compliance). Unsubscribe = stop transactional sequence; does not affect magic-link delivery.
- Track per-email open and click rates via Resend webhooks → `email_events` table. Review weekly.
- Re-read this file when product surface changes (e.g. when custom domains ship, update Email 0 to mention the option).

## Voice rules (apply to every email)

- One specific number > five adjectives. ("47 updates posted in week 2" > "great traction".)
- Founder-to-founder. Sign with first name only.
- No exclamation marks. No emoji.
- One CTA per email. Two at most. Never three.
- Subject lines: lowercase first word feels more human; capitalise only when starting with a name.
- If a sentence could appear in any SaaS's onboarding email, rewrite it.
