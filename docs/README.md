
# MindsDB Crypto Platform - Docker Solution

A comprehensive Docker-based solution for MindsDB with custom cryptocurrency handlers and MCP server access, designed for the XplainCrypto platform.

## 🚀 Features

- **Custom Crypto Handlers**: CoinMarketCap, DefiLlama, CoinGecko, Binance, and more
- **MCP Server**: External access for Model Context Protocol
- **AI Agents**: Prediction, anomaly detection, sentiment analysis, and more
- **Production Ready**: SSL/TLS, monitoring, logging, and security
- **Multi-Container**: PostgreSQL, Redis, Nginx, Grafana, Prometheus
- **Auto-Scaling**: Docker Compose with health checks and restart policies

## 📋 Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Domain name (for SSL certificates)
- API keys for crypto data providers

## 🛠 Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd mindsdb-crypto-docker
chmod +x scripts/*.sh
```

### 2. Configure Environment

```bash
# Copy and edit environment variables
cp .env.example .env
nano .env
```

Update the following in `.env`:
- `DOMAIN`: Your domain name
- `EMAIL`: Your email for SSL certificates
- API keys for crypto data providers

### 3. Deploy

```bash
# Full deployment with SSL
./scripts/deploy.sh

# Or skip SSL for local testing
./scripts/deploy.sh --skip-ssl
```

### 4. Verify Deployment

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f mindsdb

# Test API
curl https://your-domain.com/api/status
```

## 🏗 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │    MindsDB      │    │   PostgreSQL    │
│  (Reverse Proxy)│────│  (Core + MCP)   │────│   (Storage)     │
│   SSL/TLS       │    │   Port 47334    │    │   Port 5432     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │     Redis       │    │    Grafana      │
         └──────────────│   (Cache)       │    │  (Monitoring)   │
                        │   Port 6379     │    │   Port 3000     │
                        └─────────────────┘    └─────────────────┘
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DOMAIN` | Your domain name | Yes |
| `EMAIL` | Email for SSL certificates | Yes |
| `COINMARKETCAP_API_KEY` | CoinMarketCap API key | Yes |
| `DEFILLAMA_API_KEY` | DefiLlama API key | No |
| `COINGECKO_API_KEY` | CoinGecko API key | Yes |
| `BINANCE_API_KEY` | Binance API key | No |
| `OPENAI_API_KEY` | OpenAI API key | Yes |

### Custom Handlers

The platform includes custom handlers for:

- **CoinMarketCap**: Real-time crypto prices and market data
- **DefiLlama**: DeFi protocol TVL and yield data
- **CoinGecko**: Alternative crypto market data
- **Binance**: Exchange data and trading pairs
- **Alpha Vantage**: Traditional financial data

### AI Agents

#### 1. Crypto Prediction Agent
- Multi-model ensemble (XGBoost, LightGBM, Random Forest)
- Technical indicators and feature engineering
- Prophet time series forecasting
- Confidence intervals and prediction horizons

#### 2. Anomaly Detection Agent
- Statistical outlier detection
- Volume-price divergence analysis
- Flash crash detection
- Market manipulation patterns

#### 3. Sentiment Analysis Agent
- Social media sentiment tracking
- News sentiment analysis
- Fear & Greed index integration
- Real-time sentiment scoring

#### 4. Risk Assessment Agent
- Portfolio risk metrics
- VaR (Value at Risk) calculations
- Correlation analysis
- Stress testing scenarios

#### 5. Whale Tracking Agent
- Large transaction monitoring
- Wallet behavior analysis
- Exchange flow tracking
- Alert system for significant moves

## 🌐 Cloud Hosting Recommendations

### DigitalOcean (Recommended for Small Projects)
- **Droplets**: $12-40/month
- **Managed Kubernetes**: $12/month + nodes
- **Easy deployment**: One-click Docker images
- **Pros**: Simple, affordable, great documentation
- **Cons**: Limited enterprise features

```bash
# DigitalOcean deployment
doctl compute droplet create mindsdb-crypto \
  --image docker-20-04 \
  --size s-2vcpu-4gb \
  --region nyc1 \
  --ssh-keys your-ssh-key-id
```

### Google Cloud Platform (Best for Scaling)
- **GKE Autopilot**: $0.10/hour per pod
- **Compute Engine**: $20-100/month
- **Free tier**: $300 credit for 12 months
- **Pros**: Excellent Kubernetes, AI/ML integration
- **Cons**: Complex pricing, learning curve

```bash
# GCP deployment
gcloud container clusters create-auto mindsdb-crypto \
  --region=us-central1 \
  --project=your-project-id
```

### AWS (Enterprise Grade)
- **ECS Fargate**: $0.04048/vCPU/hour
- **EKS**: $0.10/hour + nodes
- **EC2**: $20-200/month
- **Pros**: Comprehensive services, global reach
- **Cons**: Complex, expensive for small projects

```bash
# AWS ECS deployment
aws ecs create-cluster --cluster-name mindsdb-crypto
```

## 🔒 Security

### SSL/TLS Configuration
- Automatic Let's Encrypt certificates
- TLS 1.2+ only
- Strong cipher suites
- HSTS headers

### Authentication
- MCP server authentication tokens
- Nginx basic auth for admin endpoints
- API key validation for handlers
- Rate limiting and DDoS protection

### Network Security
- Internal Docker networks
- Firewall rules (ports 80, 443 only)
- No direct database access
- Encrypted inter-service communication

## 📊 Monitoring

### Prometheus Metrics
- MindsDB API performance
- Database connections
- Cache hit rates
- Custom crypto metrics

### Grafana Dashboards
- System overview
- API performance
- Crypto data freshness
- Alert notifications

### Log Management
- Centralized logging
- Log rotation
- Error tracking
- Performance monitoring

## 🔄 Backup & Recovery

### Automated Backups
```bash
# Run backup
./scripts/backup.sh

# Schedule daily backups (crontab)
0 2 * * * /path/to/scripts/backup.sh
```

### Restore Process
```bash
# List available backups
./scripts/restore.sh

# Restore specific backup
./scripts/restore.sh 20231201_143000
```

## 🚀 Scaling

### Horizontal Scaling
```yaml
# docker-compose.override.yml
services:
  mindsdb:
    deploy:
      replicas: 3
    environment:
      - MINDSDB_CLUSTER_MODE=true
```

### Kubernetes Deployment
```bash
# Convert to Kubernetes
kompose convert

# Deploy to Kubernetes
kubectl apply -f .
```

### Load Balancing
- Nginx upstream configuration
- Health check endpoints
- Session affinity for stateful connections

## 🔧 Troubleshooting

### Common Issues

#### 1. SSL Certificate Issues
```bash
# Check certificate status
docker-compose logs certbot

# Manual certificate renewal
docker-compose run --rm certbot renew
```

#### 2. Database Connection Issues
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Test connection
docker-compose exec postgres psql -U mindsdb -d mindsdb
```

#### 3. API Handler Errors
```bash
# Check MindsDB logs
docker-compose logs mindsdb

# Test handler connection
curl -X POST https://your-domain.com/api/sql/query \
  -H "Content-Type: application/json" \
  -d '{"query": "SHOW DATABASES;"}'
```

### Performance Optimization

#### 1. Database Tuning
```sql
-- PostgreSQL optimization
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
```

#### 2. Redis Configuration
```bash
# Redis memory optimization
echo "maxmemory 512mb" >> redis.conf
echo "maxmemory-policy allkeys-lru" >> redis.conf
```

#### 3. Nginx Optimization
```nginx
# Worker processes
worker_processes auto;
worker_connections 2048;

# Caching
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m;
```

## 📚 API Documentation

### MindsDB HTTP API
- **Base URL**: `https://your-domain.com/api/`
- **Authentication**: Bearer token
- **Rate Limit**: 100 requests/minute

### MCP Server API
- **Base URL**: `https://your-domain.com/mcp/`
- **Authentication**: Basic auth + token
- **Rate Limit**: 50 requests/minute

### Crypto Handlers Usage

#### CoinMarketCap
```sql
-- Create connection
CREATE DATABASE cmc_db
WITH ENGINE = 'coinmarketcap',
PARAMETERS = {'api_key': 'your_key'};

-- Query latest prices
SELECT * FROM cmc_db.listings LIMIT 10;
```

#### DefiLlama
```sql
-- Create connection
CREATE DATABASE defi_db
WITH ENGINE = 'defillama';

-- Query TVL data
SELECT * FROM defi_db.protocols WHERE tvl > 1000000;
```

## 🤝 Integration with XplainCrypto

### API Endpoints
```javascript
// XplainCrypto integration
const mindsdbClient = new MindsDBClient({
  baseUrl: 'https://your-domain.com/api',
  token: 'your_mcp_token'
});

// Get price predictions
const predictions = await mindsdbClient.query(`
  SELECT * FROM crypto_predictions 
  WHERE symbol = 'BTC' 
  AND horizon = '24h'
`);

// Detect anomalies
const anomalies = await mindsdbClient.query(`
  SELECT * FROM anomaly_detections 
  WHERE symbol = 'ETH' 
  AND severity = 'high'
  AND detected_at > NOW() - INTERVAL '1 hour'
`);
```

### WebSocket Integration
```javascript
// Real-time data streaming
const ws = new WebSocket('wss://your-domain.com/api/ws');

ws.on('message', (data) => {
  const update = JSON.parse(data);
  if (update.type === 'price_prediction') {
    updatePredictionChart(update.data);
  }
});
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [docs/](docs/)
- **Issues**: GitHub Issues
- **Discord**: [MindsDB Community](https://discord.gg/mindsdb)
- **Email**: support@xplaincrypto.com

## 🔄 Updates

### Version 1.0.0
- Initial release with basic crypto handlers
- Docker Compose setup
- SSL/TLS configuration

### Version 1.1.0
- Added AI agents for prediction and anomaly detection
- Monitoring with Prometheus and Grafana
- Backup and restore scripts

### Version 1.2.0 (Planned)
- Kubernetes deployment manifests
- Advanced security features
- Multi-region deployment support
