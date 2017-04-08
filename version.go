package main

// interact with git repo to list and increment versions

import (
	"bytes"
	"fmt"
	"log"
	"os/exec"
	"strconv"
	"strings"

	"github.com/urfave/cli"
)

var versionMainCommand []cli.Command

func init() {
	bumpSubCommands := []cli.Command{
		{
			Name:    "patch",
			Aliases: []string{"p"},
			Action: func(c *cli.Context) error {
				exitIfDirty()
				v := getCurrentVersion()
				fmt.Println(v.BumpPatch())
				return nil
			},
		},

		{
			Name:    "minor",
			Aliases: []string{"mi"},
			Action: func(c *cli.Context) error {
				exitIfDirty()
				v := getCurrentVersion()
				fmt.Println(v.BumpMinor())
				return nil
			},
		},

		{
			Name:    "major",
			Aliases: []string{"ma"},
			Action: func(c *cli.Context) error {
				exitIfDirty()
				v := getCurrentVersion()
				fmt.Println(v.BumpMajor())
				return nil
			},
		},
	}

	versionMainCommand = []cli.Command{
		{
			Name:    "version",
			Aliases: []string{"v"},
			Usage:   "Versioning tools",
			Subcommands: []cli.Command{

				{
					Name:    "print",
					Aliases: []string{"p"},
					Usage:   "Print current version",
					Action: func(c *cli.Context) error {
						exitIfDirty()
						fmt.Println(getCurrentVersion())
						return nil
					},
				},

				{
					Name:        "bump",
					Aliases:     []string{"b"},
					Usage:       "Print a version incremented by major, minor, or patch",
					Subcommands: bumpSubCommands,
				},
			},
		},
	}
}

type shellCommand struct {
	cmd    *exec.Cmd
	stderr bytes.Buffer
	stdout bytes.Buffer
}

func newShellCommand(name string, arg ...string) *shellCommand {
	c := &shellCommand{cmd: exec.Command(name, arg...)}
	c.cmd.Stdout = &c.stdout
	c.cmd.Stderr = &c.stderr
	return c
}

func (s *shellCommand) runOrRaise() *bytes.Buffer {
	err := s.cmd.Run()
	if err != nil {
		log.Fatalf("%v: %v", s.stderr)
	}
	return &s.stdout
}

func exitIfDirty() {
	// if the git repo is dirty, exit and print a message
	// else pass the error along
	cmd := exec.Command("git", "diff-index", "--quiet", "HEAD")
	// since we're using `--quiet`, stdout is not needed
	stderr := bytes.Buffer{}
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		if len(stderr.String()) == 0 {
			log.Fatal("Repo dirty. Please commit or stash changes to continue.")
		}
		log.Fatalf("git: %v", stderr.String())
	}
}

type Version struct {
	major int
	minor int
	patch int
}

func newVersion(major, minor, patch int) *Version {
	return &Version{major: major, minor: minor, patch: patch}
}

func (v *Version) String() string {
	return fmt.Sprintf("%d.%d.%d", v.major, v.minor, v.patch)
}

func (v *Version) BumpPatch() *Version {
	v.patch += 1
	return v
}

func (v *Version) BumpMinor() *Version {
	v.minor += 1
	v.patch = 0
	return v
}

func (v *Version) BumpMajor() *Version {
	v.major += 1
	v.minor = 0
	v.patch = 0
	return v
}

func (v *Version) Bump(increment string) *Version {
	switch strings.ToLower(increment) {
	case "patch":
		v.BumpPatch()
	case "minor":
		v.BumpMinor()
	case "major":
		v.BumpMajor()
	default:
		log.Fatal("Unable to parse version increment ", increment)
	}
	return v
}

func getCurrentVersion() *Version {
	gitDescribe := newShellCommand("git", "describe")
	stdout := gitDescribe.runOrRaise()
	rawVersion := bytes.Trim(stdout.Bytes(), "\n")

	increments := [3]int{}
	for i, increment := range bytes.Split(rawVersion, []byte(".")) {
		inc, err := strconv.Atoi(string(increment))
		if err != nil {
			log.Fatal(err)
		}
		increments[i] = inc
	}
	return newVersion(increments[0], increments[1], increments[2])
}
