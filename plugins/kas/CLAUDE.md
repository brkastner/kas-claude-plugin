# kas Plugin - Claude Code Workflow Instructions

## Plugin Development Context

**This is a Claude Code plugin** (`kas-claude-plugins`), not a regular project.

**Plugin structure:**
- `.claude-plugin/plugin.json` - plugin metadata
- `commands/*.md` - slash commands provided by the plugin
- `agents/*.md` - agents provided by the plugin
- `CLAUDE.md` - instructions active when plugin is enabled

**How plugins work:**
- Target projects enable plugins via `.claude/settings.json`
- Once enabled, plugin's commands and agents become available
- Don't confuse plugin code with target project configuration

**When implementing /kas:setup:**
- It sets up a **target project** to use this plugin
- Check if plugin is enabled in target's `.claude/settings.json`

## Context7 Documentation Lookups

**Always use Context7** when looking up library/framework documentation:
- Ensures latest version is referenced (not stale training data)
- Workflow: `resolve-library-id` → `query-docs` → implement
- Use for: code generation, setup steps, API documentation

## How to Use Context

- Your context window will be automatically compacted as it approaches its limit
- Never stop tasks early due to token budget concerns - complete tasks fully
- When writing code, write code as Linus Torvalds would: simple, correct, readable
- When running a sub-agent that does a review, **summarize the findings to me before acting on the results**

## Complete Workflow

```
/kas:start (enter plan mode)
    ↓
Plan Mode (structured exploration + design)
    ↓
Plan Reviewer → ExitPlanMode
    ↓
Session Start: Create branch → Implement
    ↓
Review (pr-review-toolkit) → Quality Gates
    ↓
Claude: Summarizes → "Approve?"
User: Responds with shortcut or explicit approval
    ↓
Session boundary:
├─ Work complete: User: /kas:done → Claude creates PR → User: /kas:merge
└─ Work continues: User: /kas:save → User: /clear → Resume next session
```

**Key:** `/kas:done`, `/kas:save`, `/kas:merge`, `/clear` are USER shortcuts, not Claude automation

**User Checkpoints (mandatory):**
1. After plan-reviewer: user approves plan and findings together
2. After code review agents: summarize findings, get approval before fixes
3. After code-simplifier: summarize suggestions, get approval before applying

## Plan Mode

> Use `/kas:start` to enter plan mode with proper workflow. This ensures review agents run automatically.

- At the end of each plan, give me a list of unresolved questions to answer, if any. Make the questions extremely concise. Sacrifice grammar for the sake of concision.
- Every plan should include high level requirements, architecture decisions, data models, and a robust testing strategy
- Do not save tests for the end - testing should be alongside the relevant requirements

### Plan Reviewer Agent

After creating a plan, run the plan-reviewer agent automatically:
```
"Review this plan for security gaps and design issues"
```

The agent returns structured feedback. Then call ExitPlanMode so user can review everything together (plan + findings).

### After Plan Approval

When user approves (plan + findings shown via ExitPlanMode):

1. **Create worktree** - derive branch from plan title (prefix: `feat/`|`fix/`|`refactor/`, slug: sanitized title, max 30 chars)
2. **Output cd command** for user to switch to worktree
3. **Stop** - user runs `cd` and `/clear` for fresh session

## Git Worktree Workflow

One worktree is created per plan after approval.

### Automatic Creation

After plan approval, Claude:
1. Creates branch + worktree from plan title
2. Outputs `cd` command for user to switch

### Conventions

- **Path**: `.worktrees/<prefix>-<slug>/` (e.g., `.worktrees/feat-user-auth/`)
- **Branch**: `<prefix>/<slug>` (e.g., `feat/user-auth`)
- **Prefix**: `feat/` (default), `fix/` (for Fix:/Bug:), `refactor/` (for Refactor:)

### Working in Worktree

```bash
cd <worktree-path>          # Switch to worktree
# ... work ...
/kas:done                   # Commit + push
/kas:merge                  # Merge PR + auto-cleanup worktree
```

- Use absolute paths for all file operations
- Main repo stays on `main` branch

### PR Workflow

- PR created after first commit (via `/kas:done` then `gh pr create`)
- Always work on feat/ or fix/ branches
- Never commit directly to main unless explicitly requested
- `/kas:merge` cleans up worktree after merging

## Code Review (pr-review-toolkit)

Run relevant agents **before commits**. Agent selection based on what changed:
- Any code changes → `code-reviewer`
- Error handling (try/catch, catch blocks) → + `silent-failure-hunter`
- Comments, docstrings, JSDoc → + `comment-analyzer`
- Type definitions, interfaces, schemas → + `type-design-analyzer`
- Before PR creation → + `pr-test-analyzer`
- After review passes → `code-simplifier` (optional)

### Running Reviews

```bash
# General code review
"Review my recent changes"

# Specific focus
"Check for silent failures in error handling"
"Analyze the comments I added"
"Review the type design for the new models"
```

### Running Multiple Agents

**Parallel** (faster):
```
"Run pr-test-analyzer and comment-analyzer in parallel"
```

**Sequential** (when one informs the other):
```
"First review test coverage, then check code quality"
```

### Review Workflow

1. Run relevant agents
2. **Summarize findings to user**
3. User approves fixes or provides direction
4. Implement fixes
5. Re-run if needed
6. Proceed to quality gates

## Quality Gates

Run before committing. Customize based on your project:

```bash
# Example patterns
npm test              # JavaScript/TypeScript
pytest                # Python
cargo test            # Rust
go test ./...         # Go

# Linting
npm run lint
ruff check .
cargo clippy
```

## Testing Requirements

- Write tests for all new functionality
- Check for proper test coverage using `pr-review-toolkit:pr-test-analyzer`
- Run tests until all pass before marking task complete
- Commit only when tests are green

## Landing the Plane

*Same as `/kas:done`*

**CRITICAL: Work is NOT complete until `git push` succeeds.**

1. Run quality gates (if code changed)
2. Push: `git pull --rebase && git push`
3. Add PR comment (if PR exists)
4. Provide next session prompt

**Output:** Summary of completed work and confirmation all changes pushed.

## Session Management

**These are user shortcuts that preserve the approval flow:** Claude still summarizes and asks for approval before taking action. The user responds with shortcuts instead of verbose approval.

### Approval Shortcuts

User responds to Claude's approval prompts with shortcuts (e.g., `/kas:done`) instead of verbose confirmation.

### /kas:save - Session Snapshot

**When to use:** Multi-session work. Need to pause and free context.

**User types:** `/kas:save`

**Claude responds by:**
1. Taking session snapshot
2. Adding PR comment with status + next prompt
3. Landing the plane (push to remote)
4. Outputting next session prompt to copy

### /clear - Context Reset

**When to use:** After `/kas:save` to free context window

**User types:** `/clear`

**Effect:** Compacts conversation history, maintains critical context, enables fresh start

### Multi-Session Workflow

```
Session 1: Work → Claude asks approval → User: "/kas:save" → User: "/clear"
Session 2: User: [Paste prompt] → Continue → User: "/kas:save" → User: "/clear"
Session 3: User: [Paste prompt] → Complete → User: "/kas:done" → User: "/kas:merge"
```

## PR Merging & Finalization

### /kas:merge - Finalize and Merge PR

**User shortcut** to finalize a feature and merge to main. User types this when ready to merge (typically after PR review passes).

**Usage:**
```bash
/kas:merge              # Infer PR from current branch
/kas:merge 123          # Specific PR number
/kas:merge <PR-URL>     # Direct PR URL
```

**When user types `/kas:merge`, Claude will:**
1. Validate CI passes (waits if pending, asks user if failed)
2. Merge to main with merge commit (preserves code history)
3. Clean up worktree (if applicable)
4. Report completion

**Requirements:**
- CI must pass (green checks)
- No merge conflicts
- Branch must not be main

**User typing `/kas:merge` = user approval to merge** - Claude proceeds without additional confirmation.

## Prerequisites

This plugin works best with these other plugins installed:
- `superpowers` - Brainstorming, subagent spawning, initial reviews (official marketplace)
- `commit-commands` - Git commit automation
- `pr-review-toolkit` - Code review agents
- `context7` - Library documentation lookups
