# kas Plugin for Claude Code

Workflow automation with beads task tracking, session management, and code review.

## Features

- **Session Management**: `/kas:done`, `/kas:save`, `/kas:next`, `/kas:merge` commands
- **Beads Integration**: Automatic daemon startup, issue tracking, work management
- **Code Review**: Specialized agents for plan review, code review, and reality checking
- **Browser Automation**: Subagent-based browser testing and scraping

## Prerequisites

Install these plugins first:
- `commit-commands` - Git commit automation
- `pr-review-toolkit` - Code review agents
- `context7` - Library documentation lookups

## Installation

### Option 1: Add Marketplace

```bash
# Add the marketplace
/plugin marketplace add brkastner/kas-plugins

# Install the plugin
/plugin install kas@kas-plugins
```

### Option 2: Local Development

```bash
# Clone the repo
git clone https://github.com/brkastner/kas-plugins.git ~/dev/kas-plugins

# Use with Claude Code
claude --plugin-dir ~/dev/kas-plugins
```

## Commands

| Command | Description |
|---------|-------------|
| `/kas:done` | Complete session, push all changes |
| `/kas:save` | Snapshot session for later continuation |
| `/kas:next` | Find next available beads issue |
| `/kas:merge` | Merge PR to main |

## Agents

| Agent | Purpose |
|-------|---------|
| `task-splitter` | Decompose plans into beads issues |
| `plan-reviewer` | Review plans for gaps and issues |
| `code-reviewer` | Ruthless code quality review |
| `browser-automation` | Web testing and automation |
| `project-reality-manager` | Validate claimed completions |

## Hooks

The plugin automatically starts the beads daemon at session start:
```bash
bd daemon --status || bd daemon --start --auto-commit --auto-push
```

## Configuration

### CLAUDE.md Precedence

When using this plugin with a project that has its own CLAUDE.md:
- Project CLAUDE.md instructions take precedence
- Plugin provides base workflow; project adds specifics

### Beads Setup

Each project using this plugin should initialize beads:
```bash
bd init
bd daemon --start --auto-commit --auto-push
```

## Workflow

```
Plan Mode → Plan Reviewer → Task Splitter
    ↓
bd ready → Pick issue → Implement
    ↓
Code Review → Quality Gates → /kas:done
    ↓
Create PR → /kas:merge
```

## License

MIT
