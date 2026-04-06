#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import fetch from 'node-fetch';

class BraveSearchServer {
  constructor() {
    this.server = new Server(
      {
        name: 'brave-search-mcp',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  setupHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'brave_web_search',
          description: 'Search the web using Brave Search API',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: 'The search query',
              },
              count: {
                type: 'number',
                description: 'Number of results (max 20)',
                default: 10,
              },
              freshness: {
                type: 'string',
                description: 'Filter by recency: pd (past day), pw (past week), pm (past month), py (past year)',
                enum: ['pd', 'pw', 'pm', 'py'],
              },
            },
            required: ['query'],
          },
        },
        {
          name: 'brave_news_search',
          description: 'Search for news articles using Brave Search',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: 'The news search query',
              },
              count: {
                type: 'number',
                description: 'Number of results',
                default: 10,
              },
            },
            required: ['query'],
          },
        },
      ],
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const apiKey = process.env.BRAVE_API_KEY;
      
      if (!apiKey) {
        throw new Error('BRAVE_API_KEY environment variable is not set');
      }

      const { name, arguments: args } = request.params;

      try {
        if (name === 'brave_web_search') {
          return await this.performWebSearch(apiKey, args);
        } else if (name === 'brave_news_search') {
          return await this.performNewsSearch(apiKey, args);
        } else {
          throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error.message}`,
            },
          ],
          isError: true,
        };
      }
    });
  }

  async performWebSearch(apiKey, args) {
    const { query, count = 10, freshness } = args;
    
    const params = new URLSearchParams({
      q: query,
      count: Math.min(count, 20).toString(),
    });
    
    if (freshness) {
      params.append('freshness', freshness);
    }

    const response = await fetch(
      `https://api.search.brave.com/res/v1/web/search?${params}`,
      {
        headers: {
          Accept: 'application/json',
          'X-Subscription-Token': apiKey,
        },
      }
    );

    if (!response.ok) {
      throw new Error(`Brave API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    
    // Format results for better readability
    let formattedResults = `Found ${data.web?.results?.length || 0} results for "${query}"\n\n`;
    
    if (data.web?.results) {
      data.web.results.forEach((result, index) => {
        formattedResults += `${index + 1}. **${result.title}**\n`;
        formattedResults += `   URL: ${result.url}\n`;
        formattedResults += `   ${result.description}\n\n`;
      });
    }

    // Add any featured snippets
    if (data.featured_snippet) {
      formattedResults = `**Featured Snippet:**\n${data.featured_snippet.description}\n\n` + formattedResults;
    }

    return {
      content: [
        {
          type: 'text',
          text: formattedResults,
        },
      ],
    };
  }

  async performNewsSearch(apiKey, args) {
    const { query, count = 10 } = args;
    
    const params = new URLSearchParams({
      q: query,
      count: Math.min(count, 20).toString(),
    });

    const response = await fetch(
      `https://api.search.brave.com/res/v1/news/search?${params}`,
      {
        headers: {
          Accept: 'application/json',
          'X-Subscription-Token': apiKey,
        },
      }
    );

    if (!response.ok) {
      throw new Error(`Brave API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    
    // Format news results
    let formattedResults = `Found ${data.results?.length || 0} news articles for "${query}"\n\n`;
    
    if (data.results) {
      data.results.forEach((article, index) => {
        formattedResults += `${index + 1}. **${article.title}**\n`;
        formattedResults += `   Source: ${article.source || 'Unknown'}\n`;
        formattedResults += `   Date: ${article.age || 'Unknown'}\n`;
        formattedResults += `   URL: ${article.url}\n`;
        formattedResults += `   ${article.description}\n\n`;
      });
    }

    return {
      content: [
        {
          type: 'text',
          text: formattedResults,
        },
      ],
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Brave Search MCP server running on stdio');
  }
}

const server = new BraveSearchServer();
server.run().catch(console.error);