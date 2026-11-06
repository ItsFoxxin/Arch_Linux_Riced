#!/usr/bin/env bash
# Manual preview only. Never bind this to the production lock hotkey yet.
set -Eeuo pipefail

video="${HOME}/Pictures/Wallpapers/FoxDen/foxden_hyprlock_animated.mp4"
cfg="${HOME}/.config/hypr/hyprlock-animated.conf"
output="eDP-1"

for command_name in hyprctl hyprlock mpvpaper jq; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing requirement: %s\n' "$command_name" >&2
        exit 1
    }
done

[[ -r "$video" && -r "$cfg" ]] || {
    printf 'Missing or unreadable local video or animated Hyprlock config.\n' >&2
    exit 1
}

# Do not expose other monitors/workspaces while transparent lock rendering runs.
monitors_json="$(hyprctl -j monitors)"
[[ "$(jq -r 'length' <<< "$monitors_json")" == 1 ]] &&
    [[ "$(jq -r '.[0].name' <<< "$monitors_json")" == "$output" ]] || {
        printf 'This preview requires only the laptop display (%s) enabled.\n' "$output" >&2
        exit 1
    }

previous_ws="$(hyprctl -j activeworkspace | jq -r '.id')"
[[ "$previous_ws" =~ ^[1-9][0-9]*$ ]] || {
    printf 'Start from a numbered workspace.\n' >&2
    exit 1
}

hyprctl getoption misc:session_lock_xray | grep -qx 'bool: false' || {
    printf 'Session lock xray must start disabled.\n' >&2
    exit 1
}

video_pid=''
temp_ws="name:foxden-lock-test-$BASHPID"

cleanup() {
    # Hide all live workspace rendering before taking down the video overlay.
    hyprctl eval 'hl.config({ misc = { session_lock_xray = false } })' >/dev/null 2>&1 || true
    if [[ -n "$video_pid" ]]; then
        kill "$video_pid" 2>/dev/null || true
        wait "$video_pid" 2>/dev/null || true
    fi
    hyprctl dispatch "hl.dsp.focus({ workspace = $previous_ws })" >/dev/null 2>&1 || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

hyprctl dispatch "hl.dsp.focus({ workspace = \"$temp_ws\" })" >/dev/null
current_ws="$(hyprctl -j activeworkspace | jq -r '.name')"
[[ "$current_ws" == "${temp_ws#name:}" ]] || {
    printf 'Failed to activate the temporary empty workspace.\n' >&2
    exit 1
}

# The video is wider than 16:9. Pan-scan fills the screen without black bars.
mpvpaper --layer overlay \
    -o 'no-audio --loop-file=inf --panscan=1.0' \
    "$output" "$video" &
video_pid=$!

sleep 1
kill -0 "$video_pid" 2>/dev/null || {
    printf 'mpvpaper did not start.\n' >&2
    exit 1
}

hyprctl eval 'hl.config({ misc = { session_lock_xray = true } })' >/dev/null
hyprctl getoption misc:session_lock_xray | grep -qx 'bool: true' || {
    printf 'Could not enable temporary session lock xray.\n' >&2
    exit 1
}

printf 'Starting Fox Den animated lock preview (unlock to restore workspace).\n'
hyprlock --config "$cfg"
