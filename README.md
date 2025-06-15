# XplainCrypto Platform - MindsDB Crypto Docker

> Comprehensive crypto analytics platform powered by MindsDB with 5 custom data handlers

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://docker.com)
[![MindsDB](https://img.shields.io/badge/MindsDB-25.5.4.2-green?logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTEyIDJMMjIgN1YxN0MyMiAyMC4zMTM3IDE5LjMxMzcgMjMgMTYgMjNIOEMzLjU4NTc5IDIzIDAgMTkuNDE0MiAwIDE1VjlMMTIgMloiIGZpbGw9IiMwMDY2Q0MiLz4KPC9zdmc+)](https://mindsdb.com)
[![Crypto](https://img.shields.io/badge/Handlers-5-orange)](#handlers)

## 🚀 Quick Start

Get the entire XplainCrypto platform running in under 10 minutes:

```bash
# 1. Clone the repository
git clone <repository-url>
cd mindsdb-crypto-docker

# 2. Set up environment
cp .env.example .env
# Edit .env with your API keys

# 3. Start the platform
./scripts/setup.sh
```

**That's it!** 🎉 Access your platform at http://localhost:47334

## 📊 Platform Overview

XplainCrypto Platform provides:

- **5 Crypto Data Sources**: Real-time market data, DeFi analytics, whale tracking
- **AI-Powered Analysis**: Predictive models and intelligent agents  
- **Automated Setup**: One-command deployment with full automation
- **Production Ready**: Docker Compose with PostgreSQL, Redis, and monitoring
- **Scalable Architecture**: Easy to add new handlers and data sources

## 🔧 Handlers

| Handler | Description | Data Sources |
|---------|-------------|--------------|
| **CoinMarketCap** | Cryptocurrency market data | Prices, market cap, volume, rankings |
| **Dune Analytics** | Blockchain analytics | On-chain data, DeFi metrics, custom queries |
| **Whale Alerts** | Large transaction monitoring | Whale movements, exchange flows |
| **DeFiLlama** | DeFi protocol analytics | TVL, yields, protocol data |
| **Blockchain.com** | Bitcoin blockchain data | Blocks, transactions, network stats |

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MindsDB UI    │    │  PostgreSQL DB  │    │   Redis Cache   │
│  localhost:47334│    │  localhost:5432 │    │  localhost:6379 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   MindsDB Core  │
                    │   + 5 Handlers  │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ CoinMarketCap   │    │ Dune Analytics  │    │ Whale Alerts    │
│ DeFiLlama       │    │ Blockchain.com  │    │ External APIs   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

- **Docker** & **Docker Compose**
- **8GB RAM** minimum (16GB recommended)
- **API Keys** for data sources (see [API Keys](#api-keys))

## 🔑 API Keys

You'll need API keys from these providers:

| Provider | Required | Get API Key | Free Tier |
|----------|----------|-------------|-----------|
| [CoinMarketCap](https://coinmarketcap.com/api/) | ✅ Yes | [Get Key](https://pro.coinmarketcap.com/signup) | 333 calls/day |
| [Dune Analytics](https://dune.com/settings/api) | ✅ Yes | [Get Key](https://dune.com/settings/api) | Limited queries |
| [Whale Alerts](https://whale-alert.io/api) | ✅ Yes | [Get Key](https://whale-alert.io/api) | 100 calls/hour |

**Note:** DeFiLlama and Blockchain.com use public API endpoints and don't require API keys.

## 🛠️ Installation

### Method 1: Automated Setup (Recommended)

```bash
# Clone repository
git clone <repository-url>
cd mindsdb-crypto-docker

# Run setup script
./scripts/setup.sh
```

The script will:
1. ✅ Check prerequisites
2. ✅ Create environment file
3. ✅ Validate API keys
4. ✅ Build Docker images
5. ✅ Start all services
6. ✅ Install all 5 handlers
7. ✅ Set up database connections
8. ✅ Verify everything works

### Method 2: Manual Setup

```bash
# 1. Environment setup
cp .env.example .env
# Edit .env with your API keys

# 2. Build and start
docker-compose build
docker-compose up -d

# 3. Verify installation
./scripts/verify-handlers.sh
```

## 🔧 Configuration

### Environment Variables

Edit `.env` file with your configuration:

```bash
# Required API Keys (only these 3 are needed)
COINMARKETCAP_API_KEY=your_cmc_api_key_here
DUNE_API_KEY=your_dune_api_key_here
WHALE_ALERTS_API_KEY=your_whale_alerts_api_key_here

# Database Configuration
POSTGRES_PASSWORD=secure_postgres_password
REDIS_PASSWORD=secure_redis_password

# MindsDB Settings
MINDSDB_LOG_LEVEL=INFO
MINDSDB_DEFAULT_PROJECT=xplaincrypto
```

### Docker Compose Services

| Service | Port | Description |
|---------|------|-------------|
| **mindsdb** | 47334, 47335 | MindsDB with crypto handlers |
| **postgres** | 5432 | PostgreSQL database |
| **redis** | 6379 | Redis cache |

## 📊 Usage Examples

### Basic Queries

```sql
-- Show all available databases
SHOW DATABASES;

-- Get top 10 cryptocurrencies
SELECT * FROM coinmarketcap_db.cryptocurrency_listings_latest 
ORDER BY market_cap DESC LIMIT 10;

-- Get recent whale transactions
SELECT * FROM whale_alerts_db.transactions 
WHERE amount_usd > 1000000 
ORDER BY timestamp DESC LIMIT 5;

-- Get DeFi protocol TVL
SELECT * FROM defillama_db.protocols 
ORDER BY tvl DESC LIMIT 10;
```

### Creating Models

```sql
-- Create price prediction model
CREATE MODEL crypto_price_predictor
FROM coinmarketcap_db.cryptocurrency_quotes_latest
PREDICT price_change_24h
USING engine = 'lightgbm';

-- Create market sentiment model
CREATE MODEL market_sentiment
FROM whale_alerts_db.transactions
PREDICT market_impact
USING engine = 'neural';
```

### AI Agents

```sql
-- Create crypto analyst agent
CREATE AGENT crypto_analyst
USING
    model = 'crypto_price_predictor',
    skills = ['analysis', 'prediction', 'reporting'];

-- Deploy market monitor agent
CREATE AGENT market_monitor
USING
    model = 'market_sentiment',
    skills = ['monitoring', 'alerts', 'notifications'];
```

## 🔍 Verification & Testing

### Verify Installation

```bash
# Check all handlers are working
./scripts/verify-handlers.sh

# Check service status
docker-compose ps

# View logs
docker-compose logs -f mindsdb
```

### Test Handlers

```bash
# Test individual handler
curl -X POST http://localhost:47334/api/sql/query \
  -H "Content-Type: application/json" \
  -d '{"query": "SHOW HANDLERS WHERE name='\''coinmarketcap'\''"}'

# Test database connection
curl -X POST http://localhost:47334/api/sql/query \
  -H "Content-Type: application/json" \
  -d '{"query": "SHOW TABLES FROM coinmarketcap_db"}'
```

## 📁 Project Structure

```
mindsdb-crypto-docker/
├── README.md                    # This file
├── .env.example                 # Environment template
├── docker-compose.yml           # Production configuration
├── docker-compose.override.yml  # Development overrides
├── Dockerfile                   # Multi-handler MindsDB image
│
├── scripts/                     # Automation scripts
│   ├── setup.sh                # Master setup script
│   ├── verify-handlers.sh      # Handler verification
│   ├── install-handlers.sh     # Handler installation
│   ├── deploy.sh               # Deployment script
│   ├── backup.sh               # Backup script
│   └── restore.sh              # Restore script
│
├── sql/                        # SQL automation
│   ├── 01-databases/           # Database connections
│   ├── 02-models/              # Model creation
│   ├── 03-agents/              # Agent deployment
│   └── 04-dashboards/          # Dashboard setup
│
├── config/                     # Configuration files
├── docs/                       # Documentation
├── tests/                      # Test scripts
├── agents/                     # Agent configurations
├── nginx/                      # Nginx configuration
├── certbot/                    # SSL certificates
└── k8s/                        # Kubernetes manifests
```

## 🚀 Deployment

### Local Development

```bash
# Start development environment
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

# View development logs
docker-compose logs -f
```

### Production Deployment

```bash
# Deploy to production server
./scripts/deploy.sh production

# Or manually:
docker-compose -f docker-compose.yml up -d
```

### Kubernetes Deployment

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/
```

## 🔧 Maintenance

### Backup & Restore

```bash
# Backup data
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh backup_file.tar.gz
```

### Updates

```bash
# Update handlers
git pull
docker-compose build --no-cache
docker-compose up -d

# Verify updates
./scripts/verify-handlers.sh
```

### Monitoring

```bash
# Check service health
docker-compose ps
curl http://localhost:47334/api/status

# View resource usage
docker stats

# Check logs
docker-compose logs -f mindsdb
```

## 🐛 Troubleshooting

### Common Issues

**Handler not found:**
```bash
# Check handler installation
./scripts/verify-handlers.sh

# Rebuild with fresh handlers
docker-compose build --no-cache
```

**API key errors:**
```bash
# Verify API keys in .env
cat .env | grep API_KEY

# Test API key manually
curl "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?limit=1" \
  -H "X-CMC_PRO_API_KEY: YOUR_API_KEY"
```

**Service won't start:**
```bash
# Check logs
docker-compose logs mindsdb

# Check ports
netstat -tulpn | grep -E "(47334|5432|6379)"

# Restart services
docker-compose restart
```

### Getting Help

1. **Check logs**: `docker-compose logs -f`
2. **Verify setup**: `./scripts/verify-handlers.sh`
3. **Check documentation**: Browse `docs/` directory
4. **Test manually**: Use MindsDB UI at http://localhost:47334

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-handler`
3. Add your changes
4. Test thoroughly: `./scripts/verify-handlers.sh`
5. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [MindsDB](https://mindsdb.com) - AI-powered database platform
- [CoinMarketCap](https://coinmarketcap.com) - Cryptocurrency market data
- [Dune Analytics](https://dune.com) - Blockchain analytics platform
- [Whale Alert](https://whale-alert.io) - Large transaction monitoring
- [DeFiLlama](https://defillama.com) - DeFi analytics platform
- [Blockchain.com](https://blockchain.com) - Bitcoin blockchain data

---

**Ready to analyze crypto markets with AI?** 🚀

Start with: `./scripts/setup.sh` 