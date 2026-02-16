# ClickUp MCP Setup

## Quick start

1. Ensure `.mcp.json` (or `crush.json` MCP section) includes the ClickUp server:

```json
{
  "mcpServers": {
    "clickup": {
      "type": "http",
      "url": "https://mcp.clickup.com/mcp"
    }
  }
}
```

2. Restart your editor/tool to load the MCP server.
3. On first use, the OAuth flow will prompt for ClickUp login.
4. Run `/specup.setup` to verify connectivity and pick a default Space.

## Manual API token (alternative)

1. ClickUp → Avatar → Settings → Apps → API Token → Generate
2. Copy token (starts with `pk_`)
3. Set environment variable:

```bash
export CLICKUP_API_TOKEN="pk_..."
```

## Troubleshooting

- **OAuth not appearing**: Restart editor, check MCP config
- **Invalid API token**: Ensure token starts with `pk_`, no trailing whitespace
- **Rate limiting**: ClickUp free plans allow 100 requests/minute
- **MCP server unreachable**: Check network, verify URL in config
