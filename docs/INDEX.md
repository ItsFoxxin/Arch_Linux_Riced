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

**Documentation roles:** The root `README.md` is the project overview and entry point. The focused `docs/` guides provide source-verified installation prerequisites, component details, maintenance procedures, manual verification and recovery. The `greetd/` tree is a separately managed system-level theme and media workflow; `systemd/` contains a separately managed optional user unit. Neither is installed by the seven-package home Stow command.

**Runtime boundary:** These guides describe operator procedures, not completed workstation tests. Applying configurations, installing packages, running previews, enabling services or activating a production greeter requires a separate, deliberate owner action. Static validation and CI do not establish live desktop or authentication behavior.
