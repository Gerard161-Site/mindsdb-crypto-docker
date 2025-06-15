#!/bin/bash
# XplainCrypto Handler Verification Script
# This script verifies that all custom handlers are properly installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verifying XplainCrypto Handlers${NC}"
echo "=================================================="

# Handler list
HANDLERS=(
    "coinmarketcap"
    "dune"
    "whale_alerts"
    "defillama"
    "blockchain"
)

# MindsDB API endpoint
MINDSDB_API="http://localhost:47334/api/sql/query"

# Function to execute SQL query
execute_sql() {
    local query="$1"
    curl -s -X POST "$MINDSDB_API" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$query\"}"
}

# Function to check if MindsDB is responding
check_mindsdb() {
    echo -e "${YELLOW}📡 Checking MindsDB connection...${NC}"
    
    if ! curl -s http://localhost:47334/api/status >/dev/null 2>&1; then
        echo -e "${RED}❌ MindsDB is not responding at http://localhost:47334${NC}"
        echo "   Make sure MindsDB is running with: docker-compose up -d"
        exit 1
    fi
    
    echo -e "${GREEN}✅ MindsDB is responding${NC}"
}

# Function to verify handler installation
verify_handler() {
    local handler="$1"
    echo -e "${YELLOW}🔧 Checking $handler handler...${NC}"
    
    # Check if handler is listed in SHOW HANDLERS
    response=$(execute_sql "SHOW HANDLERS WHERE name='$handler'")
    
    if echo "$response" | grep -q "\"$handler\""; then
        echo -e "${GREEN}   ✅ $handler handler is registered${NC}"
        return 0
    else
        echo -e "${RED}   ❌ $handler handler is not registered${NC}"
        echo "   Response: $response"
        return 1
    fi
}

# Function to test handler functionality
test_handler_functionality() {
    local handler="$1"
    echo -e "${YELLOW}🧪 Testing $handler functionality...${NC}"
    
    case $handler in
        "coinmarketcap")
            # Test CoinMarketCap handler
            response=$(execute_sql "SHOW TABLES FROM coinmarketcap_db" 2>/dev/null || echo "error")
            if echo "$response" | grep -q "cryptocurrency"; then
                echo -e "${GREEN}   ✅ CoinMarketCap tables accessible${NC}"
            else
                echo -e "${YELLOW}   ⚠️  CoinMarketCap database not configured or API key invalid${NC}"
            fi
            ;;
        "dune")
            # Test Dune handler
            response=$(execute_sql "SHOW TABLES FROM dune_db" 2>/dev/null || echo "error")
            if echo "$response" | grep -q -E "(queries|executions|results)"; then
                echo -e "${GREEN}   ✅ Dune tables accessible${NC}"
            else
                echo -e "${YELLOW}   ⚠️  Dune database not configured or API key invalid${NC}"
            fi
            ;;
        "whale_alerts")
            # Test Whale Alerts handler
            response=$(execute_sql "SHOW TABLES FROM whale_alerts_db" 2>/dev/null || echo "error")
            if echo "$response" | grep -q "transactions"; then
                echo -e "${GREEN}   ✅ Whale Alerts tables accessible${NC}"
            else
                echo -e "${YELLOW}   ⚠️  Whale Alerts database not configured or API key invalid${NC}"
            fi
            ;;
        "defillama")
            # Test DeFiLlama handler
            response=$(execute_sql "SHOW TABLES FROM defillama_db" 2>/dev/null || echo "error")
            if echo "$response" | grep -q -E "(protocols|tvl)"; then
                echo -e "${GREEN}   ✅ DeFiLlama tables accessible${NC}"
            else
                echo -e "${YELLOW}   ⚠️  DeFiLlama database not configured${NC}"
            fi
            ;;
        "blockchain")
            # Test Blockchain.com handler
            response=$(execute_sql "SHOW TABLES FROM blockchain_db" 2>/dev/null || echo "error")
            if echo "$response" | grep -q -E "(stats|blocks)"; then
                echo -e "${GREEN}   ✅ Blockchain.com tables accessible${NC}"
            else
                echo -e "${YELLOW}   ⚠️  Blockchain.com database not configured${NC}"
            fi
            ;;
    esac
}

# Main verification process
main() {
    check_mindsdb
    
    echo ""
    echo -e "${YELLOW}🔍 Verifying handler installations...${NC}"
    
    installed_handlers=0
    total_handlers=${#HANDLERS[@]}
    
    for handler in "${HANDLERS[@]}"; do
        if verify_handler "$handler"; then
            ((installed_handlers++))
            test_handler_functionality "$handler"
        fi
        echo ""
    done
    
    echo "=================================================="
    echo -e "${BLUE}📊 Verification Summary${NC}"
    echo "   Handlers installed: $installed_handlers/$total_handlers"
    
    if [ $installed_handlers -eq $total_handlers ]; then
        echo -e "${GREEN}✅ All handlers are properly installed!${NC}"
        
        echo ""
        echo -e "${BLUE}📋 Available Databases:${NC}"
        response=$(execute_sql "SHOW DATABASES")
        echo "$response" | grep -E "(coinmarketcap|dune|whale|defillama|blockchain)" || echo "   No handler databases found"
        
        echo ""
        echo -e "${BLUE}🎯 Next Steps:${NC}"
        echo "   1. Test database connections with: SHOW DATABASES;"
        echo "   2. Query handler data with: SELECT * FROM <database>.<table> LIMIT 5;"
        echo "   3. Create models and agents using the available data"
        
        exit 0
    else
        echo -e "${YELLOW}⚠️  Some handlers are missing or not working properly${NC}"
        echo ""
        echo -e "${BLUE}🔧 Troubleshooting:${NC}"
        echo "   1. Check Docker logs: docker-compose logs mindsdb"
        echo "   2. Verify API keys in .env file"
        echo "   3. Rebuild container: docker-compose build --no-cache"
        echo "   4. Check handler files in ../mindsdb-handlers/"
        
        exit 1
    fi
}

# Run main function
main 