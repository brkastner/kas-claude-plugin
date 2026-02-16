---
name: specup
description: >
  Bidirectional bridge between ClickUp and spec-kitty feature specs.
  Use when the user mentions ClickUp tasks, CU- IDs, spec-kitty features,
  creating tasks in ClickUp, importing ClickUp context into specs,
  or exporting spec-kitty specs to ClickUp.
  Provides /specup.setup, /specup.new, /specup.import, and /specup.export commands.
metadata:
  author: brkastner
  version: "1.0.0"
compatibility: >
  Requires ClickUp MCP server (https://mcp.clickup.com/mcp) and
  spec-kitty CLI (pip install spec-kitty-cli).
  Works with any Agent Skills-compatible tool: Crush, Claude Code, Gemini CLI, Cursor, etc.
---

# specup — ClickUp + spec-kitty Bridge

Bidirectional bridge between ClickUp task management and spec-kitty feature specifications.

## When to activate

- User mentions ClickUp tasks, CU- IDs, or ClickUp URLs
- User wants to create a task in ClickUp
- User wants to turn ClickUp context into a spec-kitty feature spec
- User wants to push a spec-kitty feature spec to ClickUp

## Prerequisites

1. **ClickUp MCP server** must be configured and authenticated (see [references/setup.md](references/setup.md))
2. **spec-kitty CLI** must be installed: `pip install spec-kitty-cli`
3. Run `/specup.setup` first to verify connectivity and save the default ClickUp Space

## Available commands

| Command | Description |
|---------|-------------|
| `/specup.setup` | Verify ClickUp MCP auth and save default Space for this project |
| `/specup.new [description]` | Create a ClickUp task from a short interview |
| `/specup.import <reference>` | Import ClickUp task/list context into a new spec-kitty feature spec |
| `/specup.export [NNN]` | Export a spec-kitty feature spec to ClickUp as a folder with docs/lists/tasks |

See the individual command files in `commands/` for full workflow details.

## ClickUp reference parsing

Accept these references in command arguments:

- Task ID: `CU-abc123`, `#abc123`, or `abc123`
- Task URL: `https://app.clickup.com/t/abc123`
- List reference: `list:123456` or list URL forms
- Multiple references: comma- or space-separated

Normalize task IDs before MCP calls: strip `CU-`/`cu-`/`#` prefixes, extract from URLs.

## ClickUp MCP tools

- `clickup_get_task` — fetch task details
- `clickup_create_task` — create task
- `clickup_update_task` — update task status/metadata
- `clickup_create_task_comment` — add comment
- `clickup_create_folder`, `clickup_create_list` — folder/list creation (export)
- `clickup_create_doc` — doc creation (export, fall back to tasks if unavailable)

## Project config

`/specup.setup` saves ClickUp workspace info to `.specup.json` in the project root.
Other commands read this file for the default Space and parent Folder.
If `.specup.json` is missing when a command needs it, prompt the user to run `/specup.setup`.

## Export sync tracking

`/specup.export` persists ClickUp IDs in `FEATURE_DIR/.specup-sync.json` for idempotent updates.

## Lane-to-status mapping (export)

| spec-kitty lane | ClickUp status |
|-----------------|----------------|
| `planned` | to do |
| `doing` | in progress |
| `for_review` | ready for review |
| `done` | complete |
