# specup

Bidirectional bridge between ClickUp and spec-kitty feature specs.

Model-agnostic. Works with Crush, OpenCode, Claude Code, Gemini CLI, Cursor, and any tool that supports [Agent Skills](https://agentskills.io) or custom commands.

## What it does

- `/specup.setup` — verify ClickUp MCP auth, save default Space for this project
- `/specup.new [description]` — create a ClickUp task from a short interview
- `/specup.import <reference>` — import ClickUp task/list into a spec-kitty feature spec
- `/specup.export [NNN]` — export a spec-kitty feature spec to ClickUp as a folder

## Layout

```
specup/
├── SKILL.md             # Agent Skills entry point (cross-tool discovery)
├── AGENTS.md            # Project-level instructions (loaded by Crush/OpenCode)
├── .mcp.json            # ClickUp MCP server config
├── install.sh           # Installer script
├── commands/            # Custom command files
│   ├── specup.setup.md
│   ├── specup.new.md
│   ├── specup.import.md
│   └── specup.export.md
└── references/
    └── setup.md         # ClickUp auth & MCP setup guide
```

## Installation

### Prerequisites

1. ClickUp account
2. spec-kitty CLI: `pip install spec-kitty-cli`
3. A project using spec-kitty conventions (`kitty-specs/`)

### Install into a project

```bash
git clone https://github.com/brkastner/specup.git ~/.local/share/specup

# Install into your project
~/.local/share/specup/install.sh /path/to/your/project
```

The installer:
1. Copies command files to `<project>/.opencode/commands/`
2. Symlinks the skill to `~/.config/crush/skills/specup` (user-level, for Crush)
3. Creates or merges `.mcp.json` with the ClickUp server entry
4. Adds `.specup.json` and `.specup-sync.json` to `.gitignore`

### Manual install

If you prefer not to use the script:

1. Copy `commands/specup.*.md` to your project's `.opencode/commands/` (or equivalent)
2. Copy or symlink this directory to your skills path (e.g., `~/.config/crush/skills/specup`)
3. Add the ClickUp MCP server to your project's `.mcp.json` or `crush.json`:

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

## Quick start

```bash
# First-time: verify MCP and pick your default ClickUp Space
/specup.setup

# Create a task in ClickUp
/specup.new add retries to sync pipeline

# Import a task into a new spec-kitty feature spec
/specup.import CU-86dzburuf

# Import a list into one consolidated feature spec
/specup.import list:123456789

# Export feature 011 to ClickUp
/specup.export 011
```

## How it works

### `/specup.setup`

Verifies ClickUp MCP connectivity and auth. Lists Spaces, lets you pick a default. Optionally selects a parent Folder. Saves config to `.specup.json` (git-ignored).

### `/specup.new`

Interviews for task type, description, and acceptance criteria. Creates task via `clickup_create_task`. Returns task ID + URL. Offers follow-up with `/specup.import`.

### `/specup.import`

Accepts flexible ClickUp references (task IDs, URLs, list IDs, multiples). Fetches context via MCP, runs a scope-proportional discovery interview, scaffolds feature with `spec-kitty agent feature create-feature`, writes `meta.json` and `spec.md`. Stops and suggests `/spec-kitty.plan`.

### `/specup.export`

Fuzzy-matches argument to a `kitty-specs/NNN-*` directory. Creates a ClickUp Folder, uploads docs (spec, plan, research, etc.) as ClickUp Docs, exports WPs as tasks in a List with subtasks and lane-to-status mapping. Idempotent via `.specup-sync.json` tracking.

## Compatibility

specup uses two distribution mechanisms:

| Mechanism | Tools | How |
|-----------|-------|-----|
| **Agent Skills** (`SKILL.md`) | Crush, Claude Code, Gemini CLI, Cursor, Roo Code, etc. | Auto-discovered when ClickUp/spec-kitty topics are mentioned |
| **Custom commands** (`commands/*.md`) | OpenCode, Crush | Explicit `/specup.*` invocation |

Both mechanisms use the same underlying command files.

## Notes

- Designed as a planning bridge (ClickUp <-> spec-kitty), not full delivery orchestration.
- Intentionally omits start/done/merge commands.
