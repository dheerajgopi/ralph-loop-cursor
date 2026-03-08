# Ralph Loop for Cursor CLI

A bash automation loop that spawns fresh Cursor CLI agent instances to work
through a task list until completion.

## Prerequisites

- **Cursor CLI** (`agent` binary):
  ```bash
  curl https://cursor.com/install -fsS | bash
  agent --version  # verify
  ```
- **API Key**: `export CURSOR_API_KEY=your_key_here`
- **Git**: Target project must be a git repository

## Install into Your Project

```bash
cd /path/to/your-project

# Option A: one-liner from GitHub
curl -fsSL https://raw.githubusercontent.com/<owner>/ralph-cursor/main/install.sh | bash

# Option B: clone and run
git clone <repo-url> /tmp/ralph-cursor
/tmp/ralph-cursor/install.sh
```

This creates: `ralph.sh`, `tasks.md`, `.cursor/rules/ralph.mdc`

## Usage

1. Edit `tasks.md` with your tasks (one `- [ ]` per task)
2. Edit `.cursor/rules/ralph.mdc` with project conventions
3. Run: `./ralph.sh`

## Configuration (Environment Variables)

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_ITERATIONS` | `50` | Max loop iterations before stopping |
| `CURSOR_API_KEY` | (required) | Cursor API key |
