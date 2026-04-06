#!/bin/bash

# Web Search Setup for Goose AI
# Provides multiple options for adding web search capability

echo "============================================"
echo "Web Search Setup for Goose AI"
echo "============================================"
echo ""

# Function to add Tavily extension
setup_tavily() {
    echo "Setting up Tavily Web Search..."
    echo "--------------------------------"
    
    # Check if API key is provided
    if [ -z "$1" ]; then
        echo "Please get your Tavily API key from: https://tavily.com"
        read -p "Enter your Tavily API key: " TAVILY_KEY
    else
        TAVILY_KEY=$1
    fi
    
    # Create extension config for Goose
    cat >> ~/.config/goose/config.yaml << EOF

  tavily-search:
    enabled: true
    type: stdio
    name: tavily-search
    description: Web search powered by Tavily AI
    display_name: Tavily Web Search
    command: npx
    args: ["-y", "tavily-mcp"]
    environment:
      TAVILY_API_KEY: "$TAVILY_KEY"
    timeout: 300
    bundled: false
    available_tools: []
EOF
    
    echo "✅ Tavily Web Search configured!"
    echo "   You can now use web search in Goose sessions"
}

# Function to set up SearxNG (self-hosted)
setup_searxng() {
    echo "Setting up SearxNG (Self-Hosted)..."
    echo "-----------------------------------"
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is required for SearxNG. Please install Docker first."
        return 1
    fi
    
    # Create SearxNG docker-compose file
    cat > searxng-docker-compose.yml << 'EOF'
version: '3.7'

services:
  searxng:
    image: searxng/searxng:latest
    container_name: searxng
    ports:
      - "8888:8080"
    volumes:
      - ./searxng:/etc/searxng
    environment:
      - SEARXNG_BASE_URL=http://localhost:8888/
    restart: unless-stopped

  redis:
    image: redis:alpine
    container_name: searxng-redis
    command: redis-server --save 30 1 --loglevel warning
    restart: unless-stopped
    volumes:
      - searxng-redis:/data

volumes:
  searxng-redis:
EOF
    
    # Create SearxNG config directory
    mkdir -p searxng
    
    # Create settings.yml
    cat > searxng/settings.yml << 'EOF'
general:
  instance_name: "Local SearxNG"
  contact_url: false
  enable_metrics: false

search:
  safe_search: 0
  autocomplete: "duckduckgo"
  default_lang: "en"
  
server:
  secret_key: "$(openssl rand -hex 32)"
  
ui:
  default_theme: simple
  query_in_title: true
  
enabled_plugins:
  - 'Hash plugin'
  - 'Search on category select'
  - 'Tracker URL remover'
  
engines:
  - name: duckduckgo
    engine: duckduckgo
    shortcut: ddg
  - name: google
    engine: google
    shortcut: g
  - name: bing
    engine: bing
    shortcut: bi
  - name: wikipedia
    engine: wikipedia
    shortcut: wp
  - name: github
    engine: github
    shortcut: gh
EOF
    
    echo "Starting SearxNG with Docker..."
    docker-compose -f searxng-docker-compose.yml up -d
    
    # Install SearxNG MCP server
    echo "Installing SearxNG MCP server..."
    npm install -g @jay4242/mcp_searxng_search
    
    # Add to Goose config
    cat >> ~/.config/goose/config.yaml << EOF

  searxng-search:
    enabled: true
    type: stdio
    name: searxng-search
    description: Private web search via local SearxNG
    display_name: SearxNG Search
    command: mcp-searxng
    args: []
    environment:
      SEARXNG_URL: "http://localhost:8888"
    timeout: 300
    bundled: false
    available_tools: []
EOF
    
    echo "✅ SearxNG configured and running!"
    echo "   Access web interface: http://localhost:8888"
    echo "   Web search now available in Goose"
}

# Function to add Brave Search
setup_brave() {
    echo "Setting up Brave Search API..."
    echo "------------------------------"
    
    if [ -z "$1" ]; then
        echo "Get your Brave Search API key from: https://brave.com/search/api/"
        read -p "Enter your Brave Search API key: " BRAVE_KEY
    else
        BRAVE_KEY=$1
    fi
    
    # Create a simple MCP wrapper script
    cat > brave-search-mcp.js << 'EOF'
#!/usr/bin/env node

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const fetch = require('node-fetch');

const BRAVE_API_KEY = process.env.BRAVE_API_KEY;
const BRAVE_API_URL = 'https://api.search.brave.com/res/v1/web/search';

class BraveSearchServer {
  constructor() {
    this.server = new Server({
      name: 'brave-search',
      version: '1.0.0',
    }, {
      capabilities: {
        tools: {},
      },
    });

    this.server.setRequestHandler('listTools', async () => ({
      tools: [{
        name: 'brave_search',
        description: 'Search the web using Brave Search',
        inputSchema: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'The search query',
            },
            count: {
              type: 'number',
              description: 'Number of results to return',
              default: 10,
            },
          },
          required: ['query'],
        },
      }],
    }));

    this.server.setRequestHandler('callTool', async (request) => {
      if (request.params.name === 'brave_search') {
        const { query, count = 10 } = request.params.arguments;
        
        const response = await fetch(`${BRAVE_API_URL}?q=${encodeURIComponent(query)}&count=${count}`, {
          headers: {
            'Accept': 'application/json',
            'X-Subscription-Token': BRAVE_API_KEY,
          },
        });
        
        const data = await response.json();
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify(data.web?.results || [], null, 2),
          }],
        };
      }
    });
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
  }
}

new BraveSearchServer().run();
EOF
    
    chmod +x brave-search-mcp.js
    
    # Install dependencies
    npm install @modelcontextprotocol/sdk node-fetch
    
    # Add to Goose config
    cat >> ~/.config/goose/config.yaml << EOF

  brave-search:
    enabled: true
    type: stdio
    name: brave-search
    description: Web search via Brave Search API
    display_name: Brave Search
    command: node
    args: ["$PWD/brave-search-mcp.js"]
    environment:
      BRAVE_API_KEY: "$BRAVE_KEY"
    timeout: 300
    bundled: false
    available_tools: []
EOF
    
    echo "✅ Brave Search configured!"
}

# Main menu
echo "Choose web search option for Goose:"
echo ""
echo "1. Tavily (Easiest - Requires API key)"
echo "2. SearxNG (Self-hosted - Privacy focused)"
echo "3. Brave Search (Requires API key)"
echo "4. Install all options"
echo "5. Exit"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        setup_tavily
        ;;
    2)
        setup_searxng
        ;;
    3)
        setup_brave
        ;;
    4)
        echo "Installing all web search options..."
        setup_tavily
        echo ""
        setup_searxng
        echo ""
        setup_brave
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "============================================"
echo "Setup Complete!"
echo "============================================"
echo ""
echo "To use web search in Goose:"
echo "1. Restart Goose: ./run-goose.sh"
echo "2. In your session, ask Goose to search the web"
echo "   Example: 'Search the web for latest MiniMax AI news'"
echo ""
echo "Note: Extensions will be loaded automatically when Goose starts"