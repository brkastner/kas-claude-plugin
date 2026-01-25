# kas Plugin

Workflow automation with session management and code review.

## Features

- **Plan Mode**: Structured planning with review agents before implementation
- **Session Management**: Multi-session workflows with context preservation
- **Code Review**: Parallel code quality + reality assessment
- **Browser Automation**: Subagent-based web testing and scraping

## Prerequisites

- **GitHub CLI** (`gh`) - For PR workflows
- **superpowers plugin** - Brainstorming, subagent spawning, initial reviews (official marketplace)
- **pr-review-toolkit plugin** - Code review agents

## Commands

| Command | Description |
|---------|-------------|
| `/kas:start` | Start structured planning workflow |
| `/kas:setup` | Prepare project: validate prerequisites |
| `/kas:done` | Complete session: commit, push |
| `/kas:save` | Snapshot session: push work, generate continuation prompt |
| `/kas:merge` | Merge PR to main, cleanup worktree |
| `/kas:verify` | Tiered verification: static -> reality -> simplifier |
| `/kas:review-code` | Standalone code review (Linus Torvalds style) |
| `/kas:review-reality` | Standalone reality assessment |
| `/kas:review-plan` | Review plan for security/design issues |

## Agents

| Agent | Purpose | When Used |
|-------|---------|-----------|
| `plan-reviewer` | Review plans for gaps/security | Auto after plan written |
| `code-reviewer` | Code quality review | Via /kas:review-code or /kas:verify |
| `project-reality-manager` | Validate claimed completions | Via /kas:review-reality or /kas:verify |
| `browser-automation` | Web testing and automation | Via browser skill |

## Workflow

```
Plan Mode -> plan-reviewer -> ExitPlanMode -> User Approval
                                                    |
                                                    v
Implementation -> Quality Gates -> /kas:verify
                                                    |
                                                    v
Completion -> /kas:done (commit, push) -> /kas:merge (PR, cleanup)
```

### Multi-Session Pattern

```
Session 1: Plan -> Review -> /clear
Session 2: [Paste prompt] -> Implement -> /kas:save -> /clear
Session 3: [Paste prompt] -> Complete -> /kas:done -> /kas:merge
```

## Critical Rules

1. **Work is NOT complete until `git push` succeeds**
2. **Summarize findings before proceeding** (after reviews)
3. **Quality gates must pass** before committing
4. **Plan mode order matters**: plan-reviewer -> ExitPlanMode

## Configuration

### Quality Gates

Customize per project:
```bash
npm test && npm run lint     # JavaScript
pytest && ruff check .       # Python
cargo test && cargo clippy   # Rust
go test ./... && golangci-lint run  # Go
```

### Branch Naming

- Features: `feat/<description>`
- Bug fixes: `fix/<description>`
- Refactors: `refactor/<description>`

## Troubleshooting

```bash
# Git push fails
git pull --rebase && git push

# Worktree cleanup
git worktree list
git worktree remove <path>
```

## License

MIT
