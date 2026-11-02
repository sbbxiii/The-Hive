#!/usr/bin/env bash
# ==============================================================================
# The Hive — Automated MariaDB / PostgreSQL Backup Routine with Retention
# ==============================================================================

set -euo pipefail

BACKUP_DIR="/var/backups/hive_databases"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RETENTION_DAYS=14

mkdir -p "$BACKUP_DIR"

echo "===> Backing up MariaDB 'homelab' database..."
docker exec hive-mariadb mariadb-dump -u root -p"${MYSQL_ROOT_PASSWORD:-hive_secure_root_password}" homelab \
    | gzip > "${BACKUP_DIR}/homelab_db_${TIMESTAMP}.sql.gz"

echo "===> Backing up PostgreSQL 'n8n' database..."
if docker ps --format '{{.Names}}' | grep -q "postgres"; then
    docker exec hive-postgres pg_dump -U n8n n8n \
        | gzip > "${BACKUP_DIR}/n8n_db_${TIMESTAMP}.sql.gz"
fi

echo "===> Pruning backups older than ${RETENTION_DAYS} days..."
find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +"$RETENTION_DAYS" -exec rm -f {} \;

echo "===> Backup completed: ${BACKUP_DIR}/homelab_db_${TIMESTAMP}.sql.gz"
ls -lh "$BACKUP_DIR"
