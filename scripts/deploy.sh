#!/bin/bash

# MindsDB Crypto Docker Deployment Script
# This script automates the deployment of MindsDB with crypto handlers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN=${DOMAIN:-"142.93.49.20"}
EMAIL=${EMAIL:-"gerard161@gmail.com"}
ENVIRONMENT=${ENVIRONMENT:-"production"}

echo -e "${BLUE}🚀 Starting MindsDB Crypto Platform Deployment${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_status "Docker and Docker Compose are installed"
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    mkdir -p logs
    mkdir -p ssl
    mkdir -p certbot/conf
    mkdir -p certbot/www
    mkdir -p nginx/conf.d
    mkdir -p monitoring
    mkdir -p init-scripts
    
    print_status "Directories created successfully"
}

# Generate environment file
generate_env_file() {
    print_status "Generating environment file..."
    
    if [ ! -f .env ]; then
        cat > .env << EOF
# Database Configuration
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)

# MindsDB Configuration
MINDSDB_PASSWORD=$(openssl rand -base64 32)
MINDSDB_SECRET=$(openssl rand -base64 32)
MCP_ACCESS_TOKEN=$(openssl rand -base64 32)

# API Keys (Replace with your actual keys)
COINMARKETCAP_API_KEY=\${COINMARKETCAP_API_KEY}
DEFILLAMA_API_KEY=\${DEFILLAMA_API_KEY}
COINGECKO_API_KEY=\${COINGECKO_API_KEY}
BINANCE_API_KEY=\${BINANCE_API_KEY}
BINANCE_SECRET_KEY=\${BINANCE_SECRET_KEY}
ALPHA_VANTAGE_API_KEY=\${ALPHA_VANTAGE_API_KEY}
OPENAI_API_KEY=\${OPENAI_API_KEY}

# Monitoring
GRAFANA_PASSWORD=$(openssl rand -base64 32)

# Domain Configuration
DOMAIN=${DOMAIN}
EMAIL=${EMAIL}
EOF
        print_status "Environment file created. Please update API keys in .env file"
    else
        print_warning "Environment file already exists. Skipping generation."
    fi
}

# Setup SSL certificates
setup_ssl() {
    print_status "Setting up SSL certificates..."
    print_warning "Development mode: using self-signed certificate for IP $DOMAIN. SSL is not trusted by browsers. Use HTTP for development."
    # Generate self-signed certificate for testing
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/nginx.key \
        -out ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"
    print_status "Self-signed certificate generated for development."
}

# Setup monitoring configuration
setup_monitoring() {
    print_status "Setting up monitoring configuration..."
    
    # Prometheus configuration
    cat > monitoring/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'mindsdb'
    static_configs:
      - targets: ['mindsdb:47334']
    metrics_path: '/api/metrics'

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx:80']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
EOF

    # Grafana datasource configuration
    mkdir -p monitoring/grafana/datasources
    cat > monitoring/grafana/datasources/prometheus.yml << EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

    print_status "Monitoring configuration created"
}

# Setup database initialization scripts
setup_database() {
    print_status "Setting up database initialization..."
    
    cat > init-scripts/01-init.sql << EOF
-- Create MindsDB database and extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create tables for crypto data caching
CREATE TABLE IF NOT EXISTS crypto_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(20) NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    data JSONB NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_crypto_cache_symbol ON crypto_cache(symbol);
CREATE INDEX IF NOT EXISTS idx_crypto_cache_type ON crypto_cache(data_type);
CREATE INDEX IF NOT EXISTS idx_crypto_cache_timestamp ON crypto_cache(timestamp);

-- Create table for anomaly detection results
CREATE TABLE IF NOT EXISTS anomaly_detections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol VARCHAR(20) NOT NULL,
    anomaly_type VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    data JSONB NOT NULL,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_anomaly_symbol ON anomaly_detections(symbol);
CREATE INDEX IF NOT EXISTS idx_anomaly_type ON anomaly_detections(anomaly_type);
CREATE INDEX IF NOT EXISTS idx_anomaly_detected_at ON anomaly_detections(detected_at);
EOF

    print_status "Database initialization scripts created"
}

# Update nginx configuration with actual domain
update_nginx_config() {
    print_status "Updating nginx configuration with IP: $DOMAIN"
    sed -i "s/server_name .*/server_name $DOMAIN;/g" nginx/nginx.conf
}

# Build and start services
deploy_services() {
    print_status "Building and starting services..."
    
    # Build custom MindsDB image
    docker-compose build --no-cache
    
    # Start services
    docker-compose up -d
    
    print_status "Services started successfully"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    echo "Waiting for PostgreSQL..."
    until docker-compose exec postgres pg_isready -U mindsdb; do
        sleep 2
    done
    
    # Wait for Redis
    echo "Waiting for Redis..."
    until docker-compose exec redis redis-cli ping; do
        sleep 2
    done
    
    # Wait for MindsDB
    echo "Waiting for MindsDB..."
    until curl -f http://localhost:47334/api/status; do
        sleep 5
    done
    
    print_status "All services are ready"
}

# Setup MindsDB handlers
setup_handlers() {
    print_status "Setting up MindsDB crypto handlers..."
    
    # Wait a bit more for MindsDB to fully initialize
    sleep 10
    
    # Create crypto data handlers
    docker-compose exec mindsdb python -c "
import requests
import json

# MindsDB API endpoint
api_url = 'http://localhost:47334/api/sql/query'

# Create CoinMarketCap handler
cmc_query = '''
CREATE DATABASE coinmarketcap_db
WITH ENGINE = 'coinmarketcap',
PARAMETERS = {
    'api_key': '${COINMARKETCAP_API_KEY}'
};
'''

# Create DefiLlama handler
defillama_query = '''
CREATE DATABASE defillama_db
WITH ENGINE = 'defillama';
'''

queries = [cmc_query, defillama_query]

for query in queries:
    try:
        response = requests.post(api_url, json={'query': query})
        print(f'Query result: {response.status_code}')
    except Exception as e:
        print(f'Error executing query: {e}')
"
    
    print_status "MindsDB handlers setup completed"
}

# Display deployment information
show_deployment_info() {
    print_status "Deployment completed successfully! 🎉"
    echo ""
    echo -e "${BLUE}=== Deployment Information ===${NC}"
    echo -e "Domain: ${GREEN}$DOMAIN${NC}"
    echo -e "MindsDB HTTP API: ${GREEN}https://$DOMAIN/api/${NC}"
    echo -e "MindsDB MCP API: ${GREEN}https://$DOMAIN/mcp/${NC}"
    echo -e "Grafana Dashboard: ${GREEN}https://$DOMAIN/monitoring/${NC}"
    echo ""
    echo -e "${BLUE}=== Service Ports (localhost) ===${NC}"
    echo -e "MindsDB HTTP: ${GREEN}http://localhost:47334${NC}"
    echo -e "MindsDB MySQL: ${GREEN}localhost:47335${NC}"
    echo -e "MindsDB MongoDB: ${GREEN}localhost:47336${NC}"
    echo -e "MindsDB MCP: ${GREEN}http://localhost:47337${NC}"
    echo -e "Grafana: ${GREEN}http://localhost:3000${NC}"
    echo -e "Prometheus: ${GREEN}http://localhost:9090${NC}"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo -e "1. Update API keys in .env file"
    echo -e "2. Configure DNS to point to this server"
    echo -e "3. Check logs: ${GREEN}docker-compose logs -f${NC}"
    echo -e "4. Access credentials are in .env file"
}

# Main deployment function
main() {
    echo -e "${BLUE}MindsDB Crypto Platform Deployment${NC}"
    echo "=================================="
    check_docker
    create_directories
    generate_env_file
    setup_monitoring
    setup_database
    update_nginx_config
    setup_ssl
    deploy_services
    wait_for_services
    setup_handlers
    show_deployment_info
}

# Handle command line arguments
case "$1" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo "Options:"
        echo "  --skip-ssl    Skip SSL certificate setup"
        echo "  --help, -h    Show this help message"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
