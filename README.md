# i3-renameworkspaces

Rename [i3](https://i3wm.org) workspaces to contain the names of the programs on them.

- Author: Michael Hofmann
- Newest version: <https://github.com/mh21/i3-renameworkspaces>

## Introduction

Workspaces in i3 have numbers and/or names, and can be renamed as documented at <http://i3wm.org/docs/userguide.html#_changing_named_workspaces_moving_to_workspaces>.
This script connects to i3 via its IPC interface and continuously updates the workspace names to reflect the programs running on them.
The resulting names are prefixed with the workspace number, so all commands using `workspace number X` continue to work.

## Screenshots

![screenshot of renamed workspaces](https://mh21.github.io/i3-renameworkspaces.png)

## Installation

Add something like the following to your i3 config:

    exec_always --no-startup-id exec i3-renameworkspaces.pl

## Configuration

The mapping between X11 window instances and the used short names can be configured in the configuration file, which defaults to `~/.i3renameworkspacesconfig`.
An example can be found in [config-example](config-example):

```json
{
    "navigator": "ff",
    "gnome-terminal": "term",
    "vclsalframe.documentwindow": "lo",
    "soffice": "lo"
}
```

## About

Get the latest version, submit pull requests, and file bug reports on GitHub:

- <https://github.com/mh21/i3-renameworkspaces>
