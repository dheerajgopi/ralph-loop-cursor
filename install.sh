#!/usr/bin/env bash
# install.sh — Installs Ralph Loop files into the current project.
#
# Usage:
#   # Piped from GitHub (fetches templates remotely):
#   curl -fsSL https://raw.githubusercontent.com/dheerajgopi/ralph-loop-cursor/main/install.sh | bash
#
#   # Cloned locally (uses local templates/):
#   git clone <repo-url> /tmp/ralph-loop-cursor
#   /tmp/ralph-loop-cursor/install.sh [--force]
#
# Options:
#   --force   Overwrite existing files (ralph.sh, tasks-init.sh, tasks.json, progress.txt, ralph.mdc)
set -euo pipefail

FORCE=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
  esac
done

TARGET_DIR="$(pwd)"

# Detect whether the script is running from a local clone or piped via curl.
# BASH_SOURCE[0] is empty or "/dev/stdin" when piped.
INSTALLER_SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "$INSTALLER_SOURCE" ] && [ "$INSTALLER_SOURCE" != "/dev/stdin" ] && [ -f "$INSTALLER_SOURCE" ]; then
  INSTALLER_DIR="$(cd "$(dirname "$INSTALLER_SOURCE")" && pwd)"
  TEMPLATES_DIR="${INSTALLER_DIR}/templates"
  USE_LOCAL=true
else
  # Piped mode: fetch templates from GitHub raw URLs.
  REPO_RAW="https://raw.githubusercontent.com/dheerajgopi/ralph-loop-cursor/main"
  USE_LOCAL=false
fi

echo "[ralph-install] Installing Ralph Loop into: $TARGET_DIR"

# Helpers to read a template either from disk or from GitHub.
read_template() {
  if [ "$USE_LOCAL" = true ]; then
    cat "$TEMPLATES_DIR/$1"
  else
    curl -fsSL "${REPO_RAW}/templates/$1"
  fi
}

# Check: is this a git repo?
if ! git -C "$TARGET_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  echo "[ralph-install] ERROR: Not a git repository. Run this inside a git repo."
  exit 1
fi

# Check: is Cursor CLI installed?
if ! command -v agent &>/dev/null; then
  echo "[ralph-install] WARNING: 'agent' (Cursor CLI) not found."
  echo "  Install it with: curl https://cursor.com/install -fsS | bash"
  echo "  Continuing anyway..."
fi

# Check: is jq installed?
if ! command -v jq &>/dev/null; then
  echo "[ralph-install] WARNING: 'jq' not found. Required for tasks.json parsing."
  echo "  Install it with: sudo apt install jq  OR  brew install jq"
  echo "  Continuing anyway..."
fi

# Install ralph.sh
if [ -f "$TARGET_DIR/ralph.sh" ] && [ "$FORCE" = false ]; then
  echo "[ralph-install] ralph.sh already exists. Use --force to overwrite."
else
  read_template "ralph.sh" > "$TARGET_DIR/ralph.sh"
  chmod +x "$TARGET_DIR/ralph.sh"
  echo "[ralph-install] Created ralph.sh"
fi

# Install tasks-init.sh
if [ -f "$TARGET_DIR/tasks-init.sh" ] && [ "$FORCE" = false ]; then
  echo "[ralph-install] tasks-init.sh already exists. Use --force to overwrite."
else
  read_template "tasks-init.sh" > "$TARGET_DIR/tasks-init.sh"
  chmod +x "$TARGET_DIR/tasks-init.sh"
  echo "[ralph-install] Created tasks-init.sh"
fi

# Install tasks.json
if [ -f "$TARGET_DIR/tasks.json" ] && [ "$FORCE" = false ]; then
  echo "[ralph-install] tasks.json already exists. Skipping."
else
  read_template "tasks.json" > "$TARGET_DIR/tasks.json"
  echo "[ralph-install] Created tasks.json"
fi

# Install progress.txt
if [ -f "$TARGET_DIR/progress.txt" ] && [ "$FORCE" = false ]; then
  echo "[ralph-install] progress.txt already exists. Skipping."
else
  read_template "progress.txt" > "$TARGET_DIR/progress.txt"
  echo "[ralph-install] Created progress.txt"
fi

# Install .cursor/rules/ralph.mdc
mkdir -p "$TARGET_DIR/.cursor/rules"
if [ -f "$TARGET_DIR/.cursor/rules/ralph.mdc" ] && [ "$FORCE" = false ]; then
  echo "[ralph-install] .cursor/rules/ralph.mdc already exists. Skipping."
else
  read_template "ralph.mdc" > "$TARGET_DIR/.cursor/rules/ralph.mdc"
  echo "[ralph-install] Created .cursor/rules/ralph.mdc"
fi

# Add .ralph/ to .gitignore
if [ -f "$TARGET_DIR/.gitignore" ]; then
  if ! grep -q '^\\.ralph/' "$TARGET_DIR/.gitignore"; then
    printf '\n.ralph/\n' >> "$TARGET_DIR/.gitignore"
    echo "[ralph-install] Added .ralph/ to .gitignore"
  fi
else
  echo '.ralph/' > "$TARGET_DIR/.gitignore"
  echo "[ralph-install] Created .gitignore with .ralph/"
fi

echo ""
echo "[ralph-install] Done! Next steps:"
echo "  1. Write your plan in PLAN.md (free-form markdown describing what to build)"
echo "  2. Run: ./tasks-init.sh   # converts PLAN.md → tasks.json"
echo "  3. Edit .cursor/rules/ralph.mdc with project conventions"
echo "  4. export CURSOR_API_KEY=your_key"
echo "  5. ./ralph.sh"
