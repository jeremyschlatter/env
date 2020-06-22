package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/go-logfmt/logfmt"
)

func main() {
	f, err := os.Open(os.ExpandEnv("$HOME/.full_history"))
	check(err)
	defer f.Close()
	scanner := bufio.NewScanner(f)

	of, err := os.Create(os.ExpandEnv("$HOME/.full_history.logfmt"))
	check(err)
	encoder := logfmt.NewEncoder(of)

	for scanner.Scan() {
		text := scanner.Text()
		text = strings.ReplaceAll(text, "Application Support", "Application|s|Support")
		text = strings.ReplaceAll(text, "Visual Studio Code", "Visual|s|Studio|s|Code")
		text = strings.ReplaceAll(text, "public-base/a b", "public-base/a|s|b")
		parts := strings.SplitN(text, " ", 4)

		date := parts[0]
		host := parts[1]
		cwd := parts[2]
		cwd = strings.ReplaceAll(cwd, "|s|", " ")
		hist := parts[3]

		dateT, err := time.Parse("2006-01-02--15-04-05", date)
		if err != nil {
			fatalf("bad time value: %v", date)
		}

		switch host {
		case "Jeremys-MacBook-Pro.local", "jeremys-mbp.lan", "macbook-pro.lan":
		case "jeremy-mbp.lan", "Jeremy-MBP.local", "Jeremy-MBP":
		default:
			fatalf("bad host value: %v", host)
		}

		{
			fields := strings.Fields(strings.TrimSpace(hist))
			id := fields[0]
			date := fields[1]
			clock := fields[2]

			if _, err := strconv.Atoi(strings.TrimSuffix(id, "*")); err != nil {
				fatalf("bad hist value (bad id): %v", hist)
			}
			if _, err := time.Parse("2006-01-02 15:04:05", date+" "+clock); err != nil {
				fatalf("bad hist value (bad timestamp): %v", hist)
			}
		}

		check(encoder.EncodeKeyvals(
			"date", dateT.Format(time.RFC3339),
			"host", host,
			"cwd", cwd,
			"hist", hist,
		))
		check(encoder.EndRecord())
	}
	check(scanner.Err())
	check(of.Sync())
	fmt.Println("ok")
}

func fatalf(format string, a ...interface{}) {
	if !strings.HasSuffix(format, "\n") {
		format += "\n"
	}
	fmt.Fprintf(os.Stderr, format, a...)
	os.Exit(1)
}

func check(err error) {
	if err != nil {
		fatalf("convert-hist: %v", err)
	}
}
