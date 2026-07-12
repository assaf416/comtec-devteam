// Package cmd implements the devteam command-line dispatch (stdlib only; the
// interactive TUI is a separate, later phase).
package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/cenevo/devteam/internal/api"
	"github.com/cenevo/devteam/internal/config"
	"github.com/cenevo/devteam/internal/gitx"
	"github.com/cenevo/devteam/internal/ui"
)

const Version = "0.1.0"

// Context carries resolved config + globals into each command.
type Context struct {
	Cfg    *config.Config
	JSON   bool
	Yes    bool
	Folder string
}

func (c *Context) api() (*api.Client, error) {
	if c.Cfg.Server == "" || c.Cfg.Token == "" {
		return nil, fmt.Errorf("not logged in — set `server:` and `token:` in %s (or run `devteam config`)", config.GlobalPath())
	}
	return api.New(c.Cfg.Server, c.Cfg.Token), nil
}

func (c *Context) repo() *gitx.Repo { return gitx.At(c.Folder) }

// Execute parses globals, dispatches to a subcommand, and returns an exit code.
func Execute(args []string) int {
	args, ctx := parseGlobals(args)

	if len(args) == 0 {
		// Bare `devteam` will launch the TUI once it's built; for now show status.
		ui.Info("interactive TUI is coming next — showing status (run `devteam --help`)")
		return cmdStatus(ctx)
	}

	switch args[0] {
	case "-h", "--help", "help":
		fmt.Print(helpText)
		return 0
	case "--version", "version":
		fmt.Println("devteam", Version)
		return 0
	case "chat":
		ui.Info("the interactive TUI ships in the next phase. For now use the commands — `devteam --help`.")
		return 0
	case "config":
		return cmdConfig(ctx, args[1:])
	case "status":
		return cmdStatus(ctx)
	case "projects":
		return cmdProjects(ctx)
	case "ticket":
		return cmdTicket(ctx, args[1:])
	case "test":
		return cmdTest(ctx, args[1:])
	case "run":
		return cmdRun(ctx, args[1:])
	case "commit":
		return cmdCommit(ctx, args[1:])
	case "push":
		return cmdPush(ctx)
	case "document", "doc":
		return cmdDocument(ctx, args[1:])
	default:
		ui.Fail("unknown command %q — run `devteam --help`", args[0])
		return 2
	}
}

// parseGlobals strips recognized global flags from anywhere in args.
func parseGlobals(in []string) ([]string, *Context) {
	cwd, _ := os.Getwd()
	ctx := &Context{Folder: cwd}
	var rest []string

	for i := 0; i < len(in); i++ {
		a := in[i]
		switch {
		case a == "--no-color":
			ui.Disable()
		case a == "-y" || a == "--yes":
			ctx.Yes = true
		case a == "--json":
			ctx.JSON = true
		case a == "--folder":
			if i+1 < len(in) {
				ctx.Folder = in[i+1]
				i++
			}
		case strings.HasPrefix(a, "--folder="):
			ctx.Folder = strings.TrimPrefix(a, "--folder=")
		default:
			rest = append(rest, a)
		}
	}

	ctx.Cfg = config.Load(ctx.Folder)
	if ctx.Cfg.Folder != "" {
		ctx.Folder = ctx.Cfg.Folder
	}
	if ctx.Cfg.NoColor {
		ui.Disable()
	}
	return rest, ctx
}

const helpText = `devteam — your DevTeam hub, from the terminal.

USAGE
  devteam [command]
  devteam                       # no command → launch the interactive TUI (coming soon)

WORK
  ticket        Tickets + their git branch   open·start·stop·done·status·commit·push·show
  test          Run tests for a file or folder
  run           Start the app locally
  commit        Stage & commit changes
  push          Push the current branch to origin
  document      Create & manipulate documents

WORKSPACE
  projects      List projects
  status        Folder · branch · ticket · PR at a glance
  config        Get/set config (server, token, …) and init this repo
  version       Print version

GLOBAL FLAGS
  --folder <path>    Project folder (default: current dir or nearest .devteam.yml)
  --json             Machine-readable output
  -y, --yes          Skip confirmation prompts
  --no-color         Disable ANSI color
  -h, --help         Help

EXAMPLES
  devteam ticket 123 open          # checkout the ticket's branch (create if none)
  devteam ticket 123 start         # status → in_progress
  devteam ticket 123 commit -m "…" # commit on the ticket branch
  devteam ticket 123 push          # push + show PR
  devteam test ./app/models        # run a folder's tests
  devteam run                      # boot the app locally

Run "devteam ticket --help" for ticket actions.
`
