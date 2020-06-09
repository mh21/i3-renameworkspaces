# i3-renameworkspaces

Rename [i3](https://i3wm.org) workspaces to contain the names of the programs on them.

- Author: Michael Hofmann
- Newest version: <https://github.com/mh21/i3-renameworkspaces>

## Introduction

Workspaces in i3 have numbers and/or names, and can be renamed as documented at <http://i3wm.org/docs/userguide.html#_changing_named_workspaces_moving_to_workspaces>.
This script connects to i3 via its IPC interface and continuously updates the workspace names to reflect the programs running on them.
The resulting names are prefixed with the workspace number, so all commands using `workspace number X` continue to work:

```
bindsym $mod+3 workspace number 3
bindsym $mod+Shift+3 move container to workspace number 3
```

## Screenshots

![screenshot of renamed workspaces](https://mh21.github.io/i3-renameworkspaces.png)

## Installation

Install the perl package `Linux::Inotify2`, e.g. by running

    sudo apt install liblinux-inotify2-perl

Add something like the following to your i3 config:

    exec_always --no-startup-id exec i3-renameworkspaces.pl

Make sure to use workspace rules like `workspace number X` in all commands in your i3 config so they will continue to work with renamed workspaces.

## Configuration

The mapping between X11 window classes/instances and the used short names can be configured in the configuration file, which defaults to `~/.i3workspaceconfig`.
An example can be found in `config-example`:

```json
{
    "classes": {
        "firefox": "ff",
        "gnome-terminal": "term",
        "libreoffice-writer": "writer",
        "libreoffice-calc": "calc",
        "chromium-browser": "chrome",
    },
    "instances": {
    }
}
```

You can choose which workspaces are controlled by i3-renameworkspaces, by assigning permanent names to some workspaces in the "staticnames" section of the configuration file. Those workspaces will not be assigned dynamically generated names:


```json
    "staticnames": {
        "1": "main",
        "2": "confs",
        "4": "video",
        "6": "pdfs",
        "8": "gimp"
    }
```


## Note

> How am I able to jump directly to these dynamically-named workspaces?

[In the i3
docs](https://i3wm.org/docs/userguide.html#_changing_named_workspaces_moving_to_workspaces),
there's a specific syntax to jump to the corresponding number of workspaces that
follow the naming convention `\d:.*`:

> Note that the workspace will really be named "1: mail". i3 treats workspace
> names beginning with a number in a slightly special way. Normally, named
> workspaces are ordered the way they appeared. When they start with a number,
> i3 will order them numerically. Also, you will be able to use workspace number
> 1 to switch to the workspace which begins with number 1, regardless of which
> name it has. This is useful in case you are changing the workspace’s name
> dynamically.

The `xprop` program can be used to determine the classes and instances of windows, look for `WM_CLASS` in the output.

Short names can also be combined with iconic fonts like [Font Awesome](https://fontawesome.com) ([cheatsheet](https://fontawesome.com/cheatsheet)) with a font fallback sequence in your i3 configuration file like

```
bar {
    font pango:DejaVu Sans Mono, FontAwesome 8
}
```

## About

Get the latest version, submit pull requests, and file bug reports on GitHub:

- <https://github.com/mh21/i3-renameworkspaces>
