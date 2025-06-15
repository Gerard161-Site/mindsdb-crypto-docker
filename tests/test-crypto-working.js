// Test working crypto functionality in MindsDB
async function testCryptoWorking() {
  console.log('🔍 Testing Working Crypto Functionality...\n');
  
  try {
    // Test 1: Check available databases
    console.log('1. 📊 Available databases:');
    let response = await fetch('http://142.93.49.20:47334/api/sql/query', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({query: 'SHOW DATABASES;'})
    });
    let result = await response.json();
    console.log('   Databases:', result.data.flat());
    
    // Test 2: Check if coinbase_db was created
    console.log('\n2. 🏦 Checking coinbase_db:');
    response = await fetch('http://142.93.49.20:47334/api/sql/query', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({query: 'SHOW TABLES FROM coinbase_db;'})
    });
    result = await response.json();
    console.log('   Tables:', result);
    
    // Test 3: Create a simple prediction model
    console.log('\n3. 🤖 Creating a simple model:');
    response = await fetch('http://142.93.49.20:47334/api/sql/query', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        query: `CREATE MODEL mindsdb.crypto_price_predictor
                PREDICT price_change
                USING
                  engine = 'lightwood',
                  tag = 'crypto_test';`
      })
    });
    result = await response.json();
    console.log('   Model creation:', result);
    
    // Test 4: Check available ML engines
    console.log('\n4. ⚙️ Available ML engines:');
    response = await fetch('http://142.93.49.20:47334/api/sql/query', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({query: 'SHOW ML_ENGINES;'})
    });
    result = await response.json();
    console.log('   ML Engines:', result.data?.map(row => row[0]) || 'None');
    
    // Test 5: Create a simple dataset for testing
    console.log('\n5. 📈 Creating test crypto data:');
    response = await fetch('http://142.93.49.20:47334/api/sql/query', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        query: `CREATE TABLE mindsdb.crypto_test_data (
                   timestamp TIMESTAMP,
                   symbol VARCHAR(10),
                   price DECIMAL(10,2),
                   volume DECIMAL(15,2),
                   price_change DECIMAL(5,2)
                 );`
      })
    });
    result = await response.json();
    console.log('   Table creation:', result.type || result.error);
    
    // Test 6: Insert sample data
    console.log('\n6. 📊 Inserting sample crypto data:');
    const sampleData = [
      "('2024-01-01 00:00:00', 'BTC', 45000.00, 1000000.00, 2.5)",
      "('2024-01-01 01:00:00', 'BTC', 45500.00, 1100000.00, 1.1)",
      "('2024-01-01 02:00:00', 'BTC', 46000.00, 1200000.00, 1.1)",
      "('2024-01-01 03:00:00', 'ETH', 3000.00, 500000.00, 3.2)",
      "('2024-01-01 04:00:00', 'ETH', 3100.00, 550000.00, 3.3)"
    ];
    
    response = await fetch('http://142.93.49.20:47334/api/sql/query', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        query: `INSERT INTO mindsdb.crypto_test_data 
                (timestamp, symbol, price, volume, price_change) 
                VALUES ${sampleData.join(', ')};`
      })
    });
    result = await response.json();
    console.log('   Data insertion:', result.type || result.error);
    
    // Test 7: Query the data
    console.log('\n7. 🔍 Querying test data:');
    response = await fetch('http://142.93.49.20:47334/api/sql/query', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        query: 'SELECT * FROM mindsdb.crypto_test_data LIMIT 5;'
      })
    });
    result = await response.json();
    console.log('   Sample data:', result.data || result.error);
    
    // Test 8: Check system status
    console.log('\n8. ⚡ System status:');
    response = await fetch('http://142.93.49.20:47334/api/status');
    result = await response.json();
    console.log('   MindsDB version:', result.mindsdb_version);
    console.log('   Environment:', result.environment);
    console.log('   Auth:', result.auth);
    
    console.log('\n✅ Crypto functionality test completed!');
    console.log('\n🎯 Next steps:');
    console.log('   1. Add real API keys to .env file');
    console.log('   2. Create crypto prediction models');
    console.log('   3. Set up automated crypto data ingestion');
    console.log('   4. Build dashboards in Grafana');
    
  } catch (error) {
    console.error('❌ Error during crypto testing:', error);
  }
}

testCryptoWorking(); 