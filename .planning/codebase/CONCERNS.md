# Codebase Concerns

**Analysis Date:** 2026-02-15

## Tech Debt

**Version Drift Across Manifests:**
- Issue: Plugin version numbers are inconsistent across `plugin.json`, `marketplace.json`, `CHANGELOG.md`, and `README.md`. The `kas` plugin is `2.0.0` in `plugins/kas/.claude-plugin/plugin.json`, `1.8.0` in `.claude-plugin/marketplace.json`, and `1.7.0` in `README.md`. The `task` plugin is `2.0.0` in `plugins/task/.claude-plugin/plugin.json` but `1.0.2` in `.claude-plugin/marketplace.json`.
- Files: `.claude-plugin/marketplace.json` (lines 12, 19), `plugins/kas/.claude-plugin/plugin.json` (line 4), `plugins/task/.claude-plugin/plugin.json` (line 4), `README.md` (line 9)
- Impact: Users installing via marketplace get outdated version metadata. Marketplace listing doesn't reflect current plugin capabilities. Could cause confusion about which features are available.
- Fix approach: Synchronize all version strings. Consider a release script or pre-commit hook that validates version consistency across `plugin.json`, `marketplace.json`, root `README.md`, and `CHANGELOG.md`.

**Stale Plan Document:**
- Issue: `plans/kas-setup-command.md` is explicitly marked `STALE` (line 3) and references removed beads integration (`bd`, `.beads/`, daemon management, `util/beads-sync`). The document itself says it "Needs a full rewrite to match the current kas plugin architecture (superpowers-based)."
- Files: `plans/kas-setup-command.md`
- Impact: Misleading if anyone references it for setup command behavior. The actual `/kas:setup` command at `plugins/kas/commands/setup.md` is current and correct, but the stale plan adds confusion.
- Fix approach: Delete `plans/kas-setup-command.md` or rewrite it to match the current `plugins/kas/commands/setup.md`. Since the actual command file is authoritative, deletion is simplest.

**Residual Beads References:**
- Issue: "Beads" was removed from the kas plugin (commit 4a7575b per the stale plan), but references remain in multiple files: `README.md` describes kas as "Workflow automation with beads task tracking" (line 9, 44), `CHANGELOG.md` has historical entries mentioning beads (acceptable for changelogs), and `plugins/task/README.md` references `/kas:next` (lines 36, 38) which was a beads command that no longer exists.
- Files: `README.md` (lines 9, 44), `plugins/task/README.md` (lines 36, 38)
- Impact: Users may expect beads-related features (`/kas:next`) that don't exist. The root `README.md` misrepresents current plugin capabilities.
- Fix approach: Update `README.md` description to remove beads references. Update `plugins/task/README.md` Quick Start section to remove `/kas:next` references. Leave `CHANGELOG.md` as-is (historical record).

**Stale Reference to task-splitter Agent:**
- Issue: `plugins/kas/commands/review-plan.md` (line 24) says "Do NOT proceed to task-splitter or implementation without explicit user approval." The `task-splitter` agent was removed with beads integration but is still referenced.
- Files: `plugins/kas/commands/review-plan.md` (line 24)
- Impact: Minor confusion. Claude may look for a non-existent agent. The instruction still makes sense without the agent name, but should be cleaned up.
- Fix approach: Change line 24 to "Do NOT proceed to implementation without explicit user approval."

**Divergent OpenCode Command Variants:**
- Issue: `plugins/kas/.opencode/command/kas.verify.md` and `plugins/kas/.opencode/command/kas.review.md` contain significantly different behavior from the main Claude Code commands at `plugins/kas/commands/verify.md` and `plugins/kas/commands/review-code.md`. The OpenCode variants integrate `spec-kitty` and `kitty-specs` features (WP scope resolution, lane automation, feedback file export) that are absent from the Claude Code versions.
- Files: `plugins/kas/.opencode/command/kas.verify.md`, `plugins/kas/.opencode/command/kas.review.md`, `plugins/kas/commands/verify.md`, `plugins/kas/commands/review-code.md`
- Impact: Feature drift between tool targets. Users on different tools get different capabilities for the same conceptual command. Maintaining two divergent implementations doubles change effort.
- Fix approach: Decide on canonical behavior. Either port spec-kitty/WP scope features to the Claude Code commands, or document that OpenCode commands have extended capabilities. Consider extracting shared logic into a reference document both variants can import.

**CONTRIBUTING.md References hooks/ Directory:**
- Issue: `CONTRIBUTING.md` documents a `hooks/` directory structure (lines 17, 111-134, 149) as part of plugin anatomy. However, no `hooks/` directory exists in either current plugin (`plugins/kas/` or `plugins/task/`). Hooks were removed with beads integration.
- Files: `CONTRIBUTING.md` (lines 17, 111-134, 149)
- Impact: Plugin developers following the contribution guide may create unnecessary hooks infrastructure. Guide doesn't match current reality.
- Fix approach: Either remove hooks section from CONTRIBUTING.md or mark it as optional. The hooks mechanism still works in Claude Code plugins (verified in `docs/plugin-subdirectory-verification.md`), so keeping a minimal reference as optional is reasonable.

## Known Bugs

**No runtime bugs detected.** This is a prompt-only codebase with no executable code, so traditional bugs don't apply. The concerns below are behavioral issues in prompt instructions.

**Potential Circular Delegation in /task:done:**
- Symptoms: `/task:done` (at `plugins/task/commands/done.md` line 24) delegates to `/kas:done`, but `/kas:done` (at `plugins/kas/commands/done.md`) performs the commit/push workflow. If `/kas:verify` (step 2 of `/task:done`) finds issues, it stops correctly. However, the step numbering in `/task:done` jumps from step 5 to step 6 (cleanup) with step 6 numbered as "6." after step 5 which is numbered as "5.", breaking the ordered list markdown.
- Files: `plugins/task/commands/done.md` (line 53)
- Trigger: Step 6 starts at line 53 with `6.` but follows a section that ends the numbered list, so markdown parsers may restart numbering.
- Workaround: The step content is clear enough that Claude can follow it regardless of markdown rendering.

## Security Considerations

**No Secrets in Codebase:**
- Risk: Low. The codebase correctly uses `.gitignore` for `.env*`, `.beads/`, `.worktrees/`, and `.claude/settings.local.json`. No hardcoded secrets detected.
- Files: `.gitignore`
- Current mitigation: Proper gitignore patterns. ClickUp integration uses OAuth or environment variables, not committed tokens.
- Recommendations: None needed. Current approach is sound.

**MCP Server URL Hardcoded:**
- Risk: Low. The ClickUp MCP server URL (`https://mcp.clickup.com/mcp`) is hardcoded in multiple `.mcp.json` files. This is intentional and not a secret, but if the URL changes, multiple files need updating.
- Files: `plugins/task/.mcp.json`, `opencode/specup/.mcp.json`
- Current mitigation: URL is a public endpoint, not a secret.
- Recommendations: None needed for security. For maintainability, consider a single canonical `.mcp.json` if the URL ever changes.

**Agent Model Selection Unpinned:**
- Risk: Low-Medium. Agents specify model preferences (e.g., `model: opus`, `model: sonnet`, `model: haiku` in agent frontmatter). These are relative model names that may map to different versions over time.
- Files: `plugins/kas/agents/plan-reviewer.md` (line 32: `model: sonnet`), `plugins/kas/agents/code-reviewer.md` (line 32: `model: opus`), `plugins/kas/agents/project-reality-manager.md` (line 32: `model: opus`), `plugins/kas/agents/browser-automation.md` (line 6: `model: sonnet`), `plugins/task/agents/clickup-task-agent.md` (line 33: `model: haiku`)
- Current mitigation: Claude Code handles model resolution. Using general model tiers is the documented pattern.
- Recommendations: This is acceptable practice. No action needed unless a specific model version is required for behavioral consistency.

**git stash clear in Session Commands:**
- Risk: Medium. Both `/kas:done` (line 55) and `/kas:save` (line 75) run `git stash clear` as part of cleanup. This permanently deletes ALL stashes, including stashes unrelated to the current kas session. A user with manually-created stashes would lose them.
- Files: `plugins/kas/commands/done.md` (line 55), `plugins/kas/commands/save.md` (line 75)
- Current mitigation: None.
- Recommendations: Replace `git stash clear` with either `git stash drop` for specific stashes created during the session, or remove the stash clearing entirely since the workflow is designed to commit all changes. At minimum, add a warning comment that this clears ALL stashes.

## Performance Bottlenecks

**Excessive Agent Spawning in /kas:verify:**
- Problem: `/kas:verify` (at `plugins/kas/commands/verify.md`) can spawn up to 7 agents across 3 tiers: 5 Tier 1 agents (code-reviewer, silent-failure-hunter, type-design-analyzer, comment-analyzer, pr-test-analyzer), 1 Tier 2 agent (project-reality-manager), and 1 Tier 3 agent (code-simplifier). Each agent consumes context window tokens and API calls.
- Files: `plugins/kas/commands/verify.md` (lines 38-121)
- Cause: The tiered architecture is well-designed for thoroughness, but the Tier 1 agents from `pr-review-toolkit` are external dependencies. If all are triggered (which happens when changes touch error handling, comments, types, and tests), 5 parallel agents launch.
- Improvement path: The command already implements change-pattern-based agent selection (lines 23-35), which is the right approach. Consider whether `code-reviewer` (kas) and the pr-review-toolkit agents have overlapping scopes. If the kas code-reviewer already checks for silent failures and type issues, some pr-review-toolkit agents may be redundant.

**Context Window Pressure from CLAUDE.md:**
- Problem: `plugins/kas/CLAUDE.md` is 273 lines of instructions that are loaded into every session where the kas plugin is active. Combined with active command files (which can be 80-190 lines each), the total prompt overhead is significant.
- Files: `plugins/kas/CLAUDE.md`
- Cause: CLAUDE.md contains detailed workflow documentation, git worktree conventions, code review patterns, and session management instructions all in one file.
- Improvement path: Keep CLAUDE.md focused on the most critical behavioral rules. Move detailed workflow documentation to skill or reference files that are loaded on-demand. The "Code Review (pr-review-toolkit)" section (lines 124-165) duplicates information already in `/kas:verify` and `/kas:review-code` commands.

## Fragile Areas

**External Plugin Dependencies:**
- Files: `plugins/kas/CLAUDE.md` (lines 269-272), `plugins/kas/README.md` (lines 14-16), `plugins/task/CLAUDE.md` (lines 72-75)
- Why fragile: The kas plugin depends on 3 external plugins (`superpowers`, `pr-review-toolkit`, `commit-commands`), and the task plugin additionally depends on kas + superpowers. None of these dependencies are version-pinned or validated at runtime. If `superpowers` changes its skill names (e.g., `superpowers:brainstorming`), `/task:start` silently fails.
- Safe modification: When modifying any command that references external plugin skills/agents, verify the skill names still exist in the referenced plugin. Document exact skill/agent names used.
- Test coverage: No automated validation exists. `/kas:setup` validates `gh` and `git` but does not check for required plugins.

**Task Plugin's Deep Dependency Chain:**
- Files: `plugins/task/CLAUDE.md` (lines 72-75), `plugins/task/commands/start.md`, `plugins/task/commands/done.md`
- Why fragile: `/task:start` requires: ClickUp MCP server + `clickup-task-agent` + `superpowers:brainstorming` + `kas:review-plan` + `EnterPlanMode` tool + (optionally) `superpowers:subagent-driven-development` OR `superpowers:using-git-worktrees` + `superpowers:executing-plans`. Any single broken link in this chain fails the entire workflow.
- Safe modification: Always test the full `/task:start` → `/task:done` → `/task:merge` flow end-to-end when changing any component. The error handling table in `plugins/task/commands/start.md` (lines 114-126) documents fallback behavior, which should be verified.
- Test coverage: Manual only. The fallback at line 122 ("Brainstorming unavailable: Fall back to `/kas:start` with ClickUp context") is important but there's no way to verify it works without simulating the failure.

**Session File Management (.claude/task-session.json):**
- Files: `plugins/task/commands/start.md` (lines 100-111), `plugins/task/commands/done.md` (lines 53-55)
- Why fragile: The session file at `.claude/task-session.json` is written by `/task:start` (Option 2, parallel session) and cleaned up by `/task:done` (step 6). If the user aborts mid-workflow without running `/task:done`, the stale session file remains. There's no `/task:abort` or cleanup command. The session file format is specified inline in the command file, not in a schema.
- Safe modification: When changing the session file format, update both `plugins/task/commands/start.md` and `plugins/task/commands/done.md`.
- Test coverage: None. No validation that the session file format is consistent between writer and reader.

**opencode/specup as Separate Ecosystem:**
- Files: `opencode/specup/` (entire directory)
- Why fragile: `specup` is a separate tool-agnostic plugin that lives alongside but shares no code with the Claude Code plugins in `plugins/`. It has its own ClickUp MCP config, its own AGENTS.md, its own command naming convention (dot-separated: `/specup.import` vs colon-separated: `/task:start`), and explicitly avoids Claude-specific patterns (AGENTS.md line 8: "no Claude-specific subagent patterns"). This means fixes or improvements to ClickUp integration in the task plugin don't flow to specup and vice versa.
- Safe modification: Treat specup as fully independent. Changes to `plugins/task/` should not assume specup behavior and vice versa.
- Test coverage: None. specup has no install script in the repo (references `install.sh` in README but the file doesn't exist in the tree).

## Scaling Limits

**Single-User Design:**
- Current capacity: All plugins assume a single developer workflow. Branch naming, worktree management, and ClickUp task assignment are single-user patterns.
- Limit: Multi-developer teams using the same plugin configuration would have branch name collisions and conflicting task status updates.
- Scaling path: Not a current concern; the plugin is designed for individual developer productivity. If multi-user support is needed, branch naming would need user disambiguation and ClickUp status updates would need conflict resolution.

## Dependencies at Risk

**ClickUp HTTP MCP Server:**
- Risk: The ClickUp MCP server at `https://mcp.clickup.com/mcp` is an external hosted service. Both `plugins/task/` and `opencode/specup/` depend on it. Service availability, API changes, or authentication flow changes would break task management features.
- Impact: `/task:start`, `/task:done`, `/task:merge`, `/task:status`, `/task:new`, and all `/specup.*` commands become non-functional.
- Migration plan: The task plugin's error handling gracefully degrades (warns user, provides manual commands). The subagent pattern isolates ClickUp failures from kas workflow. If ClickUp MCP becomes unavailable, falling back to direct API calls with `curl` is possible but would require rewriting the clickup-task-agent.

**superpowers Plugin (External, Unversioned):**
- Risk: The `superpowers` plugin is referenced by name (`superpowers@superpowers-marketplace` in `.claude/settings.json`) but is external and version-uncontrolled. Skills referenced: `superpowers:brainstorming`, `superpowers:subagent-driven-development`, `superpowers:using-git-worktrees`, `superpowers:executing-plans`, `superpowers:finishing-a-development-branch`.
- Impact: If any skill is renamed, removed, or changes behavior, `/task:start` breaks silently. The kas plugin itself is less affected since `/kas:start` doesn't directly use superpowers.
- Migration plan: Document exact skill names and expected interfaces. Consider local fallback implementations for critical skills.

**pr-review-toolkit Plugin (External, Unversioned):**
- Risk: Referenced agents (`silent-failure-hunter`, `comment-analyzer`, `type-design-analyzer`, `pr-test-analyzer`, `code-simplifier`) are from an external plugin with no version pinning.
- Impact: `/kas:verify` Tier 1 and Tier 3 agents fail if pr-review-toolkit changes. The kas `code-reviewer` agent (local) still works.
- Migration plan: The kas plugin has its own `code-reviewer` agent. If pr-review-toolkit becomes unavailable, `/kas:verify` should degrade to using only the local code-reviewer for Tier 1 and skip Tier 3. This fallback is not currently implemented.

## Missing Critical Features

**No Plugin Dependency Validation:**
- Problem: Neither `/kas:setup` nor any other command validates that required external plugins (`superpowers`, `pr-review-toolkit`, `commit-commands`) are installed and enabled. The setup command only checks `gh` and `git`.
- Blocks: Users can install kas without its dependencies and get cryptic failures when running `/kas:verify` or `/task:start`.
- Recommended fix: Add a plugin dependency check to `/kas:setup` that verifies `.claude/settings.json` includes required plugins. Show clear install instructions for missing ones.

**No /task:abort Command:**
- Problem: If a user starts `/task:start` and wants to abandon mid-workflow (after ClickUp status was changed to "in progress"), there's no explicit abort command to clean up. The workflow mentions capturing `original_status` for rollback on abort within `/task:start` itself, but there's no standalone abort for a session that was paused.
- Blocks: ClickUp tasks may remain stuck in "in progress" status after abandoned work sessions.
- Recommended fix: Consider a `/task:abort [id]` command that reverts ClickUp status and cleans up the session file.

**Missing install.sh for specup:**
- Problem: `opencode/specup/README.md` references `install.sh` (line 43-46) for installing specup into a project, but no `install.sh` file exists in the repository.
- Blocks: Users cannot follow the documented installation process for specup.
- Recommended fix: Either create the `install.sh` script or update the README to provide only the manual installation steps.

## Test Coverage Gaps

**No Automated Tests:**
- What's not tested: The entire codebase is prompt/markdown files with no executable code and therefore no test framework. There are no automated tests for:
  - Version consistency across manifests
  - Command file syntax validation
  - Agent frontmatter schema validation
  - Cross-reference validation (referenced agents/skills exist)
  - Markdown structure validation
- Files: All files in `plugins/`, `opencode/`, `.claude-plugin/`
- Risk: Any refactoring (like removing beads) can leave stale references (as currently exists). Version drift goes undetected until users report issues.
- Priority: Medium. A simple CI script could validate: (1) versions match across manifests, (2) referenced agents exist in `agents/` directory, (3) no references to removed features. This would catch the stale beads references and version drift documented above.

**No End-to-End Workflow Validation:**
- What's not tested: The multi-step workflows (`/task:start` through `/task:merge`, `/kas:start` through `/kas:merge`) have no end-to-end validation. Command interactions, error handling paths, and fallback behaviors are tested only manually.
- Files: All command files in `plugins/kas/commands/`, `plugins/task/commands/`
- Risk: Breaking changes in one command silently break downstream commands. The task plugin's dependency chain is especially vulnerable.
- Priority: Low. These are LLM prompt instructions, not traditional code. End-to-end testing would require Claude Code integration tests, which is outside typical scope. The error handling tables in each command file serve as informal test specifications.

---

*Concerns audit: 2026-02-15*
