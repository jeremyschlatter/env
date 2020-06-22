package main

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/go-logfmt/logfmt"
)

func main() {
	f, err := os.OpenFile(
		os.ExpandEnv("$HOME/.full_history.logfmt"),
		os.O_WRONLY|os.O_APPEND|os.O_CREATE,
		0644,
	)
	check(err)
	defer f.Close()
	host, err := os.Hostname()
	if err != nil {
		host = "unknown_host"
	}
	cwd, err := os.Getwd()
	if err != nil {
		cwd = "unknown_cwd"
	}
	encoder := logfmt.NewEncoder(f)
	check(encoder.EncodeKeyvals(
		"date", time.Now().Format(time.RFC3339),
		"host", host,
		"cwd", cwd,
		"hist", strings.Join(os.Args[1:], " "),
	))
	check(encoder.EndRecord())
	check(f.Sync())
}

func check(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "add-hist: %v\n", err)
		os.Exit(1)
	}
}
