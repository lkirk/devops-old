package main

import (
	"os"

	"github.com/urfave/cli"
)

func main() {
	app := cli.NewApp()
	app.Commands = append([]cli.Command{}, versionMainCommand...)
	app.Run(os.Args)
}
