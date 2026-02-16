# Architecture

**Analysis Date:** 2026-02-15

## Pattern Overview

**Overall:** Plugin Marketplace with Declarative Markdown Architecture

This is a **Claude Code plugin marketplace** — a repository of AI agent plugins composed entirely of declarative Markdown files. There is zero runtime code (no TypeScript, Python, or compiled artifacts). All behavior is defined through structured Markdown documents that Claude Code interprets as commands, agents, and skills.

**Key Characteristics:**
- No source code — all logic is encoded in Markdown instruction files
- Plugin-based composition — plugins are self-contained directories with manifest files
- Layered delegation — commands → agents (subagents) → MCP tools → external APIs
- Multi-tool compatibility — plugins target Claude Code, OpenCode/Crush, and Agent Skills-compatible tools
- Marketplace distribution — plugins are registered in a central manifest and installed via `claude plugin install`

## Layers

**Marketplace Layer:**
- Purpose: Registers and distributes plugins to Claude Code instances
- Location: `.claude-plugin/marketplace.json`
- Contains: Plugin metadata, version, source paths, categories
- Depends on: Nothing (top-level registry)
- Used by: `claude plugin marketplace list`, `claude plugin install`

**Plugin Layer:**
- Purpose: Self-contained workflow automation packages
- Location: `plugins/<name>/` (e.g., `plugins/kas/`, `plugins/task/`)
- Contains: Plugin manifest (`.claude-plugin/plugin.json`), commands, agents, skills, instructions
- Depends on: Marketplace registration, Claude Code plugin runtime
- Used by: Target projects that enable the plugin via `.claude/settings.json`

**Command Layer:**
- Purpose: User-invokable slash commands that define workflows
- Location: `plugins/<name>/commands/*.md`
- Contains: Step-by-step workflow instructions, error handling tables, integration contracts
- Depends on: Agent layer (delegates review/assessment), Claude Code tools (EnterPlanMode, ExitPlanMode, Task, Bash)
- Used by: Users via `/plugin:command` syntax (e.g., `/kas:start`, `/task:done`)

**Agent Layer:**
- Purpose: Specialized subagents spawned via Claude Code's Task tool
- Location: `plugins/<name>/agents/*.md`
- Contains: Agent persona, constraints, review checklists, output format specifications
- Depends on: Claude Code tools (Read, Glob, Grep, Bash), MCP servers
- Used by: Commands and skills that delegate to agents for isolated, focused tasks

**Skill Layer:**
- Purpose: Context-triggered capabilities with detection patterns
- Location: `plugins/<name>/skills/<skill-name>/SKILL.md`
- Contains: Trigger conditions, delegation patterns, reference materials
- Depends on: Agent layer, external MCP servers
- Used by: Claude Code skill auto-detection system

**Instructions Layer:**
- Purpose: Persistent behavioral instructions loaded when plugin is active
- Location: `plugins/<name>/CLAUDE.md`, `plugins/<name>/AGENTS.md`
- Contains: Workflow rules, critical constraints, integration prerequisites
- Depends on: Nothing (loaded into context automatically)
- Used by: Claude Code context system (CLAUDE.md for main, AGENTS.md for subagents)
- Note: `CLAUDE.md` in plugin subdirectories is **not** auto-loaded by Claude Code (verified in `docs/plugin-subdirectory-verification.md`). Instructions must be in command/agent files instead.

**OpenCode Compatibility Layer:**
- Purpose: Cross-tool command compatibility for OpenCode/Crush
- Location: `plugins/kas/.opencode/command/*.md`, `opencode/specup/`
- Contains: OpenCode-formatted commands mirroring Claude Code commands
- Depends on: Same workflow logic as Claude Code commands
- Used by: OpenCode, Crush, and Agent Skills-compatible tools

## Data Flow

**Planning Workflow (`/kas:start`):**

1. User invokes `/kas:start` → command file at `plugins/kas/commands/start.md` is read
2. Claude enters plan mode via `EnterPlanMode` tool
3. Explore agents gather codebase context (parallel Task tool invocations)
4. Plan agent writes implementation plan to `.claude/plans/<name>.md`
5. `plan-reviewer` agent (at `plugins/kas/agents/plan-reviewer.md`) runs automatically — read-only, returns structured findings
6. `ExitPlanMode` presents plan + review findings to user
7. User approves → worktree created at `.worktrees/<prefix>-<slug>/`
8. User runs `/clear` to free context, implements in new session

**Verification Workflow (`/kas:verify`):**

1. User invokes `/kas:verify` → `plugins/kas/commands/verify.md`
2. Git diff analyzed to classify change profile
3. **Tier 1 (Static):** Relevant agents run in parallel via Task tool:
   - `code-reviewer` (at `plugins/kas/agents/code-reviewer.md`) — always for code changes
   - Additional pr-review-toolkit agents based on diff content
4. **Tier 2 (Reality):** `project-reality-manager` (at `plugins/kas/agents/project-reality-manager.md`) validates plan completion
5. **Tier 3 (Polish):** Optional `code-simplifier` suggestions if VERIFIED
6. Structured verdict returned: VERIFIED / NEEDS CHANGES / BLOCKED

**ClickUp Task Workflow (`/task:start`):**

1. User invokes `/task:start CU-xxx` → `plugins/task/commands/start.md`
2. `clickup-task-agent` (at `plugins/task/agents/clickup-task-agent.md`, model: haiku) fetches task via ClickUp MCP server
3. Status updated to "in progress" via MCP
4. Delegates to `superpowers:brainstorming` skill for plan creation
5. `kas:review-plan` loop (max 5 iterations) until APPROVED or user override/abort
6. Implementation via user choice: same-session subagent or separate-session worktree

**Subagent Delegation Pattern (Core Architectural Pattern):**

1. Main context identifies need for external API interaction
2. Task tool spawns lightweight subagent with specific instructions
3. Subagent interacts with MCP server (verbose API responses stay in subagent context)
4. Subagent returns concise, formatted summary to main context
5. Main context continues with clean, unpolluted conversation

**State Management:**
- **Git state**: Branch names encode context (`feat/CU-<id>-<slug>`, `fix/<description>`)
- **Plan files**: `.claude/plans/<name>.md` — persisted plans
- **Session files**: `.claude/task-session.json` — cross-session state for task plugin
- **Worktrees**: `.worktrees/<prefix>-<slug>/` — isolated working directories
- **No database or runtime state** — all state is in the filesystem or git

## Key Abstractions

**Plugin Manifest:**
- Purpose: Declares plugin identity and metadata for marketplace distribution
- Examples: `plugins/kas/.claude-plugin/plugin.json`, `plugins/task/.claude-plugin/plugin.json`
- Pattern: JSON manifest with name, version, author, keywords

**Slash Command:**
- Purpose: User-facing entry point that defines a multi-step workflow
- Examples: `plugins/kas/commands/start.md`, `plugins/kas/commands/done.md`, `plugins/kas/commands/verify.md`
- Pattern: Markdown with optional YAML frontmatter (`description`, `argument-hint`), numbered workflow steps, error handling tables, integration contracts

**Agent Definition:**
- Purpose: Specialized persona with constrained tools and structured output format
- Examples: `plugins/kas/agents/code-reviewer.md`, `plugins/kas/agents/project-reality-manager.md`, `plugins/task/agents/clickup-task-agent.md`
- Pattern: YAML frontmatter (`name`, `description` with examples, `model`, `color`, `tools`) followed by persona instructions, constraints, checklists, and output format specification

**Skill:**
- Purpose: Auto-triggered capability with detection patterns and delegation logic
- Examples: `plugins/kas/skills/browser/SKILL.md`, `plugins/task/skills/task-workflow/SKILL.md`
- Pattern: YAML frontmatter metadata, detection triggers section, subagent delegation patterns, reference file pointers

**Reference Material:**
- Purpose: Supporting documentation loaded by skills/agents on demand
- Examples: `plugins/task/skills/task-workflow/references/subagent-prompts.md`, `plugins/task/skills/task-workflow/references/task-templates.md`
- Pattern: Copy-paste prompt templates, setup guides, and structured templates

## Entry Points

**User-Facing Commands (kas plugin):**
- `/kas:start` → `plugins/kas/commands/start.md` — enter planning workflow
- `/kas:setup` → `plugins/kas/commands/setup.md` — validate prerequisites
- `/kas:done` → `plugins/kas/commands/done.md` — commit, push, land session
- `/kas:save` → `plugins/kas/commands/save.md` — snapshot for multi-session
- `/kas:merge` → `plugins/kas/commands/merge.md` — merge PR, cleanup worktree
- `/kas:verify` → `plugins/kas/commands/verify.md` — tiered verification
- `/kas:review-code` → `plugins/kas/commands/review-code.md` — standalone code review
- `/kas:review-plan` → `plugins/kas/commands/review-plan.md` — standalone plan review
- `/kas:review-reality` → `plugins/kas/commands/review-reality.md` — standalone reality check

**User-Facing Commands (task plugin):**
- `/task:start <id>` → `plugins/task/commands/start.md` — start ClickUp task
- `/task:done` → `plugins/task/commands/done.md` — complete + update ClickUp
- `/task:merge` → `plugins/task/commands/merge.md` — merge + close ClickUp
- `/task:status` → `plugins/task/commands/status.md` — check task status
- `/task:new` → `plugins/task/commands/new.md` — create ClickUp task

**User-Facing Commands (specup — OpenCode/Agent Skills):**
- `/specup.setup` → `opencode/specup/commands/specup.setup.md` — verify ClickUp MCP auth
- `/specup.new` → `opencode/specup/commands/specup.new.md` — create ClickUp task
- `/specup.import` → `opencode/specup/commands/specup.import.md` — import ClickUp → spec-kitty
- `/specup.export` → `opencode/specup/commands/specup.export.md` — export spec-kitty → ClickUp

**Context Loading (auto-loaded when plugin active):**
- `plugins/kas/AGENTS.md` — loaded for all subagents when kas is enabled
- `plugins/task/CLAUDE.md` — loaded for main context when task is enabled (see note about CLAUDE.md limitation)

**Marketplace Registration:**
- `.claude-plugin/marketplace.json` — top-level registry for all plugins

## Error Handling

**Strategy:** Defensive, cascading with early-exit

Each command defines explicit error handling via tables mapping error conditions to actions. The pattern is consistent across all commands:

**Patterns:**
- **Blocker/Stop pattern**: Critical failures halt the workflow immediately and present actionable fix instructions. Example: `/kas:setup` stops if `gh` is not authenticated.
- **Warn/Continue pattern**: Non-critical failures log a warning and allow the workflow to continue. Example: Plugin not enabled in settings.json.
- **Cascade protection**: When a workflow wraps another (`/task:done` wraps `/kas:verify` + `/kas:done`), failures in inner commands prevent outer commands from executing side effects (e.g., ClickUp is NOT updated if `kas:done` fails).
- **Rollback on abort**: `/task:start` captures the original ClickUp status before modifying it, and restores it if the user aborts the workflow.
- **Tier-based early exit**: `/kas:verify` uses a three-tier system where each tier only runs if the previous tier passes.

## Cross-Cutting Concerns

**Logging:** Not applicable — there is no runtime logging. Agent output is the "log". Commands specify what to report to the user at each step.

**Validation:** Encoded in command workflows (e.g., `/kas:setup` validates prerequisites). Agent output includes severity-rated findings. No schema validation framework.

**Authentication:** Delegated to external tools — `gh auth` for GitHub, OAuth via ClickUp MCP server. The plugin never handles credentials directly.

**Plugin Dependencies:** The `task` plugin depends on `kas` (for verify/done/merge), `superpowers` (for brainstorming/implementation), and ClickUp MCP server. The `kas` plugin depends on `superpowers` and `pr-review-toolkit` plugins. These are documented but not enforced programmatically.

**Multi-Tool Targeting:** The codebase supports multiple AI coding tools:
- Claude Code: via `.claude-plugin/`, `commands/`, `agents/`, `CLAUDE.md`, `AGENTS.md`
- OpenCode/Crush: via `.opencode/command/` directories and `AGENTS.md`
- Agent Skills (Crush, Gemini CLI, Cursor, etc.): via `SKILL.md` with frontmatter metadata

---

*Architecture analysis: 2026-02-15*
