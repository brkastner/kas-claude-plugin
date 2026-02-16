# External Integrations

**Analysis Date:** 2026-02-15

## APIs & External Services

**ClickUp (Task Management):**
- Used for task tracking, status management, and PR linking
- SDK/Client: ClickUp HTTP MCP Server
- URL: `https://mcp.clickup.com/mcp`
- Auth: OAuth (automatic on first use) or `CLICKUP_API_TOKEN` env var + `CLICKUP_TEAM_ID`
- Config files: `plugins/task/.mcp.json`, `opencode/specup/.mcp.json`
- MCP tools used:
  - `clickup_get_task` - Fetch task details
  - `clickup_create_task` - Create new tasks
  - `clickup_update_task` - Update status/metadata
  - `clickup_create_task_comment` - Add comments (PR links, status updates)
  - `clickup_get_task_comments` - Read task comments
  - `clickup_create_folder` - Create ClickUp folders (specup export)
  - `clickup_create_list` - Create ClickUp lists (specup export)
  - `clickup_create_doc` - Create ClickUp docs (specup export, with task fallback)
  - `clickup_get_spaces` - List spaces (specup setup)
  - `clickup_get_teams` - Verify auth/connectivity (specup setup)
- Delegation patterns:
  - **task plugin** (Claude Code): All ClickUp calls go through `clickup-task-agent` subagent (haiku model) to keep main context clean. See `plugins/task/agents/clickup-task-agent.md`.
  - **specup** (OpenCode): Calls ClickUp MCP tools directly (no subagent pattern). See `opencode/specup/AGENTS.md`.
- Task ID normalization: Strip `CU-`/`cu-`/`#` prefixes, extract from URLs. Implemented in `plugins/task/agents/clickup-task-agent.md`.

**GitHub (Code Hosting & CI):**
- Used for PR creation, merge, CI status checks, and code review workflow
- SDK/Client: `gh` CLI (GitHub CLI ≥ 2.0.0)
- Auth: `gh auth login` with `repo` scope
- No MCP server — direct CLI calls via Bash
- Operations used:
  - `gh pr create` - Create PRs with `[CU-xxx]` prefix titles
  - `gh pr view` - Check PR state, URL, mergeability
  - `gh pr merge --merge --delete-branch` - Merge with merge commit strategy
  - `gh pr checks` - Verify CI status (wait up to 5 min, check every 30s)
  - `gh pr comment` - Add session status comments to PRs
  - `gh auth status` - Validate authentication and scopes
- Referenced in: `plugins/kas/commands/done.md`, `plugins/kas/commands/merge.md`, `plugins/kas/commands/save.md`, `plugins/kas/commands/setup.md`

**Claude-in-Chrome (Browser Automation):**
- Used for web testing, UI interaction, scraping, and screenshot/GIF capture
- SDK/Client: Claude-in-Chrome MCP extension
- Auth: Browser extension (local, no API key)
- MCP tools (all prefixed `mcp__claude_in_chrome__`):
  - `javascript_tool` - Execute JS in page context
  - `read_page`, `get_page_text` - Read page content
  - `find` - Find elements via natural language
  - `form_input` - Fill forms
  - `computer` - Click/interact
  - `navigate` - Navigate to URLs
  - `resize_window` - Responsive testing
  - `gif_creator`, `upload_image` - Visual capture
  - `tabs_context_mcp`, `tabs_create_mcp` - Tab management
  - `read_console_messages`, `read_network_requests` - Debugging
  - `shortcuts_list`, `shortcuts_execute` - Browser shortcuts
  - `update_plan` - Plan tracking
- Delegation: All browser ops go through `browser-automation` agent subagent. See `plugins/kas/agents/browser-automation.md` and `plugins/kas/skills/browser/SKILL.md`.

**Beads (Issue Tracking):**
- Used for local issue/task tracking within the repository
- SDK/Client: `bd` CLI (Beads CLI)
- Auth: None (local tool)
- Storage: `.beads/beads.db` (SQLite), `.beads/issues.jsonl` (JSONL export for git sync)
- Config: `.beads/config.yaml`
- Operations: `bd create`, `bd update`, `bd close`, `bd list`, `bd show`, `bd daemon`, `bd dep add`, `bd sync`
- Git integration: Custom merge driver for JSONL files (`.gitattributes`), sync branch strategy
- Referenced in: `.claude/settings.local.json` (permission allowlists)

**spec-kitty (Feature Spec Management):**
- Used for feature specification scaffolding and task planning
- SDK/Client: `spec-kitty` CLI (`pip install spec-kitty-cli`)
- Auth: None (local tool)
- Operations:
  - `spec-kitty agent feature create-feature "<slug>" --json` - Create feature scaffold
  - `spec-kitty agent tasks move-task <WP> --feature <spec> --to <lane>` - Move work packages between lanes
  - `spec-kitty --version` - Verify installation
- Referenced in: `opencode/specup/commands/specup.import.md`, `plugins/kas/.opencode/command/kas.review.md`
- Integration: specup skill bridges spec-kitty with ClickUp bidirectionally

## Data Storage

**Databases:**
- Beads SQLite: `.beads/beads.db` (local issue tracking, gitignored)
  - Client: `bd` CLI
  - Schema: Managed by beads tool (issues, interactions, metadata)
  - Sync: JSONL export to `.beads/issues.jsonl` for git-based sharing

**File Storage:**
- Local filesystem only
- Plan files: `.claude/plans/<name>.md` (created during plan mode)
- Session files: `.claude/task-session.json` (temporary, created by task:start, cleaned by task:done)
- Specup config: `.specup.json` (per-project ClickUp workspace config, gitignored)
- Specup sync: `FEATURE_DIR/.specup-sync.json` (per-feature ClickUp ID tracking, gitignored)
- Review feedback: `.kas/review-<WP>.feedback.md`, `.kas/review-<WP>.last.txt`
- Worktrees: `.worktrees/<prefix>-<slug>/` (gitignored)

**Caching:**
- None

## Authentication & Identity

**Auth Providers:**
- GitHub OAuth: Via `gh auth login` - authenticates git push and PR operations
- ClickUp OAuth: Via MCP server at `https://mcp.clickup.com/mcp` - automatic browser-based OAuth on first use
- ClickUp API Token (alternative): Manual `pk_*` token via `CLICKUP_API_TOKEN` env var. See `plugins/task/skills/task-workflow/references/setup.md`.

**Implementation:**
- No custom auth code — all authentication delegated to external tools (`gh`, ClickUp MCP)
- Permission model: Claude Code's `.claude/settings.local.json` defines tool-level permission allowlists

## Monitoring & Observability

**Error Tracking:**
- None — no external error tracking service

**Logs:**
- Beads daemon: `.beads/daemon.log`, `.beads/daemon-error`
- Plugin operations: Claude Code conversation context (ephemeral)
- No structured logging framework

## CI/CD & Deployment

**Hosting:**
- GitHub (`https://github.com/brkastner/kas-claude-plugins`)

**CI Pipeline:**
- No automated CI pipeline detected (no `.github/workflows/`, no CI config files)
- Validation is manual: `claude plugin validate ./plugins/your-plugin`

**Distribution:**
- Claude Code Plugin Marketplace:
  1. `claude plugin marketplace add brkastner/kas-claude-plugins`
  2. `claude plugin install kas@kas-claude-plugins`
- Local development: `claude --plugin-dir ./plugins/kas`
- OpenCode specup: Manual install via `opencode/specup/install.sh`

## Environment Configuration

**Required env vars (for full functionality):**
- None strictly required for kas plugin alone (uses `gh` CLI auth)
- `CLICKUP_API_TOKEN` - Only if using manual ClickUp auth instead of OAuth
- `CLICKUP_TEAM_ID` - Only if using manual ClickUp auth

**Optional env vars:**
- `KAS_REVIEW_MODEL` - Override review agent model (default: `anthropic/claude-opus-4-6`)
- `KAS_REVIEW_VARIANT` - Override review reasoning level (default: `high`)
- `KAS_REVIEW_AGENT` - Override reviewer name in spec-kitty automation (default: `reviewer`)
- `CRUSH_SKILLS_DIR` - Override Agent Skills install directory (default: `~/.config/crush/skills`)

**Secrets location:**
- GitHub auth: Managed by `gh auth` token store
- ClickUp auth: Managed by MCP server OAuth session or `CLICKUP_API_TOKEN` env var
- No `.env` files in this repository
- `.gitignore` does not explicitly list `.env*` (but plugin operates on target projects which should)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- ClickUp task comments with PR URLs (via `clickup_create_task_comment`)
- GitHub PR comments with session status (via `gh pr comment`)

## Plugin Dependency Graph

```
task plugin
├── kas plugin (done, merge, verify, review-plan commands)
├── superpowers plugin (brainstorming, subagent-driven-development, etc.)
└── ClickUp MCP server

kas plugin
├── superpowers plugin (optional, for brainstorming in /kas:start)
├── pr-review-toolkit plugin (for verify workflow agents)
├── commit-commands plugin (git commit automation)
├── context7 plugin (documentation lookups)
└── Claude-in-Chrome MCP (browser automation, optional)

specup skill (opencode)
├── ClickUp MCP server
└── spec-kitty CLI
```

## MCP Server Configurations

**ClickUp (used by task plugin and specup):**
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
- Files: `plugins/task/.mcp.json`, `opencode/specup/.mcp.json`

**Claude-in-Chrome (used by kas browser-automation agent):**
- Configured externally via browser extension
- No `.mcp.json` entry — tools available when extension is running

---

*Integration audit: 2026-02-15*
