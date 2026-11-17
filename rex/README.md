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
| `[`, PageUp | Copy mode; PageUp opens one page back |
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

Copy mode keeps colors and covers just the active pane. Use `hjkl`, Ctrl+U/D,
Ctrl+B/F, and `/` or `?` to navigate. `v`/Space, `V`, and Ctrl+V select;
`y`/Enter copies and closes. Esc cancels selection; `q` closes. `Y` copies a
whole wrapped line. Focus and zoom return to the source pane on exit.

It still uses a frozen snapshot, starting at the latest output, not your mouse
scroll position. Reopen to refresh. The viewer keeps up to 100,000 terminal rows.
