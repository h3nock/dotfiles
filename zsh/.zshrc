# --- rexume: bring Rex panes back after a restart (~/rexume) ---
# Before the instant prompt: a restored pane redraws its saved screen and
# reopens its agent conversation or program.
[[ -n $REX_BLOCK && -o interactive && -x /Users/macbook/.local/bin/rexume ]] &&
  source <(/Users/macbook/.local/bin/rexume shell-init)

# --- Powerlevel10k Instant Prompt ---
# Keep this near the top so new tmux panes can paint a prompt before slower
# optional tooling initializes.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Environment Variables & PATH Setup ---
# Keep only the first copy of each PATH entry, so a shell started from another
# shell doesn't double PATH. Lookup order is unchanged: the first copy wins.
typeset -U PATH path
# Homebrew must be available before tools installed through brew are initialized.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# bookmark the iCloud Docs folder as ~cloud
hash -d cloud="$HOME/Library/Mobile Documents/com~apple~CloudDocs"

# --- Oh My Zsh Setup ---
export ZSH="$HOME/.oh-my-zsh"
# Avoid update checks on shell startup; run `omz update` manually when needed.
DISABLE_AUTO_UPDATE="true"
# Set theme to Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"
# Enable plugins: git and zsh-syntax-highlighting are already great;
# adding zsh-autosuggestions for command completion suggestions.
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
# Keep the completion cache in ~/.cache instead of .zcompdump-* files in $HOME.
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
[[ -d ${ZSH_COMPDUMP:h} ]] || mkdir -p "${ZSH_COMPDUMP:h}"

source "$ZSH/oh-my-zsh.sh"

bindkey '^E' autosuggest-accept
bindkey -M viins '^E' autosuggest-accept

# --- Custom Aliases ---

# Editor & compiler 
alias gcc="gcc-15"
alias g++="g++-15"
alias vim="nvim"

# alias for the C preprocessor and other tools
alias cc='gcc-15'
alias cpp='cpp-15'

# CP (Competitive Programming) aliases
[[ -r "$HOME/cp/scripts/aliases.zsh" ]] && source "$HOME/cp/scripts/aliases.zsh"

# fzf + bat preview in Neovim 
# fzf command for opening multiple files in Neovim with a bat powred preview 
alias nfzf='nvim $(fzf -m --preview="bat --color=always {}")'

if command -v eza >/dev/null 2>&1; then
  export EZA_CONFIG_DIR="$HOME/.config/eza"
  unset EZA_COLORS EXA_COLORS LS_COLORS

  alias la='eza -alh'
  alias ll='eza -lH'
fi

# Claude Code (CLAUDECODE=1) copies this shell's functions and aliases into
# the shells that run its commands, so cd, cat, ls, and tree stay standard
# there. zoxide's cd loses its hook in those shells: it warns on every call and
# jumps elsewhere when the path doesn't exist. eza rejects ls flags such as -t,
# and its -d and -f mean something else than tree's.
if [[ -z ${CLAUDECODE:-} ]]; then
  if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd cd zsh)"
  fi
  if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
  fi
  if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto'
    alias tree='eza --tree'
  fi
fi

# Shortcut for Obsidian symlink script
alias obslink="~/scripts/obsidian_link.zsh"

# git alias 
alias ga='git add'
alias gc='git commit'
alias gcam='git commit --amend --no-edit'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gdiff='git diff'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpo='git push origin'
alias gs='git status'
alias gt='git tag'
alias gr='git restore'
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
# gac: git add + commit in one go
gac() {
  if [ $# -lt 2 ]; then
    echo "Usage: gac <files...> \"commit message\""
    return 1
  fi
  # gram args 1 - n-1 as files 
  local files=(${argv[1,-2]}) 
  # grab the last argument as commit message
  local msg=${argv[-1]}
  # add all the other args as files
  git add -- "${files[@]}" && git commit -m "$msg"
}

# tmux alias
# ta NAME: attach; a session that isn't running is first brought back from its last tmux-resurrect save
ta() {
  if [[ $# -eq 0 ]]; then
    tmux attach
    return
  fi
  tmux has-session -t "$1" 2>/dev/null || ~/scripts/tmux-restore-session "$1" || return
  tmux attach -t "$@"
}
alias tls='tmux ls' 
alias tks='tmux kill-session -t'
 
brave() {
  open -a "Brave Browser" "$@"
}

#obs: open any folder as an Obsidian valut 
obs(){
  if [[ $# -lt 1 ]]; then 
    echo "Usage: obs <vault-dir-or-path>"
    return 1 
  fi 
  local dir="$1"
  if [[ "$dir" != /* && "$dir" != ~* ]]; then 
    dir="$HOME/$dir"
  fi 

  dir="${dir/#\~/$HOME}"

  open -a Obsidian "$dir"
}

alias dkb='open -a Obsidian ~/dev-knowledge-base'

# --- Pyenv Setup ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

__remux_pyenv_init() {
  unset -f pyenv
  eval "$(command pyenv init -)"
  eval "$(command pyenv virtualenv-init -)" 2>/dev/null || true
}

pyenv() {
  __remux_pyenv_init
  pyenv "$@"
}

# --- Java Setup ---
# Choose one Java installation. For JDK 23, use:
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-23.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# --- Go Environment ---
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"

# --- Flutter Settings (only on machines where the SDK is installed) ---
if [[ -d "$HOME/Developments/Flutter/flutter" ]]; then
  export FLUTTER_ROOT="$HOME/Developments/Flutter/flutter"
  export PATH="$FLUTTER_ROOT/bin:$PATH"
  export PATH="$PATH:$HOME/.pub-cache/bin"
fi

bindkey -v
# in vi insert mode, jk sends back to command (normal) mode
bindkey -M viins 'jk' vi-cmd-mode

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# --- Conda Setup (only on machines where Miniforge is installed) ---
# Keep conda available without activating base or running the shell hook in
# every new terminal. The first `conda ...` command installs the shell function.
if [[ -x /opt/homebrew/Caskroom/miniforge/base/bin/conda ]]; then
  export PATH="/opt/homebrew/Caskroom/miniforge/base/bin:$PATH"

  __remux_conda_init() {
    unset -f conda
    local __conda_setup
    __conda_setup="$('/opt/homebrew/Caskroom/miniforge/base/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
    if [[ $? -eq 0 ]]; then
      eval "$__conda_setup"
    elif [[ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]]; then
      source "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
    fi
    unset __conda_setup
  }

  conda() {
    __remux_conda_init
    conda "$@"
  }
fi

export MACOSX_DEPLOYMENT_TARGET=26.0
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/dotfiles/zsh/.p10k.zsh.
[[ ! -f ~/dotfiles/zsh/.p10k.zsh ]] || source ~/dotfiles/zsh/.p10k.zsh

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"

# Machine-local and experimental shell customizations.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# --- Tools added by installers ---
if command -v daytona >/dev/null 2>&1 && [[ -r "$HOME/.daytona.completion_script.zsh" ]]; then
  source "$HOME/.daytona.completion_script.zsh"
fi
# ~/.local/bin goes ahead of Homebrew and bun on purpose: its clipper, winpick,
# python3.12, and bunx are the ones that run.
export PATH="$HOME/.okc/bin:$HOME/.opencode/bin:$HOME/.local/bin:$PATH:$HOME/.lmstudio/bin"
