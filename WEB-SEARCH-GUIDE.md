# Web Search Capability for Goose AI

## Overview
Goose AI supports web search through MCP (Model Context Protocol) servers. This guide covers multiple options for adding web search functionality to your Goose setup.

## Quick Setup
Run the automated setup script:
```bash
./setup-websearch.sh
```

## Available Options

### 1. Tavily Search (Recommended for Ease of Use)

**Pros:**
- Easy setup - just need API key
- AI-optimized search results
- Good for research and fact-checking
- Free tier available (1000 searches/month)

**Setup:**
1. Get API key from [tavily.com](https://tavily.com)
2. Run setup script and choose option 1
3. Or manually add to `~/.config/goose/config.yaml`:

```yaml
extensions:
  tavily-search:
    enabled: true
    type: stdio
    name: tavily-search
    description: Web search powered by Tavily AI
    display_name: Tavily Web Search
    command: npx
    args: ["-y", "tavily-mcp"]
    environment:
      TAVILY_API_KEY: "your-api-key-here"
    timeout: 300
```

### 2. SearxNG (Best for Privacy)

**Pros:**
- Complete privacy - self-hosted
- No API limits or costs
- Aggregates results from multiple search engines
- Customizable search engines and settings

**Cons:**
- Requires Docker
- Uses local resources
- More complex setup

**Setup:**
1. Ensure Docker is installed
2. Run setup script and choose option 2
3. Access web UI at http://localhost:8888

**Manual Setup:**
```bash
# Start SearxNG with Docker
docker run -d \
  --name searxng \
  -p 8888:8080 \
  -v ./searxng:/etc/searxng \
  -e SEARXNG_BASE_URL=http://localhost:8888/ \
  searxng/searxng:latest

# Install MCP server
npm install -g @ihor-sokoliuk/mcp-searxng
```

### 3. Brave Search

**Pros:**
- Privacy-focused
- Independent search index
- Good for general web search
- Free tier available (2000 queries/month)

**Setup:**
1. Get API key from [brave.com/search/api](https://brave.com/search/api/)
2. Run setup script and choose option 3

### 4. Alternative: Google Custom Search

If you prefer Google results, you can set up a custom MCP server:

```bash
# Install Google Search MCP
npm install -g @modelcontextprotocol/server-google-search

# Add to Goose config
```

## Using Web Search in Goose

Once configured, you can use web search naturally in your conversations:

```
🪿 Search the web for the latest news about MiniMax AI
🪿 What are the current best practices for React in 2024?
🪿 Find recent research papers about transformer models
🪿 Search for Python pandas performance optimization tips
```

## MCP Server Architecture

```
Goose Session
    ↓
MCP Client (in Goose)
    ↓
MCP Server (Extension)
    ↓
Search Provider API
    ↓
Search Results
```

## Troubleshooting

### Extension Not Loading
1. Check Goose config syntax: `cat ~/.config/goose/config.yaml`
2. Ensure proper indentation (2 spaces)
3. Restart Goose after config changes

### API Key Issues
- Tavily: Ensure key is from correct region
- Brave: Check API quota hasn't been exceeded
- Set keys in environment or config file

### SearxNG Issues
```bash
# Check if running
docker ps | grep searxng

# View logs
docker logs searxng

# Restart
docker restart searxng
```

### Windows-Specific Issues
- Environment variables may not pass correctly to STDIO extensions
- Consider using WSL or remote MCP servers

## Performance Tips

1. **Cache Results**: Some MCP servers cache results automatically
2. **Rate Limiting**: Be aware of API limits for free tiers
3. **Local First**: SearxNG avoids API limits entirely

## Security Considerations

1. **API Keys**: Never commit API keys to git
2. **Self-Hosted**: SearxNG keeps all searches private
3. **HTTPS**: Ensure secure connections for API calls

## Advanced Configuration

### Multiple Search Providers
You can enable multiple search extensions and Goose will choose the appropriate one:

```yaml
extensions:
  tavily-search:
    enabled: true
    # ... config
  searxng-search:
    enabled: true
    # ... config
  brave-search:
    enabled: false  # Disabled but available
    # ... config
```

### Custom Search Engines
For SearxNG, edit `searxng/settings.yml` to add/remove search engines:

```yaml
engines:
  - name: arxiv
    engine: arxiv
    shortcut: arx
  - name: stackexchange
    engine: stackexchange
    shortcut: se
```

## Comparison Table

| Feature | Tavily | SearxNG | Brave | Google CSE |
|---------|--------|---------|-------|------------|
| **Setup Ease** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Privacy** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **Free Tier** | 1000/mo | Unlimited | 2000/mo | 100/day |
| **AI Optimized** | Yes | No | No | No |
| **Self-Hosted** | No | Yes | No | No |
| **Speed** | Fast | Medium | Fast | Fast |

## Resources

- [MCP Protocol Docs](https://modelcontextprotocol.io/)
- [Goose Extensions Guide](https://block.github.io/goose/docs/extensions)
- [Tavily API Docs](https://docs.tavily.com/)
- [SearxNG Docs](https://docs.searxng.org/)
- [Brave Search API](https://brave.com/search/api/)

## Contributing

To create your own search MCP server:
1. Use the MCP SDK: `@modelcontextprotocol/sdk`
2. Implement search tool handler
3. Package as npm module or standalone script
4. Add to Goose config as STDIO extension