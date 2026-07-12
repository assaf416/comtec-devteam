// Package gitx wraps the git binary for the operations devteam needs. (A later
// pass can swap to go-git; shelling out keeps the first cut tiny and portable.)
package gitx

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

type Repo struct {
	Dir string
}

func At(dir string) *Repo { return &Repo{Dir: dir} }

func (r *Repo) run(args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	cmd.Dir = r.Dir
	out, err := cmd.CombinedOutput()
	s := strings.TrimSpace(string(out))
	if err != nil {
		return s, fmt.Errorf("git %s: %s", strings.Join(args, " "), s)
	}
	return s, nil
}

// IsRepo reports whether Dir is inside a git work tree.
func (r *Repo) IsRepo() bool {
	_, err := r.run("rev-parse", "--is-inside-work-tree")
	return err == nil
}

func (r *Repo) CurrentBranch() (string, error) {
	return r.run("rev-parse", "--abbrev-ref", "HEAD")
}

func (r *Repo) BranchExists(name string) bool {
	_, err := r.run("rev-parse", "--verify", "--quiet", "refs/heads/"+name)
	return err == nil
}

func (r *Repo) Fetch() error {
	_, err := r.run("fetch", "--quiet", "origin")
	return err
}

func (r *Repo) Checkout(name string) error {
	_, err := r.run("checkout", name)
	return err
}

func (r *Repo) CreateAndCheckout(name, base string) error {
	if base != "" {
		_, _ = r.run("fetch", "--quiet", "origin", base)
		if _, err := r.run("checkout", "-b", name, base); err == nil {
			return nil
		}
		// base may not exist locally as-is; fall back to current HEAD.
	}
	_, err := r.run("checkout", "-b", name)
	return err
}

func (r *Repo) Dirty() bool {
	out, err := r.run("status", "--porcelain")
	return err == nil && out != ""
}

// AheadBehind compares the current branch to its upstream. Returns 0,0 when
// there is no upstream.
func (r *Repo) AheadBehind() (ahead, behind int) {
	out, err := r.run("rev-list", "--left-right", "--count", "@{upstream}...HEAD")
	if err != nil {
		return 0, 0
	}
	fields := strings.Fields(out)
	if len(fields) == 2 {
		behind, _ = strconv.Atoi(fields[0])
		ahead, _ = strconv.Atoi(fields[1])
	}
	return ahead, behind
}

func (r *Repo) AddAll() error {
	_, err := r.run("add", "-A")
	return err
}

func (r *Repo) Commit(message string) (string, error) {
	return r.run("commit", "-m", message)
}

// StagedDiffStat is a short summary used to seed an AI commit message.
func (r *Repo) StagedDiffStat() string {
	out, _ := r.run("diff", "--cached", "--stat")
	return out
}

func (r *Repo) Push(branch string) (string, error) {
	return r.run("push", "--set-upstream", "origin", branch)
}
