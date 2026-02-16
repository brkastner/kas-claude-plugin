---
description: Verify ClickUp MCP connection and save the default Space for this project
---

# /specup.setup

First-time setup for specup. Verifies the ClickUp MCP server is reachable and authenticated, then saves the default ClickUp Space (and optional parent Folder) for this project so that `/specup.export` and `/specup.new` know where to operate without asking each time.

## Workflow

### 1) Verify ClickUp MCP server connectivity

Run a lightweight read-only MCP call to confirm the server is reachable and the user is authenticated. A good candidate is listing workspaces/teams, or fetching the authenticated user:

1. Try calling `clickup_get_teams` (or `clickup_get_authorized_teams`, `clickup_get_user`, or whichever read-only tool is available).
2. Parse the response.

**If successful:**

```
ClickUp MCP: connected
User: {name or email from response}
Teams: {team names}
```

**If the call fails or the tool is not found:**

- If the error indicates auth failure (401, token invalid, OAuth expired): instruct the user to re-authenticate:

  > ClickUp MCP server returned an authentication error.
  > Re-run OAuth by restarting your editor or re-adding the MCP server.
  > Config location: `.mcp.json` (should contain `https://mcp.clickup.com/mcp`)

- If the MCP server itself is unreachable (connection refused, tool not registered): confirm `.mcp.json` exists and contains the clickup entry, then stop:

  > ClickUp MCP server is not available. Ensure `.mcp.json` includes:
  >
  > ```json
  > {
  >   "mcpServers": {
  >     "clickup": {
  >       "type": "http",
  >       "url": "https://mcp.clickup.com/mcp"
  >     }
  >   }
  > }
  > ```
  >
  > Then restart your editor to load the MCP server.

Stop here if connectivity or auth fails. The remaining steps require a working connection.

### 2) List available Spaces

Once authenticated, fetch the user's Spaces:

1. Call `clickup_get_spaces` (or equivalent) for the team/workspace from step 1.
2. Present a numbered list:

```
Available Spaces:

1. Engineering (id: 12345)
2. Product (id: 67890)
3. Personal (id: 11111)

Which Space should specup use as the default for this project?
(Enter number, Space name, or Space ID)
```

If only one Space exists, confirm it rather than asking.

### 3) Optionally select a parent Folder

After the user picks a Space, ask whether exports should go into the Space root or a specific Folder:

> Place feature folders directly in the Space root, or inside an existing Folder?
>
> 1. Space root (features become top-level Folders)
> 2. Inside an existing Folder (I'll list them)

If the user chooses option 2:

1. Fetch Folders in the selected Space.
2. Present the list for selection.
3. Store the chosen `parent_folder_id`.

### 4) Select a default List for task creation

`/specup.new` needs a List to create tasks in. Fetch the Lists in the selected Space (or parent Folder if one was chosen) and present them:

```
Available Lists:

1. Backlog (id: 900111)
2. Sprint 12 (id: 900222)
3. Inbox (id: 900333)

Which List should /specup.new use for new tasks?
(Enter number, List name, or List ID)
```

If only one List exists, confirm it rather than asking. Store the chosen `default_list_id`.

### 5) Save project config

Write `.specup.json` in the project root (same directory where `kitty-specs/` lives):

```json
{
  "clickup": {
    "space_id": "<selected_space_id>",
    "space_name": "<selected_space_name>",
    "parent_folder_id": null,
    "parent_folder_name": null,
    "default_list_id": "<selected_list_id>",
    "default_list_name": "<selected_list_name>",
    "team_id": "<team_id>",
    "user": "<authenticated_user_name>"
  },
  "configured_at": "<ISO timestamp>",
  "version": 1
}
```

`parent_folder_id` and `parent_folder_name` are `null` when exporting to the Space root.
`default_list_id` is the List where `/specup.new` creates tasks.

**If `.specup.json` already exists:** Read it, show current settings, and ask whether to update or keep them. Only overwrite on explicit confirmation.

### 6) Update .gitignore

Check if `.specup.json` is already covered by `.gitignore`. If not, append it:

```
# specup project config (contains ClickUp workspace IDs)
.specup.json
```

Also ensure `.specup-sync.json` patterns are ignored (these live inside feature dirs):

```
# specup per-feature sync state
**/.specup-sync.json
```

If both patterns are already present, skip this step.

### 7) Return summary

```
specup setup complete

MCP server:  connected ({user})
Space:       {space_name} ({space_id})
Parent:      {folder_name or "Space root"}
Config:      .specup.json (saved)
.gitignore:  updated

Ready to use:
  /specup.new        - create a ClickUp task
  /specup.import     - import ClickUp context into a spec-kitty feature spec
  /specup.export     - export a spec-kitty feature spec to ClickUp
```

## Error handling

- MCP not reachable: show `.mcp.json` fix instructions and stop.
- Auth failure: show re-auth instructions and stop.
- No Spaces found: suggest checking ClickUp workspace membership and stop.
- User cancels at any prompt: stop without writing config.
- File write failure: report path and error.
