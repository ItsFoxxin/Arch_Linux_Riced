# Desktop, shell and application configuration

This guide describes **existing tracked behavior on `dev`**. File references are paths from the repository root; Stow places their contents under `$HOME`. For installation prerequisites, see [dependency inventory](INSTALLATION_DEPENDENCIES.md). All suggested runtime checks are **manual**, not results from this PR.

## Hyprland Lua and startup

Source: `hypr/.config/hypr/hyprland.lua`, with `require("foxden/autostart")` at the end loading `hypr/.config/hypr/foxden/autostart.lua`.

- Lua config uses `hl.monitor`, `hl.config`, `hl.bind`, `hl.window_rule`, `hl.on` and other `hl.*` APIs. Parsing successfully with a standalone Lua compiler **does not prove** the installed Hyprland build implements these APIs.
- Monitor rule prefers the available mode and automatic scale/position. Input keyboard layout is `us` and a three-finger horizontal gesture switches workspace.
- DenKit colors are defined in a local Lua `midnight` table; the active border is mint and inactive border slate. Dwindle, blur, shadows, curves and animations are configured here.
- Session start attempts `waybar`, `swaync`, `hyprpaper`, `fcitx5 -d`, `systemctl --user start hyprpolkitagent.service` and `mpvpaper` using the *local* wallpaper on `eDP-1`. This is an **attempt to start** these programs, not a check of their success. Reconcile the static Hyprpaper rule and animated mpvpaper layer on the target display.
- TTY1 startup lives in `bash/.bash_profile`: it calls `start-hyprland` only when `tty` is `/dev/tty1`, no Wayland/X11 or SSH session is already present, and the executable exists. Review before replacing a login-shell profile.

### Source-verified key bindings

| Shortcut | Configured action / dependency |
| --- | --- |
| Super (release) | Rofi Fox Den launcher via `foxden-launcher.sh` |
| **Super + Alt + S** | Quick Controls via `quick-controls.sh` |
| **Super + S** | Toggle `special:magic` workspace; **not** Quick Controls |
| Super + Alt + Shift + S | Move active window to `special:magic` |
| Super + Q / E / R | Kitty / Dolphin / `hyprlauncher` |
| Super + C / V / P / J | Close / float / pseudo / toggle split |
| Super + 1–0 | Focus workspaces 1–10; Super + Shift + 1–0 moves a window there |
| Super + Arrow / wheel | Change focus / traverse workspaces |
| Super + Shift + S | Hyprshot region to clipboard |
| Print / Super + Print | Hyprshot monitor / window to clipboard |
| Super + Shift + A | Grim + Slurp region piped to Satty; saved under `~/Pictures/Screenshots` |
| Super + Shift + R | Toggle `foxden-record-toggle.sh` region video capture |
| Audio/media/brightness keys | `wpctl`, `playerctl`, `brightnessctl` where applicable |

For the authoritative shortcut definitions, inspect `hypr/.config/hypr/hyprland.lua` directly. The Lua bindings distinguish **Super + Alt + S** (Quick Controls) from **Super + S** (the special workspace).

The recording script requires `XDG_RUNTIME_DIR`, uses an exclusive lock and PID/start-time validation, stores state and logs below `$XDG_RUNTIME_DIR/foxden-capture`, and writes silent MP4 files in `~/Videos/Captures`. It starts on a region selection and stops/finalizes on the next toggle; do not terminate `wf-recorder` indiscriminately while finalizing. These are not tracked assets.

## Waybar, Rofi, and Quick Controls

Sources: `waybar/.config/waybar/config.jsonc`, `style.css`, `foxden-midnight.rasi`, `foxden-launcher.rasi`, `quick-controls.rasi` and files under `scripts/`.

The **active** Waybar arrangement is:

- Left: custom Fox Den launcher, Hyprland workspaces, active window title.
- Center: New York/Pennsylvania and Seoul clocks (the format uses the 24-hour clock).
- Right: network + a Python network sparkline, CPU + memory + battery, and input-method indicator + Quick Controls + tray.
- `wireplumber`, `backlight` and `power-profiles-daemon` modules have configuration blocks but are **not currently in an active module group**. Their absence from the rendered bar is not automatically a fault.

The network sparkline is a persistent Python script using the current IPv4 default route in `/proc/net/route` and RX/TX counters in `/proc/net/dev`; it writes one JSON line per update. Without an IPv4 default route it reports an offline state. The regression tests do not require a running Waybar.

The two Rofi menus share palette definitions via `@import "foxden-midnight.rasi"` in the **Waybar configuration directory**. The launcher handles Applications (`drun`), Windows, Terminal, Quick Controls, and a confirmation-gated Power & Sessions menu. Its Lock action uses `hyprlock` if available or `loginctl lock-session` as fallback; it does **not** invoke the animated lock preview.

Quick Controls exposes:

| Menu | Underlying command / caveat |
| --- | --- |
| Volume | `wpctl`; audio-settings action launches `pavucontrol` if present |
| Brightness | `brightnessctl`; may be inapplicable on some displays |
| Bluetooth | `bluetoothctl`; manager requires `blueman-manager` |
| Power Profile | `powerprofilesctl`; depends on daemon and supported profiles |
| Stay Awake | Starts/stops `systemd-inhibit --what=idle:sleep ... sleep infinity` with a PID file under `XDG_RUNTIME_DIR` |
| Network Settings | `nm-connection-editor` if present, otherwise `nmtui` in Kitty |

The Quick Controls script writes menu diagnostics to `~/.cache/waybar-quick-controls.log` (or `XDG_CACHE_HOME`). Status may say `Unavailable` when a binary is missing; installing one optional helper does not imply every menu works. Stay Awake is an inhibitor while its process runs, not a persistent power policy. Inspect it before repeatedly toggling if the process has been interrupted.

The input-method script classifies `fcitx5-remote -n` outputs `keyboard-us` and `hangul`, otherwise `?`. A correct Fcitx5 setup and switch hotkey are separately required. Right-click is bound to `fcitx5-configtool`.

## Kitty

Source: `kitty/.config/kitty/kitty.conf`.

- Primary font `Monaspace Radon NF`; Korean Hangul ranges mapped to `LXGW WenKai Mono KR`. Font installation is **not managed** here.
- Midnight background with opacity `0.91`, mint cursor, mint active internal-pane borders, coral selected tabs at the **top**, cursor trail and split/stack/tall layouts.
- `editor nvim`, `wayland_enable_ime yes`, `allow_remote_control no`, paste safety confirmation, read-clipboard confirmation and automatic config reload are explicitly configured.
- `Ctrl+Shift+Enter` creates a Kitty window/pane in the current working directory, `Ctrl+L` clears current output into scrollback, and `Ctrl+Shift+F5` reloads the configuration.
- Some appearance options are version-sensitive. A valid text file is not evidence that your Kitty version supports every cursor/scrollbar setting. Use the target terminal's own diagnostics and retain a prior working config.

## Bash and Starship

Sources: `bash/.bashrc`, `bash/.bash_profile`, `starship/.config/starship.toml`.

- Interactive Bash gets history behavior, conditional bash-completion, fzf key integration (`Ctrl+R`, `Ctrl+T`, `Alt+C`) with `bat`/`eza` previews, conditional `zoxide`, `ll/la/lt/lt2` aliases and Git convenience aliases.
- `cfox` assumes the repository at `~/Projects/Arch_Linux_Riced`; adapt this shell function on other machines. `kssh` aliases `kitten ssh`.
- Starship is initialized only if installed; otherwise the rc file supplies a simple Bash `PS1`. The DenKit Starship palette includes a two-line prompt, responsive Fox Den label, SSH/ROOT warnings, working-tree state and command status.
- **SSH-agent caution:** the last lines of `.bashrc` prepend `~/.local/bin` to `PATH` and unconditionally set `SSH_AUTH_SOCK=~/.ssh/proton-pass-agent.sock`. This may override a working agent even when Proton Pass is absent. Check the optional service in [greeter, wallpaper and service recovery](GREETER_WALLPAPER_RECOVERY.md).

## SwayNC and Spotify Player

- `swaync/.config/swaync/config.json` configures upper-right notifications, a right-side control center, DND, MPRIS, notification grouping, keyboard shortcuts and Fox Den style; `style.css` contains the DenKit colors. The Hyprland autostart launches `swaync` but does **not** define a dedicated SwayNC control-center keybind here.
- `spotify-player/.config/spotify-player/app.toml` selects theme `fox_den`, disables local streaming (`enable_streaming = "Never"`) and media-control integration, and enables notifications. `theme.toml` defines the named palette. The Hyprland `workspace.created` event starts `kitty -e spotify_player` **only if workspace 2 is created and empty**; switching to an already-existing workspace does not guarantee a launch. Login/OAuth, Spotify API registration and playback devices are external to this repository. Do not commit tokens or account state.

## Manual troubleshooting order

1. Confirm the correct file is linked under `~/.config` and that no old config is still being loaded.
2. Inspect the component's binary availability and version; check scripts for optional commands before blaming the palette.
3. Confirm correct monitor name, font resolution and existing local wallpapers.
4. Check Rofi `.rasi` import paths, Quick Controls logfile, SwayNC config and Fcitx5 engine output separately.
5. For lock/login failure use the dedicated [recovery guide](GREETER_WALLPAPER_RECOVERY.md) and [animated preview guide](ANIMATED_HYPRLOCK_PREVIEW.md), not blind desktop restarts.

Continue with the explicit [manual runtime checklist](VALIDATION_RUNTIME_CHECKLIST.md).
