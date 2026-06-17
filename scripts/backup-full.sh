#!/usr/bin/env bash
# Full, restorable backup (schema + data) via pg_dump → compressed .sql.gz.
# This is the gold-standard backup you can restore from completely.
#
# One-time setup — get your connection string from:
#   Supabase Dashboard → Project Settings → Database → Connection string → URI
#   (use the "Session pooler" or "Direct connection" URI; include your DB password)
#
# Usage:
#   export SUPABASE_DB_URL='postgresql://postgres.<ref>:<password>@<host>:5432/postgres'
#   ./scripts/backup-full.sh
set -euo pipefail
cd "$(dirname "$0")/.."

: "${SUPABASE_DB_URL:?Set SUPABASE_DB_URL (see comments at the top of this script)}"

TS=$(date +%Y%m%d-%H%M)
OUT="backups/nibbles-full-$TS.sql"
mkdir -p backups

echo "Dumping full database → $OUT.gz"
pg_dump "$SUPABASE_DB_URL" \
  --no-owner --no-privileges --clean --if-exists \
  --schema=public \
  -f "$OUT"
gzip -f "$OUT"
echo "Done: $OUT.gz"
echo
echo "Restore with:"
echo "  gunzip -c $OUT.gz | psql \"\$SUPABASE_DB_URL\""
