# Fox Den Arch/Hyprland technical guides

These documents describe **tracked configuration on `dev`**, with an explicit distinction between source evidence, CI validation, and manual runtime testing. They are maintenance and recovery references for an existing desktop, **not** a new Arch installation script or proof of workstation behavior.

| Guide | Use it for |
| --- | --- |
| [Installation prerequisites and dependencies](INSTALLATION_DEPENDENCIES.md) | Required vs optional executables; fonts; Fcitx5/Hangul; device and path assumptions |
| [Stow deployment and recovery](STOW_DEPLOYMENT_RECOVERY.md) | Seven-package map; home-directory preflight; conflicts; backups; rollback |
| [Desktop configuration](DESKTOP_CONFIGURATION.md) | Hyprland Lua/autostart/keybinds; Waybar/Rofi/Quick Controls; capture; Kitty/Bash/Starship; SwayNC/Spotify |
| [Greeter, wallpaper and optional service recovery](GREETER_WALLPAPER_RECOVERY.md) | Static Hyprlock, local-only media; ReGreet processing/demo/fallback/TTY recovery; optional Proton Pass SSH agent |
| [Animated Hyprlock preview](ANIMATED_HYPRLOCK_PREVIEW.md) | Current `dev` preview, no obsolete feature branch; single-monitor/xray safety; cleanup |
| [CI vs live runtime verification](VALIDATION_RUNTIME_CHECKLIST.md) | Existing CI capabilities, local static commands and owner-only acceptance checklist |

**Ownership boundaries:** `README.md` is handled separately by Issue #5; the current documentation PR touches `docs/` only. `greetd/` is a system-level configuration and media workflow, `systemd/` is a separately managed optional unit, and neither is installed as part of the seven Stow home packages.

No command in these guides has been run against the user's workstation as part of the documentation change. Configuration changes, installs, runtime previews, service activation, production greeter deployment and merges require separate owner action.
