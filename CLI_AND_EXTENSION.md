# DevTeam Hub — CLI & VS Code Extension

A developer-facing toolchain that lets your team manage tickets, branch work,
run tests and deploy — all without leaving the terminal or VS Code.

---

## CLI (`devteam`)

### Install (symlink to PATH)

```bash
# From the project root
ln -sf "$(pwd)/cli/devteam" /usr/local/bin/devteam
```

### First-time setup

```bash
devteam setup
# Prompts for Hub URL (default: http://localhost:3000) and your API token.
# Token is at: http://localhost:3000/api/v1/token  (after logging in)
```

### Commands

| Command | Description |
|---|---|
| `devteam setup` | Configure CLI with server URL + API token |
| `devteam whoami` | Show authenticated user info |
| `devteam status` | Show current branch + linked ticket |
| `devteam checkout <T-ID>` | Create/switch to ticket branch |
| `devteam ticket list` | List your assigned tickets |
| `devteam ticket list --all` | List all tickets |
| `devteam ticket list --status in_progress` | Filter by status |
| `devteam ticket show <T-ID>` | Show ticket details |
| `devteam ticket update <T-ID> --status in_review` | Update status |
| `devteam ticket start <T-ID>` | Checkout + set in_progress |
| `devteam ticket done <T-ID>` | Mark ticket done |
| `devteam test` | Run Rails test suite |
| `devteam test test/models/ticket_test.rb` | Run specific file |
| `devteam run` | Start dev server (port 3000) |
| `devteam run --stop` | Stop running server |
| `devteam deploy staging` | Deploy to staging |
| `devteam deploy production` | Deploy to production |
| `devteam pr` | Push branch + open PR URL |
| `devteam log` | Recent git log with ticket links |
| `devteam projects` | List your projects |

### Ticket branch naming

Branches are automatically named:

- `feature/T-<id>-<slug>` for stories
- `bugfix/T-<id>-<slug>` for bug fixes  
- `hotfix/T-<id>-<slug>` for hotfixes
- `chore/T-<id>-<slug>` for meta stories
- `spike/T-<id>-<slug>` for spikes

---

## VS Code Extension

### Install

```bash
cd vscode-extension
npm install
npm run compile
# Then: F5 in VS Code to run Extension Development Host
# Or: npm run package  to produce a .vsix and install via Extensions > Install from VSIX
```

### Features

- **Activity Bar panel** — "DevTeam Hub" sidebar with two views:
  - **My Tickets** — tickets grouped by status (in_progress, in_review, open, backlog)
  - **Projects** — your project memberships
- **Status bar** — shows current ticket when on a `feature/T-X-*` branch
- **Webview** — rich ticket detail panel (side column) with metadata + description
- **Git integration** — auto-detects ticket from branch name; refreshes on branch change
- **Terminal integration** — `Run`, `Test`, `Deploy`, `PR` commands open a named terminal

### Command Palette

All commands are under the `DevTeam:` prefix:

| Command | Description |
|---|---|
| `DevTeam: Setup / Configure` | Enter Hub URL + API token |
| `DevTeam: Who Am I?` | Show current user |
| `DevTeam: Checkout Ticket Branch` | Prompt for ticket ID, run git checkout in terminal |
| `DevTeam: Show Current Status` | Run `devteam status` in terminal |
| `DevTeam: List My Tickets` | Quick-pick from open tickets |
| `DevTeam: Show Ticket Details` | Open ticket in webview panel |
| `DevTeam: Update Ticket Status` | Quick-pick new status |
| `DevTeam: Start Ticket (checkout + in_progress)` | Checkout + set in_progress |
| `DevTeam: Mark Ticket Done` | One-click done |
| `DevTeam: Run Tests` | Quick-pick test mode, run in terminal |
| `DevTeam: Run Dev Server` | `bin/rails server` in terminal |
| `DevTeam: Stop Dev Server` | Kill port 3000 |
| `DevTeam: Deploy...` | Choose staging/production |
| `DevTeam: Create Pull Request` | Push + open PR URL |
| `DevTeam: Open in Browser` | Open Hub in default browser |

### Settings

```json
{
  "devteamHub.apiUrl":   "http://localhost:3000",
  "devteamHub.apiToken": "<your-token>",
  "devteamHub.cliPath":  "/path/to/project/cli/devteam"
}
```

---

## API Token

Each internal user has a unique API token stored in the database.

```bash
# Rails console — print your token
bin/rails runner "puts User.find_by(email: 'you@devteam.local').api_token"

# Or via API (authenticated browser session)
curl http://localhost:3000/api/v1/token -H "Authorization: Bearer <token>"

# Regenerate
curl -X POST http://localhost:3000/api/v1/token/regenerate -H "Authorization: Bearer <token>"
```
