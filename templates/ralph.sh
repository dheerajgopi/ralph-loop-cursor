#!/usr/bin/env bash
# ralph.sh — Ralph Loop for Cursor CLI
#
# Spawns a fresh Cursor agent instance per task until all tasks in tasks.md
# are complete. Each agent starts with a clean context window, preserving
# quality as the conversation history never grows stale.
#
# Usage:
#   ./ralph.sh
#
# Environment variables:
#   MAX_ITERATIONS  Max loop iterations before force-stopping (default: 50)
#   MAX_RETRIES     Max consecutive stalls on the same task before stopping (default: 2)
#   CURSOR_API_KEY  Cursor API key (required)
#   CURSOR_MODEL    Model to use, e.g. claude-3-5-sonnet (optional, uses agent default)
#
# Logs:
#   .ralph/ralph.log              — Appended on every run
#   .ralph/logs/iteration-<N>.log — Per-iteration agent output
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

# Write a timestamped message to stdout and the persistent log file.
log() {
  local msg="[ralph] $*"
  echo "$msg"
  echo "$(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$RALPH_LOG"
}

# Count incomplete tasks (lines matching "- [ ]").
count_remaining() {
  grep -c '^\- \[ \]' "$TASKS_FILE" 2>/dev/null || echo 0
}

# Count completed tasks (lines matching "- [x]").
count_completed() {
  grep -c '^\- \[x\]' "$TASKS_FILE" 2>/dev/null || echo 0
}

# Return a SHA-256 hash of tasks.md, used for stall detection.
hash_tasks() {
  sha256sum "$TASKS_FILE" | awk '{print $1}'
}

iteration=0
consecutive_failures=0  # Tracks back-to-back stalls on the same task.

log "Starting Ralph Loop (MAX_ITERATIONS=$MAX_ITERATIONS, MAX_RETRIES=$MAX_RETRIES)"

while true; do
  iteration=$((iteration + 1))

  # Hard stop — prevents runaway loops.
  if [ "$iteration" -gt "$MAX_ITERATIONS" ]; then
    log "Max iterations ($MAX_ITERATIONS) reached. Stopping."
    exit 1
  fi

  # Pick the first incomplete task. Exit cleanly if none remain.
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

  # Hash tasks.md before the agent runs to detect stalls afterward.
  TASKS_HASH_BEFORE=$(hash_tasks)

  ITERATION_LOG="${LOG_DIR}/iteration-${iteration}.log"
  AGENT_EXIT_CODE=0

  # Build optional --model flag from CURSOR_MODEL env var.
  MODEL_FLAG=""
  if [ -n "$CURSOR_MODEL" ]; then
    MODEL_FLAG="--model $CURSOR_MODEL"
  fi

  # Run a fresh agent instance for this iteration.
  # --force: apply file changes (not just propose them)
  # --trust: skip workspace confirmation prompt in headless mode
  # tee: stream output to terminal and save to per-iteration log
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

  # Stall detection: if tasks.md is unchanged, the agent made no progress.
  # After MAX_RETRIES consecutive stalls on the same task, stop the loop.
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
    consecutive_failures=0  # Progress detected — reset the stall counter.
  fi

  log "Agent instance finished. Looping..."
done
