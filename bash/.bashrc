# ~/.bashrc — Fox Den Seoul
# Managed through GNU Stow from ~/Projects/Arch_Linux_Riced/bash

# Do nothing for non-interactive Bash sessions.
[[ $- != *i* ]] && return

# Preserve the useful color behavior from the original Arch Bash config.
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Load Starship when installed. Keep a conventional Bash prompt as a safe
# fallback so a missing or temporarily broken Starship binary does not leave
# the shell without a usable prompt.
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    PS1='[\u@\h \W]\$ '
fi
