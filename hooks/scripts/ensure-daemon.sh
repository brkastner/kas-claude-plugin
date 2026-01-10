#!/bin/bash
# Ensure beads daemon runs with correct flags
# Exit codes: 0 = success, 1 = error (non-fatal, won't block session)

# Check if bd command exists
if ! command -v bd &>/dev/null; then
  echo "beads not installed, skipping daemon check"
  exit 0
fi

# Check if in a beads-enabled directory
if [ ! -d ".beads" ]; then
  echo "Not a beads directory, skipping daemon check"
  exit 0
fi

if status=$(bd daemon --status 2>/dev/null); then
  # Daemon running - check if flags are correct
  if echo "$status" | grep -q "Auto-Commit: true" && echo "$status" | grep -q "Auto-Push: true"; then
    echo "Daemon running with correct flags"
    exit 0
  fi
  # Wrong flags - stop and restart
  echo "Daemon running with wrong flags, restarting..."
  bd daemon --stop 2>/dev/null
  sleep 0.5  # Brief pause to ensure clean shutdown
fi

# Start with correct flags
echo "Starting daemon with --auto-commit --auto-push"
bd daemon --start --auto-commit --auto-push
