package main

import (
	"fmt"
	"os"
	"os/exec"
	"path"
	"strings"
)

func main() {
	if len(os.Args) != 2 {
		exitUsage()
	}
	parts := strings.Split(os.Args[1], "/")
	if len(parts) != 2 {
		exitUsage()
	}
	home, err := os.UserHomeDir()
	check(err)
	base := path.Join(home, "src", "github.com", parts[0])
	full := path.Join(base, parts[1])
	check(os.MkdirAll(base, 0755))
	cmd := exec.Command("hub", "clone", os.Args[1], full)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	check(cmd.Run())

	fmt.Println("cd " + full)
}

func exitUsage() {
	fmt.Fprintf(os.Stderr, "usage: github <user/repo>")
	os.Exit(1)
}

func check(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
