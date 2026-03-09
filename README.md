# Ralph Loop for Cursor CLI

A bash automation loop that spawns fresh Cursor CLI agent instances to work
through a task list (tasks.json) until all tasks pass.

## Prerequisites

- **Cursor CLI** (`agent` binary):
  ```bash
  curl https://cursor.com/install -fsS | bash
  agent --version  # verify
  ```
- **jq**: `sudo apt install jq` or `brew install jq`
- **API Key**: `export CURSOR_API_KEY=your_key_here`
- **Git**: Target project must be a git repository

## Install into Your Project

```bash
cd /path/to/your-project

# Option A: one-liner from GitHub
curl -fsSL https://raw.githubusercontent.com/dheerajgopi/ralph-loop-cursor/main/install.sh | bash

# Option B: clone and run
git clone <repo-url> /tmp/ralph-cursor
/tmp/ralph-cursor/install.sh
```

This creates: `ralph.sh`, `tasks-init.sh`, `tasks.json`, `progress.txt`, `.cursor/rules/ralph.mdc`

## Usage

1. Write your plan: create `PLAN.md` describing what you want to build
2. Convert to tasks: `./tasks-init.sh` → generates `tasks.json`
3. Review `tasks.json` — reorder or edit tasks as needed
4. Edit `.cursor/rules/ralph.mdc` with project conventions
5. Run: `./ralph.sh`

## Configuration (Environment Variables)

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_ITERATIONS` | `50` | Max loop iterations before stopping |
| `MAX_RETRIES` | `2` | Max consecutive stalls on the same task before stopping |
| `CURSOR_API_KEY` | (required) | Cursor API key |
| `CURSOR_MODEL` | (agent default) | Model to use (e.g. `claude-3-5-sonnet`) |

## Logs

Each run appends to `.ralph/ralph.log`. Per-iteration output is saved to `.ralph/logs/iteration-<N>.log`.

The `.ralph/` directory is gitignored by default.
