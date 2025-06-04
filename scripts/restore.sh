
#!/bin/bash

# MindsDB Crypto Platform Restore Script

set -e

# Configuration
BACKUP_DIR="/opt/backups/mindsdb-crypto"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[RESTORE]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to list available backups
list_backups() {
    echo -e "${BLUE}Available backups:${NC}"
    ls -la "$BACKUP_DIR"/ | grep -E "\.(gz|rdb)$" | sort -r
}

# Function to restore from backup
restore_backup() {
    local timestamp=$1
    
    if [ -z "$timestamp" ]; then
        print_error "Please provide a timestamp for the backup to restore"
        echo "Usage: $0 <timestamp>"
        echo "Example: $0 20231201_143000"
        list_backups
        exit 1
    fi
    
    print_warning "This will restore the system to backup timestamp: $timestamp"
    print_warning "Current data will be replaced. Are you sure? (y/N)"
    read -r confirmation
    
    if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
        print_status "Restore cancelled"
        exit 0
    fi
    
    # Stop services
    print_status "Stopping services..."
    docker-compose down
    
    # Restore PostgreSQL
    if [ -f "$BACKUP_DIR/postgres_$timestamp.sql.gz" ]; then
        print_status "Restoring PostgreSQL database..."
        docker-compose up -d postgres
        sleep 10
        
        # Drop and recreate database
        docker-compose exec postgres psql -U mindsdb -c "DROP DATABASE IF EXISTS mindsdb;"
        docker-compose exec postgres psql -U mindsdb -c "CREATE DATABASE mindsdb;"
        
        # Restore data
        gunzip -c "$BACKUP_DIR/postgres_$timestamp.sql.gz" | docker-compose exec -T postgres psql -U mindsdb mindsdb
        
        docker-compose stop postgres
        print_status "PostgreSQL restore completed"
    else
        print_warning "PostgreSQL backup not found for timestamp: $timestamp"
    fi
    
    # Restore Redis
    if [ -f "$BACKUP_DIR/redis_$timestamp.rdb" ]; then
        print_status "Restoring Redis data..."
        
        # Remove existing Redis data
        docker volume rm mindsdb-crypto-docker_redis_data 2>/dev/null || true
        
        # Start Redis and copy backup
        docker-compose up -d redis
        sleep 5
        docker-compose stop redis
        
        # Copy backup file
        docker cp "$BACKUP_DIR/redis_$timestamp.rdb" $(docker-compose ps -q redis):/data/dump.rdb
        
        print_status "Redis restore completed"
    else
        print_warning "Redis backup not found for timestamp: $timestamp"
    fi
    
    # Restore MindsDB data
    if [ -f "$BACKUP_DIR/mindsdb_data_$timestamp.tar.gz" ]; then
        print_status "Restoring MindsDB data..."
        
        # Remove existing MindsDB data
        docker volume rm mindsdb-crypto-docker_mindsdb_data 2>/dev/null || true
        
        # Start MindsDB temporarily to create volume
        docker-compose up -d mindsdb
        sleep 10
        docker-compose stop mindsdb
        
        # Restore data
        gunzip -c "$BACKUP_DIR/mindsdb_data_$timestamp.tar.gz" | docker-compose exec -T mindsdb tar -xzf - -C /
        
        print_status "MindsDB data restore completed"
    else
        print_warning "MindsDB data backup not found for timestamp: $timestamp"
    fi
    
    # Restore configuration
    if [ -f "$BACKUP_DIR/config_$timestamp.tar.gz" ]; then
        print_status "Restoring configuration files..."
        tar -xzf "$BACKUP_DIR/config_$timestamp.tar.gz"
        print_status "Configuration restore completed"
    else
        print_warning "Configuration backup not found for timestamp: $timestamp"
    fi
    
    # Restore SSL certificates
    if [ -f "$BACKUP_DIR/ssl_$timestamp.tar.gz" ]; then
        print_status "Restoring SSL certificates..."
        tar -xzf "$BACKUP_DIR/ssl_$timestamp.tar.gz"
        print_status "SSL certificates restore completed"
    else
        print_warning "SSL backup not found for timestamp: $timestamp"
    fi
    
    # Start all services
    print_status "Starting all services..."
    docker-compose up -d
    
    print_status "Restore completed successfully!"
    print_status "Please verify that all services are running correctly"
}

# Main function
main() {
    if [ $# -eq 0 ]; then
        list_backups
        echo ""
        echo "Usage: $0 <timestamp>"
        echo "Example: $0 20231201_143000"
        exit 1
    fi
    
    restore_backup "$1"
}

main "$@"
