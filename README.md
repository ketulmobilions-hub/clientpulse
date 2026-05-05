# ClientPulse

**Lightweight client update portal for service-based agencies.**

Post structured project updates. Clients view them via a magic link — no login, no app install.

---

## What Is ClientPulse

ClientPulse is a white-label-ready status portal where agencies post updates and clients track progress through a branded link. Think Statuspage.io, but for client projects instead of infrastructure.

Agency teams manage projects, milestones, and updates from a dashboard. Clients get a clean, mobile-friendly portal they can open from any device.

---

## Features

- **Agency Dashboard** — Create projects, post rich-text updates (with file attachments), manage milestones, invite team members
- **Client Portal** — Branded public page with updates timeline, milestone tracker, progress bar, and comment box — accessible via magic link
- **Notifications** — Email client when update posted; email agency when client comments (via Resend)
- **Workspace Branding** — Agency name + logo displayed on client portal header

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter Web (FVM managed) |
| State management | Riverpod |
| Routing | GoRouter |
| Backend | Node.js + Express + TypeScript |
| Database / Auth / Storage | Supabase (PostgreSQL) |
| Email | Resend |
| Frontend hosting | Firebase Hosting |
| Backend hosting | Render |

---

## Project Structure

```
clientpulse/
├── client/                  # Flutter Web app
│   └── lib/
│       ├── features/        # auth, dashboard, projects, updates, milestones, portal, settings
│       ├── shared/          # widgets, models, services
│       └── core/            # router, theme, constants
├── server/                  # Node.js + Express backend
│   └── src/
│       ├── routes/
│       ├── services/
│       ├── middleware/      # auth.middleware.ts, portal.middleware.ts
│       ├── config/          # env.ts, supabase.ts
│       └── scripts/         # seed.ts
├── docs/
│   └── business-brief.md
└── supabase/
    └── migrations/
```

---

## Local Dev Setup

### Prerequisites

- Node.js 20+
- [FVM](https://fvm.app) (Flutter Version Manager)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- A Supabase project + Resend account (see [infrastructure setup](#infrastructure-setup))

### 1. Clone

```bash
git clone https://github.com/ketulmobilions-hub/clientpulse.git  # update URL if repo is renamed/private
cd clientpulse
```

### 2. Backend

```bash
cd server
cp .env.example .env
# Fill in all values in .env (see Environment Variables below)
npm install
npm run dev  # nodemon + ts-node, hot reloads on save
# API running at http://localhost:3000
```

### 3. Frontend

```bash
cd client
fvm flutter pub get
fvm dart run build_runner build -d  # generates freezed/injectable files
fvm flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=http://localhost:3000
# App running at http://localhost:5000
```

### 4. Seed demo data (optional)

Prerequisites: migrations must be applied (`supabase db push`) and the backend running.

```bash
cd server
npx ts-node src/scripts/seed.ts  # ts-node is a devDependency, npx resolves it
# Creates 4 sample projects with milestones, updates, and comments
# Login: demo@clientpulse.dev / DemoPass123!
```

> **Note:** The seed script will register the demo user via the API on first run. Re-running creates duplicate data — truncate the relevant tables in Supabase first for a clean slate.

---

## Environment Variables

All vars live in `server/.env` (copy from `server/.env.example`):

| Variable | Description |
|----------|-------------|
| `NODE_ENV` | `development` or `production` |
| `PORT` | Server port (default `3000`) |
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase publishable anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (server-side only) |
| `RESEND_API_KEY` | Resend API key |
| `RESEND_FROM_EMAIL` | Verified sender address (e.g. `ClientPulse <noreply@clientpulse.dev>`) |
| `JWT_SECRET` | ≥32 char secret for JWT signing |
| `COOKIE_SECRET` | ≥32 char secret for cookie signing |
| `APP_BASE_URL` | Backend base URL (used in email links) |
| `ALLOWED_ORIGINS` | Comma-separated allowed frontend origins |
| `FRONTEND_BASE_URL` | Frontend URL (used to construct portal links in emails) |

Generate secrets:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

---

## Infrastructure Setup

1. **Supabase** — Create project → link CLI → run migrations → copy keys
   ```bash
   supabase login
   supabase link --project-ref <your-project-ref>
   supabase db push
   ```
   Copy `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` from the Supabase dashboard → Project Settings → API.
2. **Resend** — Sign up at [resend.com](https://resend.com) → verify sender domain → copy `RESEND_API_KEY`
3. **Firebase** — Create project → enable Hosting → copy config into `client/lib/core/`
4. **Render** — Connect GitHub repo → set env vars → auto-deploy on push to `main`

---

## Deployment

### Frontend (Flutter Web → Firebase Hosting)

```bash
cd client
fvm flutter build web --release
firebase deploy --only hosting
```

CI/CD is configured via `.github/workflows/deploy-web.yml` — pushes to `main` auto-deploy.

Required GitHub secrets:

| Secret | Purpose |
|--------|---------|
| `FIREBASE_SERVICE_ACCOUNT` | Firebase deploy credentials (JSON) |
| `API_BASE_URL` | Passed to Flutter as `--dart-define=API_BASE_URL=...` — production Render backend URL |
| `APP_BASE_URL` | Backend's own base URL, used by the workflow for health-check or post-deploy steps |

### Backend (Node.js → Render)

Render auto-deploys from `main` on push. Set all environment variables in the Render dashboard.

Configure the Render service with:
- **Build command:** `npm install && npm run build`
- **Start command:** `npm start` (`node dist/index.js`)

---

## Running Tests

### Backend

```bash
cd server
npm test              # Jest — all unit + integration tests
npm run test:watch    # watch mode
```

### Frontend

```bash
cd client
fvm flutter test      # all widget + unit tests
```

---

## Auth Flows

**Agency (team login):**
Supabase email/password → JWT returned → Flutter stores in secure storage (falls back to `localStorage` on Flutter Web) → sent as `Authorization: Bearer <token>` on every API request.

**Client (magic link):**
Agency posts update → backend generates token → stored in `magic_links` table (24h expiry) → client receives email via Resend → clicks link → token verified → session persists via cookie or query param.

---

## License

MIT
