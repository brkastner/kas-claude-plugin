# specup Instructions

For full command reference, tool lists, and ClickUp reference parsing rules, see [SKILL.md](SKILL.md).

## Core principles

- Keep workflows model-agnostic and self-contained.
- Use ClickUp MCP tools directly (no Claude-specific subagent patterns).
- Keep responses concise and human-readable; never dump raw API payloads.
- If a specific MCP tool is unavailable, fall back to the closest alternative and note the fallback in output.

## spec-kitty integration

- Prefer the spec-kitty CLI for scaffold operations.
- Required create command:

```bash
spec-kitty agent feature create-feature "<kebab-slug>" --json
```

- Parse JSON output and use returned `feature` and `feature_dir` values as source of truth.
- Generate/update `meta.json` and `spec.md` using ClickUp context plus discovery answers.
- Stop after spec generation. Do not run `/spec-kitty.plan` automatically.

## spec.md quality rules

- Focus on user outcomes and requirements; avoid implementation details.
- Include independently testable user scenarios.
- Write functional requirements with stable IDs (`FR-001`, `FR-002`, ...).
- Write measurable success criteria (`SC-001`, `SC-002`, ...).
- Keep clarifications explicit when the user defers decisions.

## Output expectations

At completion of `/specup.import`, return:

1. Feature slug and directory path
2. `spec.md` path
3. Source ClickUp references consumed
4. Suggested next command: `/spec-kitty.plan`

At completion of `/specup.export`, return:

1. Feature slug exported
2. ClickUp folder URL
3. Counts: docs created/updated, tasks exported, subtasks synced
4. Any skipped or failed items
5. Path to `.specup-sync.json`
