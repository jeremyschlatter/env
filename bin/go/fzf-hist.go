package main

import (
	"bytes"
	"fmt"
	"os"

	"github.com/go-logfmt/logfmt"
)

func main() {
	f, err := os.Open(os.ExpandEnv("$HOME/.full_history.logfmt"))
	check(err)
	defer f.Close()
	decoder := logfmt.NewDecoder(f)
	seen := make(map[string]bool)
	for decoder.ScanRecord() {
		decoder.ScanKeyval()
		decoder.ScanKeyval()
		decoder.ScanKeyval()
		decoder.ScanKeyval()
		blah := bytes.SplitN(
			bytes.TrimLeft(decoder.Value(), " "),
			[]byte(" "),
			5,
		)
		if len(blah) != 5 {
			fmt.Println("bad line:")
			fmt.Fprintf(os.Stderr, "%s\n", decoder.Value())
			os.Exit(1)
		}
		next := string(bytes.SplitN(
			bytes.TrimLeft(decoder.Value(), " "),
			[]byte(" "),
			5,
		)[4])
		if !seen[next] {
			fmt.Println(next)
			seen[next] = true
		}
	}
	check(decoder.Err())
}

func check(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "fzf-hist: %v\n", err)
		os.Exit(1)
	}
}
