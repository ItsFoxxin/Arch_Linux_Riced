# ~/.bash_profile — Fox Den Seoul
# Managed through GNU Stow from ~/Projects/Arch_Linux_Riced/bash

# Login shells load the interactive Bash configuration.
[[ -f ~/.bashrc ]] && . ~/.bashrc

# Fox Den - Start Hyprland after local TTY1 login
if [[ "$(tty)" == "/dev/tty1" ]] \
    && [[ -z "${WAYLAND_DISPLAY:-}" ]] \
    && [[ -z "${DISPLAY:-}" ]] \
    && [[ -z "${SSH_TTY:-}" ]]; then

    if command -v start-hyprland >/dev/null 2>&1; then
        start-hyprland
    fi
fi
