package cmd

import (
	"fmt"
	"strings"

	"github.com/cenevo/devteam/internal/config"
	"github.com/cenevo/devteam/internal/runner"
	"github.com/cenevo/devteam/internal/ui"
)

// ── test ─────────────────────────────────────────────────────────────────────

func cmdTest(ctx *Context, args []string) int {
	base := ctx.Cfg.TestCmd
	if base == "" {
		ui.Fail("no test command configured — add `test_cmd:` to .devteam.yml (e.g. `test_cmd: bundle exec rspec`)")
		return 1
	}
	line := base
	if len(args) > 0 {
		line = base + " " + strings.Join(args, " ")
	}
	ui.Info("running: %s", ui.Cyan(line))
	code := runner.Exec(ctx.Folder, line)
	if code == 0 {
		ui.OK("tests passed")
	} else {
		ui.Fail("tests failed (exit %d)", code)
	}
	return code
}

// ── run ──────────────────────────────────────────────────────────────────────

func cmdRun(ctx *Context, args []string) int {
	if len(args) > 0 && args[0] == "stop" {
		ui.Info("stop the app with Ctrl-C in its terminal (process management lands with the daemon mode)")
		return 0
	}
	line := ctx.Cfg.RunCmd
	if line == "" {
		ui.Fail("no run command configured — add `run_cmd:` to .devteam.yml (e.g. `run_cmd: bin/dev`)")
		return 1
	}
	ui.Info("starting app: %s", ui.Cyan(line))
	return runner.Exec(ctx.Folder, line)
}

// ── commit (current branch) ────────────────────────────────────────────────────

func cmdCommit(ctx *Context, args []string) int {
	repo := ctx.repo()
	if !repo.IsRepo() {
		ui.Fail("not a git repository")
		return 1
	}
	if err := repo.AddAll(); err != nil {
		ui.Fail("%v", err)
		return 1
	}
	msg := flagValue(args, "--message", flagValue(args, "-m", ""))
	if msg == "" {
		branch, _ := repo.CurrentBranch()
		msg = "WIP on " + branch
	}
	out, err := repo.Commit(msg)
	if err != nil {
		ui.Fail("%v", err)
		return 1
	}
	ui.OK("committed: %s", msg)
	if out != "" {
		fmt.Println(ui.Dim(out))
	}
	return 0
}

// ── push (current branch) ──────────────────────────────────────────────────────

func cmdPush(ctx *Context) int {
	return doPush(ctx, "")
}

// ── status ─────────────────────────────────────────────────────────────────────

func cmdStatus(ctx *Context) int {
	fmt.Printf("%s %s\n", ui.Bold("folder "), ctx.Folder)
	if ctx.Cfg.Project != "" {
		fmt.Printf("%s %s\n", ui.Bold("project"), ctx.Cfg.Project)
	}
	repo := ctx.repo()
	if !repo.IsRepo() {
		ui.Warn("not a git repository here")
	} else {
		branch, _ := repo.CurrentBranch()
		ahead, behind := repo.AheadBehind()
		dirty := "clean"
		if repo.Dirty() {
			dirty = ui.Yellow("dirty")
		}
		fmt.Printf("%s %s  ↑%d ↓%d  %s\n", ui.Bold("branch "), ui.Cyan(branch), ahead, behind, dirty)
	}
	if ctx.Cfg.Server == "" || ctx.Cfg.Token == "" {
		ui.Tip("not logged in — run `devteam config` to set server + token")
	}
	return 0
}

// ── projects ───────────────────────────────────────────────────────────────────

func cmdProjects(ctx *Context) int {
	client, err := ctx.api()
	if err != nil {
		ui.Fail("%v", err)
		return 1
	}
	ps, err := client.ListProjects()
	if err != nil {
		ui.Fail("%v", err)
		return 1
	}
	if len(ps) == 0 {
		ui.Info("no projects")
		return 0
	}
	for _, p := range ps {
		fmt.Printf("  %s  %s\n", ui.Bold(fmt.Sprintf("#%d", p.ID)), p.Name)
		if p.RepoURL != "" {
			fmt.Printf("     %s\n", ui.Dim(p.RepoURL))
		}
	}
	return 0
}

// ── config ─────────────────────────────────────────────────────────────────────

func cmdConfig(ctx *Context, args []string) int {
	if len(args) == 0 {
		fmt.Printf("config file: %s\n", config.GlobalPath())
		fmt.Printf("  server : %s\n", orDash(ctx.Cfg.Server))
		fmt.Printf("  token  : %s\n", masked(ctx.Cfg.Token))
		if ctx.Cfg.RepoFile != "" {
			fmt.Printf("repo file:  %s\n", ctx.Cfg.RepoFile)
			fmt.Printf("  project : %s\n", orDash(ctx.Cfg.Project))
			fmt.Printf("  test_cmd: %s\n", orDash(ctx.Cfg.TestCmd))
			fmt.Printf("  run_cmd : %s\n", orDash(ctx.Cfg.RunCmd))
		}
		ui.Tip("set with: devteam config set server https://hub.local")
		return 0
	}
	switch args[0] {
	case "set":
		if len(args) < 3 {
			ui.Fail("usage: devteam config set <key> <value>   (keys: server, token, editor)")
			return 2
		}
		if err := config.SetGlobal(args[1], args[2]); err != nil {
			ui.Fail("%v", err)
			return 1
		}
		ui.OK("set %s", args[1])
		return 0
	case "path":
		fmt.Println(config.GlobalPath())
		return 0
	default:
		ui.Fail("unknown config subcommand %q (try: set, path)", args[0])
		return 2
	}
}

// ── document ───────────────────────────────────────────────────────────────────

func cmdDocument(ctx *Context, args []string) int {
	ui.Warn("document commands need the documents API on the server (/api/v1/documents), which isn't enabled yet.")
	ui.Tip("planned: devteam document create \"<name>\" --type spec · devteam document <id> translate --to he")
	return 0
}

func orDash(s string) string {
	if s == "" {
		return ui.Dim("—")
	}
	return s
}

func masked(s string) string {
	if s == "" {
		return ui.Dim("—")
	}
	if len(s) <= 6 {
		return "••••"
	}
	return s[:3] + "••••••••"
}
