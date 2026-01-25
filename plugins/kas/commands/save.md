# /kas:save - Session Snapshot

Save session progress for continuation across multiple sessions. Unlike `/kas:done`, this doesn't close all work - it creates a snapshot and generates a continuation prompt.

## Arguments
- `$ARGUMENTS` - Optional context or notes to include in the snapshot

## When to Use

- Pausing work that will continue in another session
- Freeing context without losing progress
- Creating a checkpoint before switching tasks

## Instructions

### 1. Collect Session State

```bash
git status --short
git log --oneline -5
```

### 2. Generate Session Summary

Review and summarize:
- **Completed work**: Recent commits
- **In-progress work**: Uncommitted changes
- **Quality gate status**: Results if run this session
- **Blockers**: Any issues preventing progress

### 3. Stage and Commit Changes (if any)

If there are unstaged changes:
```bash
git add <relevant-files>
git commit -m "<appropriate message>"
```

### 4. Push to Remote

```bash
git pull --rebase
git push
```

### 5. Add PR Comment (if PR exists)

Check for existing PR:
```bash
gh pr view --json url -q .url 2>/dev/null
```

If PR exists, add session snapshot comment:

```bash
gh pr comment --body "$(cat <<'EOF'
## Session Snapshot - {date}

**Completed:**
- {completed_items}

**Quality Gates:** {status}

**Next Session Prompt:**
```
{next_prompt}
```
EOF
)"
```

### 6. Clean Up Git State

```bash
git stash clear
git remote prune origin
```

### 7. Verify Clean State

```bash
git status
```

Must show branch is up to date with origin.

### 8. Output Next Session Prompt

Generate and display prominently for user to copy:

```
Continue work on {feature-name}:
- Resume: {current in-progress work}
- Context: {brief context about blockers or pending work}
```

Display this in a code block for easy copying.

## Key Differences from /kas:done

| Aspect | /kas:save | /kas:done |
|--------|-----------|-----------|
| Work status | Keeps work open | Closes completed work |
| Focus | Session boundary | Task completion |
| Prompt | Continuation-focused | Next task suggestion |
| PR comment | Session snapshot | Optional |

## Rules

- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- If push fails, resolve and retry until it succeeds
- Always generate the next session prompt for easy continuation
