#!/usr/bin/env bash
# Stage the user's login animation for ReGreet without changing its live config.
set -Eeuo pipefail

usage() {
    printf 'Usage: %s [processed-login-video.mp4]\n' "${0##*/}"
    printf 'Default: $HOME/Pictures/Wallpapers/FoxDen/foxden_login_processed.mp4\n'
    printf 'Run greetd/process-login-video.sh to create the processed video first.\n'
}

if [[ ${1:-} == "--help" || ${1:-} == "-h" ]]; then
    usage
    exit 0
fi

if (( $# > 1 )); then
    usage >&2
    exit 2
fi

source_video="${1:-$HOME/Pictures/Wallpapers/FoxDen/foxden_login_processed.mp4}"
if [[ ! -f "$source_video" || ! -s "$source_video" || ! -r "$source_video" ]]; then
    printf 'Missing or unreadable login video: %s\n' "$source_video" >&2
    printf 'Process the Hailuo login video first; no video is bundled in this repo.\n' >&2
    exit 1
fi

for command_name in ffmpeg sudo install mktemp; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$command_name" >&2
        exit 1
    fi
done

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT

# Remove any audio without re-encoding the already-processed image.
ffmpeg -nostdin -hide_banner -loglevel error -y \
    -i "$source_video" -map 0:v:0 -c:v copy -an -movflags +faststart \
    "$tmpdir/foxden-greeter.mp4"

# Generate a matching still from the same animation, not the lock-screen artwork.
ffmpeg -nostdin -hide_banner -loglevel error -y \
    -ss 1 -i "$source_video" -frames:v 1 -q:v 2 \
    "$tmpdir/foxden-greeter.jpg"

if [[ ! -s "$tmpdir/foxden-greeter.mp4" || ! -s "$tmpdir/foxden-greeter.jpg" ]]; then
    printf 'Asset preparation failed; existing greeter media was not replaced.\n' >&2
    exit 1
fi

sudo install -d -m 0755 /usr/share/backgrounds/foxden
sudo install -m 0644 "$tmpdir/foxden-greeter.mp4" /usr/share/backgrounds/foxden/foxden-greeter.mp4
sudo install -m 0644 "$tmpdir/foxden-greeter.jpg" /usr/share/backgrounds/foxden/foxden-greeter.jpg

printf 'Staged login video and matching still from %s\n' "$source_video"
printf 'Active greetd configuration unchanged. Run regreet --demo before deployment.\n'
