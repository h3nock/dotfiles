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
git clone https://github.com/your-username/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the full installation
./install.sh
```

This will automatically:

- ✅ Install Homebrew (on macOS).
- ✅ Install all packages from the `Brewfile` (on macOS).
- ✅ Create symlinks for all your configuration files using `stow`.

## Usage

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
- And many more (see the `Brewfile`).

### Applications

- **Ghostty** - A modern terminal.
- **Obsidian** - A note-taking application.
- **Hammerspoon** - A macOS automation tool.

### VS Code Extensions

- GitHub Copilot
- Language support for Python, Go, Dart/Flutter, C/C++, and Java.
- Themes and productivity extensions.
