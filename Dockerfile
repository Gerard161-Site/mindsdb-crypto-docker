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
    pycoingecko \
    coinmarketcapapi \
    dune-client

# Create necessary directories
RUN mkdir -p /mindsdb/mindsdb/integrations/handlers

# Clone handler repositories at build time
RUN cd /tmp && \
    git clone https://github.com/mindsdb/mindsdb.git mindsdb-repo && \
    mkdir -p mindsdb-handlers && \
    cp -r mindsdb-repo/mindsdb/integrations/handlers/coinmarketcap_handler mindsdb-handlers/ && \
    git clone https://github.com/Gerard161-Site/dune-handler.git mindsdb-handlers/dune_handler || echo "Dune handler not available" && \
    git clone https://github.com/Gerard161-Site/whale-alerts-handler.git mindsdb-handlers/whale_alerts_handler || echo "Whale alerts handler not available" && \
    git clone https://github.com/Gerard161-Site/defillama-handler.git mindsdb-handlers/defillama_handler || echo "DeFiLlama handler not available" && \
    git clone https://github.com/Gerard161-Site/blockchain-handler.git mindsdb-handlers/blockchain_handler || echo "Blockchain handler not available"

# Copy handler installation script
COPY scripts/install-handlers.sh /tmp/install-handlers.sh
RUN chmod +x /tmp/install-handlers.sh

# Install all handlers
RUN cd /tmp && \
    HANDLERS_BASE_PATH="/tmp/mindsdb-handlers" /tmp/install-handlers.sh

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