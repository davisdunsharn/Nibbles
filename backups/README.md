# Database backups

Supabase's **free tier has no automatic backups**, so we manage our own. There are
three layers — use as many as you like.

## 1. Quick snapshot (no password, no Docker) — run anytime
```bash
./scripts/backup-data.sh
```
Exports every table to CSV under `backups/data-<timestamp>/`. Great for a fast safety
copy before a risky change. Re-import a table via the Supabase Table Editor → Import CSV,
or with `\copy` in psql.

## 2. Full restorable backup (recommended) — needs your DB password once
Use the **Session pooler** URI (the direct `db.<ref>.supabase.co` host is IPv6-only and
won't resolve on many networks). For this project it is:

```
postgresql://postgres.yxbqcafkifdtpjcqrlge:<YOUR-PASSWORD>@aws-1-eu-central-1.pooler.supabase.com:5432/postgres
```

(Dashboard → Project Settings → Database → Connection string → **Session pooler**.)

```bash
export SUPABASE_DB_URL='postgresql://postgres.<ref>:<password>@<host>:5432/postgres'
./scripts/backup-full.sh
```
Produces `backups/nibbles-full-<timestamp>.sql.gz` — a complete schema + data dump.

**Restore (into the same or a fresh project):**
```bash
gunzip -c backups/nibbles-full-<timestamp>.sql.gz | psql "$SUPABASE_DB_URL"
```

## 3. Automated daily backup (set & forget) — GitHub Actions
`.github/workflows/backup.yml` runs `pg_dump` every day at 01:00 UTC and stores the
dump as a downloadable artifact (90-day retention). One-time setup:

> GitHub repo → **Settings → Secrets and variables → Actions → New repository secret**
> `SUPABASE_DB_URL` = your connection string (same URI as above).

You can also trigger it manually from the repo's **Actions** tab → *Database backup* → *Run workflow*,
then download the artifact.

## Tips
- Keep at least one full backup **off your laptop** (the GitHub artifact covers this, or copy a `.sql.gz` to cloud storage).
- The schema itself is also versioned in `supabase/migrations/` and seed data in `supabase/seeds/`.
- For zero-effort, point-in-time recovery, upgrading the Supabase project to **Pro** adds automatic daily backups + PITR.
