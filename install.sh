#!/usr/bin/env bash
set -euo pipefail

FORCE=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
  esac
done

# Resolve installer's own directory and templates location
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${INSTALLER_DIR}/templates"
TARGET_DIR="$(pwd)"

echo "[ralph-install] Installing Ralph Loop into: $TARGET_DIR"

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

# Copy ralph.sh
if [ -f "$TARGET_DIR/ralph.sh" ] && [ "$FORCE" = false ]; then
  echo "[ralph-install] ralph.sh already exists. Use --force to overwrite."
else
  cp "$TEMPLATES_DIR/ralph.sh" "$TARGET_DIR/ralph.sh"
  chmod +x "$TARGET_DIR/ralph.sh"
  echo "[ralph-install] Created ralph.sh"
fi

# Copy tasks.md template
if [ -f "$TARGET_DIR/tasks.md" ] && [ "$FORCE" = false ]; then
  echo "[ralph-install] tasks.md already exists. Skipping."
else
  cp "$TEMPLATES_DIR/tasks.md" "$TARGET_DIR/tasks.md"
  echo "[ralph-install] Created tasks.md"
fi

# Copy .cursor/rules/ralph.mdc
mkdir -p "$TARGET_DIR/.cursor/rules"
if [ -f "$TARGET_DIR/.cursor/rules/ralph.mdc" ] && [ "$FORCE" = false ]; then
  echo "[ralph-install] .cursor/rules/ralph.mdc already exists. Skipping."
else
  cp "$TEMPLATES_DIR/ralph.mdc" "$TARGET_DIR/.cursor/rules/ralph.mdc"
  echo "[ralph-install] Created .cursor/rules/ralph.mdc"
fi

# Add .ralph/ to .gitignore
if [ -f "$TARGET_DIR/.gitignore" ]; then
  if ! grep -q '^\\.ralph/' "$TARGET_DIR/.gitignore"; then
    echo '.ralph/' >> "$TARGET_DIR/.gitignore"
    echo "[ralph-install] Added .ralph/ to .gitignore"
  fi
else
  echo '.ralph/' > "$TARGET_DIR/.gitignore"
  echo "[ralph-install] Created .gitignore with .ralph/"
fi

echo ""
echo "[ralph-install] Done! Next steps:"
echo "  1. Edit tasks.md with your tasks"
echo "  2. Edit .cursor/rules/ralph.mdc with project conventions"
echo "  3. export CURSOR_API_KEY=your_key"
echo "  4. ./ralph.sh"
