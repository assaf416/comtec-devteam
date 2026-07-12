package cmd

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"github.com/cenevo/devteam/internal/api"
	"github.com/cenevo/devteam/internal/ui"
)

const ticketHelp = `Work with a ticket and the git branch behind it.

USAGE
  devteam ticket <id> <action> [flags]

ACTIONS
  show              Status, assignee, branch, PR
  open              Switch to the ticket branch (create from base if nil)
  start             Status → in_progress
  stop              Pause the work session (no status change)
  done              Status → done (alias: complete)
  status <value>    Set an explicit status
  commit [-m msg]   Commit staged changes on the ticket branch
  push              Push branch + show PR

FLAGS
  --base <branch>   Base for new branches (default: config base_branch or main)
  -m, --message     Commit message
  --no-switch       Don't change the local branch on open
`

func cmdTicket(ctx *Context, args []string) int {
	if len(args) == 0 || args[0] == "-h" || args[0] == "--help" {
		fmt.Print(ticketHelp)
		return 0
	}

	id, err := strconv.Atoi(args[0])
	if err != nil {
		ui.Fail("expected a numeric ticket id, got %q", args[0])
		return 2
	}
	action := "show"
	if len(args) > 1 {
		action = args[1]
	}
	rest := args[2:]

	client, err := ctx.api()
	if err != nil {
		ui.Fail("%v", err)
		return 1
	}
	t, err := client.GetTicket(id)
	if err != nil {
		ui.Fail("%v", err)
		return 1
	}

	switch action {
	case "show":
		return ticketShow(ctx, t)
	case "open":
		return ticketOpen(ctx, t, rest)
	case "start":
		return setStatus(ctx, id, "in_progress", "▶ work session started")
	case "stop":
		ui.OK("⏸ paused work on T-%d (%s)", id, t.Status)
		return 0
	case "done", "complete":
		return setStatus(ctx, id, "done", "✓ marked done")
	case "status":
		if len(rest) == 0 {
			ui.Fail("usage: devteam ticket %d status <value>", id)
			return 2
		}
		return setStatus(ctx, id, rest[0], "status updated")
	case "commit":
		return ticketCommit(ctx, t, rest)
	case "push":
		return doPush(ctx, t.BranchName)
	default:
		ui.Fail("unknown ticket action %q — run `devteam ticket --help`", action)
		return 2
	}
}

func ticketShow(ctx *Context, t *api.Ticket) int {
	fmt.Printf("%s %s\n", ui.Bold(fmt.Sprintf("T-%d", t.ID)), t.Title)
	fmt.Printf("  status   %s\n", t.Status)
	fmt.Printf("  project  %s\n", t.Project.Name)
	branch := t.BranchName
	if branch == "" {
		branch = ui.Dim("(none yet)")
	}
	fmt.Printf("  branch   %s\n", branch)
	if t.Assignee != nil {
		fmt.Printf("  assignee %s\n", t.Assignee.Name)
	}
	if t.PRNumber > 0 {
		fmt.Printf("  pr       #%d %s\n", t.PRNumber, t.PRURL)
	}
	return 0
}

func ticketOpen(ctx *Context, t *api.Ticket, rest []string) int {
	base := flagValue(rest, "--base", firstNonEmpty(ctx.Cfg.BaseBranch, t.Project.DefaultBranch, "main"))
	noSwitch := hasFlag(rest, "--no-switch")

	repo := ctx.repo()
	if !repo.IsRepo() {
		ui.Fail("%s is not a git repository (run inside the project, or set --folder)", ctx.Folder)
		return 1
	}

	branch := t.BranchName
	created := false
	if branch == "" {
		branch = fmt.Sprintf("feature/t-%d-%s", t.ID, slugify(t.Title))
		if !noSwitch {
			if err := repo.CreateAndCheckout(branch, base); err != nil {
				ui.Fail("%v", err)
				return 1
			}
			created = true
		}
		// Persist the branch back to the ticket so teammates land on the same one.
		client, _ := ctx.api()
		if _, err := client.UpdateTicket(t.ID, map[string]any{"branch_name": branch}); err != nil {
			ui.Warn("checked out locally but couldn't save branch to the ticket: %v", err)
		}
	} else if !noSwitch {
		if !repo.BranchExists(branch) {
			_ = repo.Fetch()
			if err := repo.CreateAndCheckout(branch, "origin/"+branch); err != nil {
				if err2 := repo.CreateAndCheckout(branch, base); err2 != nil {
					ui.Fail("%v", err2)
					return 1
				}
				created = true
			}
		} else if err := repo.Checkout(branch); err != nil {
			ui.Fail("%v", err)
			return 1
		}
	}

	ui.OK("T-%d %q", t.ID, t.Title)
	if created {
		ui.OK("branch %s created from %s and checked out", ui.Cyan(branch), ui.Cyan(base))
	} else if noSwitch {
		ui.Info("ticket branch is %s (not switched, --no-switch)", ui.Cyan(branch))
	} else {
		ui.OK("checked out %s", ui.Cyan(branch))
	}
	ui.Tip("`devteam ticket %d start` to begin a work session", t.ID)
	return 0
}

func ticketCommit(ctx *Context, t *api.Ticket, rest []string) int {
	repo := ctx.repo()
	if !repo.IsRepo() {
		ui.Fail("not a git repository")
		return 1
	}
	if err := repo.AddAll(); err != nil {
		ui.Fail("%v", err)
		return 1
	}
	msg := flagValue(rest, "--message", flagValue(rest, "-m", ""))
	if msg == "" {
		// No AI in the CLI yet — derive a sensible default from the ticket.
		msg = fmt.Sprintf("T-%d: %s", t.ID, t.Title)
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

func setStatus(ctx *Context, id int, status, okMsg string) int {
	client, err := ctx.api()
	if err != nil {
		ui.Fail("%v", err)
		return 1
	}
	t, err := client.UpdateTicket(id, map[string]any{"status": status})
	if err != nil {
		ui.Fail("%v", err)
		return 1
	}
	ui.OK("%s — T-%d is now %s", okMsg, id, ui.Blue(t.Status))
	return 0
}

func doPush(ctx *Context, branch string) int {
	repo := ctx.repo()
	if !repo.IsRepo() {
		ui.Fail("not a git repository")
		return 1
	}
	if branch == "" {
		branch, _ = repo.CurrentBranch()
	}
	out, err := repo.Push(branch)
	if err != nil {
		ui.Fail("%v", err)
		return 1
	}
	ui.OK("pushed → origin/%s", branch)
	if out != "" {
		fmt.Println(ui.Dim(out))
	}
	return 0
}

// ── helpers ──────────────────────────────────────────────────────────────────

var slugRe = regexp.MustCompile(`[^a-z0-9]+`)

func slugify(s string) string {
	s = strings.ToLower(s)
	s = slugRe.ReplaceAllString(s, "-")
	s = strings.Trim(s, "-")
	if len(s) > 40 {
		s = strings.Trim(s[:40], "-")
	}
	if s == "" {
		s = "work"
	}
	return s
}

func hasFlag(args []string, name string) bool {
	for _, a := range args {
		if a == name {
			return true
		}
	}
	return false
}

func flagValue(args []string, name, def string) string {
	for i, a := range args {
		if a == name && i+1 < len(args) {
			return args[i+1]
		}
		if strings.HasPrefix(a, name+"=") {
			return strings.TrimPrefix(a, name+"=")
		}
	}
	return def
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if v != "" {
			return v
		}
	}
	return ""
}
