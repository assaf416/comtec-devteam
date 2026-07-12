// Package config loads devteam configuration from two flat YAML-ish files:
//
//	~/.config/devteam/config.yml   global: server, token, editor, no_color
//	<repo>/.devteam.yml            per-project: project, base_branch, test_cmd, run_cmd
//
// We parse a tiny flat subset ("key: value", "# comments", blank lines) so the
// client has zero external dependencies. The repo file is found by walking up
// from the working directory.
package config

import (
	"bufio"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

type Config struct {
	// global
	Server  string
	Token   string
	Editor  string
	NoColor bool
	// repo
	Project    string
	BaseBranch string
	TestCmd    string
	RunCmd     string
	// where the repo config was found (its dir is the project folder)
	RepoFile string
	Folder   string
}

// Load merges the global config and the nearest .devteam.yml (repo wins for
// repo-scoped keys). startDir is usually the current working directory.
func Load(startDir string) *Config {
	c := &Config{BaseBranch: "main"}

	for k, v := range parseFlat(GlobalPath()) {
		switch k {
		case "server":
			c.Server = v
		case "token":
			c.Token = v
		case "editor":
			c.Editor = v
		case "no_color":
			c.NoColor = truthy(v)
		}
	}

	if rf := findRepoFile(startDir); rf != "" {
		c.RepoFile = rf
		c.Folder = filepath.Dir(rf)
		for k, v := range parseFlat(rf) {
			switch k {
			case "project":
				c.Project = v
			case "base_branch":
				c.BaseBranch = v
			case "test_cmd":
				c.TestCmd = v
			case "run_cmd":
				c.RunCmd = v
			case "server":
				if c.Server == "" {
					c.Server = v
				}
			}
		}
	}
	if c.Folder == "" {
		c.Folder = startDir
	}
	return c
}

// GlobalPath returns the per-user config file path for the current OS.
func GlobalPath() string {
	if runtime.GOOS == "windows" {
		if appdata := os.Getenv("APPDATA"); appdata != "" {
			return filepath.Join(appdata, "devteam", "config.yml")
		}
	}
	if xdg := os.Getenv("XDG_CONFIG_HOME"); xdg != "" {
		return filepath.Join(xdg, "devteam", "config.yml")
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".config", "devteam", "config.yml")
}

// SetGlobal writes/updates a single key in the global config file.
func SetGlobal(key, value string) error {
	path := GlobalPath()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	kv := parseFlat(path)
	kv[key] = value
	var b strings.Builder
	b.WriteString("# devteam global config\n")
	for k, v := range kv {
		b.WriteString(k)
		b.WriteString(": ")
		b.WriteString(v)
		b.WriteString("\n")
	}
	return os.WriteFile(path, []byte(b.String()), 0o600)
}

func findRepoFile(startDir string) string {
	dir := startDir
	for {
		p := filepath.Join(dir, ".devteam.yml")
		if _, err := os.Stat(p); err == nil {
			return p
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return ""
		}
		dir = parent
	}
}

func parseFlat(path string) map[string]string {
	out := map[string]string{}
	f, err := os.Open(path)
	if err != nil {
		return out
	}
	defer f.Close()

	sc := bufio.NewScanner(f)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		idx := strings.Index(line, ":")
		if idx < 0 {
			continue
		}
		key := strings.TrimSpace(line[:idx])
		val := strings.TrimSpace(line[idx+1:])
		val = strings.Trim(val, `"'`)
		out[key] = val
	}
	return out
}

func truthy(v string) bool {
	switch strings.ToLower(strings.TrimSpace(v)) {
	case "1", "true", "yes", "on":
		return true
	}
	return false
}
