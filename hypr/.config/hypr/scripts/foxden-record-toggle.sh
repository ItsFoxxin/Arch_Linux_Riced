#!/usr/bin/env bash
# Fox Den Seoul - region recording toggle for Hyprland/Wayland.
# First invocation: select a region and start an MP4 recording.
# Second invocation: ask that recorder to stop cleanly and save the MP4.
# Audio is deliberately disabled by default (privacy).
set -uo pipefail
umask 077

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send --app-name='Fox Den Capture' "$1" "${2:-}" >/dev/null 2>&1 || true
    fi
}

error() {
    printf 'Fox Den recording: %s\n' "$*" >&2
    notify 'Recording error' "$*"
    exit 1
}

# An exclusive per-user runtime directory prevents multiple toggles racing.
[[ -n "${XDG_RUNTIME_DIR:-}" && -d "${XDG_RUNTIME_DIR}" ]] || \
    error 'XDG_RUNTIME_DIR is unavailable; run from your desktop session.'
state_dir="$XDG_RUNTIME_DIR/foxden-capture"
[[ ! -L "$state_dir" ]] || error 'Refusing symlinked state directory.'
mkdir -p -m 700 -- "$state_dir" || error 'Could not create runtime state directory.'
[[ -O "$state_dir" ]] || error 'Runtime state directory is not owned by this user.'

state_file="$state_dir/recording.state"
log_file="$state_dir/wf-recorder.log"
lock_file="$state_dir/toggle.lock"

# The recorder child closes fd 9 so the lock is released when this script exits.
exec 9>"$lock_file" || error 'Could not open runtime lock.'
flock -n 9 || { notify 'Fox Den Capture' 'Capture selection is already in progress.'; exit 0; }

pid=''
start_ticks=''
video_file=''
load_state() {
    local lines=()
    [[ -f "$state_file" ]] || return 1
    mapfile -t lines < "$state_file"
    pid="${lines[0]:-}"
    start_ticks="${lines[1]:-}"
    video_file="${lines[2]:-}"
    [[ "$pid" =~ ^[0-9]+$ && "$start_ticks" =~ ^[0-9]+$ && -n "$video_file" ]]
}

# /proc/PID/stat field 22 identifies the process start time. Using it with
# the PID prevents accidentally signalling an unrelated reused PID.
process_start_ticks() {
    [[ -r "/proc/$1/stat" ]] || return 1
    awk '{ sub(/^.*\) /, ""); print $20 }' "/proc/$1/stat" 2>/dev/null
}

recording_active() {
    [[ "$pid" =~ ^[0-9]+$ && "$start_ticks" =~ ^[0-9]+$ ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    [[ "$(process_start_ticks "$pid")" == "$start_ticks" ]] || return 1
    # A zombie is no longer recording; its output may still require inspection.
    [[ "$(awk '/^State:/ {print $2}' "/proc/$pid/status" 2>/dev/null)" != 'Z' ]]
}

load_state || true

case "${1:-toggle}" in
    status)
        if recording_active; then
            printf 'Recording: %s (PID %s)\n' "$video_file" "$pid"
        else
            printf 'No Fox Den recording active.\n'
        fi
        exit 0
        ;;
    waybar)
        if recording_active; then
            printf '{"text":"● REC","tooltip":"Fox Den screen recording active","class":"recording"}\n'
        else
            printf '{"text":"","tooltip":"No active screen recording","class":"idle"}\n'
        fi
        exit 0
        ;;
    toggle|start|stop) ;;
    *) printf 'Usage: %s [toggle|start|stop|status|waybar]\n' "$0" >&2; exit 2 ;;
esac

if recording_active; then
    [[ "${1:-toggle}" != 'start' ]] || { notify 'Fox Den Capture' 'Already recording.'; exit 0; }

    # SIGINT gives wf-recorder a chance to finalize the MP4 container.
    kill -INT "$pid" 2>/dev/null || error 'Could not signal the recorder.'
    for ((i=0; i<70; i++)); do
        recording_active || break
        sleep 0.1
    done
    if recording_active; then
        error "Recorder is still stopping (PID $pid). Try again shortly."
    fi
    rm -f -- "$state_file"
    if [[ -s "$video_file" ]]; then
        printf 'Recording saved: %s\n' "$video_file"
        notify 'Recording saved' "$video_file"
    else
        error "No completed MP4 found; inspect $log_file"
    fi
    exit 0
fi

if [[ "${1:-toggle}" == 'stop' ]]; then
    printf 'No Fox Den recording active.\n'
    exit 0
fi

# An old state file can remain after a logout or recorder crash.
rm -f -- "$state_file"
command -v wf-recorder >/dev/null 2>&1 || error 'wf-recorder is not installed.'
command -v slurp >/dev/null 2>&1 || error 'slurp is not installed.'
command -v setsid >/dev/null 2>&1 || error 'setsid (util-linux) is missing.'

# Cancelling slurp does not start a recording or create a video.
region="$(slurp)" || exit 0
[[ -n "$region" ]] || exit 0

capture_dir="$HOME/Videos/Captures"
mkdir -p -- "$capture_dir" || error "Cannot create $capture_dir"
video_file="$capture_dir/foxden-$(date +%Y%m%d-%H%M%S)-$$.mp4"

# Start detached so the recording survives this short-lived shortcut process.
# Close the flock fd in the child so another press can stop it.
setsid -- wf-recorder -g "$region" -f "$video_file" >"$log_file" 2>&1 9>&- &
pid=$!
sleep 0.5
kill -0 "$pid" 2>/dev/null || error "Recorder exited early; inspect $log_file"
start_ticks="$(process_start_ticks "$pid")"
[[ "$start_ticks" =~ ^[0-9]+$ ]] || error 'Could not validate recorder process.'
printf '%s\n%s\n%s\n' "$pid" "$start_ticks" "$video_file" > "$state_file" || \
    error 'Could not save recording state.'
printf 'Recording started: %s (PID %s)\n' "$video_file" "$pid"
notify '● Recording started' 'Super + Shift + R to stop · No microphone/system audio'
