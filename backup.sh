#!/bin/bash
set -e

cd "$(dirname "$0")"
mkdir -p backups

FILE="backups/clouddesk_$(date +%Y%m%d_%H%M%S).sql"

docker compose exec -T db sh -c \
'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists' > "$FILE"

echo "Backup created: $FILE"
ls -lh "$FILE"
