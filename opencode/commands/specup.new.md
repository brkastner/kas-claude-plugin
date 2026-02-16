---
description: Create a new ClickUp task from a short interview flow
argument-hint: [description]
---

# /specup.new $ARGUMENTS

Create a new ClickUp task without Claude-specific dependencies.

## Workflow

1. Gather task input:
   - Task type: `feature`, `bug`, `refactor`, or `chore`
   - Task title
   - Description (use `$ARGUMENTS` as a starting point when provided)
   - Acceptance criteria (bullet points)

2. Build the task description:

```markdown
## Description
{description}

## Acceptance Criteria
- [ ] {criterion 1}
- [ ] {criterion 2}
```

3. Resolve the target List:
   - Read `.specup.json` from the project root and use `clickup.default_list_id`.
   - If `.specup.json` is missing or `default_list_id` is not set, ask the user for a List ID or suggest running `/specup.setup` first.

4. Call ClickUp MCP tool `clickup_create_task` directly with:
   - `list_id`: resolved from step 3
   - `name`: task title
   - `description`: formatted markdown block
   - `tags`: include task type tag

5. Return concise confirmation:

```markdown
**Created:** CU-{id} - {name}
**URL:** {url}
**Next:** /specup.import CU-{id}
```

## Description templates

Use the template matching the selected type.

### Feature

```markdown
## Summary
[What this adds and why it matters]

## Context
- **Why**: [problem to solve]
- **Impact**: [what improves]

## Acceptance Criteria
- [ ] [specific, testable outcome]
```

### Bug

```markdown
## Summary
[Current behavior vs expected behavior]

## Steps to Reproduce
1. [step]
2. [step]

## Acceptance Criteria
- [ ] Bug is no longer reproducible
- [ ] Regression coverage is updated when requested
```

### Refactor

```markdown
## Summary
[What is being improved and why]

## Current State
[brief description]

## Target State
[brief description]

## Acceptance Criteria
- [ ] Behavior remains correct
- [ ] Code is simpler or more maintainable
```

### Chore

```markdown
## Summary
[Maintenance/configuration task]

## Tasks
- [ ] [task]
- [ ] [task]

## Acceptance Criteria
- [ ] Work is complete and verified
```

## Error handling

- If required fields are missing, ask focused follow-up questions.
- If `.specup.json` is missing or has no `default_list_id`, ask the user for a list or suggest `/specup.setup`.
- If `clickup_create_task` fails, report the error and suggest retry.
- If task creation succeeds but URL is missing, still return the task ID.
