# Fox Den Midnight — animated ReGreet login screen

This is the **pre-session greetd/ReGreet login screen**, not Hyprlock.
It uses the Hailuo clip of the fox **walking into the Seoul homelab**, not the
lock-screen animation. The ReGreet GTK4 theme uses the DenKit v0.1 palette,
a midnight authentication card, a mint Eastern-time clock, and normal
user/session selection. Password authentication still runs through greetd/PAM.

## Source artwork policy

The source Hailuo animation and processed MP4 are **local assets**; they are
not committed to this dotfiles repository. An earlier revision mistakenly
included the lock-screen clip under `greetd/assets/`. That misleading video
and matching still were removed. Local video files are ignored by Git.

Expected paths on the laptop:

- Original: `~/Pictures/Wallpapers/FoxDen/foxden_login_animated.mp4`
- Processed: `~/Pictures/Wallpapers/FoxDen/foxden_login_processed.mp4`
- ReGreet's silent video: `/usr/share/backgrounds/foxden/foxden-greeter.mp4`
- ReGreet's matching fallback: `/usr/share/backgrounds/foxden/foxden-greeter.jpg`

There is no implicit `~` expansion in the TOML file. The installed media must
be world-readable so the separate greeter account can access it.

## Prerequisites

- An existing working greetd + ReGreet login session. Keep
  `/etc/greetd/config.toml` and its compositor command unchanged.
- `ffmpeg` (includes `ffprobe`) for processing the original video and creating
  the static fallback.
- A ReGreet build supporting video backgrounds and compatible GStreamer
  decoders. On Arch Linux, install `gstreamer`, `gst-libav`,
  `gst-plugins-base`, `gst-plugins-good` and `gst-plugins-bad` as needed.
- Working TTY access (Ctrl+Alt+F2/F3) before changing live login files.

## 1. Process the *correct* login video

Save the Hailuo walking-into-the-homelab MP4 to the original path above.
From the root of this repository, run:

```bash
bash greetd/process-login-video.sh
```

The processor preserves the original. It produces a silent, 1920×1080,
24-FPS H.264 video with full-bleed cropping, adjustable right-biased crop,
and a short end-to-start fade. Override the source/output paths if needed:

```bash
bash greetd/process-login-video.sh /path/to/login-original.mp4 /path/to/login-processed.mp4
```

The crop and loop can be tuned with `FOX_CROP_BIAS` (0 = left, 1 = right)
and `FOX_LOOP_BLEND_SECONDS` (default 0.70). Keep the fox visible to the
right of the login card, and check the seam after a few loops.

## 2. Stage media and preview without logging out

```bash
bash greetd/stage-assets.sh
regreet --demo --config "$PWD/greetd/regreet.toml" --style "$PWD/greetd/regreet.css"
```

The staging script reads `foxden_login_processed.mp4` by default. It copies a
silent MP4 and generates the fallback JPG **from the same video** under
`/usr/share/backgrounds/foxden/`. It does not modify the active greeter
configuration. To stage a different processed file, pass its full path as
an argument.

To isolate a video-decoder failure, test the matching still:

```bash
regreet --demo --config "$PWD/greetd/regreet-static.toml" --style "$PWD/greetd/regreet.css"
```

If the image renders but the video doesn't, check the installed GStreamer
plugins using `gst-inspect-1.0 avdec_h264` and inspect the video with
`ffprobe /usr/share/backgrounds/foxden/foxden-greeter.mp4`.

## 3. Activate after the demo works

After confirming a working TTY login, back up any existing files, then install:

```bash
for file in regreet.toml regreet.css; do
  if [[ -f "/etc/greetd/$file" ]]; then
    sudo cp -a "/etc/greetd/$file" "/etc/greetd/$file.$(date +%Y%m%d-%H%M%S).bak"
  fi
done
sudo install -m 0644 greetd/regreet.toml /etc/greetd/regreet.toml
sudo install -m 0644 greetd/regreet.css /etc/greetd/regreet.css
```

If your greeter launch command uses explicit `--config` or `--style` paths,
check that it points to the installed files. Don't restart `greetd` from your
active Hyprland session. Log out or reboot only after saving work and checking
TTY recovery.

## Fallback and rollback

If video playback fails but ReGreet still works, activate the still-image
configuration:

```bash
sudo install -m 0644 greetd/regreet-static.toml /etc/greetd/regreet.toml
```

If the greeter fails, switch to TTY, log in, and restore the timestamped
copies in `/etc/greetd/`. Do not enable autologin or weaken PAM to troubleshoot
an artwork problem. These are system files; do not `stow greetd` into `$HOME`.

## References

- [ReGreet sample configuration](https://github.com/rharish101/ReGreet/blob/main/regreet.sample.toml)
- [ReGreet README](https://github.com/rharish101/ReGreet)
- [ArchWiki greetd](https://wiki.archlinux.org/title/Greetd)
