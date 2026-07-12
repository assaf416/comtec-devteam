// Package runner executes a project's local commands (test/run) and streams
// their output to the terminal.
package runner

import (
	"os"
	"os/exec"
	"runtime"
)

// Exec runs a shell command line in dir, streaming stdout/stderr, and returns
// the process exit code (or -1 if it could not start).
func Exec(dir, commandLine string) int {
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("cmd", "/c", commandLine)
	} else {
		shell := os.Getenv("SHELL")
		if shell == "" {
			shell = "/bin/sh"
		}
		cmd = exec.Command(shell, "-c", commandLine)
	}
	cmd.Dir = dir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Start(); err != nil {
		return -1
	}
	if err := cmd.Wait(); err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			return ee.ExitCode()
		}
		return 1
	}
	return 0
}
