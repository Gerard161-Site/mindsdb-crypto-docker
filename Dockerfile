# XplainCrypto Platform - Multi-Handler MindsDB Dockerfile
FROM mindsdb/mindsdb:latest

# Set metadata
LABEL maintainer="XplainCrypto Platform"
LABEL description="MindsDB with custom crypto handlers for comprehensive market analysis"
LABEL version="1.0"

# Install system dependencies
USER root
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV MINDSDB_STORAGE_PATH=/mindsdb
ENV PYTHONPATH="${PYTHONPATH}:/mindsdb"

# Install additional Python packages for crypto handlers
RUN pip install --no-cache-dir \
    requests \
    pandas \
    numpy \
    python-dotenv \
    websocket-client \
    ccxt \
    web3 \
    pycoingecko

# Install crypto-specific handlers that are available
# Note: Most crypto APIs work through HTTP requests, not separate handlers
RUN pip install --no-cache-dir \
    coinmarketcapapi \
    dune-client \
    defillama \
    blockchain

# Create necessary directories
RUN mkdir -p /mindsdb/mindsdb/integrations/handlers

# Copy configuration files
COPY config/ /mindsdb/config/

# Create default MindsDB config if not exists
RUN if [ ! -f /mindsdb/config.json ]; then \
    echo '{"config_version": "1.4", "api": {"http": {"host": "0.0.0.0", "port": "47334"}}}' > /mindsdb/config.json; \
    fi

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:47334/api/status || exit 1

# Expose ports
EXPOSE 47334 47335 47336 47337

# Set working directory
WORKDIR /mindsdb

# Start MindsDB
CMD ["python", "-m", "mindsdb", "--config=/mindsdb/config.json", "--api=http,mysql,mongodb"]