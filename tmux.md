# tmux

With this tmux config you can use nested sessions.

## Status line indicators

| tmux key  | Description |
| ------------- | ------------- |
| 🖰 | external mouse input enabled |
| [OFF] | prefix and all F-Keys are disabled for tmux |
| ⌨ | Prefix entered |
| 🔔 | Bell |
| 🔍 | Zoom in current pane |

## keys

| tmux key  | Description |
| ------------- | ------------- |
| `F1`| new window |
| `F2` | next window |
| `F3` | previous window |
| `F4` | Close window and its panes. The last window closes tmux, too. |
| `F5` | Reload config |
| `F6` | Toogle status bar on and off |
| `F7` | New Session |
| `F8` | detach |
| `F9` | Rotate through different pre set layouts |
| `F11` | Toogle mouse on and off |
| `F12` | Turn off/on the parent **tmux in nested tmux** or for the use of a program like midnight commander (mc) that uses the F keys itself |
| `CTRL + B` `\|` | Split window vertical |
| `CTRL + B` `-` | Split window horizontal |
| `CTRL + B` `S` | Toggle pane synchronization |
| `CTRL + B` `!` | Pane to window |
| `CTRL + B` `Spacebar` | Toggle between pane layouts |
| `CTRL + B` `r` | Reload config |
| `CTRL + B` `$` | Rename session |
| `CTRL + B` `,` | Rename window |
| `CTRL + B` `z` | Zoom into pane or window / zoom out |
| `CTRL + B` `PageUp` or `PageDown` | Scrolling |
| `CTRL + B` `w` | List sessions and windows |
| `CTRL + B` `d` | Detach from session |
| `CTRL + B` `&` | Close current window |
| `CTRL + B` `q` | Number all windows and panes |
| `CTRL + B` `Crtl + v` | paste |

### Switch panes using Alt-arrow without prefix

- `ALT + ➡️ ⬇️ ⬅️ ⬆️`

### Use SHIFT plus arrows to navigate between windows

`SHIFT + ⬅️ ➡️`

Included is

- Tmux Plugin Manager
- Tmux resurrect

Running Tmux for the first time press `CTRL + B` `I` to install the plugins.

- `CTRL + B` `CTRL + s` saves the current environment
- `CTRL + B` `CTRL + r` restores the previous saved environment

## Sharing Terminal Sessions Between Two Different Accounts

In the first terminal, start tmux where shared is the session name and shareds is the name of the socket:

`tmux -S /tmp/shareds new -s shared`

In the second terminal attach using that socket and session.

`tmux -S /tmp/shareds attach -t shared`

The decision to work read-only is made when the second user attaches to the session.
`tmux -S /tmp/shareds attach -t shared -r`

## Split in three equal panes

`CTRL + B` `|`
`CTRL + B` `|`
`CTRL + B` `:` `select-layout even-horizontal`

### or

`CTRL + B` `-`
`CTRL + B` `-`
`CTRL + B` `:` `select-layout even-vertical`

##

`CTRL + B` `:` `tmux select-layout tiled`
