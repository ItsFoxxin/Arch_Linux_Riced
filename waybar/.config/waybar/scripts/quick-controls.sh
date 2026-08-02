#!/usr/bin/env bash
# Fox Den quick-controls popup for Waybar.

set -uo pipefail

THEME="${HOME}/.config/waybar/quick-controls.rasi"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
AWAKE_PID_FILE="${RUNTIME_DIR}/foxden-stay-awake.pid"
LOG_FILE="${XDG_CACHE_HOME:-${HOME}/.cache}/waybar-quick-controls.log"
mkdir -p "$(dirname "$LOG_FILE")"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Fox Den Quick Controls" "$1"
    fi
}

launch_detached() {
    nohup "$@" >/dev/null 2>&1 &
}

show_menu() {
    local prompt="$1"
    shift

    printf '%s\n' "$@" | rofi \
        -dmenu \
        -i \
        -no-custom \
        -p "$prompt" \
        -theme "$THEME" \
        2>>"$LOG_FILE"
}

volume_status() {
    if ! command -v wpctl >/dev/null 2>&1; then
        printf 'Unavailable'
        return
    fi

    local raw volume
    raw="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
    volume="$(awk '{printf "%d%%", $2 * 100}' <<<"$raw" 2>/dev/null || true)"

    if [[ "$raw" == *MUTED* ]]; then
        printf 'Muted'
    elif [[ -n "$volume" ]]; then
        printf '%s' "$volume"
    else
        printf 'Unknown'
    fi
}

brightness_status() {
    if ! command -v brightnessctl >/dev/null 2>&1; then
        printf 'Unavailable'
        return
    fi

    brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 {print $4}'
}

bluetooth_status() {
    if ! command -v bluetoothctl >/dev/null 2>&1; then
        printf 'Unavailable'
        return
    fi

    if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
        printf 'On'
    else
        printf 'Off'
    fi
}

power_profile_status() {
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl get 2>/dev/null || printf 'Unknown'
    else
        printf 'Unavailable'
    fi
}

stay_awake_running() {
    [[ -f "$AWAKE_PID_FILE" ]] || return 1

    local pid
    pid="$(cat "$AWAKE_PID_FILE" 2>/dev/null || true)"
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

stay_awake_status() {
    if stay_awake_running; then
        printf 'On'
    else
        rm -f "$AWAKE_PID_FILE"
        printf 'Off'
    fi
}

toggle_stay_awake() {
    if stay_awake_running; then
        kill "$(cat "$AWAKE_PID_FILE")" 2>/dev/null || true
        rm -f "$AWAKE_PID_FILE"
        notify "Stay Awake disabled"
        return
    fi

    if ! command -v systemd-inhibit >/dev/null 2>&1; then
        notify "systemd-inhibit is unavailable"
        return
    fi

    nohup systemd-inhibit \
        --what=idle:sleep \
        --mode=block \
        --who="Fox Den" \
        --why="Stay Awake enabled from Waybar" \
        sleep infinity \
        >/dev/null 2>&1 &

    printf '%s\n' "$!" > "$AWAKE_PID_FILE"
    notify "Stay Awake enabled"
}

open_terminal_command() {
    if command -v kitty >/dev/null 2>&1; then
        launch_detached kitty --class foxden-quick-controls -e "$@"
    else
        notify "Kitty is unavailable"
    fi
}

bluetooth_menu() {
    local choice
    choice="$(show_menu "Bluetooth" \
        "Toggle Bluetooth Power" \
        "Open Bluetooth Manager" \
        "Open bluetoothctl")" || return 0

    case "$choice" in
        "Toggle Bluetooth Power")
            if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
                bluetoothctl power off >/dev/null 2>&1 || notify "Unable to disable Bluetooth"
            else
                bluetoothctl power on >/dev/null 2>&1 || notify "Unable to enable Bluetooth"
            fi
            ;;
        "Open Bluetooth Manager")
            if command -v blueman-manager >/dev/null 2>&1; then
                launch_detached blueman-manager
            else
                notify "Blueman Manager is not installed"
            fi
            ;;
        "Open bluetoothctl")
            open_terminal_command bluetoothctl
            ;;
    esac
}

volume_menu() {
    local choice
    choice="$(show_menu "Volume" \
        "Mute / Unmute" \
        "Set Volume to 25%" \
        "Set Volume to 50%" \
        "Set Volume to 75%" \
        "Set Volume to 100%" \
        "Open Audio Settings")" || return 0

    case "$choice" in
        "Mute / Unmute") wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        "Set Volume to 25%") wpctl set-volume @DEFAULT_AUDIO_SINK@ 25% ;;
        "Set Volume to 50%") wpctl set-volume @DEFAULT_AUDIO_SINK@ 50% ;;
        "Set Volume to 75%") wpctl set-volume @DEFAULT_AUDIO_SINK@ 75% ;;
        "Set Volume to 100%") wpctl set-volume @DEFAULT_AUDIO_SINK@ 100% ;;
        "Open Audio Settings")
            if command -v pavucontrol >/dev/null 2>&1; then
                launch_detached pavucontrol
            else
                notify "pavucontrol is not installed"
            fi
            ;;
    esac
}

brightness_menu() {
    local choice
    choice="$(show_menu "Brightness" \
        "Set Brightness to 10%" \
        "Set Brightness to 25%" \
        "Set Brightness to 50%" \
        "Set Brightness to 75%" \
        "Set Brightness to 100%")" || return 0

    case "$choice" in
        "Set Brightness to 10%") brightnessctl set 10% ;;
        "Set Brightness to 25%") brightnessctl set 25% ;;
        "Set Brightness to 50%") brightnessctl set 50% ;;
        "Set Brightness to 75%") brightnessctl set 75% ;;
        "Set Brightness to 100%") brightnessctl set 100% ;;
    esac
}

power_profile_menu() {
    local choice
    choice="$(show_menu "Power Profile" \
        "Power Saver" \
        "Balanced" \
        "Performance")" || return 0

    case "$choice" in
        "Power Saver") powerprofilesctl set power-saver ;;
        "Balanced") powerprofilesctl set balanced ;;
        "Performance") powerprofilesctl set performance ;;
    esac
}

open_network_settings() {
    if command -v nm-connection-editor >/dev/null 2>&1; then
        launch_detached nm-connection-editor
    elif command -v nmtui >/dev/null 2>&1; then
        open_terminal_command nmtui
    else
        notify "No NetworkManager settings tool was found"
    fi
}

main() {
    if ! command -v rofi >/dev/null 2>&1; then
        notify "Rofi is not installed"
        exit 1
    fi

    local bluetooth volume brightness profile awake choice
    bluetooth="$(bluetooth_status)"
    volume="$(volume_status)"
    brightness="$(brightness_status)"
    profile="$(power_profile_status)"
    awake="$(stay_awake_status)"

    choice="$(show_menu "Quick Controls" \
        "$(printf '%-19s %s' 'Bluetooth' "$bluetooth")" \
        "$(printf '%-19s %s' 'Volume' "$volume")" \
        "$(printf '%-19s %s' 'Brightness' "$brightness")" \
        "$(printf '%-19s %s' 'Power Profile' "$profile")" \
        "$(printf '%-19s %s' 'Stay Awake' "$awake")" \
        "Audio Settings" \
        "Network Settings")" || exit 0

    case "$choice" in
        Bluetooth*) bluetooth_menu ;;
        Volume*) volume_menu ;;
        Brightness*) brightness_menu ;;
        "Power Profile"*) power_profile_menu ;;
        "Stay Awake"*) toggle_stay_awake ;;
        "Audio Settings")
            if command -v pavucontrol >/dev/null 2>&1; then
                launch_detached pavucontrol
            else
                notify "pavucontrol is not installed"
            fi
            ;;
        "Network Settings") open_network_settings ;;
    esac
}

main "$@"
