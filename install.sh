#!/bin/bash

# if true, it doesn't install packages only symlink  
STOW_ONLY=false

if [[ "$1" == "--stow-only" ]]; then
    STOW_ONLY=true
fi

# helper function to check if command exists 
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# package installations 
install_packages() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "Running macOS setup..."
        if ! command_exists brew; then
            echo "Homebrew not found. Installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        echo "Installing packages from Brewfile..."
        brew bundle --file=Brewfile
    elif [[ "$(uname)" == "Linux" ]]; then
        echo "Linux package installation not yet implemented."
        # TODO: Add package installation for Linux (using apt, dnf, pacman)
    fi
}

configure_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        return
    fi

    echo "Enabling native macOS menu bar auto-hide..."
    if ! osascript -e 'tell application "System Events" to tell dock preferences to set autohide menu bar to true' >/dev/null; then
        echo "Warning: could not enable menu bar auto-hide. Set System Settings > Control Center > Automatically hide and show the menu bar to Always."
    fi
}

build_helpers() {
    if [[ "$(uname)" != "Darwin" ]]; then
        return
    fi

    echo "Building local helper binaries..."
    make -C scripts
}

# stow operations 
stow_dotfiles() {
    echo "Stowing dotfiles..."
    PACKAGES_TO_STOW=()
    if [[ "$(uname)" == "Darwin" ]]; then
        PACKAGES_TO_STOW=(zsh nvim tmux btop bat eza karabiner skhd yabai ghostty scripts)
    elif [[ "$(uname)" == "Linux" ]]; then
        PACKAGES_TO_STOW=(zsh nvim tmux btop bat eza scripts)
    fi

    # pre-stow check for conflicts and backup existing files
    for pkg in "${PACKAGES_TO_STOW[@]}"; do
        if [ -e "$HOME/$pkg" ] && [ ! -L "$HOME/$pkg" ]; then
            echo "Backing up existing '$HOME/$pkg' to '$HOME/$pkg.bak'..."
            mv "$HOME/$pkg" "$HOME/$pkg.bak"
        fi
    done

    stow "${PACKAGES_TO_STOW[@]}"
}

if [ "$STOW_ONLY" = true ]; then
    echo "Skipping package installation. Stowing dotfiles only..."
    configure_macos
    build_helpers
    stow_dotfiles
else
    install_packages
    configure_macos
    build_helpers
    stow_dotfiles
fi

echo "Dotfiles setup complete!"
