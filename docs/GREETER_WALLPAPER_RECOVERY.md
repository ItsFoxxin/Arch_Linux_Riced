# Greeter, local wallpapers, static lock and optional user service

> **Operator boundary:** this PR does not process or stage video, touch `/etc/greetd`, change PAM, enable a service, reload the desktop, or run a lock. This runbook documents **manual future steps**, with separate preview, activation and recovery paths. See [greetd/README.md](../greetd/README.md) for the tracked script's original workflow.

## Different screens, different responsibilities

| Component | Tracked source | What actually renders | Management / risk |
| --- | --- | --- | --- |
| Static session lock (normal) | `hypr/.config/hypr/hyprlock.conf`; tracked PNGs in `hypr/.config/hypr/assets/hyprlock/` | Fox Den lock art, two clocks, password input | Stow-managed; uses PAM. Two absolute `/home/foxxin` image paths require host review |
| Animated session-lock **preview** | `hyprlock-animated.conf`, `scripts/foxden-lock-animated-test.sh` | Local `foxden_hyprlock_animated.mp4` under an overlay with temporarily enabled session-lock xray | **Not** default; single `eDP-1` only; follows [preview safety guide](ANIMATED_HYPRLOCK_PREVIEW.md) |
| Login screen before session | `greetd/regreet.toml`, `regreet-static.toml`, `regreet.css` | User-supplied Hailuo login animation / matching JPG | System-managed **outside Stow**; greetd/PAM remains authoritative |
| Desktop wallpaper | `hypr/.config/hypr/hyprpaper.conf`; `foxden/autostart.lua` | Local static `foxden_static_wallpaper` and animated `foxden_max_animation_wallpaper` | `eDP-1` and local paths assumed; media not committed |

**Do not confuse the login-video source and lock-preview source.** The default Hyprlock uses the tracked still artwork. `foxden-launcher.sh` calls normal `hyprlock` on Lock, not the animated test script.

## Local-only media and host assumptions

The repository deliberately does not distribute the following files:

| Expected local path | Reader / purpose |
| --- | --- |
| `~/Pictures/Wallpapers/FoxDen/foxden_static_wallpaper` | `hyprpaper.conf` uses an **absolute** path currently rooted at `/home/foxxin` |
| `~/Pictures/Wallpapers/FoxDen/foxden_max_animation_wallpaper` | `autostart.lua` passes it to `mpvpaper` for `eDP-1` |
| `~/Pictures/Wallpapers/FoxDen/foxden_hyprlock_animated.mp4` | Animated lock preview launcher; not used for production lock |
| `~/Pictures/Wallpapers/FoxDen/foxden_login_animated.mp4` | Original **login** animation input |
| `~/Pictures/Wallpapers/FoxDen/foxden_login_processed.mp4` | Processed login video output |

The two **tracked** static lock PNGs are `fox-den-lock-bg.png` and `fox-den-logo.png` under `hypr/.config/hypr/assets/hyprlock/`. ReGreet expects **separately staged** media under `/usr/share/backgrounds/foxden/`, not `~/Pictures`, because the greeter runs in a different security context. Do not add user-supplied videos, exported credentials, home-directory state or private workstation assets to Git.

For a new machine, verify its monitor output and adjust host-specific configuration; do not assume `eDP-1` or `/home/foxxin` exists.

## Greeter prerequisites and processing (manual only)

Before **any** live greeter change, confirm existing greetd/ReGreet login works, document the current `/etc/greetd/config.toml` compositor/session command, and verify you can log into a TTY using Ctrl+Alt+F2 or F3. Preserve the original PAM flow, session chooser and login configuration.

`greetd/process-login-video.sh` requires `ffmpeg`, `ffprobe` and `awk`. It refuses an absent/empty source, identical input/output paths and invalid clip/blend/bias combinations. The default input/output are the login paths above. It produces a silent H.264 MP4 with 1920×1080 cropped frames at 24 FPS and a fade between tail/head sections. It does **not** overwrite the source. The default right-biased crop and blend can be adjusted with `FOX_CROP_BIAS` and `FOX_LOOP_BLEND_SECONDS` as documented in the script.

Example operator invocation from repo root (does **not** install or activate a greeter):

```bash
bash greetd/process-login-video.sh
ffprobe -v error -show_entries stream=width,height,avg_frame_rate,codec_name:format=duration \
  -of default=noprint_wrappers=1 \
  "$HOME/Pictures/Wallpapers/FoxDen/foxden_login_processed.mp4"
```

The above commands are for a local operator after verifying the correct input media. This PR has not run them.

## Stage media, then preview (manual and separate)

`greetd/stage-assets.sh` accepts at most one processed-video path. It makes a temp directory, strips audio without re-encoding the already-processed video and extracts a matching JPG. It then uses **sudo** to write these two files at permissions readable by the greeter:

```text
/usr/share/backgrounds/foxden/foxden-greeter.mp4
/usr/share/backgrounds/foxden/foxden-greeter.jpg
```

**Staging writes to a system asset directory** even though it does **not** replace `/etc/greetd/` files or restart the active login manager. Do not call it a read-only dry run. Back up any previous staged media separately before replacing it.

After the owner has elected to stage the media, the source-verified preview flow from repository root is:

```bash
bash greetd/stage-assets.sh
regreet --demo --config "$PWD/greetd/regreet.toml" --style "$PWD/greetd/regreet.css"
```

If animated video fails, try the static-video-derived JPG **without changing live files**:

```bash
regreet --demo --config "$PWD/greetd/regreet-static.toml" --style "$PWD/greetd/regreet.css"
gst-inspect-1.0 avdec_h264
ffprobe /usr/share/backgrounds/foxden/foxden-greeter.mp4
```

A missing `avdec_h264` suggests decoder support needs review; the tracked `greetd/README.md` identifies GStreamer with `gst-libav`, `gst-plugins-base`, `gst-plugins-good` and `gst-plugins-bad` as possible Arch components. Installing packages or deciding exact versions belongs to the owner, **not** this documentation PR. Confirm video, fallback still, selectors, clocks, password field, focus and a legitimate login path in demo before considering activation.

## Greeter activation and rollback (owner-only; never part of this PR)

Only after successful demo and TTY recovery checks, follow the backup/install steps in [greetd/README.md](../greetd/README.md) for `regreet.toml` and `regreet.css`, checking the actual greetd launcher flags. Do **not** replace `/etc/greetd/config.toml` just to theme ReGreet. Do **not** restart greetd from within an active Hyprland session or weaken PAM to troubleshoot a media problem.

If video playback is faulty but the greeter still accepts logins, the tracked static fallback configuration targets `/usr/share/backgrounds/foxden/foxden-greeter.jpg`. After owner review, the source's documented fallback is:

```bash
sudo install -m 0644 greetd/regreet-static.toml /etc/greetd/regreet.toml
```

If login UI becomes unusable, **switch to a working TTY**, authenticate normally, inspect current `/etc/greetd/regreet.toml` and `.css`, and restore the timestamped backups that were made **before** activation. Backups are not created automatically by the staging script. Do not use Stow to reverse ReGreet settings; it does not own them. Re-test a valid login path before removing recovery access.

For static lock failure, use the standard tracked `hyprlock.conf` with corrected local PNG paths, not the transparent `hyprlock-animated.conf` without its launcher. **Never kill Hyprlock to bypass authentication.** The lock's password verification remains PAM-based.

## Optional Proton Pass SSH agent user service

Tracked unit: `systemd/.config/systemd/user/proton-pass-ssh-agent.service`.

The only unit in `systemd/` has:

```ini
ExecStart=%h/.local/bin/pass-cli ssh-agent start --socket-path %h/.ssh/proton-pass-agent.sock
Restart=on-failure
RestartSec=5
WantedBy=default.target
```

It is a **template in the repository**, not installed or enabled by the seven-package Stow command. It assumes an independently installed Proton Pass `pass-cli` binary at `~/.local/bin/pass-cli`. This repo does **not** provision Proton Pass, authenticate it, store SSH keys, or manage service credentials.

Review your existing SSH agent before choosing to install a user unit. `bash/.bashrc` **already exports** `SSH_AUTH_SOCK="$HOME/.ssh/proton-pass-agent.sock"` unconditionally; that path can point to a nonexistent socket until an agent runs. Verify with **read-only** checks:

```bash
command -v pass-cli
printf 'SSH_AUTH_SOCK=%s\n' "$SSH_AUTH_SOCK"
systemctl --user status proton-pass-ssh-agent.service
```

A `not-found` status is expected if the optional template has not been installed. Do not enable or start it merely to make the status green. To recover another SSH-agent setup, restore the previously backed-up shell configuration/environment and use the service's actual installed state as the source of truth. No service deployment, user-unit changes or login credential changes are authorized by Issue #6.
