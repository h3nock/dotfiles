# Rex

Tmux-style controls with **Ctrl+A** as the prefix. Press it, release, then the next key.

## Setup

From your dotfiles directory, inside Rex:

```sh
stow rex
rex config reload
```

Requires Neovim 0.10+, Python 3, fzf, and [poplink](https://github.com/h3nock/poplink)
at `~/poplink`. Theme and font are set in Rex Settings.

## Keys

| After Ctrl+A | Action |
| --- | --- |
| `[` | Vim copy mode |
| `o` | Poplink file picker |
| `c`, `n`, `p`, `1`–`9` | New, next, previous, or numbered tab |
| `%`, `"` | Split right or down |
| `h/j/k/l`, arrows | Focus pane |
| `v` | Resize mode; Esc to finish |
| `z`, Tab, `x` | Zoom, next pane, close pane |
| `,`, `$`, `s` | Rename tab, rename session, switch session |
| `N`, `A` | Project notes, btop |
| `/`, `r`, `?` | Search, reload config, command palette |

Ctrl+H/J/K/L navigates panes without the prefix; Neovim integration uses the
`nvim` package.

In copy mode, use Vim motions and `/` to search. Select with `v`, `V`, or Ctrl+V;
`y` or Enter copies and closes. `q` exits. This views a frozen text snapshot;
reopen for new output. If a popup does not take keyboard focus, click inside it.
