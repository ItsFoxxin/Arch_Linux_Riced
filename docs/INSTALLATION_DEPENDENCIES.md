# Installation prerequisites and dependency inventory

> **Scope:** the existing `dev` desktop, not an automated Arch installer. This is a source-based dependency map; it is **not** proof the listed programs work on an arbitrary machine. No package installation or activation is performed by this guide.

## What is actually in the repository

The seven GNU Stow home packages are `bash`, `hypr`, `kitty`, `spotify-player`, `starship`, `swaync`, and `waybar`. Each contains files intended to land relative to `$HOME`. The `greetd/` directory is a **separate system-level theme and media workflow**, and `systemd/` contains an **optional user-unit template**; neither is included in the seven-package Stow invocation. See [Stow deployment and rollback](STOW_DEPLOYMENT_RECOVERY.md).

This repository does not install Arch, Hyprland, a display manager, fonts, codecs, applications, or a Korean input-method profile. It does not contain a general package manifest. Only the Hyprlock **background PNG and fox logo PNG** are checked in as artwork. All full-screen animated and wallpaper media are workstation-local.

## Dependency map (checked against tracked source)

| Area | Required for the described feature | Optional / conditional | Evidence |
| --- | --- | --- | --- |
| Base / deployment | Existing Arch Linux installation; Git; GNU Stow; Bash | Python for checks; a second TTY for recovery | `README.md`, `ci/stow_smoke.py` |
| Hyprland desktop | A Hyprland build supporting this `hl.*` Lua config; `start-hyprland` when relying on the TTY1 auto-start; Kitty, Dolphin, `hyprlauncher` for the configured shortcuts | `hyprshutdown` has a `hyprctl` fallback; `hyprpolkitagent.service` is started by the autostart hook | `hypr/.config/hypr/hyprland.lua`, `foxden/autostart.lua`, `bash/.bash_profile` |
| Desktop startup | Waybar; SwayNC; Hyprpaper; Fcitx5; `mpvpaper` to display the local animated wallpaper | A matching `eDP-1` output and local wallpaper paths are assumed, not autodetected | `hypr/.config/hypr/foxden/autostart.lua`, `hyprpaper.conf` |
| Waybar | Waybar with Hyprland, network, clock, CPU, memory, battery, tray modules; Python 3 for network helper; `fcitx5-remote` for input indicator | WirePlumber/pipewire `wpctl`, `pavucontrol`, `fcitx5-configtool`; `power-profiles-daemon` and backlight modules are configured but **not included** in `modules-right` | `waybar/.config/waybar/config.jsonc`, `scripts/network-sparkline.py`, `scripts/input-method.sh` |
| Menus / Quick Controls | Rofi; Bash; GTK notification tool `notify-send` when notifications are desired | `wpctl`, `brightnessctl`, `bluetoothctl`, `blueman-manager`, `powerprofilesctl`, `pavucontrol`, `nm-connection-editor` or `nmtui`, Kitty and `systemd-inhibit` are used only by their respective actions | `waybar/.config/waybar/scripts/foxden-launcher.sh`, `quick-controls.sh` |
| Capture | `hyprshot` for the three screenshot shortcuts; `grim`, `slurp`, `satty` for the annotation shortcut; `wf-recorder`, `slurp`, `setsid`, `flock` for the region recorder | `notify-send` for feedback; active Wayland session for all capture tools | `hypr/.config/hypr/hyprland.lua`, `scripts/foxden-record-toggle.sh` |
| Lock screen | `hyprlock`, usable PAM authentication; Monaspace Radon NF and LXGW WenKai Mono KR for matching appearance | `mpvpaper`, `jq`, `hyprctl` and local `foxden_hyprlock_animated.mp4` are **preview-only** dependencies | `hyprlock.conf`, `hyprlock-animated.conf`, `scripts/foxden-lock-animated-test.sh` |
| ReGreet | An existing working greetd/ReGreet + PAM login with a valid compositor/session setup | `ffmpeg`, `ffprobe`, `awk` for processing; `sudo`, `install`, `mktemp` for staging; GStreamer H.264 decoder support for video playback | `greetd/README.md`, `process-login-video.sh`, `stage-assets.sh` |
| Terminal and shell | Kitty; Bash; Starship if you want the custom prompt | `fzf` (plus `eza` / `bat` for its previews), `zoxide`, `nvim`, `git`, `kitten ssh` (Kitty), `bash-completion`; Starship has a Bash fallback if absent | `kitty/kitty.conf`, `bash/.bashrc`, `starship/starship.toml` |
| Music / notifications | `spotify_player` to run the TUI; `swaync` as notification daemon | Spotify account authorization and an appropriate playback device are external; `spotify_player` sets `enable_streaming = "Never"` | `spotify-player/.config/spotify-player/app.toml`, `hyprland.lua`, `swaync/config.json` |
| Optional SSH agent | `$HOME/.local/bin/pass-cli` if the optional Proton Pass unit is selected; authenticated CLI session before start | Bash probes the Proton socket and preserves a reachable inherited agent instead of advertising a dead socket | `systemd/.config/systemd/user/proton-pass-ssh-agent.service`, `bash/.bashrc`, [agent guide](PROTON_PASS_SSH_AGENT.md) |
| Static validation | Python **3.11+** (`tomllib`), `json5` Python module; GNU Stow; ShellCheck; Lua compiler `luac` | CI uses Ubuntu 24.04, Lua 5.4, `json5==0.12.1`; these are CI specifics, not an Arch runtime version guarantee | `.github/workflows/ci.yml`, `ci/validate.py`, `ci/stow_smoke.py` |

This map names **executables or capabilities found in tracked files**, not a verified one-to-one list of Arch package names. Discover package names and compatibility for the target machine before installing. Do not bulk-install optional software just to satisfy unrelated controls.

## Fonts and Korean input

- `Monaspace Radon NF` is the Kitty font, a Starship/Nerd Font glyph source and the primary ReGreet/Hyprlock UI font. `LXGW WenKai Mono KR` supplies Hangul glyphs through Kitty `symbol_map` ranges, and both lock configurations use it for Korean text. The repository does **not** package these font files.
- The Hyprland input layout is `us`. The autostart hook calls `fcitx5 -d`. Waybar's input script calls `fcitx5-remote -n` and recognizes `keyboard-us` and `hangul`. Right-clicking the indicator opens `fcitx5-configtool`.
- Install/configure the Fcitx5 Hangul input method, switch hotkey, session environment and appropriate font fallbacks **outside this repo**. Neither a Hangul engine package nor a switch binding is configured here. Check the actual engine names before interpreting a `?` indicator as a Waybar defect.

Non-mutating host checks (run locally only when ready):

```bash
command -v stow hyprctl kitty waybar rofi swaync fcitx5-remote
command -v hyprshot grim slurp satty wf-recorder mpvpaper jq
command -v hyprlock regreet ffmpeg ffprobe gst-inspect-1.0
fc-match 'Monaspace Radon NF'
fc-match 'LXGW WenKai Mono KR'
```

A command being found does not establish its version compatibility, GPU behavior, systemd availability, PAM integration or font identity. Inspect the `fc-match` result: it may silently substitute another font.

## Device and session assumptions to adjust before deployment

- `hyprpaper.conf` has an absolute wallpaper path under `/home/foxxin` and targets `eDP-1`; the autostart `mpvpaper` command also targets `eDP-1`. Both reference **local-only** media.
- The static Hyprlock config includes absolute `/home/foxxin/.config/hypr/assets/hyprlock/` paths. The two referenced PNGs are tracked, but users with a different home path must edit those paths before testing a lock.
- The preview launcher requires exactly one connected monitor named `eDP-1`, a numbered workspace and initially disabled `misc:session_lock_xray`. Do not generalize it to multi-monitor configurations.
- The `bash/.bash_profile` TTY1 startup block runs `start-hyprland` only when that command exists and no graphical/SSH session is detected. Back it up before Stow deployment to prevent an unexpected session-launch change.
- `America/New_York` and `Asia/Seoul` are explicitly configured clocks. Waybar and Hyprlock use Pennsylvania-themed labels; this is a theme preference, not machine geolocation.
- The managed Bash startup selects Proton Pass only when its socket is user-owned and responds to `ssh-add -l`, otherwise preserves a reachable inherited agent or unsets the dead path. A host-specific OpenSSH `IdentityAgent` can override this selection; see [the agent guide](PROTON_PASS_SSH_AGENT.md).

## Next steps

1. Read [Stow preflight and rollback](STOW_DEPLOYMENT_RECOVERY.md) before making any links.
2. Review [Desktop and app configuration](DESKTOP_CONFIGURATION.md).
3. Read [Login, wallpaper, and optional service recovery](GREETER_WALLPAPER_RECOVERY.md) before modifying greeter media or services.
4. Use the [runtime checklist](VALIDATION_RUNTIME_CHECKLIST.md) on the target machine. CI validates syntax and isolated Stow behavior, **not** the desktop.
