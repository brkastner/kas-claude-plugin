# kas Plugin for Claude Code

Workflow automation with [beads](https://github.com/steveyegge/beads) task tracking, session management, and code review.

## Prerequisites

- [beads](https://github.com/steveyegge/beads) - Local-first issue tracking
- [GitHub CLI](https://cli.github.com/) - PR workflows
- `pr-review-toolkit` plugin - Extended code review (optional but recommended)

## Installation

### Option 1: Add Marketplace

```bash
# Add the marketplace
/plugin marketplace add brkastner/kas-claude-plugin

# Install the plugin
/plugin install kas@kas-claude-plugin
```

### Option 2: Local Development

```bash
# Clone the repo
git clone https://github.com/brkastner/kas-claude-plugin.git ~/dev/kas-claude-plugin

# Use with Claude Code
claude --plugin-dir ~/dev/kas-claude-plugin
```

## How It Works

### What Happens Automatically

During plan mode, Claude automatically runs review agents:

1. **plan-reviewer** - Reviews your plan for security/design gaps
2. **task-splitter** - Prepares beads issues from your plan

You see the results and approve before anything is created.

### Commands You Invoke

| Command | When to Use |
|---------|------------|
| `/kas:next` | Find available work to claim |
| `/kas:done` | Complete session (commit, push, close issues) |
| `/kas:save` | Pause session for later continuation |
| `/kas:merge` | Merge PR to main |
| `/kas:verify` | Run full review suite before committing |

The standalone review commands (`/kas:review-code`, `/kas:review-plan`, `/kas:review-reality`) are available when you want just one type of review instead of the full suite.

### What You Customize

In your project's `CLAUDE.md`, define:

- **Quality gates** - Test/lint commands to run before commits (e.g., `npm test && npm run lint`)
- **Branch naming** - Conventions for your project
- **Beads categories** - How to categorize issues for your workflow

## Workflow

```
PLAN MODE
├─ Write implementation plan
├─ plan-reviewer (auto) → summarizes findings
├─ task-splitter (auto) → prepares bd create commands
└─ ExitPlanMode → user reviews plan + findings + commands
       ↓
USER APPROVAL (approves everything at once)
├─ Claude executes bd create commands
├─ Claude stops (provides next session prompt)
└─ User: /clear (free context)
       ↓
IMPLEMENTATION (one or more sessions)
├─ [Paste continuation prompt]
├─ /kas:next → pick issue → implement
├─ /kas:verify (code + reality review)
├─ Quality gates (tests, linting)
├─ /kas:save (if continuing) OR /kas:done (if complete)
└─ [If /kas:save: /clear → next session]
       ↓
FINALIZATION
├─ /kas:done → commit, push, close issues
├─ Create PR (gh pr create)
└─ /kas:merge → merge to main, delete branch
```

## Commands

| Command | Description |
|---------|-------------|
| `/kas:done` | Complete session: commit, push, close issues, verify daemon |
| `/kas:save` | Snapshot session: push work, generate continuation prompt |
| `/kas:next` | Find next available beads issue to work on |
| `/kas:merge` | Merge PR to main, delete branch |
| `/kas:verify` | Tiered verification: static analysis → reality check → simplifier |
| `/kas:review-code` | Standalone code quality review |
| `/kas:review-reality` | Standalone reality assessment |
| `/kas:review-plan` | Review plan for security gaps and design issues |

## Agents

| Agent | Purpose | Trigger |
|-------|---------|---------|
| `plan-reviewer` | Review plans for gaps/security | Auto after plan written |
| `task-splitter` | Decompose plans into beads issues | Auto after plan-reviewer |
| `code-reviewer` | Ruthless code quality review | Via /kas:review-code or /kas:verify |
| `project-reality-manager` | Validate claimed completions | Via /kas:review-reality or /kas:verify |
| `browser-automation` | Web testing and automation | Detected via skill pattern |

## Critical Rules

1. **Work is NOT complete until `git push` succeeds** - Never stop before pushing
2. **Summarize findings before proceeding** - After reviews, get user approval before applying fixes
3. **Quality gates must pass** - Run tests before committing

## Beads Integration

The plugin auto-starts the beads daemon on session start, syncing to the `util/beads-sync` branch. See [beads documentation](https://github.com/steveyegge/beads) for CLI usage.

## License

MIT
