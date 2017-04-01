package main

// interact with git repo to bump versions

import (
	// "fmt"
	"log"
	"os/exec"
	// "strings"
	"syscall"
)

func main() {
	cmd := exec.Command("git", "diff-index", "--quiet", "HEAD")
	err := cmd.Start()
	if err != nil {
		log.Fatal(err)
	}

	if err := cmd.Wait(); err != nil {
		if exiterr, ok := err.(*exec.ExitError); ok {
			if status, ok := exiterr.Sys().(syscall.WaitStatus); ok {
				if status.ExitStatus() == 1 {
					log.Fatal("dirty git repo, cannot version...")
				}
				log.Printf("git exit status: %d", status.ExitStatus())
			}
		} else {
			log.Fatal(err)
		}
	}

}
