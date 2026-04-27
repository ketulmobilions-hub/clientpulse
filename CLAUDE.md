# CLAUDE.md — ClientPulse

Client update portal for service-based agencies. Built solo during a 2-week internal sprint ("Zero to Product"). Claude assists heavily.

---

## Project Layout

```
clientpulse/
├── client/       # Flutter Web app
├── server/       # Node.js + TypeScript + Express backend
└── docs/
```

Local path: `~/development/brief_loop/clientpulse`  
GitHub: `ketulmobilions-hub/clientpulse`  
Project board: https://github.com/users/ketulmobilions-hub/projects/5

---

## Backend (server/)

**Stack:** Node.js + TypeScript + Express + Supabase JS client  
**Package manager:** npm  
**DB/Auth/Storage:** Supabase (project not yet created — set up first before any backend work)  
**Email:** Resend (account not yet created — sign up at resend.com first)  
**Deploy:** Render (free tier, auto-deploy from GitHub)  
**API base:** `/api/v1/`  
**ORM:** None — use Supabase JS client directly, no Prisma  

Key conventions:
- Error responses always: `{ success: false, error: { code: "...", message: "..." } }`
- All env vars through `src/config/env.ts` — never hardcode secrets
- Auth middleware in `src/middleware/auth.middleware.ts` — JWT from Supabase Auth
- Portal middleware in `src/middleware/portal.middleware.ts` — validates share_token / magic link token

---

## Frontend (client/)

**Flutter SDK manager:** FVM — always use `fvm flutter` / `fvm dart`  
**HTTP client:** Dio (with JWT interceptor in `shared/services/api_service.dart`)  
**State management:** Riverpod  
**Routing:** GoRouter (auth guard + public `/p/:token` portal route)  
**Code generation:** freezed + injectable — run `fgc` after modifying annotated files  
**Markdown:** flutter_markdown for rendering update bodies  
**Flavors:** dev + prod (separate build configs)  
**Deploy:** Firebase Hosting  

Key aliases:
| Alias | Command |
|-------|---------|
| `fvpg` | `fvm flutter pub get` |
| `fgc` | `fvm dart run build_runner build -d` |

Folder structure: `features/` `shared/` `core/` — mirrors joinbeet layout.

---

## Infrastructure

| Service | Tool | Status |
|---------|------|--------|
| Database | Supabase Postgres | Not created yet |
| Auth | Supabase Auth | Not created yet |
| File storage | Supabase Storage | Not created yet |
| Email | Resend | Account not created yet |
| FE hosting | Firebase Hosting | Not set up yet |
| BE hosting | Render | Not set up yet |
| Domain | Free subdomains only | — |

---

## Auth Flows

- **Agency:** Supabase email/password → JWT → `Authorization: Bearer <token>` header
- **Client:** Backend generates magic link token → stored in `magic_links` table (24h expiry) → sent via Resend → client clicks → session cookie / query param

---

## File Upload Flow

Flutter does NOT upload through the backend. Flow:
1. Flutter calls backend → backend returns Supabase Storage signed URL
2. Flutter PUTs file directly to Supabase Storage
3. Flutter sends resulting file URL to backend → saved in `attachments` table

---

## Sprint Timeline

2 weeks, solo. Deadline: ~2026-05-11.

| Phase | Days | Scope |
|-------|------|-------|
| 1 | 1–2 | Foundation, auth, project scaffold |
| 2 | 3–4 | Workspace + project CRUD |
| 3 | 5–7 | Updates + milestones + file upload |
| 4 | 8–9 | Client portal |
| 5 | 10–11 | Comments + email notifications |
| 6 | 12–14 | Polish, deploy, README, business brief |

GitHub issues #1–41 on project board map to these phases.

---

## Git Workflow (STRICT RULE)

**NEVER work directly on `main` or `dev`. Always create a feature branch.**

### Branch structure
- **`main`**: Production branch. Only merged into from `dev` after ALL issues in a phase are completed.
- **`dev`**: Integration branch. Only merged into from feature branches.
- **`feature/*`**: Created from `dev` for every GitHub issue. Format: `feature/issue-<number>-<short-description>`.

Flow: `feature/*` → `dev` → `main`

### Steps for every issue

1. **Move issue to "In Progress"** on the project board
2. `git checkout dev && git pull`
3. `git checkout -b feature/issue-<number>-<short-description>`
4. Do all work on the feature branch
5. **Run the mandatory 3-step review flow** (see Development Workflow below)
6. **Wait for user approval before committing. Do NOT commit until the user explicitly clears it.**
7. Pull latest dev before merging: `git checkout dev && git pull && git checkout - && git merge dev`. Resolve any merge conflicts on the feature branch first.
8. After approval, commit and merge feature branch into `dev` with `--no-ff`
9. **Move issue to "Done"**: `gh issue close <number>` and update project board status

Only after an **entire phase** is complete, merge `dev` into `main`.

---

## Development Workflow (Mandatory)

After completing every feature, the following 3-step review flow is **strictly required** before merging. Do not skip any step.

### Step 1 — Developer Explanation
Immediately after finishing a feature, provide a detailed explanation:

- What was done, why, and how — describe the feature, its purpose, and the approach taken
- List ALL created/modified files with a one-line purpose for each
- Explain the complete data flow through the system (e.g., UI → Provider → Repository → API/DB and back)

**Wait for the user to review before proceeding to Step 2.**

### Step 2 — Code Review
After the user has reviewed Step 1:

- Launch a `code-reviewer` agent to audit all feature code
- List ALL issues found with their respective file names
- For each issue: explain what it is, why it's a problem, and give a real-world example of the consequence if left unfixed

**Present the full list to the user and wait for their decision before proceeding to Step 3.**

### Step 3 — Fix Approved Issues
After the user has reviewed Step 2:

- Fix only the issues the user has approved — do NOT fix issues the user has not approved
- If fixes are substantial (new files, significant logic changes), repeat from Step 1 for the fixes

---

## Testing (Mandatory)

Every feature must include unit tests. Tests are written as part of the feature, not after — they are included in the same branch and reviewed in the 3-step review flow above.

---

## Before Starting Any Backend Work

1. Create Supabase project → grab `SUPABASE_URL` + `SUPABASE_ANON_KEY` + `SUPABASE_SERVICE_ROLE_KEY`
2. Run schema migrations (issue #2)
3. Create Resend account → grab `RESEND_API_KEY`
4. Populate `.env` from `.env.example`

## Before Starting Any Flutter Work

1. Backend must have auth endpoints live (at minimum a local server running)
2. Set `API_BASE_URL` in Flutter dev flavor config
