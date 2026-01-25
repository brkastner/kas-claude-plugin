# /kas:start - Structured Planning Workflow

Entry point for creating implementation plans with proper workflow enforcement.

## Usage

```bash
/kas:start                    # Start planning for current task
/kas:start "Add user auth"    # Start with specific task description
```

## Workflow

### Step 1: Enter Plan Mode

If not already in plan mode, use the **EnterPlanMode tool** to request plan mode from user.

**If already in plan mode:** Skip this step, continue with current plan file.

### Step 2: Explore Phase

Launch Explore agents (1-3 based on scope) to gather codebase context:
- Existing implementations and patterns
- Related components and dependencies
- Testing patterns

**On explore failure:** Report findings so far, ask user how to proceed.

### Step 3: Design Phase

Launch Plan agent with:
- Exploration findings from Step 2
- User requirements

### Step 4: Review & Finalize

1. Read critical files identified by agents
2. Validate alignment with user intent
3. Ask clarifying questions via AskUserQuestion if needed
4. Write final plan to plan file

### Step 5: Review Agent (Auto-triggered)

After plan is written, ALWAYS run before ExitPlanMode:

1. **plan-reviewer** - Check for security gaps, design flaws

### Step 6: Exit Plan Mode

Call ExitPlanMode to present to user:
- The plan
- Review findings

## Error Handling

| Failure | Response |
|---------|----------|
| Already in plan mode | Use existing plan file, continue workflow |
| Explore agent fails | Report partial findings, ask user direction |
| User rejects at review | Ask what to revise, update plan |
| plan-reviewer finds blockers | Show findings, do NOT call ExitPlanMode until resolved |

## Integration Contract (for 3rd Party Skills)

Skills invoking `/kas:start` can depend on:

**Guaranteed after completion:**
- Plan mode was active during planning
- Plan file exists at `.claude/plans/<name>.md`
- plan-reviewer ran (findings available)
- User approved via ExitPlanMode

**Side effects:**
- Plan file written

## Rules

- Never skip plan-reviewer
- Stop after ExitPlanMode - user clears context before implementation
- If plan-reviewer returns BLOCKED, do not exit plan mode
