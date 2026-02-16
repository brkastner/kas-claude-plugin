---
description: Create a spec-kitty feature spec from ClickUp task or list context
argument-hint: <clickup-reference>
---

# /specup.import $ARGUMENTS

Create a new spec-kitty feature spec from ClickUp context.

## Goal

Turn one or more ClickUp references into a high-quality `spec.md` that is ready for `/spec-kitty.plan`.

## Accepted input

`$ARGUMENTS` may include:

- Single task: `CU-abc123`, `#abc123`, `abc123`, `https://app.clickup.com/t/abc123`
- List reference: `list:123456`, list URL forms such as `/list/123456` or `/li/123456`
- Multiple references: `CU-a1b2c3, CU-d4e5f6` (comma or space separated)

If no argument is provided, ask the user for a ClickUp reference and stop.

## Workflow

### 1) Preflight checks

1. Ensure the command runs from a project root where `kitty-specs/` is expected.
2. Ensure `spec-kitty` CLI is installed:

```bash
spec-kitty --version
```

If missing, stop and provide:

```bash
pip install spec-kitty-cli
```

### 2) Parse and normalize ClickUp references

Normalize IDs before MCP calls:

- Strip `CU-` / `cu-`
- Strip leading `#`
- Extract IDs from task URLs
- Detect list references from `list:` prefix or list URL patterns

Deduplicate all resolved IDs.

### 3) Fetch ClickUp context via MCP

1. For each task ID, call `clickup_get_task`.
2. For each list reference, use available list MCP tools (for example `clickup_get_list`) to resolve task IDs, then hydrate each task with `clickup_get_task`.
3. Build a concise context bundle containing:
   - task name
   - status
   - priority
   - description
   - acceptance/checklist items
   - subtasks (if present)
   - useful comments (if available)

If list lookup tools are unavailable, ask the user for explicit task IDs and continue.

### 4) Discovery interview (scope-proportional)

Before writing files, run a short interview:

- Trivial scope: 1-2 questions
- Medium scope: 3-4 questions
- Complex scope: 5+ questions

Cover at least:

1. scope boundaries (what is in/out)
2. target users and expected outcomes
3. constraints and dependencies
4. success signals

Then present a short intent summary and confirm with the user.

### 5) Choose title, mission, and slug

1. Derive a friendly feature title from ClickUp + interview context.
2. Select mission (default `software-dev`; use another mission only if clearly requested).
3. Derive kebab-case slug base from title.

### 6) Create feature scaffold with spec-kitty

Run:

```bash
spec-kitty agent feature create-feature "<slug-base>" --json
```

Parse returned JSON and treat these as source of truth:

- `feature` (full slug with number, for example `014-my-feature`)
- `feature_dir` (absolute path)

### 7) Write `meta.json`

Create or update `<feature_dir>/meta.json` with:

```json
{
  "feature_number": "<NNN>",
  "slug": "<NNN-slug>",
  "friendly_name": "<Friendly Title>",
  "mission": "<mission>",
  "source_description": "ClickUp references: <normalized refs>",
  "created_at": "<ISO timestamp>",
  "target_branch": "main",
  "vcs": "git"
}
```

### 8) Generate `spec.md`

Write `<feature_dir>/spec.md` in spec-kitty style (no frontmatter):

```markdown
# Feature Specification: <Friendly Title>

**Feature Branch**: `<NNN-slug>`
**Created**: <date>
**Status**: Draft
**Input**: ClickUp references + discovery interview

## User Scenarios & Testing *(mandatory)*
### User Story 1 - <title> (Priority: P1)
...

### Edge Cases
- ...

## Requirements *(mandatory)*
### Functional Requirements
- **FR-001**: ...
- **FR-002**: ...

### Key Entities
- **Entity**: ...

## Success Criteria *(mandatory)*
### Measurable Outcomes
- **SC-001**: ...
- **SC-002**: ...
```

Mapping guidance:

- Single task: treat it as the primary story; derive additional stories from subtasks/checklists.
- Multi-task/list: map each major task to a candidate story, then merge into a coherent feature narrative.
- Keep requirements technology-agnostic; focus on user/business outcomes.

### 9) Quality validation pass

Validate spec quality before completion:

- no implementation-level details
- clear and testable requirements
- measurable success criteria
- explicit assumptions or clarifications for deferred decisions

If major gaps remain, revise `spec.md` before final output.

### 10) Return completion summary

Return:

1. feature slug
2. feature directory path
3. `spec.md` path
4. ClickUp references consumed
5. suggested next command: `/spec-kitty.plan`

## Error handling

- If no ClickUp data can be resolved, stop and ask for valid task/list references.
- If `spec-kitty` scaffold fails, return the exact error and stop.
- If file write fails, return path + error and stop.
- Never create a partial spec silently.
