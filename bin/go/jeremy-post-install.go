// jeremy-post-install
//
// This is my hook to run arbitrary code after installing my nix packages.
//
// It is very sad that I need this hook.
//
// Strive to keep this as small as possible!
//
// Also, everything in here must be idempotent and main should complete in
// under ~50ms.

package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	defer func() {
		if r := recover(); r != nil {
			fmt.Fprintf(os.Stderr, "error during jeremy-post-install: %v\n", r)
		}
	}()

	nixConfDir := os.ExpandEnv("$HOME/.flake/profile/config/")
	homeConfDir := os.ExpandEnv("$HOME/.config/")

	wantSymlink := make(map[string]bool)

	// Symlink ~/.flake/profile/config/* into ~/.config
	{
		fis, err := ioutil.ReadDir(nixConfDir)
		check(err)
		for _, fi := range fis {
			wantSymlink[fi.Name()] = true
			linkFrom := homeConfDir + fi.Name()
			haveLink, err := os.Readlink(linkFrom)
			wantLink := nixConfDir + fi.Name()
			switch {
			case os.IsNotExist(err):
				fmt.Printf("symlinking %v config...\n", fi.Name())
				check(os.Symlink(wantLink, linkFrom))
			case err == nil && haveLink == wantLink:
				// Nothing more to do.
			case err == nil && haveLink != wantLink:
				fmt.Printf("I want to install a symlink at %v, but it is already symlinked to %q\n", linkFrom, haveLink)
			default:
				_, err = os.Stat(linkFrom)
				if err == nil {
					fmt.Printf("I want to install a symlink at %v, but there is already something else there.\n", linkFrom)
				} else {
					fmt.Printf("I want to install a symlink at %v, but I failed to stat the existing file: %v\n", linkFrom, err)
				}
			}
		}
	}

	// Remove old symlinks from ~/.config
	{
		fis, err := ioutil.ReadDir(homeConfDir)
		check(err)
		for _, fi := range fis {
			link, err := os.Readlink(homeConfDir + fi.Name())
			if err == nil && strings.HasPrefix(link, nixConfDir) && !wantSymlink[fi.Name()] {
				fmt.Printf("removing %v config...\n", fi.Name())
				check(os.Remove(homeConfDir + fi.Name()))
			}
		}
	}

	// Build bat theme
	{
		if _, err := os.Stat(filepath.Join(os.Getenv("HOME"), ".cache", "bat", "themes.bin")); os.IsNotExist(err) {
			fmt.Println("installing solarized theme for bat...")
			run(exec.Command("bat", "cache", "--build"))
		}
	}
}

func run(cmd *exec.Cmd) {
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	check(cmd.Run())
}

func check(err error) {
	if err != nil {
		panic(err)
	}
}
