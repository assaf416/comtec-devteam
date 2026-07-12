package main

import (
	"os"

	"github.com/cenevo/devteam/cmd"
)

func main() {
	os.Exit(cmd.Execute(os.Args[1:]))
}
