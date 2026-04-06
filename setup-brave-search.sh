#!/bin/bash

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
cat > /home/kasjens/projects/goose-ollama-minimax/brave-search-mcp/.env << EOF
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
    enabled: true
    type: stdio
    name: brave-search
    description: Web and news search powered by Brave Search API
    display_name: Brave Search
    command: node
    args: ["/home/kasjens/projects/goose-ollama-minimax/brave-search-mcp/index.js"]
    environment:
      BRAVE_API_KEY: "$BRAVE_API_KEY"
    timeout: 300
    bundled: false
    available_tools: ["brave_web_search", "brave_news_search"]
EOF

# Check if brave-search already exists in config
if grep -q "brave-search:" ~/.config/goose/config.yaml 2>/dev/null; then
    echo "Brave Search extension already exists. Updating..."
    # Remove old brave-search config (this is complex, so we'll just notify)
    echo "⚠️  Please manually remove the old brave-search section from ~/.config/goose/config.yaml"
    echo "Then re-run this script."
else
    # Append the new extension
    cat /tmp/brave-search-extension.yaml >> ~/.config/goose/config.yaml
    echo "✅ Brave Search extension added to Goose config"
fi

# Clean up
rm -f /tmp/brave-search-extension.yaml

# Test the MCP server
echo ""
echo "Testing Brave Search MCP server..."
cd /home/kasjens/projects/goose-ollama-minimax/brave-search-mcp
export BRAVE_API_KEY="$BRAVE_API_KEY"

# Create a test script
cat > test-server.js << 'EOF'
import fetch from 'node-fetch';

const apiKey = process.env.BRAVE_API_KEY;
const testQuery = "test query";

console.log("Testing Brave Search API...");
console.log("API Key length:", apiKey ? apiKey.length : 0);

fetch(`https://api.search.brave.com/res/v1/web/search?q=${encodeURIComponent(testQuery)}&count=1`, {
  headers: {
    'Accept': 'application/json',
    'X-Subscription-Token': apiKey,
  },
})
  .then(response => {
    console.log("Response status:", response.status);
    if (response.ok) {
      console.log("✅ Brave Search API is working!");
    } else {
      console.log("❌ API error:", response.statusText);
    }
    process.exit(response.ok ? 0 : 1);
  })
  .catch(error => {
    console.log("❌ Connection error:", error.message);
    process.exit(1);
  });
EOF

node test-server.js
TEST_RESULT=$?

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
    echo "To use Brave Search:"
    echo "1. Restart Goose: cd /home/kasjens/projects/goose-ollama-minimax && ./run-goose.sh"
    echo "2. Ask Goose to search the web"
    echo ""
    echo "Examples:"
    echo "  🪿 Search the web for React best practices 2024"
    echo "  🪿 Find recent news about artificial intelligence"
    echo "  🪿 What are the latest Python 3.13 features?"
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
echo "  • /home/kasjens/projects/goose-ollama-minimax/brave-search-mcp/.env"
echo "  • ~/.config/goose/config.yaml"
echo ""
echo "Keep these files secure and don't commit them to git."