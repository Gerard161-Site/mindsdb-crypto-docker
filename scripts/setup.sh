#!/bin/bash
# XplainCrypto Platform Master Setup Script
# This script sets up the entire platform with one command

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 XplainCrypto Platform Setup${NC}"
echo "=================================================="

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

command -v docker >/dev/null 2>&1 || { 
    echo -e "${RED}❌ Docker is required but not installed. Please install Docker first.${NC}" >&2
    exit 1
}

command -v docker-compose >/dev/null 2>&1 || { 
    echo -e "${RED}❌ Docker Compose is required but not installed. Please install Docker Compose first.${NC}" >&2
    exit 1
}

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Environment setup
echo -e "${YELLOW}🔧 Setting up environment...${NC}"

if [[ ! -f .env ]]; then
    if [[ -f .env.example ]]; then
        echo -e "${YELLOW}📝 Creating .env from template...${NC}"
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Please edit .env file with your API keys before continuing${NC}"
        echo -e "${BLUE}📋 Required API keys:${NC}"
        echo "   - COINMARKETCAP_API_KEY"
        echo "   - DUNE_API_KEY"
        echo "   - WHALE_ALERTS_API_KEY"
        echo "   - DEFILLAMA_API_KEY"
        echo "   - BLOCKCHAIN_API_KEY"
        echo "   - POSTGRES_PASSWORD"
        echo "   - REDIS_PASSWORD"
        echo ""
        echo -e "${YELLOW}Run this script again after editing .env${NC}"
        exit 1
    else
        echo -e "${RED}❌ .env.example file not found. Please create environment configuration.${NC}"
        exit 1
    fi
fi

# Load environment variables
echo -e "${YELLOW}📖 Loading environment variables...${NC}"
source .env

# Validate required API keys
echo -e "${YELLOW}🔍 Validating API keys...${NC}"
required_keys=("COINMARKETCAP_API_KEY" "DUNE_API_KEY" "WHALE_ALERTS_API_KEY" "DEFILLAMA_API_KEY" "BLOCKCHAIN_API_KEY" "POSTGRES_PASSWORD" "REDIS_PASSWORD")
missing_keys=()

for key in "${required_keys[@]}"; do
    if [[ -z "${!key}" || "${!key}" == *"your_"* || "${!key}" == *"_here"* || "${!key}" == *"change_me"* ]]; then
        missing_keys+=("$key")
    fi
done

if [ ${#missing_keys[@]} -ne 0 ]; then
    echo -e "${RED}❌ Missing or invalid environment variables:${NC}"
    for key in "${missing_keys[@]}"; do
        echo "   - $key"
    done
    echo -e "${YELLOW}Please update your .env file with valid values${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Environment validation passed${NC}"

# Create necessary directories
echo -e "${YELLOW}📁 Creating directories...${NC}"
mkdir -p logs config

# Build and start services
echo -e "${YELLOW}🔨 Building XplainCrypto platform...${NC}"
echo "This may take several minutes on first run..."

if ! docker-compose build; then
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build completed successfully${NC}"

echo -e "${YELLOW}🚀 Starting services...${NC}"
if ! docker-compose up -d; then
    echo -e "${RED}❌ Failed to start services${NC}"
    exit 1
fi

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"

# Wait for PostgreSQL
echo "   Waiting for PostgreSQL..."
timeout=60
while ! docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; do
    if [ $timeout -le 0 ]; then
        echo -e "${RED}❌ Timeout waiting for PostgreSQL${NC}"
        exit 1
    fi
    sleep 2
    timeout=$((timeout-2))
done
echo -e "${GREEN}   ✅ PostgreSQL ready${NC}"

# Wait for Redis
echo "   Waiting for Redis..."
timeout=60
while ! docker-compose exec -T redis redis-cli --no-auth-warning -a "$REDIS_PASSWORD" ping >/dev/null 2>&1; do
    if [ $timeout -le 0 ]; then
        echo -e "${RED}❌ Timeout waiting for Redis${NC}"
        exit 1
    fi
    sleep 2
    timeout=$((timeout-2))
done
echo -e "${GREEN}   ✅ Redis ready${NC}"

# Wait for MindsDB
echo "   Waiting for MindsDB..."
timeout=300
while ! curl -s http://localhost:47334/api/status >/dev/null 2>&1; do
    if [ $timeout -le 0 ]; then
        echo -e "${RED}❌ Timeout waiting for MindsDB${NC}"
        echo "Check logs with: docker-compose logs mindsdb"
        exit 1
    fi
    sleep 5
    timeout=$((timeout-5))
done
echo -e "${GREEN}   ✅ MindsDB ready${NC}"

# Verify handlers
echo -e "${YELLOW}🔍 Verifying handlers...${NC}"
if [[ -f scripts/verify-handlers.sh ]]; then
    chmod +x scripts/verify-handlers.sh
    ./scripts/verify-handlers.sh
else
    echo -e "${YELLOW}⚠️  Handler verification script not found, skipping...${NC}"
fi

# Setup databases
echo -e "${YELLOW}🗄️ Setting up database connections...${NC}"
for sql_file in sql/01-databases/*.sql; do
    if [ -f "$sql_file" ]; then
        echo "   Executing $(basename "$sql_file")..."
        
        # Replace environment variables in SQL file
        sql_content=$(envsubst < "$sql_file")
        
        # Execute SQL via MindsDB API
        response=$(curl -s -X POST http://localhost:47334/api/sql/query \
            -H "Content-Type: application/json" \
            -d "{\"query\": \"$sql_content\"}")
        
        # Check if there was an error
        if echo "$response" | grep -q '"error"'; then
            echo -e "${YELLOW}   ⚠️  Warning: $(basename "$sql_file") may have failed${NC}"
            echo "   Response: $response"
        else
            echo -e "${GREEN}   ✅ $(basename "$sql_file") executed successfully${NC}"
        fi
    fi
done

# Final status check
echo -e "${YELLOW}🏁 Final status check...${NC}"
echo ""
echo -e "${GREEN}✅ XplainCrypto Platform Setup Complete!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}🌐 Access Points:${NC}"
echo "   MindsDB UI:    http://localhost:47334"
echo "   PostgreSQL:    localhost:5432 (user: postgres)"
echo "   Redis:         localhost:6379"
echo ""
echo -e "${BLUE}📋 Useful Commands:${NC}"
echo "   View logs:     docker-compose logs -f"
echo "   Stop services: docker-compose down"
echo "   Restart:       docker-compose restart"
echo ""
echo -e "${BLUE}📚 Next Steps:${NC}"
echo "   1. Open MindsDB UI at http://localhost:47334"
echo "   2. Check available databases with: SHOW DATABASES;"
echo "   3. Explore handler documentation in docs/"
echo ""
echo -e "${GREEN}🎉 Happy analyzing!${NC}" 