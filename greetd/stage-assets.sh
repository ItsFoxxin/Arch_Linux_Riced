#!/usr/bin/env bash
# Stage artwork only. This does not change greetd's active login configuration.
set -Eeuo pipefail

usage() {
    printf 'Usage: %s [source-video.mp4]\n' "${0##*/}"
    printf 'Default: $HOME/Pictures/Wallpapers/FoxDen/foxden_login_animated.mp4\n'
}

if [[ ${1:-} == "--help" || ${1:-} == "-h" ]]; then
    usage
    exit 0
fi

if (( $# > 1 )); then
    usage >&2
    exit 2
fi

source_video="${1:-$HOME/Pictures/Wallpapers/FoxDen/foxden_login_animated.mp4}"
if [[ ! -r "$source_video" || ! -f "$source_video" ]]; then
    printf 'Cannot read source video: %s\n' "$source_video" >&2
    printf 'Supply a readable file path, or use the bundled greetd/assets/foxden-greeter.mp4.\n' >&2
    exit 1
fi

for command_name in ffmpeg sudo install mktemp; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$command_name" >&2
        exit 1
    fi
done

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
temporary_video="$(mktemp --suffix=.mp4)"
trap 'rm -f -- "$temporary_video"' EXIT

# The greeter must never unexpectedly play the video's audio stream.
# Stream-copy preserves the original video without re-encoding or reducing quality.
ffmpeg -nostdin -hide_banner -loglevel error \
    -i "$source_video" -map 0:v:0 -c:v copy -an -movflags +faststart \
    -y "$temporary_video"

if [[ ! -s "$temporary_video" ]]; then
    printf 'Video preparation produced an empty file; leaving system artwork unchanged.\n' >&2
    exit 1
fi

sudo install -d -m 0755 /usr/share/backgrounds/foxden
sudo install -m 0644 "$temporary_video" /usr/share/backgrounds/foxden/foxden-greeter.mp4
sudo install -m 0644 "$script_dir/assets/foxden-greeter.jpg" /usr/share/backgrounds/foxden/foxden-greeter.jpg

printf 'Staged silent video from %s\n' "$source_video"
printf 'ReGreet configuration has not been changed. Preview with regreet --demo first.\n'
