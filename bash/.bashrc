# ~/.bashrc - Fox Den Seoul
# Managed through GNU Stow from ~/Projects/Arch_Linux_Riced/bash

# Do nothing for non-interactive Bash sessions.
[[ $- != *i* ]] && return

# Preserve the useful color behavior from the original Arch Bash config.
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# ---------------------------------------------------------------------------
# Bash history
# ---------------------------------------------------------------------------

# Ignore commands beginning with a space, avoid adjacent duplicates, and
# remove older duplicates when a command is entered again.
HISTCONTROL=ignoreboth:erasedups

# Keep a useful interactive history without allowing it to grow indefinitely.
HISTSIZE=10000
HISTFILESIZE=20000

# Append instead of replacing history, and preserve multiline commands.
shopt -s histappend
shopt -s cmdhist
shopt -s lithist

# ---------------------------------------------------------------------------
# Bash completion
# ---------------------------------------------------------------------------

# Load Arch's bash-completion framework only when it has not already loaded.
if ! declare -p BASH_COMPLETION_VERSINFO >/dev/null 2>&1 \
    && [[ -r /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
fi

# ---------------------------------------------------------------------------
# fzf
# ---------------------------------------------------------------------------

if command -v fzf >/dev/null 2>&1; then
    # Fox Den Seoul colors and a compact reverse-list interface.
    export FZF_DEFAULT_OPTS="\
--height=65% \
--layout=reverse \
--border=rounded \
--info=inline \
--prompt='󰍉  ' \
--pointer='❯' \
--marker='✓' \
--color=bg+:#111823,bg:#070b12,spinner:#25d9ff,hl:#ff2fb3 \
--color=fg:#edf7ff,header:#8291a5,info:#ff9f43,pointer:#ff681f \
--color=marker:#55e6a5,fg+:#ffffff,prompt:#25d9ff,hl+:#df55ff \
--color=border:#ff681f,label:#ff681f"

    # Ctrl+T: select files with a bat/eza preview.
    export FZF_CTRL_T_OPTS="\
--preview 'if [[ -d {} ]]; then
    eza --tree --level=2 --color=always --icons=always -- {}
else
    bat --color=always --style=numbers,changes,header --line-range=:300 -- {}
fi' \
--preview-window=right:55%:border-left"

    # Alt+C: select directories with a shallow tree preview.
    export FZF_ALT_C_OPTS="\
--preview 'eza --tree --level=2 --color=always --icons=always -- {} | head -200' \
--preview-window=right:55%:border-left"

    # Official fzf Bash integration: Ctrl+R, Ctrl+T, Alt+C, and completion.
    eval "$(fzf --bash)"
fi

# ---------------------------------------------------------------------------
# zoxide
# ---------------------------------------------------------------------------

# Add the `z` and `zi` directory-jump commands without replacing `cd`.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# ---------------------------------------------------------------------------
# Safe convenience commands
# ---------------------------------------------------------------------------

if command -v eza >/dev/null 2>&1; then
    alias ll='eza --long --icons=auto --git --group-directories-first --header --time-style=long-iso'
    alias la='eza --long --all --icons=auto --git --group-directories-first --header --time-style=long-iso'
    alias lt='eza --tree --level=3 --icons=auto --git --group-directories-first'
    alias lt2='eza --tree --level=2 --icons=auto --git --group-directories-first'
fi

# Explicit bat preview command. Standard `cat` remains unchanged.
batp() {
    if (($# == 0)); then
        bat --style=numbers,changes,header --paging=always
    else
        bat --style=numbers,changes,header --paging=always -- "$@"
    fi
}

# Git helpers. Standard Git commands remain available.
alias gs='git status --short --branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --graph --decorate --oneline --all -20'

# Jump directly to the Fox Den desktop repository.
cfox() {
    cd "$HOME/Projects/Arch_Linux_Riced" || return
}

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------

# Load Starship when installed. Keep a conventional Bash prompt as a safe
# fallback so a missing or temporarily broken Starship binary does not leave
# the shell without a usable prompt.
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    PS1='[\u@\h \W]\$ '
fi
