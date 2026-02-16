# Codebase Structure

**Analysis Date:** 2026-02-15

## Directory Layout

```
kas-claude-plugins/
├── .claude-plugin/                # Marketplace manifest (top-level registry)
│   └── marketplace.json           # Lists all available plugins with versions
├── .claude/                       # Claude Code project settings + skills
│   ├── settings.json              # Enabled plugins for this repo
│   ├── settings.local.json        # User-specific overrides (git-ignored)
│   └── skills/                    # Project-level skills (not plugin-distributed)
│       └── project-auditor/       # Audit skill with reference checklists
├── plugins/                       # All distributable plugins live here
│   ├── kas/                       # Core workflow plugin (v2.0.0)
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json        # Plugin manifest
│   │   ├── agents/                # Subagent definitions (4 agents)
│   │   ├── commands/              # Slash commands (9 commands)
│   │   ├── skills/                # Auto-triggered capabilities
│   │   │   └── browser/           # Browser automation skill
│   │   ├── .opencode/             # OpenCode-compatible command variants
│   │   │   └── command/           # /kas.review and /kas.verify for OpenCode
│   │   ├── AGENTS.md              # Subagent-level instructions
│   │   ├── CLAUDE.md              # Main context instructions
│   │   └── README.md              # Plugin documentation
│   └── task/                      # ClickUp integration plugin (v2.0.0)
│       ├── .claude-plugin/
│       │   └── plugin.json        # Plugin manifest
│       ├── agents/                # Subagent definitions (1 agent)
│       ├── commands/              # Slash commands (5 commands)
│       ├── skills/                # Auto-triggered capabilities
│       │   └── task-workflow/     # ClickUp workflow skill + references
│       ├── .mcp.json              # MCP server config (ClickUp HTTP)
│       ├── CLAUDE.md              # Main context instructions
│       ├── CHANGELOG.md           # Version history
│       └── README.md              # Plugin documentation
├── opencode/                      # OpenCode/Crush-compatible plugins
│   └── specup/                    # ClickUp ↔ spec-kitty bridge
│       ├── commands/              # Slash commands (4 commands)
│       ├── references/            # Setup guide
│       ├── AGENTS.md              # OpenCode agent instructions
│       ├── SKILL.md               # Agent Skills entry point
│       ├── .mcp.json              # ClickUp MCP server config
│       ├── install.sh             # Project installer script
│       └── README.md              # Documentation
├── docs/                          # Project-level documentation
│   └── plugin-subdirectory-verification.md
├── plans/                         # Historical/stale implementation plans
│   └── kas-setup-command.md       # Stale plan (pre-superpowers)
├── .beads/                        # Beads task tracking (git-ignored)
├── .worktrees/                    # Git worktrees (git-ignored)
├── CHANGELOG.md                   # Project changelog
├── CONTRIBUTING.md                # Plugin contribution guide
├── LICENSE                        # MIT license
└── README.md                      # Marketplace documentation
```

## Directory Purposes

**`plugins/`:**
- Purpose: Contains all distributable Claude Code plugins
- Contains: One subdirectory per plugin, each self-contained with manifest, commands, agents, skills
- Key files: Each plugin has `.claude-plugin/plugin.json` (required manifest)

**`plugins/kas/commands/`:**
- Purpose: Slash command definitions for the kas workflow plugin
- Contains: 9 Markdown files, each defining one `/kas:<name>` command
- Key files: `start.md` (planning entry), `done.md` (session completion), `verify.md` (tiered verification), `merge.md` (PR merge + cleanup)

**`plugins/kas/agents/`:**
- Purpose: Subagent persona definitions spawned via Task tool
- Contains: 4 agent Markdown files with YAML frontmatter (name, model, tools, color)
- Key files: `code-reviewer.md` (opus model, green), `plan-reviewer.md` (sonnet model, purple), `project-reality-manager.md` (opus model, red), `browser-automation.md` (sonnet model, blue)

**`plugins/kas/skills/`:**
- Purpose: Auto-triggered capabilities with detection patterns
- Contains: One skill subdirectory per capability
- Key files: `browser/SKILL.md` — browser automation with Claude-in-Chrome MCP delegation

**`plugins/kas/.opencode/command/`:**
- Purpose: OpenCode/Crush-compatible versions of kas commands
- Contains: Review and verify commands with spec-kitty integration
- Key files: `kas.review.md` (extended review with WP scope), `kas.verify.md` (verify alias)

**`plugins/task/commands/`:**
- Purpose: ClickUp-integrated workflow commands
- Contains: 5 Markdown files wrapping kas commands with ClickUp sync
- Key files: `start.md` (superpowers-driven planning), `done.md` (verify + PR + ClickUp update), `merge.md` (merge + ClickUp close)

**`plugins/task/agents/`:**
- Purpose: ClickUp API delegation agent
- Contains: 1 agent (`clickup-task-agent.md`, haiku model, cyan)
- Key files: `clickup-task-agent.md` — normalizes task IDs, returns concise summaries

**`plugins/task/skills/task-workflow/`:**
- Purpose: ClickUp workflow automation with detection triggers
- Contains: Skill definition + reference materials
- Key files: `SKILL.md` (workflow patterns), `references/subagent-prompts.md` (copy-paste agent prompts), `references/task-templates.md` (task description templates), `references/setup.md` (ClickUp auth setup)

**`opencode/specup/`:**
- Purpose: Model-agnostic ClickUp ↔ spec-kitty bridge (not Claude Code-specific)
- Contains: Commands, install script, skill definition, MCP config
- Key files: `SKILL.md` (Agent Skills entry point), `install.sh` (project installer), `commands/specup.import.md` (ClickUp → spec-kitty), `commands/specup.export.md` (spec-kitty → ClickUp)

**`.claude/skills/project-auditor/`:**
- Purpose: Project-level skill for auditing codebases (not plugin-distributed)
- Contains: Skill definition + reference checklists
- Key files: `SKILL.md` (364-line audit workflow), `references/security-checklist.md`, `references/code-quality-checklist.md`, `references/infrastructure-checklist.md`, `references/vibe-code-patterns.md`

**`docs/`:**
- Purpose: Project-level technical documentation
- Contains: Verification results and architectural decisions
- Key files: `plugin-subdirectory-verification.md` — confirms Claude Code subdirectory plugin behavior

**`plans/`:**
- Purpose: Historical implementation plans (may be stale)
- Contains: Past plan documents
- Key files: `kas-setup-command.md` — marked STALE, pre-superpowers architecture

## Key File Locations

**Entry Points:**
- `.claude-plugin/marketplace.json`: Top-level marketplace registry — lists all plugins
- `plugins/kas/.claude-plugin/plugin.json`: kas plugin manifest (v2.0.0)
- `plugins/task/.claude-plugin/plugin.json`: task plugin manifest (v2.0.0)

**Configuration:**
- `.claude/settings.json`: Enabled plugins for this repository
- `plugins/task/.mcp.json`: ClickUp MCP server config (`https://mcp.clickup.com/mcp`)
- `opencode/specup/.mcp.json`: Same ClickUp MCP server config for OpenCode
- `.gitignore`: Excludes `.beads/`, `.worktrees/`, `.claude/settings.local.json`, IDE files
- `.gitattributes`: Custom merge driver for `.beads/issues.jsonl`

**Core Logic (kas plugin):**
- `plugins/kas/commands/start.md`: Planning workflow — EnterPlanMode → explore → design → review → ExitPlanMode
- `plugins/kas/commands/verify.md`: Three-tier verification — static → reality → polish
- `plugins/kas/commands/done.md`: Session completion — commit → push → PR comment → cleanup
- `plugins/kas/commands/save.md`: Session snapshot — commit → push → generate continuation prompt
- `plugins/kas/commands/merge.md`: PR finalization — CI check → merge → worktree cleanup
- `plugins/kas/CLAUDE.md`: 273-line instruction file defining complete workflow, plan mode, git worktrees, review process, quality gates

**Core Logic (task plugin):**
- `plugins/task/commands/start.md`: ClickUp-aware planning — fetch task → brainstorming → review loop → implementation choice
- `plugins/task/commands/done.md`: ClickUp-aware completion — verify → kas:done → PR → ClickUp update
- `plugins/task/CLAUDE.md`: 76-line instruction file — subagent delegation pattern, superpowers integration

**Core Logic (specup):**
- `opencode/specup/commands/specup.import.md`: 186-line workflow — fetch ClickUp → discovery interview → scaffold spec-kitty feature
- `opencode/specup/commands/specup.export.md`: 192-line workflow — resolve feature → create ClickUp folder → export docs/tasks/subtasks

**Agent Definitions:**
- `plugins/kas/agents/code-reviewer.md`: 187-line agent — Linus Torvalds philosophy, severity 1-100, review checklist
- `plugins/kas/agents/plan-reviewer.md`: 139-line agent — senior architect, proactive triggering, structured findings
- `plugins/kas/agents/project-reality-manager.md`: 120-line agent — completion skeptic, gap analysis, validation checklist
- `plugins/kas/agents/browser-automation.md`: 57-line agent — Claude-in-Chrome MCP, web testing/scraping
- `plugins/task/agents/clickup-task-agent.md`: 99-line agent — haiku model, ID normalization, concise output

**Skills:**
- `plugins/kas/skills/browser/SKILL.md`: 160-line skill — detection triggers, subagent delegation examples
- `plugins/task/skills/task-workflow/SKILL.md`: 93-line skill — command mapping, planning workflow, error handling
- `opencode/specup/SKILL.md`: 84-line skill — Agent Skills entry point, MCP tools, lane-to-status mapping
- `.claude/skills/project-auditor/SKILL.md`: 364-line skill — 5-phase audit, scoring methodology, framework-specific checks

**Documentation:**
- `CONTRIBUTING.md`: 193-line guide — plugin structure, component types, best practices, PR process
- `docs/plugin-subdirectory-verification.md`: Verified Claude Code plugin subdirectory behavior
- `README.md`: Marketplace overview, installation instructions

## Naming Conventions

**Files:**
- Commands: `kebab-case.md` (e.g., `review-code.md`, `review-plan.md`, `review-reality.md`)
- Agents: `kebab-case.md` (e.g., `code-reviewer.md`, `clickup-task-agent.md`)
- Skills: `SKILL.md` (always uppercase, one per skill directory)
- Instructions: `CLAUDE.md` or `AGENTS.md` (uppercase, recognized by Claude Code)
- Manifests: `plugin.json` or `marketplace.json` (lowercase)
- OpenCode commands: `plugin.command.md` (dot-separated, e.g., `kas.review.md`, `specup.import.md`)

**Directories:**
- Plugins: `kebab-case` (e.g., `plugins/kas/`, `plugins/task/`)
- Skills: `kebab-case` (e.g., `skills/browser/`, `skills/task-workflow/`)
- Agent Skills: name matches skill slug (e.g., `opencode/specup/`)
- Standard plugin subdirectories: `.claude-plugin/`, `commands/`, `agents/`, `skills/`, `.opencode/`
- References: `references/` within skill directories

**Slash Commands:**
- Claude Code: `/plugin:command` (colon-separated, e.g., `/kas:start`, `/task:done`)
- OpenCode/Crush: `/plugin.command` (dot-separated, e.g., `/specup.import`, `/kas.review`)

**Branches:**
- Features: `feat/<description>` or `feat/CU-<id>-<slug>`
- Bug fixes: `fix/<description>` or `fix/CU-<id>-<slug>`
- Refactors: `refactor/<description>`

**Worktrees:**
- Path: `.worktrees/<prefix>-<slug>/` (e.g., `.worktrees/feat-user-auth/`)

## Where to Add New Code

**New Plugin:**
1. Create directory: `plugins/<plugin-name>/`
2. Add manifest: `plugins/<plugin-name>/.claude-plugin/plugin.json`
3. Add commands: `plugins/<plugin-name>/commands/<command>.md`
4. Add agents (if needed): `plugins/<plugin-name>/agents/<agent>.md`
5. Add skills (if needed): `plugins/<plugin-name>/skills/<skill-name>/SKILL.md`
6. Add instructions: `plugins/<plugin-name>/CLAUDE.md` (main context), `AGENTS.md` (subagent context)
7. Register in: `.claude-plugin/marketplace.json`
8. Add docs: `plugins/<plugin-name>/README.md`

**New Command (existing plugin):**
- Claude Code: `plugins/<plugin>/commands/<command-name>.md`
- OpenCode: `plugins/<plugin>/.opencode/command/<plugin>.<command>.md`
- Both: Create in both locations if cross-tool compatibility needed

**New Agent (existing plugin):**
- Create: `plugins/<plugin>/agents/<agent-name>.md`
- Include YAML frontmatter: `name`, `description` with examples, `model` (opus/sonnet/haiku), `color`, `tools`
- Follow existing pattern: persona → constraints → checklist → output format

**New Skill (existing plugin):**
- Create directory: `plugins/<plugin>/skills/<skill-name>/`
- Create: `plugins/<plugin>/skills/<skill-name>/SKILL.md` with frontmatter
- Add references: `plugins/<plugin>/skills/<skill-name>/references/*.md`
- Include: detection triggers, delegation patterns, examples

**New Reference Material:**
- Add to: `plugins/<plugin>/skills/<skill-name>/references/<name>.md`
- Or for project-level: `.claude/skills/<skill-name>/references/<name>.md`

**New OpenCode/Agent Skills Plugin:**
- Create directory: `opencode/<plugin-name>/`
- Add: `SKILL.md` (Agent Skills entry), `AGENTS.md` (instructions), `commands/*.md`, `.mcp.json` (if MCP needed)
- Optionally add: `install.sh` for project installation

## Special Directories

**`.beads/`:**
- Purpose: Beads task tracking database and daemon state
- Generated: Yes (by `bd init`)
- Committed: No (git-ignored)

**`.worktrees/`:**
- Purpose: Git worktree working directories for parallel development
- Generated: Yes (by `git worktree add`)
- Committed: No (git-ignored)

**`.claude/`:**
- Purpose: Claude Code project configuration and project-level skills
- Generated: Partially (settings created manually or by setup)
- Committed: `settings.json` yes, `settings.local.json` no (git-ignored)

**`.claude-plugin/`:**
- Purpose: Marketplace manifest (top-level only)
- Generated: No (manually maintained)
- Committed: Yes

**`plans/`:**
- Purpose: Historical implementation plans (may be stale)
- Generated: No (written during planning sessions)
- Committed: Yes (but check for STALE markers)

---

*Structure analysis: 2026-02-15*
