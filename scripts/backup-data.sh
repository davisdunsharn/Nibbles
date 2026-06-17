#!/usr/bin/env bash
# Quick data backup — exports every public table to timestamped CSV files.
# Works with NO Docker and NO database password (uses the Supabase Management API
# via the linked CLI). Good for a fast safety snapshot you can re-import later.
#
# Usage:  ./scripts/backup-data.sh
set -euo pipefail
cd "$(dirname "$0")/.."

TS=$(date +%Y%m%d-%H%M)
OUT="backups/data-$TS"
mkdir -p "$OUT"

echo "Backing up Nibbles database → $OUT"

TABLES=$(supabase db query --linked -o json \
  "select table_name from information_schema.tables where table_schema='public' and table_type='BASE TABLE' order by table_name" 2>/dev/null \
  | python3 -c "import sys,json;s=sys.stdin.read();print('\n'.join(r['table_name'] for r in json.loads(s[s.index('{'):])['rows']))")

for t in $TABLES; do
  supabase db query --linked -o csv "select * from \"$t\"" 2>/dev/null \
    | grep -v '^Initialising login role' > "$OUT/$t.csv" || true
  rows=$(( $(wc -l < "$OUT/$t.csv") - 1 ))
  printf '  %-22s %s rows\n' "$t" "$rows"
done

echo "Done. Snapshot: $OUT"
