
import requests
import pandas as pd
from typing import Dict, List, Optional
from mindsdb.integrations.libs.base import DatabaseHandler
from mindsdb.integrations.libs.response import HandlerStatusResponse, HandlerResponse
from mindsdb.utilities import log

logger = log.getLogger(__name__)

class CoinMarketCapHandler(DatabaseHandler):
    """
    CoinMarketCap API handler for MindsDB
    """
    
    name = 'coinmarketcap'
    
    def __init__(self, name: str, connection_data: Optional[Dict], **kwargs):
        super().__init__(name, **kwargs)
        self.connection_data = connection_data or {}
        self.api_key = self.connection_data.get('api_key')
        self.base_url = 'https://pro-api.coinmarketcap.com/v1'
        self.headers = {
            'X-CMC_PRO_API_KEY': self.api_key,
            'Accept': 'application/json'
        }
        self.is_connected = False
        
    def connect(self):
        """Test connection to CoinMarketCap API"""
        try:
            response = requests.get(
                f"{self.base_url}/key/info",
                headers=self.headers,
                timeout=10
            )
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
        # Parse query to determine endpoint and parameters
        # This is a simplified implementation
        try:
            if 'listings' in query.lower():
                return self._get_listings()
            elif 'quotes' in query.lower():
                return self._get_quotes()
            elif 'ohlcv' in query.lower():
                return self._get_ohlcv()
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
    
    def _get_listings(self, limit: int = 100) -> HandlerResponse:
        """Get cryptocurrency listings"""
        try:
            response = requests.get(
                f"{self.base_url}/cryptocurrency/listings/latest",
                headers=self.headers,
                params={'limit': limit}
            )
            
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
    
    def _get_quotes(self, symbols: List[str] = None) -> HandlerResponse:
        """Get latest quotes for cryptocurrencies"""
        try:
            params = {}
            if symbols:
                params['symbol'] = ','.join(symbols)
            
            response = requests.get(
                f"{self.base_url}/cryptocurrency/quotes/latest",
                headers=self.headers,
                params=params
            )
            
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
    
    def _get_ohlcv(self, symbol: str, time_period: str = 'daily') -> HandlerResponse:
        """Get OHLCV historical data"""
        try:
            response = requests.get(
                f"{self.base_url}/cryptocurrency/ohlcv/historical",
                headers=self.headers,
                params={
                    'symbol': symbol,
                    'time_period': time_period
                }
            )
            
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
            'listings',
            'quotes', 
            'ohlcv',
            'market_metrics',
            'global_metrics'
        ]
        return HandlerResponse(RESPONSE_TYPE.TABLE, data_frame=pd.DataFrame({'table_name': tables}))
    
    def get_columns(self, table_name: str) -> HandlerResponse:
        """Get columns for a table"""
        columns_map = {
            'listings': ['id', 'name', 'symbol', 'slug', 'cmc_rank', 'market_cap', 'price', 'volume_24h'],
            'quotes': ['id', 'name', 'symbol', 'price', 'volume_24h', 'market_cap', 'percent_change_1h', 'percent_change_24h'],
            'ohlcv': ['time_open', 'time_close', 'open', 'high', 'low', 'close', 'volume']
        }
        
        columns = columns_map.get(table_name, [])
        return HandlerResponse(RESPONSE_TYPE.TABLE, data_frame=pd.DataFrame({'column_name': columns}))
