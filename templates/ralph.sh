#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${SCRIPT_DIR}"
TASKS_FILE="${WORKSPACE}/tasks.md"
MAX_ITERATIONS="${MAX_ITERATIONS:-50}"

iteration=0

while true; do
  iteration=$((iteration + 1))

  if [ "$iteration" -gt "$MAX_ITERATIONS" ]; then
    echo "[ralph] Max iterations ($MAX_ITERATIONS) reached. Stopping."
    exit 1
  fi

  TASK=$(grep -m 1 '^\- \[ \]' "$TASKS_FILE" 2>/dev/null || true)

  if [ -z "$TASK" ]; then
    echo "[ralph] All tasks complete!"
    exit 0
  fi

  echo ""
  echo "========================================"
  echo "[ralph] Iteration $iteration"
  echo "[ralph] Task: $TASK"
  echo "========================================"
  echo ""

  agent -p --force --trust --workspace "$WORKSPACE" "
You are working through a task list. Follow these steps exactly:

1. Read .cursor/rules/ralph.mdc for project conventions and learnings.
2. Read tasks.md and find the FIRST incomplete task (marked with '- [ ]').
3. Implement ONLY that single task. Do not work on other tasks.
4. After implementation, run any quality checks described in the task or in project conventions.
5. If checks pass:
   a. Mark the task complete in tasks.md by changing '- [ ]' to '- [x]'.
   b. Stage and commit your changes with a descriptive commit message.
   c. Add any learnings or gotchas to .cursor/rules/ralph.mdc under the Learnings section.
6. If checks fail, fix the issues and retry. If you cannot fix them, leave the task incomplete and document what went wrong in .cursor/rules/ralph.mdc.

IMPORTANT: Only work on ONE task per invocation. Be thorough but focused.
"

  echo "[ralph] Agent instance finished. Looping..."
done
