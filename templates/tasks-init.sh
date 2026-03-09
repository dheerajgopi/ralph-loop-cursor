#!/usr/bin/env bash
# tasks-init.sh — Converts PLAN.md into a structured tasks.json using the Cursor agent.
#
# Usage:
#   ./tasks-init.sh
#
# Requires:
#   PLAN.md         — Free-form markdown describing what you want to build
#   CURSOR_API_KEY  — Cursor API key (must be exported)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${SCRIPT_DIR}"
PLAN_FILE="${WORKSPACE}/PLAN.md"
TASKS_JSON="${WORKSPACE}/tasks.json"

if [ ! -f "$PLAN_FILE" ]; then
  echo "[tasks-init] ERROR: PLAN.md not found. Write your plan first."
  exit 1
fi

echo "[tasks-init] Converting PLAN.md → tasks.json..."

agent -p --force --trust --workspace "$WORKSPACE" "
Read PLAN.md carefully. Break it down into small, self-contained implementation tasks.

Write the result to tasks.json as a JSON array. Each task must follow this schema exactly:
{
  \"id\": \"task-NNN\",        // sequential: task-001, task-002, ...
  \"title\": \"...\",           // short imperative title
  \"acceptanceCriteria\": [    // 2-5 specific, testable criteria
    \"criterion 1\",
    \"criterion 2\"
  ],
  \"passes\": false            // always false initially
}

Rules:
- Each task must be completable in a single agent context window
- Order tasks by dependency (blockers first)
- Do NOT include anything except the JSON array in tasks.json
- Overwrite tasks.json completely with the result
"

echo "[tasks-init] Done. Review tasks.json before running ralph.sh."
