# Rex

Tmux-style controls with **Ctrl+A** as the prefix. Press it, release, then the next key.

## Setup

From your dotfiles directory, inside Rex:

```sh
stow rex
rex config reload
```

Requires Neovim, Python 3, fzf, and [poplink](https://github.com/h3nock/poplink)
at `~/poplink`. Theme and font are set in Rex Settings. Copy mode needs the
Bleeding Edge update channel (Settings > Developer > App Version, with
Developer Mode on) until it reaches Preview.

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
| `,`, `$` | Rename tab, rename session |
| `s` then `1`–`9`, `n`, `p`, `s` | Numbered session (as `rex ls` orders them), next, previous, or the session picker |
| `N`, `A` | Project notes, btop |
| `/`, `r`, `?` | Search, reload config, command palette |

Ctrl+H/J/K/L navigates panes without the prefix; Neovim integration uses the
`nvim` package.

Copy mode is Rex's native one, in the live pane. Move with vi motions, `/` or
`?` to search, and `f`/`t` to jump to a character. `v`, `V`, and Ctrl+V select;
`y`/Enter copies and exits; `D` copies to the end of the line. Esc or `q` exits
and restores the scroll position.
