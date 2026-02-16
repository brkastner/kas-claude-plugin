# Coding Conventions

**Analysis Date:** 2026-02-15

## Project Nature

This is a **Markdown-as-code** codebase — a Claude Code plugin marketplace. There is no traditional programming language source code (no TypeScript, Python, Go, etc.). All "code" is structured Markdown files that instruct AI agents, define slash commands, configure skills, and document workflows. Conventions here govern Markdown authoring, file organization, YAML frontmatter, and structured prompt design.

## Naming Patterns

**Files:**
- Commands: `kebab-case.md` — e.g., `plugins/kas/commands/review-code.md`, `plugins/kas/commands/review-reality.md`
- Agents: `kebab-case.md` — e.g., `plugins/kas/agents/code-reviewer.md`, `plugins/task/agents/clickup-task-agent.md`
- Skills: `SKILL.md` (always uppercase) inside a kebab-case directory — e.g., `plugins/kas/skills/browser/SKILL.md`
- Reference files: `kebab-case.md` — e.g., `plugins/task/skills/task-workflow/references/subagent-prompts.md`
- Top-level instruction files: `UPPERCASE.md` — `CLAUDE.md`, `AGENTS.md`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`
- Plugin manifests: `plugin.json` inside `.claude-plugin/` directory
- MCP configs: `.mcp.json` at plugin root

**Directories:**
- Plugin directories: `kebab-case` — `plugins/kas/`, `plugins/task/`
- Standard subdirectories: `commands/`, `agents/`, `skills/`, `references/`
- Skill directories: `kebab-case` — `skills/browser/`, `skills/task-workflow/`
- Hidden config directories: `.claude-plugin/`, `.opencode/`, `.claude/`

**Command naming (slash commands):**
- Claude Code plugins: `<plugin>:<command>` — `/kas:start`, `/kas:done`, `/task:merge`
- OpenCode plugins: `<plugin>.<command>` — `/specup.setup`, `/specup.import`
- Use verb names: `start`, `done`, `save`, `merge`, `verify`, `setup`, `new`, `status`
- Use compound verbs with hyphens: `review-code`, `review-plan`, `review-reality`

**Agent naming:**
- YAML frontmatter `name:` field: `kebab-case` — `kas-code-reviewer`, `plan-reviewer`, `clickup-task-agent`
- Filename matches the name minus the plugin prefix (when applicable)

**Severity levels (standardized across all agents):**
- Use: `Critical`, `High`, `Medium`, `Low`
- Code reviewer adds numeric scores: Critical (91-100), High (71-90), Medium (41-70), Low (1-40)
- Verdict labels: `APPROVED`, `NEEDS CHANGES`, `REJECTED` (code review); `APPROVED`, `NEEDS REVISION`, `BLOCKED` (plan review); `VERIFIED`, `NEEDS CHANGES`, `BLOCKED` (verification)

## Markdown Structure Conventions

**Command files (`commands/*.md`):**
1. Optional YAML frontmatter with `description:` and `argument-hint:`
2. H1 title: `# /<plugin>:<command> - Brief Description`
3. Optional intro paragraph
4. `## Workflow` section with numbered steps (`### 1.`, `### 2.`, etc.)
5. Each step includes bash code blocks for concrete commands
6. `## Error Handling` section as a table: `| Error | Action |`
7. `## Rules` section with bullet points of constraints
8. `## Notes` section for additional context

```markdown
---
description: Brief description for command listing
argument-hint: <required-arg> [optional-arg]
---

# /plugin:command $ARGUMENTS

Brief purpose statement.

## Workflow

### 1. Step Name

```bash
concrete commands here
```

### 2. Next Step

...

## Error Handling

| Error | Action |
|-------|--------|
| Specific failure | Specific recovery |

## Rules

- Constraint 1
- Constraint 2
```

**Agent files (`agents/*.md`):**
1. Required YAML frontmatter block with: `name:`, `description:` (including `<example>` blocks), `model:`, `color:`, `tools:`
2. H1 role title (not the command name)
3. `## Purpose` section
4. `## Constraints` section
5. Domain-specific review criteria or checklists
6. `## Output Format` with a Markdown code block template
7. Integration notes

```markdown
---
name: agent-name
description: |
  Use this agent when...

  <example>
  Context: ...
  user: "..."
  assistant: "..."
  <commentary>
  Reasoning for trigger.
  </commentary>
  </example>
model: opus|sonnet|haiku
color: green|purple|red|blue|cyan
tools: Read, Glob, Grep, Bash
---

# Agent Role Title

## Purpose
...

## Constraints
- **Read-only**: Never edit files
- **Structured output**: Return findings in format below

## Output Format
```

**Skill files (`skills/*/SKILL.md`):**
1. Optional YAML frontmatter with `name:`, `description:`, metadata
2. H1 with skill name
3. `## Core Principle` section (delegation pattern)
4. `## Detection Triggers` section (when to activate)
5. `## Subagent Delegation Pattern` section with Task tool invocation templates
6. `## Examples` section with concrete delegation examples
7. `## Security Reminders` or `## Error Handling`
8. `## Response Format`

**CLAUDE.md (plugin instructions):**
- Plugin development context at top
- Workflow overview with ASCII art flow diagram
- Mode-specific instructions (Plan Mode, Code Review, etc.)
- Session management shortcuts
- Prerequisites section listing dependencies on other plugins

## YAML Frontmatter Conventions

**Always use `---` delimiters.** Present in command files, agent files, and skill files.

**Command frontmatter fields:**
- `description:` (required) — shown in command listings
- `argument-hint:` (optional) — shows usage pattern

**Agent frontmatter fields:**
- `name:` (required) — kebab-case identifier
- `description:` (required) — multi-line with `<example>` blocks
- `model:` (required) — `opus`, `sonnet`, or `haiku`
- `color:` (required) — terminal color for the agent
- `tools:` (optional) — comma-separated tool list

**Model selection convention:**
- `opus` — for thorough review (code-reviewer, project-reality-manager)
- `sonnet` — for lighter review (plan-reviewer, browser-automation)
- `haiku` — for fast API delegation (clickup-task-agent)

## Code Style (Embedded Bash)

**Bash in command files follows strict patterns:**
- Use `set -euo pipefail` in standalone scripts (see `opencode/specup/install.sh`)
- Quote all variable expansions: `"$VARIABLE"`
- Use `2>/dev/null` for optional command checks
- Use `command -v` for tool existence checks (not `which`)
- Use heredocs for multi-line content: `$(cat <<'EOF' ... EOF)`
- Chain commands with `&&` for dependent operations
- Use conditional `if [[ ... ]]; then` blocks (not single-bracket `[`)

```bash
# Correct pattern for tool checking
if ! command -v gh &>/dev/null; then
  echo "[FAIL] gh not found"
fi

# Correct pattern for git operations
git pull --rebase && git push
git status  # MUST show "up to date with origin"

# Correct pattern for optional checks
PR_URL=$(gh pr view --json url -q .url 2>/dev/null)
if [[ -n "$PR_URL" ]]; then
  # ... act on PR
fi
```

## Import Organization

Not applicable — this is a Markdown codebase. Cross-referencing between files uses:

**Relative path references:**
- Agent instructions: `agents/code-reviewer.md (relative to plugin root)`
- Reference files: `skills/task-workflow/references/subagent-prompts.md`
- Skill invocation: `Skill("superpowers:brainstorming")`
- Command delegation: `Delegate to /kas:verify`

**Plugin variable for hooks/scripts:**
- Always use `${CLAUDE_PLUGIN_ROOT}` for paths in hooks (never absolute paths)

## Error Handling

**Standardized error handling tables in commands:**

Every command file includes an error handling section. Use this exact table format:

```markdown
## Error Handling

| Error | Action |
|-------|--------|
| Specific failure mode | Concrete recovery step |
```

**Error handling principles across all commands:**
1. Never fail silently — always report errors to the user
2. For partial failures: complete what you can, report what failed
3. For ClickUp API failures after local success: warn user, provide manual command
4. For git push failures: resolve and retry until successful (NEVER leave unpushed work)
5. For verification failures: stop and present findings, do NOT proceed to next step
6. For agent failures: offer retry or manual alternative

**Severity classification for stop/continue decisions:**
- `BLOCKER` (FAIL) — must fix before continuing (e.g., missing prerequisites, merge conflicts)
- `WARNING` (WARN) — continue but note the issue (e.g., plugin not enabled)
- `PASS` — no action needed

## Logging

**Status output format:**
- Use `[PASS]`, `[FAIL]`, `[WARN]` prefixes for setup/validation output
- Include fix instructions with every `[FAIL]` message
- Keep success output minimal; verbose on failure

**Agent output format:**
- Use structured Markdown with `## Summary`, severity counts, findings by severity
- Always include `**Overall Assessment:**` verdict
- Always include `**File:** path:line` references in findings

## Comments

**When to comment in Markdown files:**
- Use HTML comments `<!-- ... -->` for metadata not shown to users (rare in this codebase)
- Use inline Markdown comments for clarifying complex workflow steps
- Document "why" decisions in `## Notes` sections at the end of command files

**JSDoc/TSDoc:** Not applicable.

## Document Design

**Length guidelines:**
- Commands: 25-200 lines (setup is longest at 193 lines)
- Agents: 50-190 lines
- Skills: 80-165 lines
- Reference files: 50-120 lines

**Structural rules:**
- Every command has a `## Workflow` with numbered steps
- Every agent has `## Purpose`, `## Constraints`, `## Output Format`
- Every skill has `## Detection Triggers`, `## Subagent Delegation Pattern`
- Error handling is always a table, never prose

## Module Design (Plugin Architecture)

**Plugin composition pattern:**
- Plugins depend on other plugins via explicit `## Dependencies` or `## Prerequisites` sections
- `task` plugin wraps `kas` commands (e.g., `/task:done` calls `/kas:verify` then `/kas:done`)
- `kas` plugin wraps `pr-review-toolkit` agents (external dependency)
- Skills invoke other skills via `Skill("plugin:skill-name")`

**Subagent delegation pattern (critical convention):**
- Never call verbose MCP tools directly in main context
- Always delegate to a dedicated agent subagent
- Subagent returns concise summary only
- Template: `Task tool with subagent_type="<plugin>:<agent-name>": "<prompt>"`

**Barrel exports:** Not applicable. Each command/agent/skill is independently discoverable.

## JSON Configuration Conventions

**plugin.json:**
```json
{
  "name": "plugin-name",
  "description": "Brief description",
  "version": "X.Y.Z",
  "author": { "name": "Name", "url": "https://..." },
  "repository": "https://github.com/...",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"]
}
```

**.mcp.json:**
```json
{
  "mcpServers": {
    "service-name": {
      "type": "http",
      "url": "https://..."
    }
  }
}
```

## Git Conventions

**Branch naming:**
- Features: `feat/<slug>` or `feat/CU-<id>-<slug>` (with ClickUp integration)
- Fixes: `fix/<slug>` or `fix/CU-<id>-<slug>`
- Refactors: `refactor/<slug>`
- Slug: sanitized from plan/task title, max 30 chars, kebab-case

**Commit messages:**
- Include `CU-<task-id>` when working with ClickUp tasks
- PR titles include `[CU-xxx]` prefix for ClickUp linking

**Worktrees:**
- Path: `.worktrees/<prefix>-<slug>/`
- Never commit directly to main
- Always use PR workflow

## Changelog Conventions

Follow [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format:
- Group changes under `### Added`, `### Changed`, `### Fixed`, `### Migration`
- Use `[X.Y.Z] - YYYY-MM-DD` headers
- Adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

---

*Convention analysis: 2026-02-15*
