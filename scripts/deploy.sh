#!/bin/bash

# XplainCrypto Platform Deployment Script
# This script deploys the MindsDB crypto platform to a DigitalOcean droplet

set -e

# Configuration
DROPLET_IP="142.93.49.20"
DROPLET_USER="root"
PROJECT_DIR="/opt/xplaincrypto"
BACKUP_DIR="/opt/backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 XplainCrypto Platform Deployment${NC}"
echo "================================================"

# Check required environment variables
required_vars=(
    "COINMARKETCAP_API_KEY"
    "DUNE_API_KEY" 
    "WHALE_ALERTS_API_KEY"
    "OPENAI_API_KEY"
    "POSTGRES_PASSWORD"
    "REDIS_PASSWORD"
)

echo -e "${YELLOW}Checking environment variables...${NC}"
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Error: $var is not set${NC}"
        echo "Please set all required environment variables:"
        printf '%s\n' "${required_vars[@]}"
        exit 1
    else
        echo -e "${GREEN}✅ $var is set${NC}"
    fi
done

# Create deployment package
echo -e "${YELLOW}📦 Creating deployment package...${NC}"
tar -czf xplaincrypto-deploy.tar.gz \
    --exclude='.git' \
    --exclude='*.tar.gz' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    .

# Transfer to droplet
echo -e "${YELLOW}📤 Transferring to droplet...${NC}"
scp xplaincrypto-deploy.tar.gz ${DROPLET_USER}@${DROPLET_IP}:/tmp/

# Deploy on droplet
echo -e "${YELLOW}🔧 Deploying on droplet...${NC}"
ssh ${DROPLET_USER}@${DROPLET_IP} << EOF
    set -e
    
    # Create backup if project exists
    if [ -d "${PROJECT_DIR}" ]; then
        echo "Creating backup..."
        mkdir -p ${BACKUP_DIR}
        tar -czf ${BACKUP_DIR}/xplaincrypto-backup-\$(date +%Y%m%d-%H%M%S).tar.gz -C ${PROJECT_DIR} .
    fi
    
    # Create project directory
    mkdir -p ${PROJECT_DIR}
    cd ${PROJECT_DIR}
    
    # Extract new deployment
    tar -xzf /tmp/xplaincrypto-deploy.tar.gz
    rm /tmp/xplaincrypto-deploy.tar.gz
    
    # Set environment variables
    cat > .env << EOL
COINMARKETCAP_API_KEY=${COINMARKETCAP_API_KEY}
DUNE_API_KEY=${DUNE_API_KEY}
WHALE_ALERTS_API_KEY=${WHALE_ALERTS_API_KEY}
OPENAI_API_KEY=${OPENAI_API_KEY}
POSTGRES_DB=mindsdb_crypto
POSTGRES_USER=mindsdb
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
MINDSDB_HOST=localhost
MINDSDB_PORT=47334
EOL
    
    # Make scripts executable
    chmod +x scripts/*.sh
    
    # Run setup
    echo "Running setup script..."
    ./scripts/setup.sh
    
    echo "Deployment completed successfully!"
EOF

# Cleanup
rm xplaincrypto-deploy.tar.gz

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. SSH to droplet: ssh ${DROPLET_USER}@${DROPLET_IP}"
echo "2. Check status: cd ${PROJECT_DIR} && docker-compose ps"
echo "3. View logs: docker-compose logs -f" 