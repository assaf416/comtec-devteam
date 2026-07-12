package main_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"testing"

	"github.com/cenevo/devteam/cmd"
	"github.com/cucumber/godog"
)

// ── test world ────────────────────────────────────────────────────────────────

type world struct {
	mu       sync.Mutex
	server   *httptest.Server
	mux      *http.ServeMux
	tickets  map[int]*ticketFixture
	projects []projectFixture
	cfgDir   string   // temp XDG_CONFIG_HOME
	repoDir  string   // temp folder passed via --folder
	stdout   string
	stderr   string
	exitCode int
}

type ticketFixture struct {
	ID         int    `json:"id"`
	Title      string `json:"title"`
	Status     string `json:"status"`
	BranchName string `json:"branch_name,omitempty"`
	Project    struct {
		ID            int    `json:"id"`
		Name          string `json:"name"`
		RepoURL       string `json:"repo_url"`
		DefaultBranch string `json:"default_branch"`
	} `json:"project"`
}

type projectFixture struct {
	ID      int    `json:"id"`
	Name    string `json:"name"`
	RepoURL string `json:"repo_url"`
}

func newWorld() *world {
	return &world{
		tickets:  make(map[int]*ticketFixture),
		projects: []projectFixture{},
	}
}

func (w *world) cleanup() {
	if w.server != nil {
		w.server.Close()
		w.server = nil
	}
	if w.cfgDir != "" {
		os.RemoveAll(w.cfgDir)
		w.cfgDir = ""
	}
	if w.repoDir != "" {
		os.RemoveAll(w.repoDir)
		w.repoDir = ""
	}
}

// ── HTTP mock server ──────────────────────────────────────────────────────────

func (w *world) startServer() {
	w.mux = http.NewServeMux()

	// GET /api/v1/tickets/:id
	w.mux.HandleFunc("/api/v1/tickets/", func(rw http.ResponseWriter, r *http.Request) {
		parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/api/v1/tickets/"), "/")
		id, err := strconv.Atoi(parts[0])
		if err != nil {
			http.Error(rw, "bad id", 400)
			return
		}

		w.mu.Lock()
		t, ok := w.tickets[id]
		w.mu.Unlock()

		if !ok {
			http.Error(rw, `{"error":"not found"}`, 404)
			return
		}

		switch r.Method {
		case http.MethodGet:
			rw.Header().Set("Content-Type", "application/json")
			json.NewEncoder(rw).Encode(t)

		case http.MethodPatch:
			var body struct {
				Ticket map[string]any `json:"ticket"`
			}
			json.NewDecoder(r.Body).Decode(&body)
			w.mu.Lock()
			if s, ok := body.Ticket["status"].(string); ok {
				t.Status = s
			}
			if b, ok := body.Ticket["branch_name"].(string); ok {
				t.BranchName = b
			}
			w.mu.Unlock()
			rw.Header().Set("Content-Type", "application/json")
			json.NewEncoder(rw).Encode(t)

		default:
			http.Error(rw, "method not allowed", 405)
		}
	})

	// GET /api/v1/projects
	w.mux.HandleFunc("/api/v1/projects", func(rw http.ResponseWriter, r *http.Request) {
		w.mu.Lock()
		ps := w.projects
		w.mu.Unlock()
		rw.Header().Set("Content-Type", "application/json")
		json.NewEncoder(rw).Encode(ps)
	})

	w.server = httptest.NewServer(w.mux)
}

// ── config helpers ─────────────────────────────────────────────────────────────

func (w *world) writeConfig(server, token string) error {
	var err error
	w.cfgDir, err = os.MkdirTemp("", "devteam-test-cfg-*")
	if err != nil {
		return err
	}
	cfgPath := filepath.Join(w.cfgDir, "devteam")
	if err := os.MkdirAll(cfgPath, 0o755); err != nil {
		return err
	}
	content := fmt.Sprintf("server: %s\ntoken: %s\n", server, token)
	return os.WriteFile(filepath.Join(cfgPath, "config.yml"), []byte(content), 0o600)
}

func (w *world) ensureRepoDir() error {
	if w.repoDir != "" {
		return nil
	}
	var err error
	w.repoDir, err = os.MkdirTemp("", "devteam-test-repo-*")
	return err
}

// ── output capture ─────────────────────────────────────────────────────────────

func (w *world) run(cmdLine string) {
	// Strip leading "devteam " prefix and split into args.
	cmdLine = strings.TrimPrefix(cmdLine, "devteam ")
	args := splitArgs(cmdLine)

	// Add --folder so config.Load doesn't walk up into the real repo.
	if err := w.ensureRepoDir(); err == nil {
		args = append([]string{"--folder", w.repoDir, "--no-color"}, args...)
	}

	// Redirect stdout.
	origStdout := os.Stdout
	origStderr := os.Stderr
	rOut, wOut, _ := os.Pipe()
	rErr, wErr, _ := os.Pipe()
	os.Stdout = wOut
	os.Stderr = wErr

	// Override XDG_CONFIG_HOME so the test config is used.
	origXDG := os.Getenv("XDG_CONFIG_HOME")
	if w.cfgDir != "" {
		os.Setenv("XDG_CONFIG_HOME", w.cfgDir)
	} else {
		// No config — point at an empty temp dir so real creds are not used.
		empty, _ := os.MkdirTemp("", "devteam-nocfg-*")
		defer os.RemoveAll(empty)
		os.Setenv("XDG_CONFIG_HOME", empty)
	}

	w.exitCode = cmd.Execute(args)

	wOut.Close()
	wErr.Close()
	os.Stdout = origStdout
	os.Stderr = origStderr
	os.Setenv("XDG_CONFIG_HOME", origXDG)

	var bufOut, bufErr bytes.Buffer
	io.Copy(&bufOut, rOut)
	io.Copy(&bufErr, rErr)
	w.stdout = bufOut.String()
	w.stderr = bufErr.String()
}

// splitArgs handles simple quoted arguments (no escaping needed for tests).
func splitArgs(s string) []string {
	var args []string
	var cur strings.Builder
	inQuote := false
	quote := rune(0)
	for _, ch := range s {
		switch {
		case inQuote && ch == quote:
			inQuote = false
		case !inQuote && (ch == '"' || ch == '\''):
			inQuote = true
			quote = ch
		case !inQuote && ch == ' ':
			if cur.Len() > 0 {
				args = append(args, cur.String())
				cur.Reset()
			}
		default:
			cur.WriteRune(ch)
		}
	}
	if cur.Len() > 0 {
		args = append(args, cur.String())
	}
	return args
}

// ── step definitions ──────────────────────────────────────────────────────────

func (w *world) theAPIServerIsRunning() {
	w.startServer()
}

func (w *world) iAmAuthenticated() error {
	if w.server == nil {
		w.startServer()
	}
	return w.writeConfig(w.server.URL, "test-token-123")
}

func (w *world) iAmNotAuthenticated() error {
	var err error
	w.cfgDir, err = os.MkdirTemp("", "devteam-nocfg-*")
	return err
}

func (w *world) aTicketWithIDTitleStatus(id int, title, status string) {
	t := &ticketFixture{ID: id, Title: title, Status: status}
	t.Project.ID = 1
	t.Project.Name = "test-project"
	t.Project.DefaultBranch = "main"
	w.mu.Lock()
	w.tickets[id] = t
	w.mu.Unlock()
}

func (w *world) aTicketWithIDTitleStatusBranch(id int, title, status, branch string) {
	w.aTicketWithIDTitleStatus(id, title, status)
	w.mu.Lock()
	w.tickets[id].BranchName = branch
	w.mu.Unlock()
}

func (w *world) theServerHasProjects(table *godog.Table) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.projects = nil
	for i, row := range table.Rows {
		if i == 0 {
			continue // skip header
		}
		id, _ := strconv.Atoi(row.Cells[0].Value)
		p := projectFixture{
			ID:      id,
			Name:    row.Cells[1].Value,
			RepoURL: row.Cells[2].Value,
		}
		w.projects = append(w.projects, p)
	}
	return nil
}

func (w *world) theServerHasNoProjects() {
	w.mu.Lock()
	w.projects = nil
	w.mu.Unlock()
}

func (w *world) aConfigWithServerAndToken(server, token string) error {
	return w.writeConfig(server, token)
}

func (w *world) iRun(cmdLine string) {
	w.run(cmdLine)
}

func (w *world) theOutputContains(expected string) error {
	combined := w.stdout + w.stderr
	if strings.Contains(strings.ToLower(combined), strings.ToLower(expected)) {
		return nil
	}
	return fmt.Errorf("expected output to contain %q but got:\nSTDOUT: %s\nSTDERR: %s", expected, w.stdout, w.stderr)
}

func (w *world) theExitCodeIs(expected int) error {
	if w.exitCode != expected {
		return fmt.Errorf("expected exit code %d, got %d\nSTDOUT: %s\nSTDERR: %s", expected, w.exitCode, w.stdout, w.stderr)
	}
	return nil
}

// ── godog wiring ──────────────────────────────────────────────────────────────

func initializeScenario(sc *godog.ScenarioContext) {
	w := newWorld()

	sc.After(func(ctx context.Context, sc *godog.Scenario, err error) (context.Context, error) {
		w.cleanup()
		return ctx, nil
	})

	sc.Step(`^the API server is running$`, w.theAPIServerIsRunning)
	sc.Step(`^I am authenticated$`, w.iAmAuthenticated)
	sc.Step(`^I am not authenticated$`, w.iAmNotAuthenticated)

	sc.Step(`^a ticket with id (\d+), title "([^"]+)", status "([^"]+)"$`, w.aTicketWithIDTitleStatus)
	sc.Step(`^a ticket with id (\d+), title "([^"]+)", status "([^"]+)", branch "([^"]+)"$`, w.aTicketWithIDTitleStatusBranch)

	sc.Step(`^the server has projects:$`, w.theServerHasProjects)
	sc.Step(`^the server has no projects$`, w.theServerHasNoProjects)

	sc.Step(`^a config with server "([^"]+)" and token "([^"]+)"$`, w.aConfigWithServerAndToken)

	sc.Step(`^I run "([^"]+)"$`, w.iRun)
	sc.Step(`^the output contains "([^"]+)"$`, w.theOutputContains)
	sc.Step(`^the exit code is (\d+)$`, w.theExitCodeIs)
}

func TestFeatures(t *testing.T) {
	suite := godog.TestSuite{
		ScenarioInitializer: initializeScenario,
		Options: &godog.Options{
			Format:   "pretty",
			Paths:    []string{"features"},
			TestingT: t,
		},
	}
	if suite.Run() != 0 {
		t.Fatal("non-zero status returned, failed to run feature tests")
	}
}
