---
description: Export a spec-kitty feature spec to ClickUp as a folder with docs, lists, and tasks
argument-hint: [NNN or feature-slug]
---

# /specup.export $ARGUMENTS

Export a local spec-kitty feature spec to ClickUp, creating a folder with docs, lists, and tasks. Idempotent: re-running updates existing items instead of creating duplicates.

## Accepted input

`$ARGUMENTS` is a fuzzy feature identifier:

- Feature number: `011`, `11`, `11-`
- Partial slug: `mcp-agent`, `agent-swarm`
- Full slug: `011-mcp-agent-swarm-orchestration`
- Empty: list available features and ask

## Workflow

### 1) Resolve feature directory

1. List all directories under `kitty-specs/`.
2. Fuzzy-match `$ARGUMENTS` against directory names:
   - Numeric prefix match: `011` matches `011-mcp-agent-swarm-orchestration`
   - Substring match: `agent-swarm` matches `011-mcp-agent-swarm-orchestration`
3. If zero matches: stop, list available features.
4. If multiple matches: present candidates and ask user to pick one.
5. Set `FEATURE_DIR` to the resolved absolute path.

### 2) Load feature artifacts

Read from `FEATURE_DIR`:

| File | Required | ClickUp target |
|------|----------|----------------|
| `meta.json` | yes | Folder name and metadata |
| `spec.md` | yes | Doc: Specification |
| `plan.md` | no | Doc: Implementation Plan |
| `research.md` | no | Doc: Research |
| `data-model.md` | no | Doc: Data Model |
| `quickstart.md` | no | Doc: Quickstart |
| `tasks.md` | no | Reference for WP overview |
| `tasks/WP*.md` | no | List items (one task per WP) |
| `checklists/*.md` | no | Checklist items on a task |
| `contracts/*.json` | no | Attached or inlined in a doc |

If `meta.json` is missing, stop with an error.

### 3) Load or create sync tracking file

Check for `FEATURE_DIR/.specup-sync.json`. This file tracks ClickUp IDs for idempotent updates:

```json
{
  "folder_id": null,
  "space_id": null,
  "docs": {},
  "lists": {},
  "tasks": {},
  "last_synced": null
}
```

If the file exists, load it. If not, initialize an empty tracking structure.

### 4) Determine ClickUp destination

Resolve the target Space (and optional parent Folder) in this order:

1. If `space_id` is already in the per-feature sync file, use it.
2. Otherwise, read `.specup.json` from the project root (created by `/specup.setup`). Use `clickup.space_id` and `clickup.parent_folder_id` from that file.
3. If `.specup.json` does not exist, ask the user to run `/specup.setup` first and stop.

Store the resolved `space_id` in the per-feature sync file for future runs.

### 5) Create or update ClickUp Folder

**If `folder_id` is in sync file:** Verify folder still exists. Update name if it changed.

**If no `folder_id`:** Search the target Space for a folder whose name starts with the feature number (for example `011 -`). If found, reuse it and store the ID. Otherwise create a new folder:

- Name: `{feature_number} - {friendly_name}` (from `meta.json`)

Use `clickup_create_folder` or equivalent MCP tool. Store `folder_id` in sync file.

### 6) Export documents

For each document artifact that exists locally, create or update a ClickUp Doc (or page/task with the content as description, depending on available MCP tools):

| Local file | ClickUp Doc name |
|------------|-------------------|
| `spec.md` | Specification |
| `plan.md` | Implementation Plan |
| `research.md` | Research |
| `data-model.md` | Data Model |
| `quickstart.md` | Quickstart |

For each doc:

1. Check sync file for existing doc ID.
2. If exists: update content.
3. If not: create new doc/page in the folder.
4. Store doc ID in sync file under `docs.<filename>`.

**Tool discovery:** Try `clickup_create_doc` or similar. If doc creation tools are unavailable, fall back to creating a List named "Documents" in the folder and adding each document as a task with the markdown content in the description field. Note the fallback in output.

### 7) Export work packages as a task list

If `tasks/` directory contains WP files:

1. **Create or reuse List:** Check sync file for `lists.work_packages`. If missing, search folder for a List named "Work Packages". If not found, create it. Store list ID.

2. **For each WP file** (`tasks/WPxx-slug.md`):

   a. Parse YAML frontmatter to extract:
      - `work_package_id` (WP01, WP02, ...)
      - `title`
      - `lane` (planned / doing / for_review / done)
      - `dependencies`
      - `subtasks` array (T001, T002, ...)
      - `phase`

   b. Check sync file for existing task ID under `tasks.<wp_id>`.

   c. **If task exists:** Update name, status, and description.

   d. **If task does not exist:** Create task in the Work Packages list:
      - Name: `WP{xx} - {title}`
      - Description: The full WP prompt body (markdown below the frontmatter)
      - Status: Map `lane` to ClickUp status:

        | spec-kitty lane | ClickUp status |
        |-----------------|----------------|
        | `planned` | to do |
        | `doing` | in progress |
        | `for_review` | ready for review |
        | `done` | complete |

      - Priority: Derive from phase ordering (Phase 0 = urgent, later phases = normal)
      - Tags: Add phase name as tag

   e. Store task ID in sync file under `tasks.<wp_id>`.

   f. **Subtasks:** For each `Txxx` in the WP's `subtasks` array, find its description from `tasks.md` (checkbox lines like `- [x] T001 Description`). Create or update ClickUp subtasks on the WP task. Mark checked items as resolved.

   g. **Dependencies:** If the WP has dependencies (e.g., `["WP01"]`), and the dependency WP was already exported (ID in sync file), set the ClickUp task dependency. If dependency tools are unavailable, note the dependency in the task description instead.

### 8) Export checklists

If `checklists/` contains files:

1. Create or reuse a task named "Quality Checklists" in the Work Packages list (or in Documents fallback list).
2. Parse checklist markdown items (`- [ ]` / `- [x]`).
3. Add as ClickUp checklist items on that task.

### 9) Persist sync file

Write the updated tracking structure to `FEATURE_DIR/.specup-sync.json` with `last_synced` set to current ISO timestamp.

### 10) Return completion summary

```
Exported: {feature_number} - {friendly_name}
Folder:   {clickup_folder_url}
Docs:     {count} created, {count} updated
Tasks:    {count} WPs exported to "Work Packages" list
Subtasks: {count} subtask items synced
Skipped:  {list of unavailable artifacts}

Sync file: {FEATURE_DIR}/.specup-sync.json
Run again to update.
```

## Error handling

- If feature directory not found: list available features and stop.
- If `meta.json` missing: stop with clear error.
- If ClickUp MCP tools are unavailable: stop and explain that MCP auth is needed.
- If a specific MCP tool is missing (for example doc creation): fall back to task-based alternatives and note in output.
- If a create/update call fails: report the error for that item, continue with remaining items, and summarize failures at the end.
- Never silently skip artifacts. Always report what was exported and what was not.

## Idempotency rules

- The `.specup-sync.json` file is the source of truth for ClickUp IDs.
- Before creating anything, check the sync file first, then search ClickUp as a fallback.
- Folder name matching uses the feature number prefix (for example `011 -`) to catch renamed folders.
- Task matching within a list uses the `WPxx` prefix in the name.
- On successful create or update, immediately write the ID to the sync file (don't batch).
- If the sync file exists but a referenced ClickUp item was deleted, detect the 404/not-found and recreate.
