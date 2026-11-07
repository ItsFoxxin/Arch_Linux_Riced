#!/usr/bin/env bash
# Fox Den Midnight — full-bleed animated ReGreet login video.
# Preserves source; produces a separate, silent, loop-smoothed H.264 MP4.
set -Eeuo pipefail

input="${1:-$HOME/Pictures/Wallpapers/FoxDen/foxden_login_animated.mp4}"
output="${2:-$HOME/Pictures/Wallpapers/FoxDen/foxden_login_processed.mp4}"
fade_seconds="${FOX_LOOP_BLEND_SECONDS:-0.70}"
crop_bias="${FOX_CROP_BIAS:-0.60}" # 0=left, 0.5=center, 1=right. Rightward favors fox.

for binary in ffmpeg ffprobe awk; do
    command -v "$binary" >/dev/null || { echo "Missing dependency: $binary" >&2; exit 1; }
done
[[ -s "$input" ]] || { echo "Missing or empty source video: $input" >&2; exit 1; }
[[ "$input" != "$output" ]] || { echo "Output must differ from input (source preservation)" >&2; exit 1; }

duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 -- "$input")"
if ! awk -v d="$duration" -v f="$fade_seconds" -v b="$crop_bias" 'BEGIN { exit !(d > 2*f + 0.25 && f >= 0.1 && f <= 1.5 && b >= 0 && b <= 1) }'; then
    echo "Bad clip duration ($duration s), blend ($fade_seconds s) or crop bias ($crop_bias)." >&2
    exit 1
fi

offset="$(awk -v d="$duration" -v f="$fade_seconds" 'BEGIN { printf "%.5f", d-2*f }')"
# Fade from the last section into matching initial frames for a smoother loop.
# Crop after upscaling: no blur padding or black letterbox bars.
filters="[0:v]fps=24,scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080:(in_w-out_w)*${crop_bias}:(in_h-out_h)/2,setsar=1,format=yuv420p,split=2[all][head];[all]trim=start=${fade_seconds},setpts=PTS-STARTPTS,fps=24,settb=AVTB[tail];[head]trim=start=0:duration=${fade_seconds},setpts=PTS-STARTPTS,fps=24,settb=AVTB[opening];[tail][opening]xfade=transition=fade:duration=${fade_seconds}:offset=${offset},format=yuv420p[out]"

mkdir -p -- "$(dirname -- "$output")"
ffmpeg -hide_banner -nostdin -y -i "$input" \
  -filter_complex "$filters" -map '[out]' -an \
  -c:v libx264 -preset medium -crf 19 -pix_fmt yuv420p \
  -movflags +faststart "$output"

printf '\nFinished: %s\n' "$output"
ffprobe -v error -show_entries stream=width,height,avg_frame_rate,codec_name:format=duration -of default=noprint_wrappers=1 "$output"
printf '\nStage for ReGreet preview from your repository root:\n'
printf '  bash greetd/stage-assets.sh "%s"\n' "$output"
printf '  regreet --demo --config "$PWD/greetd/regreet.toml" --style "$PWD/greetd/regreet.css"\n'
