# Fox Den Midnight — animated ReGreet login screen

This is the **login screen before Hyprland starts**, not the Hyprlock screen.
The included silent, five-second Seoul workshop video is used directly by
ReGreet's `[background]` setting. There is no separate wallpaper daemon, shell
loop, or second compositor to keep running.

The Fox Den Midnight palette follows DenKit v0.1. A nearly opaque midnight
authentication card stays centered, with a mint login button, amber hover,
coral power controls, and a mint Eastern-time clock above. The fox in the video
remains visible on the right side of the screen. User and session selection
remain enabled; greetd/PAM still handles authentication.

## Files

| File | Purpose |
|---|---|
| `regreet.toml` | Animated-video ReGreet configuration |
| `regreet-static.toml` | Static fallback with identical login settings |
| `regreet.css` | GTK4 login form, clock, input, button, and notification styling |
| `assets/foxden-greeter.mp4` | Silent H.264/MP4 background (no audio playback) |
| `assets/foxden-greeter.jpg` | Still background from the same scene |
| `stage-assets.sh` | Stages your local video for the greeter user without changing the login configuration |

## Prerequisites

- An already working greetd + ReGreet login session (this package does **not**
  replace your existing `/etc/greetd/config.toml` compositor/session command).
- A ReGreet build with video background support and a working H.264 GStreamer
  decoder. On Arch, check `pacman -Q greetd-regreet gstreamer gst-libav` first;
  install missing packages through pacman if the video cannot decode.
- `ffmpeg` for preparing the locally stored video without its audio track.
- The `Monaspace Radon NF` and Korean fallback font used in the desktop. If the
  font is unavailable to the **greeter** user, GTK will use its fallback font.
- TTY access (Ctrl+Alt+F2/F3) or another reliable way to recover a broken
  greeter **before** changing live system files.

Your source video stays at
`~/Pictures/Wallpapers/FoxDen/foxden_login_animated.mp4` on the Arch laptop.
Do not point ReGreet directly at `~/...`: TOML paths do not expand the shell's
tilde, and the separate greeter account may not be able to traverse your home
directory. We stage a silent copy under `/usr/share/backgrounds`, leaving the
original unchanged.

## 1. Stage only the media, then preview safely

From the root of a checkout of this branch:

```bash
# Reads ~/Pictures/Wallpapers/FoxDen/foxden_login_animated.mp4 by default.
# Pass greetd/assets/foxden-greeter.mp4 as an argument to use the bundled copy.
bash greetd/stage-assets.sh

# This opens a test window in your existing desktop; it does not authenticate.
regreet --demo --config "$PWD/greetd/regreet.toml" --style "$PWD/greetd/regreet.css"
```

The demo can differ slightly from the actual greeter due to the desktop's GTK
theme. Use GTK Inspector if necessary to investigate CSS selectors. Test on the
laptop display and any external monitor layouts you commonly use.

For a still-image preview, change only the config path:

```bash
regreet --demo --config "$PWD/greetd/regreet-static.toml" --style "$PWD/greetd/regreet.css"
```

If the video is black/blank but the JPG loads, check ReGreet/GStreamer versions
and decoder availability. The MP4 is H.264 with the sound track removed. You
can verify the asset with `ffprobe greetd/assets/foxden-greeter.mp4` or
`gst-discoverer-1.0 /usr/share/backgrounds/foxden/foxden-greeter.mp4` if those
utilities are installed.

## 2. Activate when you're ready (optional)

After the demo works **and** you have confirmed that a TTY login works, back up
the current configuration. Skip the backup command only if that file does not
exist yet.

```bash
sudo cp -a /etc/greetd/regreet.toml "/etc/greetd/regreet.toml.$(date +%Y%m%d-%H%M%S).bak"
sudo cp -a /etc/greetd/regreet.css "/etc/greetd/regreet.css.$(date +%Y%m%d-%H%M%S).bak"

sudo install -m 0644 greetd/regreet.toml /etc/greetd/regreet.toml
sudo install -m 0644 greetd/regreet.css /etc/greetd/regreet.css
```

If your existing greetd launch command explicitly specifies `regreet --config`
or `--style`, update those paths instead; this package deliberately does not
guess at or replace the display manager's startup command. Do not restart
`greetd` from your active desktop session. After saving your work, log out to
see the boot greeter, or test during a planned reboot with TTY recovery ready.

## 3. Fallback and rollback

If video playback is unsupported but ReGreet still opens:

```bash
sudo install -m 0644 greetd/regreet-static.toml /etc/greetd/regreet.toml
```

If the greeter does not start, switch to a TTY, log in, and restore your
timestamped copies of `regreet.toml` and `regreet.css` from `/etc/greetd/`.
The earlier `/etc/greetd/config.toml` was intentionally left untouched, so the
existing greetd recovery path still applies. Avoid enabling autologin or
relaxing PAM file permissions to debug an artwork or video issue.

## Notes

- `fit = "Cover"` intentionally fills wide and standard laptop screens;
  cropping is expected at the edges on monitors with a different aspect ratio.
- The original video contained audio. This packaged copy has none, so a login
  screen will never unexpectedly play sound.
- The clock uses `America/New_York`, matching the desktop's existing setting.
- These are **system** configuration files, not GNU Stow home dotfiles. Do not
  run `stow greetd` into your home directory.
- The video contains Hailuo/Minimax branding embedded by the creator. Artwork
  is included in this personal theme only; check the generation service's
  license before redistributing it beyond your own setup.

Sources: [ReGreet configuration and video support](https://github.com/rharish101/ReGreet/blob/main/regreet.sample.toml),
[ReGreet custom CSS and demo mode](https://github.com/rharish101/ReGreet#custom-css),
and [ArchWiki greetd](https://wiki.archlinux.org/title/Greetd).
