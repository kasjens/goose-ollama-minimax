#!/bin/bash

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "============================================"
echo "Brave Search Setup for Goose AI"
echo "============================================"
echo ""
echo "This script will configure Brave Search for Goose."
echo ""
echo "Please get your Brave Search API key from:"
echo "https://brave.com/search/api/"
echo ""
echo "The free tier includes:"
echo "- 2,000 queries per month"
echo "- Web search API access"
echo "- News search API access"
echo ""

# Prompt for API key
read -p "Enter your Brave Search API key: " BRAVE_API_KEY

if [ -z "$BRAVE_API_KEY" ]; then
    echo "Error: API key cannot be empty"
    exit 1
fi

# Store API key in .env file for the MCP server
echo "Creating .env file for Brave Search MCP..."
cat > $PROJECT_DIR/brave-search-mcp/.env << EOF
BRAVE_API_KEY=$BRAVE_API_KEY
EOF

# Check if extensions section exists in Goose config
if ! grep -q "extensions:" ~/.config/goose/config.yaml 2>/dev/null; then
    echo "Adding extensions section to Goose config..."
    echo "" >> ~/.config/goose/config.yaml
    echo "extensions:" >> ~/.config/goose/config.yaml
fi

# Add Brave Search extension to Goose config
echo "Adding Brave Search to Goose configuration..."

# Create a temporary file with the new extension
cat > /tmp/brave-search-extension.yaml << EOF
  brave-search:
    name: brave-search
    cmd: npx
    args:
      - -y
      - "@brave/brave-search-mcp-server"
    enabled: true
    envs:
      BRAVE_API_KEY: "$BRAVE_API_KEY"
    type: stdio
    timeout: 300
EOF

# Check if brave-search already exists in config
if grep -q "brave-search:" ~/.config/goose/config.yaml 2>/dev/null; then
    echo "✅ Brave Search extension already configured"
else
    # Insert the extension into the extensions section (before GOOSE_TELEMETRY_ENABLED)
    if grep -q "GOOSE_TELEMETRY_ENABLED:" ~/.config/goose/config.yaml 2>/dev/null; then
        # Insert before GOOSE_TELEMETRY_ENABLED
        sed -i '/GOOSE_TELEMETRY_ENABLED:/i\  brave-search:\
    name: brave-search\
    cmd: npx\
    args:\
      - -y\
      - "@brave/brave-search-mcp-server"\
    enabled: true\
    envs:\
      BRAVE_API_KEY: "'$BRAVE_API_KEY'"\
    type: stdio\
    timeout: 300' ~/.config/goose/config.yaml
    else
        # Append to end of extensions section  
        cat /tmp/brave-search-extension.yaml >> ~/.config/goose/config.yaml
    fi
    echo "✅ Brave Search extension added to Goose config"
fi

# Clean up
rm -f /tmp/brave-search-extension.yaml

# Test the official Brave Search MCP server
echo ""
echo "Testing official Brave Search MCP server..."
export BRAVE_API_KEY="$BRAVE_API_KEY"

# Test if the official server loads
echo "Checking if @brave/brave-search-mcp-server is available..."
if timeout 3 npx -y @brave/brave-search-mcp-server < /dev/null > /dev/null 2>&1; then
    echo "✅ Official Brave Search MCP server is working!"
    TEST_RESULT=0
else
    echo "⚠️  Official server test inconclusive (this is normal)"
    # Test API directly as fallback
    echo "Testing Brave Search API directly..."
    RESPONSE=$(curl -s -w "%{http_code}" \
        -H "Accept: application/json" \
        -H "X-Subscription-Token: $BRAVE_API_KEY" \
        "https://api.search.brave.com/res/v1/web/search?q=test&count=1" \
        -o /dev/null)
    
    echo "Response status: $RESPONSE"
    if [ "$RESPONSE" = "200" ]; then
        echo "✅ Brave Search API is working!"
        TEST_RESULT=0
    else
        echo "❌ API test failed with status: $RESPONSE"
        TEST_RESULT=1
    fi
fi

rm -f test-server.js

echo ""
echo "============================================"

if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ Setup Complete!"
    echo "============================================"
    echo ""
    echo "Brave Search is now configured for Goose!"
    echo ""
    echo "Available commands in Goose:"
    echo "  • Web search: 'Search the web for...'"
    echo "  • News search: 'Find news about...'"
    echo ""
    echo "For CLI: restart Goose with ./run-goose.sh"
    echo ""
    echo "For Desktop UI: add the extension in Settings > Extensions:"
    echo "  Name:    brave-search"
    echo "  Type:    STDIO"
    echo "  Command: npx -y @brave/brave-search-mcp-server"
    echo "  Env:     BRAVE_API_KEY = $BRAVE_API_KEY"
    echo ""
    echo "Examples:"
    echo "  'Search the web for React best practices'"
    echo "  'Find news about artificial intelligence'"
else
    echo "⚠️  Setup completed but API test failed"
    echo "============================================"
    echo ""
    echo "Please check:"
    echo "1. Your API key is correct"
    echo "2. Your Brave Search API subscription is active"
    echo "3. You haven't exceeded your monthly quota"
    echo ""
    echo "Visit: https://brave.com/search/api/manage"
fi

echo ""
echo "Your API key has been stored in:"
echo "  • $PROJECT_DIR/brave-search-mcp/.env"
echo "  • ~/.config/goose/config.yaml (CLI)"
echo ""
echo "Note: Desktop UI requires adding extensions through its Settings UI."
echo ""
echo "Keep these files secure and don't commit them to git."