package main

// interact with git repo to bump versions

import (
	// "fmt"
	"bytes"
	"log"
	"os/exec"
	// "strings"
	"strconv"
	"syscall"
)

func exitIfDirty() {
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

func main() {
	exitIfDirty()
	cmd := exec.Command("git", "describe")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		log.Fatal(err)
	}

	versions := bytes.Split(bytes.Trim(out.Bytes(), "\n"), []byte("."))
	for i, version := range versions {
		v, err := strconv.Atoi(string(version))
		if err != nil {
			log.Fatal(err)
		}
		versions[i] = v
	}
	log.Printf("%#v", versions)
}
