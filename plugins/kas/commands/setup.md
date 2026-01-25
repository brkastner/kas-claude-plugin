# /kas:setup - Prepare Project for KAS Workflow

Validate prerequisites and verify the environment is ready.

## Workflow

Execute these steps in order. Track results as PASS, FAIL (blocker), or WARN (non-blocking).

### 1. Check Prerequisites

Prerequisites are **BLOCKERS** - setup cannot continue if any fail.

#### 1.1 Check GitHub CLI (gh)

```bash
# Check installed
if ! command -v gh &>/dev/null; then
  echo "[FAIL] gh not found"
  echo "  Install: https://cli.github.com/"
  # BLOCKER
fi

# Check version >= 2.0.0
GH_VERSION=$(gh --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
GH_MAJOR=$(echo "$GH_VERSION" | cut -d. -f1)
GH_MAJOR=${GH_MAJOR:-0}
if [[ "$GH_MAJOR" -lt 2 ]]; then
  echo "[FAIL] gh version $GH_VERSION < 2.0.0"
  echo "  Upgrade: https://cli.github.com/"
  # BLOCKER
fi

# Check authenticated
if ! gh auth status &>/dev/null; then
  echo "[FAIL] gh not authenticated"
  echo "  Run: gh auth login"
  # BLOCKER
fi

# Check repo scope
GH_SCOPES=$(gh auth status 2>&1 | grep -i "token scopes" || true)
if [[ -z "$GH_SCOPES" ]] || ! echo "$GH_SCOPES" | grep -qi "repo"; then
  echo "[FAIL] gh missing 'repo' scope"
  echo "  Run: gh auth refresh -s repo"
  # BLOCKER
else
  echo "[PASS] gh $GH_VERSION (authenticated, repo scope)"
fi
```

#### 1.2 Check Git Configuration

```bash
# Check version >= 2.20.0
GIT_VERSION=$(git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
GIT_MAJOR=$(echo "$GIT_VERSION" | cut -d. -f1)
GIT_MINOR=$(echo "$GIT_VERSION" | cut -d. -f2)
GIT_MAJOR=${GIT_MAJOR:-0}
GIT_MINOR=${GIT_MINOR:-0}
if [[ "$GIT_MAJOR" -lt 2 ]] || [[ "$GIT_MAJOR" -eq 2 && "$GIT_MINOR" -lt 20 ]]; then
  echo "[FAIL] git version $GIT_VERSION < 2.20.0"
  # BLOCKER
fi

# Check user.name configured
GIT_NAME=$(git config --get user.name || true)
if [[ -z "$GIT_NAME" ]]; then
  echo "[FAIL] git user.name not configured"
  echo "  Run: git config --global user.name \"Your Name\""
  # BLOCKER
fi

# Check user.email configured
GIT_EMAIL=$(git config --get user.email || true)
if [[ -z "$GIT_EMAIL" ]]; then
  echo "[FAIL] git user.email not configured"
  echo "  Run: git config --global user.email \"you@example.com\""
  # BLOCKER
else
  echo "[PASS] git $GIT_VERSION (user: $GIT_NAME <$GIT_EMAIL>)"
fi
```

**If any prerequisite fails**: Stop and show all failures with fix instructions. Do not proceed to next steps.

### 2. Check Remote Access

Remote issues are **BLOCKERS** - PR workflow requires push access.

```bash
# Check origin remote exists
ORIGIN_URL=$(git remote get-url origin 2>/dev/null)
if [[ -z "$ORIGIN_URL" ]]; then
  echo "[FAIL] No 'origin' remote configured"
  echo "  Run: git remote add origin <your-repo-url>"
  # BLOCKER
fi

# Test push access with dry-run
PUSH_ERR=$(git push --dry-run origin HEAD 2>&1)
if [[ $? -ne 0 ]]; then
  echo "[FAIL] Cannot push to origin"
  echo "  Error: $PUSH_ERR"
  echo "  Check SSH keys or HTTPS credentials"
  # BLOCKER
else
  echo "[PASS] Remote access verified"
fi
```

### 3. Check Plugin Enablement

Plugin issues are **WARNINGS** - kas workflow works but commands won't auto-load.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
SETTINGS_FILE="$REPO_ROOT/.claude/settings.json"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo "[WARN] No .claude/settings.json found"
  echo "  kas plugin not enabled - commands won't auto-load"
  echo "  Create settings.json and enable plugin? (prompt user)"
  # If user confirms, create:
  # mkdir -p "$REPO_ROOT/.claude"
  # echo '{"enabledPlugins":{"kas@kas-claude-plugins":true}}' > "$SETTINGS_FILE"
  # WARN - continue but note the issue
else
  # Check if kas plugin is enabled (use jq if available, fallback to grep)
  if command -v jq &>/dev/null; then
    ENABLED=$(jq -r '.enabledPlugins["kas@kas-claude-plugins"] // false' "$SETTINGS_FILE" 2>/dev/null)
    if [[ "$ENABLED" == "true" ]]; then
      echo "[PASS] kas plugin enabled"
    else
      echo "[WARN] kas plugin not enabled in settings.json"
      echo "  Enable plugin? (prompt user)"
      # WARN - continue but note the issue
    fi
  else
    # Fallback: check for pattern on same/adjacent lines
    if grep -q '"kas@kas-claude-plugins"[[:space:]]*:[[:space:]]*true' "$SETTINGS_FILE"; then
      echo "[PASS] kas plugin enabled"
    else
      echo "[WARN] kas plugin not enabled in settings.json"
      echo "  Enable plugin? (prompt user)"
      # WARN - continue but note the issue
    fi
  fi
fi

# To enable kas plugin, settings.json needs:
# {
#   "enabledPlugins": {
#     "kas@kas-claude-plugins": true
#   }
# }
```

### 4. Show Summary

Aggregate results and provide final verdict.

```
## Setup Summary

| Check | Status |
|-------|--------|
| gh CLI | [PASS/FAIL] |
| git config | [PASS/FAIL] |
| Remote access | [PASS/FAIL] |
| Plugin enabled | [PASS/WARN] |
```

**Verdict logic:**

- Any `[FAIL]` → "Setup incomplete. Fix the issues above before using kas workflow."
- Only `[WARN]` → "Ready for kas workflow (with warnings). Optional fixes noted above."
- All `[PASS]` → "Ready for kas workflow."

**Severity mapping:**

| Check | Severity | Reason |
|-------|----------|--------|
| Prerequisites (gh, git) | BLOCKER | Cannot function without these |
| Remote access | BLOCKER | Cannot push PRs without access |
| Plugin enabled | WARN | Commands work but won't auto-load |

## Rules

- Prerequisites are BLOCKERS - must all pass before continuing
- Report versions only on failure (keep success output minimal)
- Idempotent: safe to run multiple times
- Non-destructive: never modify without user confirmation
