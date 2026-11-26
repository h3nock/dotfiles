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

install_personal_tools() {
    if [[ "$(uname)" != "Darwin" ]]; then
        return
    fi

    if ! command_exists git; then
        echo "git is required to install poplink."
        return 1
    fi

    local poplink_dir="$HOME/poplink"
    local winpick_dir="$HOME/winpick"
    local local_bin_dir="$HOME/.local/bin"

    if [ -d "$poplink_dir/.git" ]; then
        echo "poplink checkout already exists at $poplink_dir."
    elif [ -e "$poplink_dir" ]; then
        echo "Cannot install poplink: $poplink_dir exists but is not a git checkout."
        return 1
    else
        echo "Installing poplink from source..."
        if ! git clone https://github.com/h3nock/poplink.git "$poplink_dir"; then
            echo "Failed to clone poplink."
            return 1
        fi
    fi

    if [ -x "$local_bin_dir/winpick" ] || command_exists winpick; then
        echo "winpick already installed."
        return
    fi

    if ! command_exists swift; then
        echo "swift is required to build winpick."
        return 1
    fi

    if [ -d "$winpick_dir/.git" ]; then
        echo "winpick checkout already exists at $winpick_dir."
    elif [ -e "$winpick_dir" ]; then
        echo "Cannot install winpick: $winpick_dir exists but is not a git checkout."
        return 1
    else
        echo "Installing winpick source..."
        if ! git clone --branch v0.1.0 --depth 1 https://github.com/h3nock/winpick.git "$winpick_dir"; then
            echo "Failed to clone winpick."
            return 1
        fi
    fi

    echo "Building winpick..."
    if ! swift build --package-path "$winpick_dir" --configuration release --disable-sandbox --product winpick; then
        echo "Failed to build winpick."
        return 1
    fi

    mkdir -p "$local_bin_dir"
    install -m 0755 "$winpick_dir/.build/release/winpick" "$local_bin_dir/winpick"
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
        PACKAGES_TO_STOW=(zsh nvim tmux rex btop bat eza karabiner skhd yabai ghostty scripts)
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
    install_personal_tools || exit 1
    configure_macos
    build_helpers
    stow_dotfiles
fi

echo "Dotfiles setup complete!"
