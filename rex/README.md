# Rex

Stow this package from the dotfiles root with `stow rex`, then run
`rex config check` and `rex config reload` inside a Rex terminal.
The configuration follows the tmux dotfiles' **Ctrl+A** prefix.
Press Ctrl+A, release it, then press the next key.

## Set up or update another Mac

Install the Rex desktop app separately, then run these commands **inside a Rex
terminal on that Mac**. This installs just the Rex configuration and its tools.

```sh
brew install stow neovim python fzf btop

# Clone once; an existing clone is updated below.
test -d "$HOME/dotfiles/.git" || git clone https://github.com/henok3878/dotfiles.git "$HOME/dotfiles"
test -d "$HOME/poplink/.git" || git clone https://github.com/h3nock/poplink.git "$HOME/poplink"
git -C "$HOME/dotfiles" pull --ff-only
git -C "$HOME/poplink" pull --ff-only

mkdir -p "$HOME/.config"
stow --dir="$HOME/dotfiles" --target="$HOME" --restow rex
rex config check
rex config reload
```

If Stow reports a conflict with an existing real `~/.config/rex` directory, move
that directory aside as a backup and rerun the Stow command. Existing edits in
either Git repository should be committed or stashed before pulling.

Try `Ctrl+A [` for copy mode and `Ctrl+A o` for poplink. No tmux server, TPM
plugins, or full dotfiles installer is needed for either feature. For smart
Neovim split navigation too, stow the `nvim` package and restart Neovim:

```sh
stow --dir="$HOME/dotfiles" --target="$HOME" --restow nvim
```

Choose the theme and font in Rex Settings on each Mac; these app preferences
are not changed by the Lua configuration.

Tested with Rex Beta 0.1.0 (1642) and Neovim 0.11.5. During background desktop
automation, Rex sometimes kept keyboard focus in the original terminal after
opening a floating panel, despite reporting the panel as focused. If keys go
to the underlying pane, click inside the panel once. Automatic focus in normal
foreground use on the MacBook Air has not been verified.

## Shortcuts

| Keys after Ctrl+A | Action |
| --- | --- |
| `c`, `n`, `p`, `1`–`9` | New, next, previous, or numbered tab |
| `%`, `"` | Split right or down |
| `h/j/k/l` or arrows | Focus a pane |
| Ctrl+arrow | Resize a pane |
| `z`, Tab, `x` | Zoom, next pane, close pane (or its tab when it is the last pane) |
| `&`, `!` | Close tab, move pane to a new tab |
| `,`, `$`, `s` | Rename tab, rename session, switch session |
| `=`, `r`, `?` | Balance panes, reload config, command palette |
| `/` | Search terminal output |
| `[` | Open a scrollback snapshot in Vim copy mode |
| `v` | Enter resize mode: h/j/k/l or arrows, Shift for larger steps; Esc/q/Enter exits |
| `N`, `A` | Project notes or btop in a floating terminal |
| `o` | Pick a file reference from terminal output with poplink |
| Ctrl+A | Send a literal Ctrl+A to the terminal |

Ctrl+H/J/K/L without the prefix moves between Rex panes. In Vim or nested tmux,
Rex passes these keys through. The accompanying Neovim mappings move between
Vim splits first and switch Rex panes at the edge. Existing tmux navigation is
used whenever Neovim is inside tmux. Restart an existing Neovim to load changes.

Notes open `.local/notes.md` in the focused terminal's current directory.
The notes editor skips the shared Neovim history (ShaDa) file. Quit Neovim or
btop normally to close its floating terminal.

Poplink needs the Rex-aware version from `h3nock/poplink`, cloned at `~/poplink`,
plus Python 3.9+, fzf, and an editor. If installed elsewhere, set `POPLINK_BIN`
to the full executable path in the login shell environment. The picker captures
the original terminal and resolves relative paths against that terminal's
working directory, even though it runs in a separate floating terminal. Escape
closes the picker; quitting the selected editor returns to the original pane.

## Vim copy mode

`Ctrl+A [` opens a full-window snapshot viewer using Neovim 0.10+ and Python 3.
It has an isolated configuration, without your editor plugins, shared ShaDa,
swap, backups, or undo files. Captured text lives in a private temporary folder
and is removed when the viewer exits normally. As with any process, force-killing
the helper can leave temporary files behind.

Use Vim movements (`h/j/k/l`, `w/b`, `gg/G`, Ctrl+U/D), `/` or `?` to search,
and `n/N` for matches. `v` selects characters, `V` selects lines, and Ctrl+V
selects a rectangle. `y` or Enter copies and closes the viewer; `yy` copies a
line. `q` or Escape in normal mode closes without copying. Escape in visual
mode cancels the selection first. Clipboard writes use OSC 52 through Rex so
the receiving desktop gets the copied text, including when the server is remote.

This is a plain-text snapshot with soft wraps joined. The original process keeps
running behind it; new output is not added until you reopen copy mode. It does
not move Rex's native selection or preserve terminal colors. Full-screen apps
can expose different content/history from ordinary shell output.

Rex's macOS shortcuts remain available. Appearance is configured in Settings;
the imported Catppuccin Mocha theme and typography are independent of this file.

## Features that do not transfer

Rex does not read tmux configuration or load TPM plugins. The snapshot viewer
provides Vim selection without controlling Rex's native scrollback selection.
These bindings do not implement tmux-pins, resurrect, continuum, or the tmux
status bar. The machine-local winpick setup stays in tmux.
