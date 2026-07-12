// Package ui provides small colored-output helpers that respect NO_COLOR and a
// global disable flag.
package ui

import (
	"fmt"
	"os"
)

var enabled = true

func init() {
	if os.Getenv("NO_COLOR") != "" {
		enabled = false
	}
}

// Disable turns off ANSI color (e.g. for --no-color or non-TTY output).
func Disable() { enabled = false }

func paint(code, s string) string {
	if !enabled {
		return s
	}
	return "\033[" + code + "m" + s + "\033[0m"
}

func Green(s string) string  { return paint("32", s) }
func Red(s string) string    { return paint("31", s) }
func Yellow(s string) string { return paint("33", s) }
func Blue(s string) string   { return paint("34", s) }
func Cyan(s string) string   { return paint("36", s) }
func Dim(s string) string    { return paint("2", s) }
func Bold(s string) string   { return paint("1", s) }

func OK(format string, a ...any)   { fmt.Printf(Green("✓ ")+format+"\n", a...) }
func Info(format string, a ...any) { fmt.Printf(Blue("• ")+format+"\n", a...) }
func Warn(format string, a ...any) { fmt.Printf(Yellow("! ")+format+"\n", a...) }
func Tip(format string, a ...any)  { fmt.Println(Dim("↳ " + fmt.Sprintf(format, a...))) }

func Fail(format string, a ...any) {
	fmt.Fprintf(os.Stderr, Red("✗ ")+format+"\n", a...)
}
