package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/fatih/color"
)

const doClientMode = "WITCH_CLIENT_MODE"

func main() {
	if len(os.Args) > 2 && os.Args[1] == doClientMode {
		clientMode(os.Args[2], os.Args[3:])
	} else {
		entrMode()
	}
}

func entrMode() {
	if len(os.Args) < 3 {
		fatal("usage: witch <glob> <command> [args...]")
	}
	self := os.Args[0]
	glob := os.Args[1]
	command := os.Args[2:]
	globs, err := filepath.Glob(glob)
	check(err)
	cmd := exec.Command("entr", append([]string{"-c", self, doClientMode}, command...)...)
	cmd.Stdin = strings.NewReader(strings.Join(globs, "\n"))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	checkExit(cmd.Run())
}

func clientMode(command string, args []string) {
	cmd := exec.Command(command, args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	checkExit(cmd.Run())
	color.Green("ok")
}

func checkExit(err error) {
	if eErr, ok := err.(*exec.ExitError); ok && eErr.ExitCode() != 0 {
		os.Exit(eErr.ExitCode())
	}
	check(err)
}

func check(err error) {
	if err != nil {
		fatal(err)
	}
}

func fatal(v interface{}) {
	fmt.Fprintln(os.Stderr, v)
	os.Exit(1)
}
