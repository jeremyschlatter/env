package main

import (
	"log"
	"os"
	"os/exec"
)

func main() {
	log.SetFlags(0)
	if len(os.Args) < 2 {
		log.Fatal("Usage: srun <binary> [args...]")
	}
	bin := os.Args[1]
	args := os.Args[2:]
	run("stack", "build", ":"+bin)
	run("stack", append([]string{"exec", bin, "--"}, args...)...)
}

func run(prog string, arg ...string) {
	cmd := exec.Command(prog, arg...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if e, ok := err.(*exec.ExitError); ok {
		os.Exit(e.ExitCode())
	}
	if err != nil {
		log.Fatal(err)
	}
}
