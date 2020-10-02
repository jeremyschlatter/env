package main

import (
	"fmt"
	"io"
	"os"
	"strings"
	"syscall"
	"time"

	"github.com/go-logfmt/logfmt"
	"go4.org/lock"
)

func main() {
	defer func() {
		if r := recover(); r != nil {
			fmt.Fprintf(os.Stderr, "add-hist: %v\n", r)
			os.Exit(1)
		}
	}()
	host, err := os.Hostname()
	if err != nil {
		host = "unknown_host"
	}
	cwd, err := os.Getwd()
	if err != nil {
		cwd = "unknown_cwd"
	}

	f, err := os.OpenFile(
		os.ExpandEnv("$HOME/.full_history.logfmt"),
		os.O_WRONLY|os.O_APPEND|os.O_CREATE,
		0644,
	)
	check(err)
	defer f.Close()
	encoder := logfmt.NewEncoder(f)

	// Ensure that only one process writes to the history file at a time.
	var histLock io.Closer
	for i := 0; i < 3; i++ {
		histLock, err = lock.Lock(os.ExpandEnv("$HOME/.full_history.lock"))
		if sysErr, ok := err.(syscall.Errno); err == nil || (ok && !sysErr.Temporary()) {
			break
		}
		fmt.Fprintf(os.Stderr, "add-hist: temporary error: %v\n", err)
		time.Sleep(10 * time.Millisecond)
	}
	check(err)
	defer histLock.Close()

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
		panic(err)
	}
}
