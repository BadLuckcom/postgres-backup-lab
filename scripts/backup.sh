#!/usr/bin/env bash

set -Eeuo pipefail

# ==========================================
# PostgreSQL Automated Backup Script
# ==========================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Load environment variables
set -a
source "$PROJECT_DIR/.env"
set +a

BACKUP_DIR="$PROJECT_DIR/backups"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/backup.log"

RETENTION_DAYS=7
EXPECTED_EMPLOYEES=100

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"

BACKUP_NAME="${POSTGRES_DB}_${TIMESTAMP}.dump"
TEMP_BACKUP="$BACKUP_DIR/.${BACKUP_NAME}.tmp"
FINAL_BACKUP="$BACKUP_DIR/$BACKUP_NAME"

TEST_DB="${POSTGRES_DB}_restore_test"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# ==========================================
# Logging
# ==========================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# ==========================================
# Docker Compose helper
# ==========================================

dc() {
    docker compose \
        --env-file "$PROJECT_DIR/.env" \
        -f "$PROJECT_DIR/compose.yaml" \
        "$@"
}

# ==========================================
# Prevent simultaneous backup executions
# ==========================================

exec 9>"$PROJECT_DIR/backup.lock"

if ! flock -n 9; then
    log "Another backup process is running. Exiting."
    exit 0
fi

# ==========================================
# Cleanup
# ==========================================

cleanup() {
    EXIT_CODE=$?

    if [ "$EXIT_CODE" -ne 0 ]; then
        log "ERROR: Backup process failed. Exit code: $EXIT_CODE"
    fi

    dc exec -T db dropdb \
        -U "$POSTGRES_USER" \
        --if-exists "$TEST_DB" >/dev/null 2>&1 || true

    rm -f "$TEMP_BACKUP"
}

trap cleanup EXIT

# ==========================================
# 1. Check PostgreSQL availability
# ==========================================

log "Starting PostgreSQL backup..."

if ! dc exec -T db pg_isready \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" >/dev/null; then

    log "ERROR: PostgreSQL is not available."
    exit 1
fi

log "PostgreSQL connection: OK"

# ==========================================
# 2. Create database backup
# ==========================================

log "Creating backup: $BACKUP_NAME"

dc exec -T db pg_dump \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -Fc > "$TEMP_BACKUP"

if [ ! -s "$TEMP_BACKUP" ]; then
    log "ERROR: Backup file is empty."
    exit 1
fi

log "Backup created successfully."
log "Backup size: $(du -h "$TEMP_BACKUP" | cut -f1)"

# ==========================================
# 3. Check backup archive
# ==========================================

log "Validating backup archive..."

dc exec -T db pg_restore \
    --list "/backups/$(basename "$TEMP_BACKUP")" >/dev/null

log "Backup archive validation: OK"

# ==========================================
# 4. Restore backup into temporary database
# ==========================================

log "Testing backup restoration..."

dc exec -T db dropdb \
    -U "$POSTGRES_USER" \
    --if-exists "$TEST_DB"

dc exec -T db createdb \
    -U "$POSTGRES_USER" \
    "$TEST_DB"

dc exec -T db pg_restore \
    --exit-on-error \
    --no-owner \
    --no-privileges \
    -U "$POSTGRES_USER" \
    -d "$TEST_DB" \
    "/backups/$(basename "$TEMP_BACKUP")"

log "Restore operation: OK"

# ==========================================
# 5. Verify restored data
# ==========================================

RESTORED_COUNT="$(
    dc exec -T db psql \
        -U "$POSTGRES_USER" \
        -d "$TEST_DB" \
        -Atqc "SELECT COUNT(*) FROM employees;"
)"

RESTORED_COUNT="$(echo "$RESTORED_COUNT" | tr -d '[:space:]')"

if [ "$RESTORED_COUNT" -ne "$EXPECTED_EMPLOYEES" ]; then
    log "ERROR: Expected $EXPECTED_EMPLOYEES employees, got $RESTORED_COUNT."
    exit 1
fi

log "Data verification: OK"
log "Restored employees: $RESTORED_COUNT"

# ==========================================
# 6. Publish final backup file
# ==========================================

mv "$TEMP_BACKUP" "$FINAL_BACKUP"

log "Final backup saved: $FINAL_BACKUP"

# ==========================================
# 7. Delete old backups
# ==========================================

find "$BACKUP_DIR" \
    -maxdepth 1 \
    -type f \
    -name "${POSTGRES_DB}_*.dump" \
    -mtime +"$RETENTION_DAYS" \
    -print -delete >> "$LOG_FILE"

log "Old backup cleanup completed."
log "BACKUP SUCCESSFUL."
