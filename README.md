# Dotfiles

This repository contains my personalized dotfiles and setup scripts for macOS and Linux environments.

## Structure

- **`<package>/`** - Each directory is a `stow` package (e.g., `zsh`, `nvim`, `tmux`).
- **`Brewfile`** - A list of all Homebrew packages, casks, and VS Code extensions for macOS.
- **`install.sh`** - A setup script to automate the installation process.

## Quick Setup

On a new machine, you can run the following commands to get started:

```bash
# Install Command Line Tools (required for git on macOS)
xcode-select --install

# Clone the dotfiles repo
git clone https://github.com/h3nock/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the full installation
./install.sh
```

This will automatically:

- ✅ Install Homebrew (on macOS).
- ✅ Install all packages from the `Brewfile` (on macOS).
- ✅ Create symlinks for all your configuration files using `stow`.

## Usage

For a focused Rex desktop setup (including Vim copy mode and poplink), follow
[the Rex setup instructions](rex/README.md) instead of the full installation.

The `install.sh` script can be used in two ways:

- **`./install.sh`**: This will run the full installation, including installing packages and creating symlinks.
- **`./install.sh --stow-only`**: This will skip the package installation and only create the symlinks.

## What Gets Installed

### Development Tools

- **Homebrew** - Package manager for macOS.
- **Git** tools (lazygit).
- **Terminal**: Ghostty (a modern, GPU-accelerated terminal).
- **Editor**: Neovim with a custom configuration.
- **Shell**: Zsh with Oh My Zsh and the Powerlevel10k theme.
- **Python**: pyenv for version management.
- **Node.js**, **Java**, and **Go** development tools.

### CLI Utilities

- `bat` (a better `cat`).
- `eza` (a better `ls`).
- `fzf` (a fuzzy finder).
- `ripgrep` (a better `grep`).
- `zoxide` (a smarter `cd` command).
- `tmux` (a terminal multiplexer).
- `btop` (a terminal resource monitor).
- `codex-meter` (Codex usage, quota, reset timing, token volume, estimated cost, and activity history).
- `clipper` (macOS window screenshots from the terminal).
- `winpick` (macOS window switching from the terminal).
- `poplink` (open files mentioned in the current tmux pane).
- `launch` (open a new app window on the current or selected yabai Space).
- And many more (see the `Brewfile`).

### Personal Tool Notes

The `codex-meter` and `clipper` formulae come from `h3nock/tap`.
If Homebrew refuses to load that tap, run:

```bash
brew trust h3nock/tap
```

`poplink` is installed from `https://github.com/h3nock/poplink.git` into
`~/poplink`, and `~/poplink/bin` is added to the shell `PATH`.

`winpick` is built from the `v0.1.0` source tag into `~/.local/bin` because its
Homebrew formula currently requires a full Xcode install.

Tmux workflows:

- Prefix + `o`: open file paths from the current pane with `poplink`.
- Prefix + `W`: pick and focus a macOS window with `winpick`.
- Prefix + `C`: pick and copy a macOS window screenshot with `clipper`.

App launcher workflow:

- `launch`: pick an app and Space interactively.
- `launch Ghostty`: open a new Ghostty window on the current Space.
- `launch --space 2 "Brave Browser"`: open a new Brave window on Space 2.

`clipper` needs Screen Recording permission for the terminal or hotkey app that
launches it. `winpick` needs Accessibility permission for that app.

### Applications

- **Ghostty** - A modern terminal.
- **Obsidian** - A note-taking application.
- **Hammerspoon** - A macOS automation tool.

### VS Code Extensions

- GitHub Copilot
- Language support for Python, Go, Dart/Flutter, C/C++, and Java.
- Themes and productivity extensions.
