# Testing Patterns

**Analysis Date:** 2026-02-15

## Test Framework

**Runner:**
- No automated test framework detected. This is a **Markdown-as-code** codebase (Claude Code plugin marketplace) — there are no `.test.*`, `.spec.*`, `jest.config.*`, `vitest.config.*`, or equivalent test configuration files.

**Assertion Library:**
- Not applicable — no programmatic tests exist.

**Run Commands:**
```bash
# No test commands available in this repository
# Validation is manual via Claude Code CLI:
claude plugin validate ./plugins/your-plugin    # Validate plugin manifest
claude --plugin-dir ./plugins/kas -p "test your commands"  # Manual integration test
```

## Testing Strategy

This codebase uses a **review-agent-based quality assurance** approach instead of traditional automated tests. Quality is enforced through structured AI agent reviews at multiple stages of the workflow.

### Quality Assurance Architecture

```
Code Changes
    │
    ├── Tier 1: Static Analysis (parallel agents)
    │     ├── code-reviewer (always for code)
    │     ├── silent-failure-hunter (error handling changes)
    │     ├── comment-analyzer (doc/comment changes)
    │     ├── type-design-analyzer (type/schema changes)
    │     └── pr-test-analyzer (test file changes)
    │
    ├── Tier 2: Reality Assessment
    │     └── project-reality-manager (validates plan completion)
    │
    └── Tier 3: Polish (only if VERIFIED)
          └── code-simplifier (optional suggestions)
```

### Agent Selection Logic

Defined in `plugins/kas/commands/verify.md`:

| Change Pattern | Agents Triggered |
|----------------|-----------------|
| Any code changes | `code-reviewer` (always) |
| try/catch, error handling | + `silent-failure-hunter` |
| Comments, docstrings, JSDoc | + `comment-analyzer` |
| Type definitions, interfaces, schemas | + `type-design-analyzer` |
| Test files, describe/it/test blocks | + `pr-test-analyzer` |
| Markdown/docs only | Skip Tier 1, proceed to Tier 2 |
| Config files only | `code-reviewer` only, then Tier 2 |
| No changes (empty diff) | Exit early, no agents launched |

## Test File Organization

**Location:**
- No test files exist in this repository. Test-related patterns documented below are for **target projects** that use this plugin.

**Plugin validation:**
- Plugin manifest validation: `claude plugin validate ./plugins/<name>` (per `CONTRIBUTING.md`)
- Manual command testing: `claude --plugin-dir ./plugins/<name> -p "test your commands"` (per `CONTRIBUTING.md`)

## Test Structure (Agent-Based Reviews)

**Suite Organization — Verification Command (`/kas:verify`):**

The verification workflow in `plugins/kas/commands/verify.md` acts as the "test suite":

```markdown
### Step 1: Check scope and determine relevant agents
- git status / git diff --stat / git diff
- If empty diff → "Nothing to verify" and stop

### Step 2: Tier 1 - Static Analysis (parallel)
- Launch relevant agents based on change pattern analysis
- Exit conditions:
  - Critical/High issues → BLOCKED (stop)
  - Medium issues → NEEDS CHANGES (stop)
  - All clean → Continue to Tier 2

### Step 3: Tier 2 - Reality Assessment
- Always runs if Tier 1 clean or skipped
- Validates implementation matches plan
- Exit conditions:
  - Gaps found → NEEDS CHANGES (stop)
  - Severe gaps → BLOCKED (stop)
  - Clean → VERIFIED (continue)

### Step 4: Tier 3 - Polish (optional)
- Only if VERIFIED and code changes exist
- code-simplifier suggestions (non-blocking)
```

**Review Output Structure (all agents follow this pattern):**

```markdown
## Code Review Summary

**Overall Assessment:** [APPROVED | NEEDS CHANGES | REJECTED]

**Severity Distribution:**
- Critical: [count]
- High: [count]
- Medium: [count]
- Low: [count]

### Critical Issues

#### [Issue Title]
**File:** `path/to/file.ts:line`
**Severity:** Critical (95)
**Problem:** [description]
**Why it matters:** [impact]
**Fix:** [recommendation]

### Positive Observations
- [What's done well]
```

## Mocking

**Framework:** Not applicable — no programmatic mocking.

**Subagent Delegation Pattern (functional equivalent of mocking):**

The `task` plugin's approach to ClickUp API isolation serves as the codebase's equivalent of dependency mocking. All external API calls are delegated to dedicated subagents to keep the main conversation context clean:

```markdown
# From plugins/task/CLAUDE.md:
# "NEVER call ClickUp MCP tools directly in main context."

Task tool with subagent_type="task:clickup-task-agent":
"[Operation]: [specific instructions]
Return ONLY: [concise format]"
```

**What to isolate (documented subagent patterns):**
- ClickUp API calls → `clickup-task-agent` (model: haiku)
- Browser automation → `browser-automation` agent (model: sonnet)
- Code review → `code-reviewer` agent (model: opus)
- Plan review → `plan-reviewer` agent (model: sonnet)
- Reality assessment → `project-reality-manager` agent (model: opus)

**Standardized subagent prompts:**
- Copy-paste templates in `plugins/task/skills/task-workflow/references/subagent-prompts.md`
- Each prompt specifies: operation, MCP tool calls, and required return format

## Fixtures and Factories

**Test Data:**
- No test fixtures or factories exist.
- The `plugins/task/skills/task-workflow/references/task-templates.md` file provides templates for ClickUp task descriptions (feature, bug, refactor, chore types).

**Description templates used as fixtures (`opencode/specup/commands/specup.new.md`):**

```markdown
### Feature template:
## Summary
[What this adds and why it matters]
## Context
- **Why**: [problem to solve]
- **Impact**: [what improves]
## Acceptance Criteria
- [ ] [specific, testable outcome]

### Bug template:
## Summary
[Current behavior vs expected behavior]
## Steps to Reproduce
1. [step]
## Acceptance Criteria
- [ ] Bug is no longer reproducible

### Refactor template:
## Summary
[What is being improved and why]
## Current State / ## Target State
## Acceptance Criteria
- [ ] Behavior remains correct
- [ ] Code is simpler or more maintainable
```

## Coverage

**Requirements:** No coverage enforcement — no automated tests exist.

**Quality gate equivalent:**
- Run review agents before every commit (documented in `plugins/kas/CLAUDE.md`)
- Run `pr-test-analyzer` for test coverage assessment on target projects
- All Critical and High issues must be resolved before committing

**View Coverage:**
```bash
# No coverage tooling in this repository
# For target projects, the plugin delegates to project-native tools:
npm test              # JavaScript/TypeScript
pytest                # Python
cargo test            # Rust
go test ./...         # Go
```

## Test Types

**Unit Tests:**
- Not present. Plugin validation (`claude plugin validate`) is the closest equivalent.

**Integration Tests:**
- Manual: `claude --plugin-dir ./plugins/kas -p "test your commands"` per `CONTRIBUTING.md`
- No automated integration test suite exists.

**E2E Tests:**
- Not present. The `browser-automation` agent (`plugins/kas/agents/browser-automation.md`) provides browser-based E2E testing capabilities for **target projects**, not for this repository itself.

**Plan Review (Design-Level Testing):**
- `plugins/kas/agents/plan-reviewer.md` reviews implementation plans before execution
- Checks: requirements clarity, architecture fit, security, testing strategy, implementation accuracy
- Verdict: `APPROVED`, `NEEDS REVISION`, `BLOCKED`
- Auto-triggered by `/kas:start` workflow — never skip

**Reality Assessment (Acceptance Testing Equivalent):**
- `plugins/kas/agents/project-reality-manager.md` validates claimed completions
- Extreme skepticism: verifies what actually works vs what merely exists in code
- Checks: end-to-end functionality, error handling, integration completeness
- Verdict via gap analysis with severity ratings

## Common Patterns

**Verification workflow (the primary "test" pattern):**

```markdown
# From plugins/kas/commands/verify.md
# This is the canonical quality gate pattern

1. Check git diff for changes
2. Classify change type (code, docs, config, tests, types, error handling)
3. Select relevant Tier 1 agents based on change classification
4. Run Tier 1 agents in parallel
5. If issues found → BLOCKED or NEEDS CHANGES → stop
6. Run Tier 2 reality assessment
7. If gaps found → stop
8. If VERIFIED → optionally run Tier 3 (code-simplifier)
9. Present findings and wait for user approval before applying fixes
```

**Error handling validation pattern (from agents):**

```markdown
# From plugins/kas/agents/code-reviewer.md

### Error Handling checklist:
- Are all error paths handled?
- Are errors logged appropriately?
- Can failures be recovered?
- Are error messages helpful?

# From plugins/kas/agents/project-reality-manager.md

### Reality Assessment checklist:
- [ ] Testing the actual functionality end-to-end
- [ ] Verifying it meets requirements
- [ ] Checking for unnecessary complexity
- [ ] Ensuring it follows project conventions
```

**Pre-commit quality gate pattern (from CLAUDE.md):**

```markdown
# Quality gates run BEFORE committing:
1. Run relevant review agents
2. Summarize findings to user
3. User approves fixes or provides direction
4. Implement fixes
5. Re-run if needed
6. Proceed only when clean
```

**Plugin validation pattern (from CONTRIBUTING.md):**

```bash
# Validate manifest structure
claude plugin validate ./plugins/your-plugin

# Test with isolated plugin directory
claude --plugin-dir ./plugins/your-plugin -p "test your commands"
```

## Tiered Review Configuration

The review system in `plugins/kas/commands/verify.md` uses environment variables for configuration:

```markdown
# Default reviewer settings (from plugins/kas/.opencode/command/kas.review.md):
- model: anthropic/claude-opus-4-6
- reasoning/variant: high
- Override: KAS_REVIEW_MODEL, KAS_REVIEW_VARIANT, KAS_REVIEW_AGENT
```

## Post-Review Automation

When reviews fail for WP-scoped work (`plugins/kas/.opencode/command/kas.review.md`):

```bash
# Feedback is persisted for traceability:
.kas/review-<WP>.feedback.md    # Full structured review output
.kas/review-<WP>.last.txt       # Last review result

# WP is moved back to implementation lane:
spec-kitty agent tasks move-task <WP> \
  --feature <spec> \
  --to doing \
  --review-feedback-file .kas/review-<WP>.feedback.md \
  --reviewer ${KAS_REVIEW_AGENT:-reviewer} \
  --force --no-auto-commit
```

## Testing Gaps

**No automated tests for:**
1. Plugin manifest validity (could add CI with `claude plugin validate`)
2. Markdown structure conformance (command files follow template but no linter enforces it)
3. Cross-reference integrity (commands reference agents that may not exist)
4. YAML frontmatter validation (required fields not programmatically checked)
5. Workflow correctness (no integration tests verify the full /kas:start → /kas:done pipeline)

**Recommendations for adding tests:**
- Add a CI job running `claude plugin validate` on all plugin directories
- Add a Markdown linter (markdownlint) with custom rules for command/agent structure
- Add a script to verify all agent references in commands resolve to existing files
- Add YAML frontmatter schema validation for agent and command files

---

*Testing analysis: 2026-02-15*
