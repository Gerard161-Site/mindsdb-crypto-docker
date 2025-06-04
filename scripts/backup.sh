
#!/bin/bash

# MindsDB Crypto Platform Backup Script

set -e

# Configuration
BACKUP_DIR="/opt/backups/mindsdb-crypto"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[BACKUP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

print_status "Starting backup process..."

# Backup PostgreSQL database
print_status "Backing up PostgreSQL database..."
docker-compose exec -T postgres pg_dump -U mindsdb mindsdb | gzip > "$BACKUP_DIR/postgres_$TIMESTAMP.sql.gz"

# Backup Redis data
print_status "Backing up Redis data..."
docker-compose exec -T redis redis-cli BGSAVE
sleep 5
docker cp $(docker-compose ps -q redis):/data/dump.rdb "$BACKUP_DIR/redis_$TIMESTAMP.rdb"

# Backup MindsDB data
print_status "Backing up MindsDB data..."
docker-compose exec -T mindsdb tar -czf - /opt/mindsdb > "$BACKUP_DIR/mindsdb_data_$TIMESTAMP.tar.gz"

# Backup configuration files
print_status "Backing up configuration files..."
tar -czf "$BACKUP_DIR/config_$TIMESTAMP.tar.gz" \
    .env \
    docker-compose.yml \
    nginx/ \
    config/ \
    monitoring/ \
    --exclude=nginx/logs \
    --exclude=monitoring/data

# Backup SSL certificates
if [ -d "certbot/conf" ]; then
    print_status "Backing up SSL certificates..."
    tar -czf "$BACKUP_DIR/ssl_$TIMESTAMP.tar.gz" certbot/conf ssl/
fi

# Clean old backups
print_status "Cleaning old backups (older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.rdb" -mtime +$RETENTION_DAYS -delete

print_status "Backup completed successfully!"
print_status "Backup location: $BACKUP_DIR"
ls -la "$BACKUP_DIR"/*$TIMESTAMP*
