# devteam (Go client)

A scriptable command-line client for the DevTeam hub. Phase 1 is the CLI;
the interactive Bubble Tea TUI (`devteam chat`) lands in phase 2.

> Note: this lives alongside the older Ruby prototypes (`cli/devteam`, `cli/dt`).
> The Go client is the one being taken forward; design spec is in
> `public/devteam-cli.html`.

## Build

```sh
cd cli/go
go build -o devteam .      # produces ./devteam (git-ignored)
# optionally: go install .
```

No external dependencies — standard library only.

## Configure

Global config (`~/.config/devteam/config.yml`, or `%APPDATA%\devteam\config.yml`):

```yaml
server: http://localhost:3000
token:  <your api_token>   # from /api/v1 — Settings → token
```

Set it without editing by hand:

```sh
devteam config set server http://localhost:3000
devteam config set token  $TOKEN
```

Per-project config — drop `.devteam.yml` at your repo root (see
`.devteam.yml.example`):

```yaml
project: print-tdi
base_branch: main
test_cmd: bundle exec rspec
run_cmd: bin/dev
```

## Use

```sh
devteam ticket 123 open        # checkout the ticket branch (create if none, persist back)
devteam ticket 123 start       # status → in_progress
devteam ticket 123 status testing
devteam ticket 123 commit -m "…"
devteam ticket 123 push        # push + show PR
devteam test ./app/models      # run test_cmd (optionally scoped to a path)
devteam run                    # run_cmd
devteam status                 # folder · branch · ahead/behind · dirty
devteam projects               # list projects
devteam --help
```

Global flags: `--folder <path>`, `--json`, `-y/--yes`, `--no-color`.

## Layout

```
main.go                 entrypoint
cmd/                    command dispatch (root, ticket, misc)
internal/config         flat-YAML config (global + repo .devteam.yml)
internal/api            /api/v1 client (Bearer api_token)
internal/gitx           git operations (shell)
internal/runner         local test/run command execution
internal/ui             colored output (respects NO_COLOR / --no-color)
```
