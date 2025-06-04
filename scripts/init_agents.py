
#!/usr/bin/env python3
"""
Initialize and register all AI agents with MindsDB
"""

import os
import sys
import json
import requests
import time
from datetime import datetime

# MindsDB API configuration
MINDSDB_API_URL = "http://localhost:47334/api/sql/query"
MINDSDB_AUTH_TOKEN = os.getenv('MCP_ACCESS_TOKEN', 'your_secure_mcp_token')

# Agent configurations
AGENTS_CONFIG = {
    'crypto_prediction_agent': {
        'name': 'CryptoPredictionAgent',
        'description': 'Advanced cryptocurrency price prediction using ensemble ML models',
        'file_path': '/opt/mindsdb/agents/crypto_prediction_agent.py',
        'class_name': 'CryptoPredictionAgent',
        'capabilities': [
            'price_prediction',
            'trend_analysis',
            'technical_indicators',
            'ensemble_modeling',
            'prophet_forecasting'
        ]
    },
    'anomaly_detection_agent': {
        'name': 'AnomalyDetectionAgent',
        'description': 'Detects market anomalies, manipulation patterns, and unusual activities',
        'file_path': '/opt/mindsdb/agents/anomaly_detection_agent.py',
        'class_name': 'AnomalyDetectionAgent',
        'capabilities': [
            'anomaly_detection',
            'manipulation_detection',
            'flash_crash_detection',
            'volume_analysis',
            'pattern_recognition'
        ]
    },
    'sentiment_analysis_agent': {
        'name': 'SentimentAnalysisAgent',
        'description': 'Analyzes market sentiment from social media, news, and on-chain data',
        'file_path': '/opt/mindsdb/agents/sentiment_analysis_agent.py',
        'class_name': 'SentimentAnalysisAgent',
        'capabilities': [
            'twitter_sentiment',
            'reddit_sentiment',
            'news_sentiment',
            'fear_greed_index',
            'social_media_monitoring'
        ]
    },
    'whale_tracking_agent': {
        'name': 'WhaleTrackingAgent',
        'description': 'Monitors large transactions and whale wallet activities',
        'file_path': '/opt/mindsdb/agents/whale_tracking_agent.py',
        'class_name': 'WhaleTrackingAgent',
        'capabilities': [
            'large_transaction_tracking',
            'whale_wallet_monitoring',
            'movement_detection',
            'blockchain_analysis',
            'alert_generation'
        ]
    },
    'risk_assessment_agent': {
        'name': 'RiskAssessmentAgent',
        'description': 'Comprehensive risk analysis for cryptocurrency investments',
        'file_path': '/opt/mindsdb/agents/risk_assessment_agent.py',
        'class_name': 'RiskAssessmentAgent',
        'capabilities': [
            'portfolio_risk_assessment',
            'var_calculation',
            'stress_testing',
            'correlation_analysis',
            'risk_scoring'
        ]
    }
}

def execute_sql_query(query: str) -> dict:
    """Execute SQL query against MindsDB API"""
    try:
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {MINDSDB_AUTH_TOKEN}'
        }
        
        payload = {'query': query}
        response = requests.post(MINDSDB_API_URL, json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Error executing query: {response.status_code} - {response.text}")
            return {'error': f'HTTP {response.status_code}'}
            
    except Exception as e:
        print(f"Exception executing query: {str(e)}")
        return {'error': str(e)}

def wait_for_mindsdb():
    """Wait for MindsDB to be ready"""
    print("Waiting for MindsDB to be ready...")
    max_attempts = 30
    
    for attempt in range(max_attempts):
        try:
            response = requests.get("http://localhost:47334/api/status", timeout=5)
            if response.status_code == 200:
                print("MindsDB is ready!")
                return True
        except:
            pass
        
        print(f"Attempt {attempt + 1}/{max_attempts} - MindsDB not ready yet...")
        time.sleep(10)
    
    print("MindsDB failed to become ready")
    return False

def create_agent_database():
    """Create database for storing agent configurations"""
    query = """
    CREATE DATABASE IF NOT EXISTS agents_db
    WITH ENGINE = 'postgres',
    PARAMETERS = {
        'host': 'postgres',
        'port': 5432,
        'database': 'mindsdb',
        'user': 'mindsdb',
        'password': 'mindsdb_secure_pass'
    };
    """
    
    result = execute_sql_query(query)
    if 'error' not in result:
        print("✓ Agent database created successfully")
    else:
        print(f"✗ Error creating agent database: {result['error']}")
    
    return 'error' not in result

def create_agent_tables():
    """Create tables for storing agent data"""
    queries = [
        """
        CREATE TABLE IF NOT EXISTS agents_db.agent_registry (
            id SERIAL PRIMARY KEY,
            agent_id VARCHAR(100) UNIQUE NOT NULL,
            name VARCHAR(200) NOT NULL,
            description TEXT,
            class_name VARCHAR(100),
            file_path VARCHAR(500),
            capabilities JSONB,
            status VARCHAR(50) DEFAULT 'inactive',
            created_at TIMESTAMP DEFAULT NOW(),
            updated_at TIMESTAMP DEFAULT NOW()
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS agents_db.agent_predictions (
            id SERIAL PRIMARY KEY,
            agent_id VARCHAR(100),
            symbol VARCHAR(20),
            prediction_type VARCHAR(100),
            prediction_data JSONB,
            confidence_score FLOAT,
            created_at TIMESTAMP DEFAULT NOW()
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS agents_db.agent_alerts (
            id SERIAL PRIMARY KEY,
            agent_id VARCHAR(100),
            alert_type VARCHAR(100),
            symbol VARCHAR(20),
            severity VARCHAR(20),
            message TEXT,
            alert_data JSONB,
            created_at TIMESTAMP DEFAULT NOW()
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS agents_db.agent_performance (
            id SERIAL PRIMARY KEY,
            agent_id VARCHAR(100),
            metric_name VARCHAR(100),
            metric_value FLOAT,
            measurement_date DATE,
            created_at TIMESTAMP DEFAULT NOW()
        );
        """
    ]
    
    for query in queries:
        result = execute_sql_query(query)
        if 'error' in result:
            print(f"✗ Error creating table: {result['error']}")
            return False
    
    print("✓ Agent tables created successfully")
    return True

def register_agent(agent_id: str, config: dict):
    """Register an agent in the database"""
    query = f"""
    INSERT INTO agents_db.agent_registry 
    (agent_id, name, description, class_name, file_path, capabilities, status)
    VALUES (
        '{agent_id}',
        '{config['name']}',
        '{config['description']}',
        '{config['class_name']}',
        '{config['file_path']}',
        '{json.dumps(config['capabilities'])}',
        'active'
    )
    ON CONFLICT (agent_id) 
    DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        class_name = EXCLUDED.class_name,
        file_path = EXCLUDED.file_path,
        capabilities = EXCLUDED.capabilities,
        status = EXCLUDED.status,
        updated_at = NOW();
    """
    
    result = execute_sql_query(query)
    if 'error' not in result:
        print(f"✓ Agent {agent_id} registered successfully")
    else:
        print(f"✗ Error registering agent {agent_id}: {result['error']}")
    
    return 'error' not in result

def create_agent_models():
    """Create ML models for each agent"""
    models = [
        {
            'name': 'crypto_price_predictor',
            'query': """
            CREATE MODEL crypto_price_predictor
            FROM coinmarketcap_db
            (SELECT symbol, price, volume_24h, market_cap, percent_change_24h, timestamp FROM listings)
            PREDICT price
            USING engine = 'lightgbm',
            time_column = 'timestamp',
            group_by = 'symbol',
            window = 100,
            horizon = 24;
            """
        },
        {
            'name': 'anomaly_detector',
            'query': """
            CREATE MODEL anomaly_detector
            FROM coinmarketcap_db
            (SELECT symbol, price, volume_24h, percent_change_1h, percent_change_24h, timestamp FROM listings)
            PREDICT is_anomaly
            USING engine = 'isolation_forest',
            anomaly_detection = true;
            """
        },
        {
            'name': 'sentiment_analyzer',
            'query': """
            CREATE MODEL sentiment_analyzer
            FROM news_db
            (SELECT title, description, sentiment_score, symbol, published_at FROM articles)
            PREDICT sentiment_score
            USING engine = 'huggingface',
            model_name = 'cardiffnlp/twitter-roberta-base-sentiment-latest';
            """
        }
    ]
    
    for model in models:
        print(f"Creating model: {model['name']}")
        result = execute_sql_query(model['query'])
        
        if 'error' not in result:
            print(f"✓ Model {model['name']} created successfully")
        else:
            print(f"✗ Error creating model {model['name']}: {result['error']}")

def create_agent_views():
    """Create views for easy agent data access"""
    views = [
        {
            'name': 'active_agents',
            'query': """
            CREATE OR REPLACE VIEW agents_db.active_agents AS
            SELECT agent_id, name, description, capabilities, status, updated_at
            FROM agents_db.agent_registry
            WHERE status = 'active';
            """
        },
        {
            'name': 'recent_predictions',
            'query': """
            CREATE OR REPLACE VIEW agents_db.recent_predictions AS
            SELECT 
                ar.name as agent_name,
                ap.symbol,
                ap.prediction_type,
                ap.confidence_score,
                ap.created_at
            FROM agents_db.agent_predictions ap
            JOIN agents_db.agent_registry ar ON ap.agent_id = ar.agent_id
            WHERE ap.created_at > NOW() - INTERVAL '24 hours'
            ORDER BY ap.created_at DESC;
            """
        },
        {
            'name': 'recent_alerts',
            'query': """
            CREATE OR REPLACE VIEW agents_db.recent_alerts AS
            SELECT 
                ar.name as agent_name,
                aa.alert_type,
                aa.symbol,
                aa.severity,
                aa.message,
                aa.created_at
            FROM agents_db.agent_alerts aa
            JOIN agents_db.agent_registry ar ON aa.agent_id = ar.agent_id
            WHERE aa.created_at > NOW() - INTERVAL '24 hours'
            ORDER BY aa.created_at DESC;
            """
        }
    ]
    
    for view in views:
        result = execute_sql_query(view['query'])
        if 'error' not in result:
            print(f"✓ View {view['name']} created successfully")
        else:
            print(f"✗ Error creating view {view['name']}: {result['error']}")

def setup_agent_jobs():
    """Setup scheduled jobs for agents"""
    jobs = [
        {
            'name': 'hourly_predictions',
            'query': """
            CREATE JOB hourly_predictions (
                INSERT INTO agents_db.agent_predictions (agent_id, symbol, prediction_type, prediction_data, confidence_score)
                SELECT 
                    'crypto_prediction_agent',
                    symbol,
                    'price_prediction',
                    JSON_BUILD_OBJECT('predicted_price', predicted_price, 'horizon', '1h'),
                    confidence
                FROM crypto_price_predictor
                WHERE symbol IN ('BTC', 'ETH', 'ADA', 'SOL', 'DOT')
            )
            EVERY hour;
            """
        },
        {
            'name': 'daily_anomaly_check',
            'query': """
            CREATE JOB daily_anomaly_check (
                INSERT INTO agents_db.agent_alerts (agent_id, alert_type, symbol, severity, message)
                SELECT 
                    'anomaly_detection_agent',
                    'anomaly_detected',
                    symbol,
                    CASE WHEN anomaly_score > 0.8 THEN 'high' ELSE 'medium' END,
                    CONCAT('Anomaly detected for ', symbol, ' with score: ', anomaly_score)
                FROM anomaly_detector
                WHERE is_anomaly = 1
            )
            EVERY day;
            """
        }
    ]
    
    for job in jobs:
        result = execute_sql_query(job['query'])
        if 'error' not in result:
            print(f"✓ Job {job['name']} created successfully")
        else:
            print(f"✗ Error creating job {job['name']}: {result['error']}")

def main():
    """Main initialization function"""
    print("🚀 Initializing XplainCrypto AI Agents...")
    print("=" * 50)
    
    # Wait for MindsDB to be ready
    if not wait_for_mindsdb():
        print("❌ MindsDB is not ready. Exiting.")
        sys.exit(1)
    
    # Create agent database
    print("\n📊 Setting up agent database...")
    if not create_agent_database():
        print("❌ Failed to create agent database. Exiting.")
        sys.exit(1)
    
    # Create agent tables
    print("\n🗃️ Creating agent tables...")
    if not create_agent_tables():
        print("❌ Failed to create agent tables. Exiting.")
        sys.exit(1)
    
    # Register all agents
    print("\n🤖 Registering AI agents...")
    for agent_id, config in AGENTS_CONFIG.items():
        register_agent(agent_id, config)
    
    # Create agent models
    print("\n🧠 Creating ML models...")
    create_agent_models()
    
    # Create views
    print("\n👁️ Creating database views...")
    create_agent_views()
    
    # Setup scheduled jobs
    print("\n⏰ Setting up scheduled jobs...")
    setup_agent_jobs()
    
    print("\n" + "=" * 50)
    print("✅ AI Agents initialization completed successfully!")
    print("\nRegistered Agents:")
    for agent_id, config in AGENTS_CONFIG.items():
        print(f"  • {config['name']} ({agent_id})")
        print(f"    Capabilities: {', '.join(config['capabilities'])}")
    
    print(f"\n📈 Access agent data via MindsDB API:")
    print(f"  • Active agents: SELECT * FROM agents_db.active_agents;")
    print(f"  • Recent predictions: SELECT * FROM agents_db.recent_predictions;")
    print(f"  • Recent alerts: SELECT * FROM agents_db.recent_alerts;")
    
    print(f"\n🔗 MindsDB API URL: {MINDSDB_API_URL}")
    print(f"🔑 Use MCP token for authentication")

if __name__ == "__main__":
    main()
