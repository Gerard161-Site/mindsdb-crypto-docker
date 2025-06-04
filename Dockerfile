
# MindsDB Custom Crypto Handlers Dockerfile
FROM mindsdb/mindsdb:latest

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV MINDSDB_STORAGE_PATH=/opt/mindsdb
ENV MINDSDB_CONFIG_PATH=/opt/mindsdb/config.json

# Install system dependencies
USER root
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /opt/mindsdb/handlers /opt/mindsdb/agents /opt/mindsdb/config

# Copy custom handlers and requirements
COPY handlers/ /opt/mindsdb/handlers/
COPY requirements-crypto.txt /opt/mindsdb/

# Install crypto-specific dependencies
RUN pip install --no-cache-dir -r /opt/mindsdb/requirements-crypto.txt

# Install additional crypto handlers
RUN pip install --no-cache-dir \
    requests \
    websocket-client \
    ccxt \
    web3 \
    pycoingecko \
    python-binance \
    alpha-vantage \
    yfinance \
    pandas-ta \
    ta-lib \
    numpy \
    scipy \
    scikit-learn \
    plotly \
    dash \
    streamlit

# Copy configuration files
COPY config/ /opt/mindsdb/config/
COPY agents/ /opt/mindsdb/agents/

# Set permissions
RUN chown -R mindsdb:mindsdb /opt/mindsdb
USER mindsdb

# Expose ports
EXPOSE 47334 47335 47336 47337

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:47334/api/status || exit 1

# Start MindsDB with all APIs enabled
CMD ["python", "-m", "mindsdb", "--api=http,mysql,mongodb,mcp", "--config=/opt/mindsdb/config/config.json"]
