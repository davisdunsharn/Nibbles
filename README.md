# Nibbles Bakery — Management System

A multi-branch bakery management platform: point-of-sale, inventory, purchasing,
staff scheduling, IoT/operations monitoring and AI-assisted reporting. Built as a
single-page application with role-based access for **Admin**, **Branch Manager**
and **Cashier**.

## Tech stack

| Layer | Technology |
|-------|-----------|
| Frontend | Vue 3 (`<script setup>`), Vue Router, Pinia, Tailwind CSS, Vite |
| Backend | Supabase — Postgres, Auth, Row-Level Security, Edge Functions (Deno) |
| AI | Groq (`llama-3.3-70b-versatile`) via a server-side Edge Function |
| Charts | Chart.js (`ChartCanvas.vue`) — native analytics, no external BI tool |
| Icons / type | Inline SVG (`AppIcon.vue`), Syne (display) + Inter (UI) |

## Roles & features

- **Admin** — dashboard, users, branches, products, suppliers, IoT/operations hub
  (live RFID scan events + a one-click simulation, deliveries, alerts), AI Sales
  Insights (charts + 7-day forecast + Groq analysis, CSV export), and an audit log.
- **Branch Manager** (scoped to one branch) — branch dashboard, inventory CRUD,
  purchase orders (create → send → confirm → receive, which restocks inventory),
  weekly shift schedule with clock-in/out, and a sales report.
- **Cashier** — point-of-sale: product grid, cart, VAT (15%), cash/card/split
  payment, receipt printing; sales deduct branch inventory; self clock-in/out for the day.

## Getting started

```bash
npm install
cp .env.example .env.local   # then fill in the values below
npm run dev                  # http://localhost:5173
npm run build                # production build
```

### Environment (`.env.local`)

```
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon-key>
```

> The Groq API key is **not** a frontend variable — it lives as a Supabase
> Edge Function secret (see below) so it never ships to the browser.

## Database

The live schema is managed in Supabase. SQL lives in:

- `supabase/migrations/` — schema & policy changes
  (`add_tax_amount.sql`, `inventory_rpcs.sql`, `manager_crud_policies.sql`, …)
- `supabase/seeds/` — demo/seed data
  (`business_demo.sql` — products, customers, inventory, ~4 weeks of sales,
  standard weekly shifts; `iot_demo.sql` — IoT events, deliveries, notifications)

Apply against the linked project (no DB password needed — uses the Management API):

```bash
supabase db query --linked -f supabase/migrations/inventory_rpcs.sql
supabase db query --linked -f supabase/seeds/business_demo.sql
```

Key RPCs: `get_branch_inventory`, `restock_inventory`, `deduct_inventory`.
Security is enforced with **Row-Level Security** throughout — branch staff only
see/modify their own branch; admins see everything. Helper functions
`current_role_name()` / `current_branch_id()` (SECURITY DEFINER) drive policies.

## Edge Functions (`supabase/functions/`)

| Function | Purpose | Secrets |
|----------|---------|---------|
| `create-user` | Admin-only user provisioning (service role) | `SUPABASE_SERVICE_ROLE_KEY` |
| `delete-user` | Admin-only user removal (deletes auth account → cascades profile) | `SUPABASE_SERVICE_ROLE_KEY` |
| `groq-insights` | Server-side Groq call for AI reports | `GROQ_API_KEY` |

```bash
supabase functions deploy groq-insights
supabase secrets set GROQ_API_KEY=gsk_...
```

## Authentication

Email/password via Supabase Auth (invitation-only — admins create accounts).
Includes a press-and-hold password reveal, a "Forgot password?" flow and a
`/reset-password` page. To reset a user's password, use the Supabase dashboard
(Authentication → Users) or the in-app reset link.

## Deploying (Vercel or Netlify)

This is a static SPA — both hosts work out of the box (config files included:
`vercel.json`, `netlify.toml`, `public/_redirects`).

**Vercel**
1. Push to GitHub → "Import Project" in Vercel (framework preset auto-detects **Vite**).
2. Add Environment Variables (Production): `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`.
3. Deploy.

**Netlify**
1. "Add new site → Import from Git" (build `npm run build`, publish `dist` — already in `netlify.toml`).
2. Add the same two Environment Variables.
3. Deploy.

Both include an SPA fallback so deep links (e.g. `/admin/reports`) and refreshes resolve.

### ⚠️ Required after deploying — fixes login from other devices

In **Supabase → Authentication → URL Configuration**:
- Set **Site URL** to your deployed domain (e.g. `https://nibbles-bakery.vercel.app`).
- Add that domain and `https://<your-domain>/reset-password` to **Redirect URLs**.

Also confirm the two `VITE_…` environment variables are set in the host — if they're
missing, the app can't reach Supabase and login will fail. (The app now logs a clear
console error and falls back to the login screen instead of showing a blank page.)

## Project structure

```
src/
  components/   AppIcon.vue, PasswordInput.vue
  layouts/      Admin / Manager / Cashier shells
  views/        admin/ · manager/ · cashier/ · auth/
  stores/       auth.js (Pinia)
  lib/          supabase.js, errorHandler.js
  router/       index.js (role-guarded routes)
supabase/
  migrations/ · seeds/ · functions/
```
