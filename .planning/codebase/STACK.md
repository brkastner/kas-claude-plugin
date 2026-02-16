# Technology Stack

**Analysis Date:** 2026-02-15

## Languages

**Primary:**
- Markdown (.md) - All plugin logic, commands, agents, and skills are written as Markdown instruction files
- Bash (shell) - Setup scripts, hook scripts, and inline command blocks within Markdown instructions

**Secondary:**
- JSON - Configuration manifests (`plugin.json`, `marketplace.json`, `.mcp.json`, `settings.json`)
- YAML - Beads configuration (`.beads/config.yaml`)

## Runtime

**Environment:**
- Claude Code CLI - Primary runtime; plugins are loaded by the Claude Code agent system
- OpenCode (Crush) - Secondary runtime for the `opencode/specup` skill (model-agnostic Agent Skills format)
- No traditional language runtime (Node.js, Python, etc.) — this is a pure declarative plugin repository

**Package Manager:**
- None — no `package.json`, `requirements.txt`, or other dependency manifests
- Plugins are installed via `claude plugin install` or `claude --plugin-dir`
- The `opencode/specup` skill has an `install.sh` bash installer at `opencode/specup/install.sh`

**Lockfile:**
- Not applicable

## Frameworks

**Core:**
- Claude Code Plugin System v2.0.0 - Plugin framework defining `commands/`, `agents/`, `skills/`, `hooks/` structure
- Claude Code Marketplace - Distribution via `.claude-plugin/marketplace.json` at repo root
- OpenCode Agent Skills - Model-agnostic skill format used by `opencode/specup/` (compatible with Crush, Gemini CLI, Cursor, etc.)

**Testing:**
- No automated test framework — validation is manual via `claude plugin validate`

**Build/Dev:**
- No build step — raw Markdown files are used directly by the Claude Code agent
- Git + GitHub - Version control and PR-based release workflow
- `gh` CLI - Required for PR operations within the plugin workflow

## Key Dependencies

**Critical (Runtime Plugins):**
- `superpowers` plugin (marketplace) - Provides `brainstorming`, `subagent-driven-development`, `using-git-worktrees`, `executing-plans` skills. Required by both `kas` and `task` plugins.
- `pr-review-toolkit` plugin (marketplace) - Provides `silent-failure-hunter`, `comment-analyzer`, `type-design-analyzer`, `pr-test-analyzer`, `code-simplifier` agents. Referenced by `kas` plugin's verify workflow.
- `commit-commands` plugin (marketplace) - Git commit automation. Referenced in `plugins/kas/CLAUDE.md`.
- `context7` plugin (marketplace) - Library documentation lookups via MCP. Referenced in `plugins/kas/CLAUDE.md`.

**Critical (External Tools):**
- `gh` CLI ≥ 2.0.0 - GitHub CLI for PR creation, merging, CI checks. Validated by `/kas:setup`.
- `git` ≥ 2.20.0 - Worktree support, version control. Validated by `/kas:setup`.
- `bd` (Beads CLI) - Issue tracking tool. Used for issue management; `.beads/` directory present with SQLite DB and JSONL files.
- `spec-kitty` CLI - Feature spec scaffolding tool. Required by `opencode/specup` skill. Installed via `pip install spec-kitty-cli`.

**Infrastructure (MCP Servers):**
- ClickUp HTTP MCP Server (`https://mcp.clickup.com/mcp`) - Task management API. Configured in `plugins/task/.mcp.json` and `opencode/specup/.mcp.json`.
- Claude-in-Chrome MCP - Browser automation. Referenced by `plugins/kas/agents/browser-automation.md` (tools prefixed `mcp__claude_in_chrome__*`).

## Configuration

**Environment:**
- `.env` files present: No `.env` files detected in repository
- ClickUp authentication: OAuth-based via MCP server (automatic on first use), or manual API token via `CLICKUP_API_TOKEN` and `CLICKUP_TEAM_ID` environment variables
- Review configuration: `KAS_REVIEW_MODEL` and `KAS_REVIEW_VARIANT` env vars override default reviewer model/reasoning level
- `KAS_REVIEW_AGENT` env var overrides the reviewer name in spec-kitty automation

**Plugin enablement (per target project):**
- `.claude/settings.json` - Enable plugins: `{"enabledPlugins": {"kas@kas-claude-plugins": true}}`
- `.claude/settings.local.json` - Local permissions (tool allowlists, not committed)

**MCP server config (per target project):**
- `.mcp.json` - Declares MCP servers (e.g., ClickUp). Located in plugin dirs and target project roots.

**Beads (issue tracking):**
- `.beads/config.yaml` - Beads daemon, sync, and integration settings
- `.beads/metadata.json` - Database file references
- `.beads/beads.db` - SQLite database (gitignored)
- `.beads/issues.jsonl` - JSONL export (synced via git)

**Build:**
- No build configuration — raw Markdown served directly
- `.gitignore` - Excludes `.DS_Store`, editor files, `node_modules/`, `.claude/settings.local.json`, `.beads/`, `.worktrees/`
- `.gitattributes` - Custom merge driver for `.beads/issues.jsonl`

## Platform Requirements

**Development:**
- Claude Code CLI installed and authenticated
- `gh` CLI ≥ 2.0.0 authenticated with `repo` scope
- `git` ≥ 2.20.0 with `user.name` and `user.email` configured
- SSH or HTTPS push access to the GitHub remote

**Production (Consumer Projects):**
- Plugin marketplace added: `claude plugin marketplace add brkastner/kas-claude-plugins`
- Plugin installed: `claude plugin install kas@kas-claude-plugins`
- For task plugin: ClickUp MCP server configured in `.mcp.json`
- For specup: `spec-kitty` CLI (`pip install spec-kitty-cli`)
- For browser automation: Claude-in-Chrome extension running

**Deployment:**
- GitHub repository at `https://github.com/brkastner/kas-claude-plugins`
- Distribution via Claude Code plugin marketplace (no separate deployment target)
- Versioned via git tags and `CHANGELOG.md` (Keep a Changelog format, SemVer)
- Current versions: kas plugin v2.0.0, task plugin v2.0.0, marketplace listing v1.8.0/v1.0.2

---

*Stack analysis: 2026-02-15*
