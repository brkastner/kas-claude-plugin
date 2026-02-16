#!/usr/bin/env bash
set -euo pipefail

# specup installer
# Installs the specup Agent Skill and custom commands into a target project.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

if [ "$TARGET_DIR" = "--help" ] || [ "$TARGET_DIR" = "-h" ]; then
  echo "Usage: install.sh [target-project-dir]"
  echo ""
  echo "Installs specup into the given project directory (default: current directory)."
  echo ""
  echo "What it does:"
  echo "  1. Copies command files to <project>/.opencode/commands/"
  echo "  2. Links the skill to the user-level skills directory"
  echo "  3. Merges ClickUp MCP config into <project>/.mcp.json (or crush.json)"
  echo "  4. Adds .specup.json and .specup-sync.json to .gitignore"
  exit 0
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "specup installer"
echo "================"
echo "Source:  $SCRIPT_DIR"
echo "Target:  $TARGET_DIR"
echo ""

# --- 1. Install custom commands ---
COMMANDS_DIR="$TARGET_DIR/.opencode/commands"
mkdir -p "$COMMANDS_DIR"

for cmd in "$SCRIPT_DIR"/commands/specup.*.md; do
  [ -f "$cmd" ] || continue
  base="$(basename "$cmd")"
  cp "$cmd" "$COMMANDS_DIR/$base"
  echo "  Installed command: $base"
done

echo ""

# --- 2. Install Agent Skill (user-level) ---
SKILLS_DIR="${CRUSH_SKILLS_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/crush/skills}"
SKILL_LINK="$SKILLS_DIR/specup"

mkdir -p "$SKILLS_DIR"

if [ -L "$SKILL_LINK" ]; then
  echo "  Skill symlink already exists: $SKILL_LINK"
  echo "  Updating to point to: $SCRIPT_DIR"
  rm "$SKILL_LINK"
fi

if [ -d "$SKILL_LINK" ]; then
  echo "  Warning: $SKILL_LINK is a directory, not a symlink."
  echo "  Skipping skill link. Remove it manually if you want a symlink."
else
  ln -s "$SCRIPT_DIR" "$SKILL_LINK"
  echo "  Linked skill: $SKILL_LINK -> $SCRIPT_DIR"
fi

echo ""

# --- 3. Merge MCP config ---
MCP_FILE="$TARGET_DIR/.mcp.json"

if [ -f "$MCP_FILE" ]; then
  if grep -q '"clickup"' "$MCP_FILE" 2>/dev/null; then
    echo "  .mcp.json already has clickup entry, skipping"
  else
    echo "  Warning: .mcp.json exists but has no clickup entry."
    echo "  Add this manually to your .mcp.json:"
    echo '    "clickup": { "type": "http", "url": "https://mcp.clickup.com/mcp" }'
  fi
else
  cp "$SCRIPT_DIR/.mcp.json" "$MCP_FILE"
  echo "  Created $MCP_FILE with ClickUp MCP server"
fi

echo ""

# --- 4. Update .gitignore ---
GITIGNORE="$TARGET_DIR/.gitignore"

add_to_gitignore() {
  local pattern="$1"
  local comment="$2"
  if [ -f "$GITIGNORE" ] && grep -qF "$pattern" "$GITIGNORE" 2>/dev/null; then
    return
  fi
  {
    echo ""
    echo "# $comment"
    echo "$pattern"
  } >> "$GITIGNORE"
  echo "  Added to .gitignore: $pattern"
}

touch "$GITIGNORE"
add_to_gitignore ".specup.json" "specup project config (ClickUp workspace IDs)"
add_to_gitignore "**/.specup-sync.json" "specup per-feature sync state"

echo ""
echo "Done. Next steps:"
echo "  1. Restart your editor to load the MCP server"
echo "  2. Run /specup.setup to verify ClickUp auth and pick a Space"
