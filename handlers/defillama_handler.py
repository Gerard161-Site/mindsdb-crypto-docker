
import requests
import pandas as pd
from typing import Dict, List, Optional
from mindsdb.integrations.libs.base import DatabaseHandler
from mindsdb.integrations.libs.response import HandlerStatusResponse, HandlerResponse
from mindsdb.utilities import log

logger = log.getLogger(__name__)

class DefiLlamaHandler(DatabaseHandler):
    """
    DefiLlama API handler for MindsDB
    """
    
    name = 'defillama'
    
    def __init__(self, name: str, connection_data: Optional[Dict], **kwargs):
        super().__init__(name, **kwargs)
        self.connection_data = connection_data or {}
        self.base_url = 'https://api.llama.fi'
        self.is_connected = False
        
    def connect(self):
        """Test connection to DefiLlama API"""
        try:
            response = requests.get(f"{self.base_url}/protocols", timeout=10)
            if response.status_code == 200:
                self.is_connected = True
                return HandlerStatusResponse(True)
            else:
                return HandlerStatusResponse(False, error_message=f"API Error: {response.status_code}")
        except Exception as e:
            return HandlerStatusResponse(False, error_message=str(e))
    
    def disconnect(self):
        """Disconnect from API"""
        self.is_connected = False
    
    def check_connection(self) -> HandlerStatusResponse:
        """Check if connection is alive"""
        return self.connect()
    
    def native_query(self, query: str) -> HandlerResponse:
        """Execute native query"""
        try:
            if 'protocols' in query.lower():
                return self._get_protocols()
            elif 'tvl' in query.lower():
                return self._get_tvl()
            elif 'chains' in query.lower():
                return self._get_chains()
            elif 'yields' in query.lower():
                return self._get_yields()
            else:
                return HandlerResponse(
                    RESPONSE_TYPE.ERROR,
                    error_message="Unsupported query type"
                )
        except Exception as e:
            return HandlerResponse(
                RESPONSE_TYPE.ERROR,
                error_message=str(e)
            )
    
    def _get_protocols(self) -> HandlerResponse:
        """Get all DeFi protocols"""
        try:
            response = requests.get(f"{self.base_url}/protocols")
            
            if response.status_code == 200:
                data = response.json()
                df = pd.json_normalize(data)
                return HandlerResponse(RESPONSE_TYPE.TABLE, data_frame=df)
            else:
                return HandlerResponse(
                    RESPONSE_TYPE.ERROR,
                    error_message=f"API Error: {response.status_code}"
                )
        except Exception as e:
            return HandlerResponse(
                RESPONSE_TYPE.ERROR,
                error_message=str(e)
            )
    
    def _get_tvl(self) -> HandlerResponse:
        """Get TVL data"""
        try:
            response = requests.get(f"{self.base_url}/charts")
            
            if response.status_code == 200:
                data = response.json()
                df = pd.DataFrame(data)
                return HandlerResponse(RESPONSE_TYPE.TABLE, data_frame=df)
            else:
                return HandlerResponse(
                    RESPONSE_TYPE.ERROR,
                    error_message=f"API Error: {response.status_code}"
                )
        except Exception as e:
            return HandlerResponse(
                RESPONSE_TYPE.ERROR,
                error_message=str(e)
            )
    
    def _get_chains(self) -> HandlerResponse:
        """Get blockchain chains data"""
        try:
            response = requests.get(f"{self.base_url}/chains")
            
            if response.status_code == 200:
                data = response.json()
                df = pd.json_normalize(data)
                return HandlerResponse(RESPONSE_TYPE.TABLE, data_frame=df)
            else:
                return HandlerResponse(
                    RESPONSE_TYPE.ERROR,
                    error_message=f"API Error: {response.status_code}"
                )
        except Exception as e:
            return HandlerResponse(
                RESPONSE_TYPE.ERROR,
                error_message=str(e)
            )
    
    def _get_yields(self) -> HandlerResponse:
        """Get yield farming data"""
        try:
            response = requests.get(f"{self.base_url}/yields")
            
            if response.status_code == 200:
                data = response.json()['data']
                df = pd.json_normalize(data)
                return HandlerResponse(RESPONSE_TYPE.TABLE, data_frame=df)
            else:
                return HandlerResponse(
                    RESPONSE_TYPE.ERROR,
                    error_message=f"API Error: {response.status_code}"
                )
        except Exception as e:
            return HandlerResponse(
                RESPONSE_TYPE.ERROR,
                error_message=str(e)
            )
    
    def get_tables(self) -> HandlerResponse:
        """Get available tables"""
        tables = [
            'protocols',
            'tvl',
            'chains',
            'yields',
            'stablecoins',
            'fees'
        ]
        return HandlerResponse(RESPONSE_TYPE.TABLE, data_frame=pd.DataFrame({'table_name': tables}))
    
    def get_columns(self, table_name: str) -> HandlerResponse:
        """Get columns for a table"""
        columns_map = {
            'protocols': ['id', 'name', 'address', 'symbol', 'url', 'description', 'chain', 'logo', 'audits', 'audit_note', 'gecko_id', 'cmcId', 'category', 'chains', 'module', 'twitter', 'forkedFrom', 'oracles', 'listedAt', 'methodology', 'slug', 'tvl', 'chainTvls', 'change_1h', 'change_1d', 'change_7d', 'tokenBreakdowns', 'mcap'],
            'tvl': ['date', 'totalLiquidityUSD'],
            'chains': ['gecko_id', 'tvl', 'tokenSymbol', 'cmcId', 'name', 'chainId'],
            'yields': ['chain', 'project', 'symbol', 'tvlUsd', 'apyBase', 'apyReward', 'apy', 'rewardTokens', 'pool', 'apyPct1D', 'apyPct7D', 'apyPct30D', 'stablecoin', 'ilRisk', 'exposure', 'predictions', 'poolMeta', 'mu', 'sigma', 'count', 'outlier', 'underlyingTokens', 'il7d', 'apyBase7d', 'apyMean30d', 'volumeUsd1d', 'volumeUsd7d', 'apyBaseInception']
        }
        
        columns = columns_map.get(table_name, [])
        return HandlerResponse(RESPONSE_TYPE.TABLE, data_frame=pd.DataFrame({'column_name': columns}))
