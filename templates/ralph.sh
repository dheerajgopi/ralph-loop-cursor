#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${SCRIPT_DIR}"
TASKS_FILE="${WORKSPACE}/tasks.md"
MAX_ITERATIONS="${MAX_ITERATIONS:-50}"
MAX_RETRIES="${MAX_RETRIES:-2}"
CURSOR_MODEL="${CURSOR_MODEL:-}"
LOG_DIR="${WORKSPACE}/.ralph/logs"
RALPH_LOG="${WORKSPACE}/.ralph/ralph.log"

mkdir -p "$LOG_DIR"

log() {
  local msg="[ralph] $*"
  echo "$msg"
  echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$RALPH_LOG"
}

count_remaining() {
  grep -c '^\- \[ \]' "$TASKS_FILE" 2>/dev/null || echo 0
}

count_completed() {
  grep -c '^\- \[x\]' "$TASKS_FILE" 2>/dev/null || echo 0
}

hash_tasks() {
  sha256sum "$TASKS_FILE" | awk '{print $1}'
}

iteration=0
consecutive_failures=0

log "Starting Ralph Loop (MAX_ITERATIONS=$MAX_ITERATIONS, MAX_RETRIES=$MAX_RETRIES)"

while true; do
  iteration=$((iteration + 1))

  if [ "$iteration" -gt "$MAX_ITERATIONS" ]; then
    log "Max iterations ($MAX_ITERATIONS) reached. Stopping."
    exit 1
  fi

  TASK=$(grep -m 1 '^\- \[ \]' "$TASKS_FILE" 2>/dev/null || true)

  if [ -z "$TASK" ]; then
    log "All tasks complete! (completed: $(count_completed))"
    exit 0
  fi

  remaining=$(count_remaining)
  completed=$(count_completed)

  log ""
  log "========================================"
  log "Iteration $iteration"
  log "Task: $TASK"
  log "Progress: $completed completed, $remaining remaining"
  log "========================================"
  log ""

  TASKS_HASH_BEFORE=$(hash_tasks)

  ITERATION_LOG="${LOG_DIR}/iteration-${iteration}.log"
  AGENT_EXIT_CODE=0

  MODEL_FLAG=""
  if [ -n "$CURSOR_MODEL" ]; then
    MODEL_FLAG="--model $CURSOR_MODEL"
  fi

  # shellcheck disable=SC2086
  agent -p --force --trust --workspace "$WORKSPACE" $MODEL_FLAG "
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
" 2>&1 | tee "$ITERATION_LOG" || AGENT_EXIT_CODE=$?

  log "Agent exit code: $AGENT_EXIT_CODE"
  log "Iteration log: $ITERATION_LOG"

  TASKS_HASH_AFTER=$(hash_tasks)

  if [ "$TASKS_HASH_BEFORE" = "$TASKS_HASH_AFTER" ]; then
    consecutive_failures=$((consecutive_failures + 1))
    log "WARNING: tasks.md unchanged after agent run (stall $consecutive_failures/$MAX_RETRIES)"

    if [ "$consecutive_failures" -ge "$MAX_RETRIES" ]; then
      log "ERROR: Agent stalled $MAX_RETRIES consecutive times on task: $TASK"
      log "Stopping to prevent infinite loop. Check $RALPH_LOG and logs in $LOG_DIR."
      exit 1
    fi
  else
    consecutive_failures=0
  fi

  log "Agent instance finished. Looping..."
done
