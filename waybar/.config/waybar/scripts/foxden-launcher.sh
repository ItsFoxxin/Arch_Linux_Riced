#!/usr/bin/env bash

# Fox Den launcher for Waybar and Rofi.

set -u

THEME="$HOME/.config/waybar/foxden-launcher.rasi"
SCRIPTS="$HOME/.config/waybar/scripts"

NOTIFY_ID_FILE="${XDG_RUNTIME_DIR:-/tmp}/foxden-power-notification.id"


show_menu() {
    local prompt="$1"
    shift

    printf '%s\n' "$@" |
        rofi \
            -dmenu \
            -i \
            -p "$prompt" \
            -theme "$THEME"
}


fox_notify() {
    local message="$1"
    local old_id=""
    local new_id=""

    # Do not interrupt the requested action if notifications are unavailable.
    command -v notify-send >/dev/null 2>&1 || return 0

    if [[ -r "$NOTIFY_ID_FILE" ]]; then
        read -r old_id < "$NOTIFY_ID_FILE"
    fi

    if [[ "$old_id" =~ ^[0-9]+$ ]]; then
        new_id="$(
            notify-send \
                --app-name="Fox Den" \
                --urgency=low \
                --expire-time=2500 \
                --transient \
                --replace-id="$old_id" \
                --print-id \
                "Power & Sessions" \
                "$message"
        )"
    else
        new_id="$(
            notify-send \
                --app-name="Fox Den" \
                --urgency=low \
                --expire-time=2500 \
                --transient \
                --print-id \
                "Power & Sessions" \
                "$message"
        )"
    fi

    if [[ "$new_id" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "$new_id" > "$NOTIFY_ID_FILE"
    fi
}


confirm_action() {
    local action="$1"
    local answer=""

    answer="$(
        show_menu \
            "Confirm $action" \
            "Cancel" \
            "$action"
    )"

    [[ "$answer" == "$action" ]]
}


power_menu() {
    local choice=""

    choice="$(
        show_menu \
            "Power & Sessions" \
            "Lock" \
            "Suspend" \
            "Log out" \
            "Restart" \
            "Shut down"
    )"

    case "$choice" in
        "Lock")
            fox_notify "Locking session"

            # Briefly allow the notification to render before locking.
            sleep 0.25

            if command -v hyprlock >/dev/null 2>&1; then
                setsid -f hyprlock >/dev/null 2>&1
            else
                loginctl lock-session
            fi
            ;;

        "Suspend")
            if confirm_action "Suspend"; then
                fox_notify "Suspending system"
                sleep 0.5
                systemctl suspend
            fi
            ;;

        "Log out")
            if confirm_action "Log out"; then
                fox_notify "Logging out"
                sleep 0.5
                hyprctl dispatch exit
            fi
            ;;

        "Restart")
            if confirm_action "Restart"; then
                fox_notify "Restarting system"
                sleep 0.5
                systemctl reboot
            fi
            ;;

        "Shut down")
            if confirm_action "Shut down"; then
                fox_notify "Shutting down"
                sleep 0.5
                systemctl poweroff
            fi
            ;;
    esac
}


selection="$(
    show_menu \
        "Fox Den" \
        "Applications" \
        "Windows" \
        "Terminal" \
        "Quick Controls" \
        "Power & Sessions"
)"


case "$selection" in
    "Applications")
        rofi \
            -show drun \
            -theme "$THEME"
        ;;

    "Windows")
        rofi \
            -show window \
            -theme "$THEME"
        ;;

    "Terminal")
        setsid -f kitty >/dev/null 2>&1
        ;;

    "Quick Controls")
        sleep 0.15
        bash "$SCRIPTS/quick-controls.sh"
        ;;

    "Power & Sessions")
        power_menu
        ;;
esac
