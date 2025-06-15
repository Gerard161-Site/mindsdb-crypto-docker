#!/bin/bash
# XplainCrypto Handler Installation Script
# This script installs all custom handlers from the mindsdb-handlers directory

set -e

echo "🔧 Installing XplainCrypto Handlers..."

# Handler list
HANDLERS=(
    "coinmarketcap_handler"
    "dune_handler"
    "whale_alerts_handler"
    "defillama_handler"
    "blockchain_handler"
)

# Base path to handlers (relative to Docker build context)
HANDLERS_BASE_PATH="../mindsdb-handlers"

# MindsDB handlers installation directory
MINDSDB_HANDLERS_DIR="/opt/mindsdb/mindsdb/integrations/handlers"

# Create handlers directory if it doesn't exist
mkdir -p "$MINDSDB_HANDLERS_DIR"

# Install each handler
for handler in "${HANDLERS[@]}"; do
    echo "📦 Installing $handler..."
    
    # Check if handler exists in source
    if [ ! -d "$HANDLERS_BASE_PATH/$handler" ]; then
        echo "❌ Handler $handler not found at $HANDLERS_BASE_PATH/$handler"
        echo "   Make sure the mindsdb-handlers directory is at the correct relative path"
        continue
    fi
    
    # Copy handler to MindsDB location
    echo "   Copying files..."
    cp -r "$HANDLERS_BASE_PATH/$handler" "$MINDSDB_HANDLERS_DIR/"
    
    # Install Python requirements if they exist
    if [ -f "$HANDLERS_BASE_PATH/$handler/requirements.txt" ]; then
        echo "   Installing Python dependencies..."
        pip install --no-cache-dir -r "$HANDLERS_BASE_PATH/$handler/requirements.txt"
    fi
    
    # Create icon if missing (MindsDB requires an icon.svg file)
    icon_path="$MINDSDB_HANDLERS_DIR/$handler/icon.svg"
    if [ ! -f "$icon_path" ]; then
        echo "   Creating default icon..."
        cat > "$icon_path" << 'ICON_EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#0066cc">
  <circle cx="12" cy="12" r="10"/>
  <text x="12" y="16" text-anchor="middle" fill="white" font-size="8" font-family="Arial">API</text>
</svg>
ICON_EOF
    fi
    
    # Verify installation
    if [ -f "$MINDSDB_HANDLERS_DIR/$handler/__init__.py" ]; then
        echo "   ✅ $handler installed successfully"
    else
        echo "   ❌ $handler installation failed - missing __init__.py"
    fi
done

echo ""
echo "🎉 Handler installation complete!"
echo ""
echo "📋 Installed handlers:"
for handler in "${HANDLERS[@]}"; do
    if [ -d "$MINDSDB_HANDLERS_DIR/$handler" ]; then
        echo "   ✅ $handler"
    else
        echo "   ❌ $handler (failed)"
    fi
done

echo ""
echo "🔍 Verifying handler structure..."
ls -la "$MINDSDB_HANDLERS_DIR" | grep -E "(coinmarketcap|dune|whale|defillama|blockchain)" || echo "No handlers found in directory"

echo ""
echo "✨ Ready to start MindsDB with custom handlers!" 