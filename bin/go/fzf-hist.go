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
	all := []*string{}
	seen := make(map[string]int)
	i := 0
	// Read in history, parsing out just the commands.
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
		next := string(bytes.TrimSpace(bytes.SplitN(
			bytes.TrimLeft(decoder.Value(), " "),
			[]byte(" "),
			5,
		)[4]))
		if prev, ok := seen[next]; ok {
			all[prev] = nil
		}
		seen[next] = i
		all = append(all, &next)
		i++
	}

	for _, s := range all {
		if s != nil {
			fmt.Println(*s)
		}
	}
}

func check(err error) {
	if err != nil {
		fmt.Fprintf(os.Stderr, "fzf-hist: %v\n", err)
		os.Exit(1)
	}
}
