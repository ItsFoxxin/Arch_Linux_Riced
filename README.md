# Fox Den | Arch Linux Riced

**A personalized Arch Linux desktop environment built around Hyprland, the Fox Den Midnight palette, and a modular, developer-focused workflow.**

Fox Den is my custom Linux desktop environment, designed for system administration, development, cybersecurity, and everyday productivity.

Built around Arch Linux and Hyprland, the project combines a custom Waybar, themed terminal environment, application launchers, system controls, bilingual English/Korean elements, and reusable configuration packages.

The visual identity, **Fox Den Midnight (DenKit v0.1)**, uses soft coral, mint, and amber accents with cream text on midnight navy and slate surfaces.

> **Project status:** Active development. The `dev` branch contains ongoing changes, while `main` is intended for reviewed updates.

## Features

### Desktop and Window Management

- Arch Linux with the Hyprland Wayland compositor
- Lua-based Hyprland configuration
- Custom window borders, blur, shadows, and animations
- Keyboard-driven tiling and workspace navigation
- Touchpad gestures and multimedia keybindings
- Workspace-specific behavior, including an attempt to launch Spotify Player in Kitty when an empty workspace 2 is created
- Hyprpaper static wallpaper configuration; session autostart also invokes `mpvpaper` with a local animation on the machine-specific `eDP-1` display

### Fox Den Waybar

A customized Waybar provides desktop status information and access to frequently used controls.

Features include:

- Custom application launcher
- Quick Controls menu
- Network activity sparkline
- Input method indicator
- Themed workspace and status modules
- Integrated desktop styling

The network sparkline is implemented in Python and includes regression tests.

### Application Launcher and Quick Controls

Fox Den includes custom Bash scripts and Rofi themes for desktop interaction.

**Application Launcher**

A themed Rofi launcher opened by releasing the Super key or clicking **Fox Den** in Waybar. It offers applications, windows, a terminal, Quick Controls, and power/session actions.

**Quick Controls**

Opened with `Super + Alt + S`, the launcher menu, or the Waybar controls button. Available actions depend on installed utilities and hardware:

- Audio volume, mute, and sound settings (`wpctl`, optional `pavucontrol`)
- Display brightness (`brightnessctl`; requires a supported backlight)
- Bluetooth power and management (`bluetoothctl`, optional Blueman)
- Viewing and changing power profiles (`powerprofilesctl`, when available)
- Stay Awake mode using `systemd-inhibit`
- Audio and NetworkManager settings, when the respective tools are installed

### Fox Den Lock Screen

A customized Hyprlock configuration featuring:

- Fox Den artwork and branding
- Dual clocks for the US Eastern time zone and Seoul
- English and Korean interface elements
- Animated password entry
- Custom colors, typography, and visual effects
- PAM-based authentication

The standard `hyprlock.conf` uses tracked still images, an opinionated 1920×1080 layout, and absolute `/home/foxxin` asset paths that other machines must adapt. The separate `hyprlock-animated.conf` and preview helper are **optional testing resources**, not the default lock action. The animated preview requires a local MP4, `mpvpaper`, `jq`, one `eDP-1` display, and specific session-lock precautions; see [Animated Hyprlock preview and recovery](docs/ANIMATED_HYPRLOCK_PREVIEW.md).

The lock screen includes the Korean phrase **시작이 반이다** — "Well begun is half done."

### Fox Den Login Screen (ReGreet)

The optional **pre-session login screen** lives in [`greetd/`](greetd/README.md).
It uses a **locally supplied Hailuo animation of the fox entering the Seoul
homelab**; the animation is not bundled with the dotfiles. The included
processing and staging scripts create a silent, loop-smoothed MP4 and a matching
static fallback for ReGreet. The normal greetd/PAM authentication flow and
user/session selectors remain unchanged. Preview with `regreet --demo` before
installing the system configuration; these files are not GNU Stow home dotfiles.

### Kitty Terminal

A customized Kitty terminal environment featuring:

- Fox Den Midnight color palette
- Monaspace Radon Nerd Font
- Korean Hangul font fallback
- Mint focus borders and coral selected tabs
- Transparent background
- Terminal splits and layouts
- Scrollback navigation
- Clipboard and paste safety settings
- Neovim integration
- Wayland input method support

### Starship Prompt

A custom two-line Starship shell prompt provides:

- Adaptive Fox Den identity
- High-visibility SSH and root indicators
- Git branch and working-tree status
- Directory and host information
- Programming language environments
- Command duration and exit status
- Responsive formatting for narrow terminals

### Shell and Music

- Customized Bash configuration
- Starship prompt integration
- Spotify Player terminal interface and theme
- Keyboard-oriented terminal workflow

## Technology Stack

| Component | Technology |
|---|---|
| Operating System | Arch Linux |
| Window Manager | Hyprland |
| Configuration | Lua |
| Status Bar | Waybar |
| Lock Screen | Hyprlock |
| Login Screen | greetd + ReGreet (optional) |
| Wallpaper | Hyprpaper; machine-specific `mpvpaper` autostart |
| Screenshots and Recording | `hyprshot`, `grim`, `slurp`, `satty`, `wf-recorder` (optional external tools) |
| Terminal | Kitty |
| Shell | Bash |
| Prompt | Starship |
| Application Menus | Rofi |
| Notifications | SwayNC |
| Music | Spotify Player |
| Input Method | Fcitx5 |
| Dotfile Management | GNU Stow (seven home packages) |
| Optional User Service | Proton Pass SSH agent (`systemd/`, separately managed) |
| Automation | GitHub Actions |
| Testing | Python, ShellCheck, Lua |

## Repository Structure

Tracked `dev` files (directories are abbreviated only where indicated):

```text
Arch_Linux_Riced/
├── .gitattributes
├── .gitignore
├── .github/
│   ├── dependabot.yml
│   └── workflows/ci.yml
├── bash/                                 # Stow
│   ├── .bash_profile
│   └── .bashrc
├── ci/
│   ├── stow_smoke.py
│   └── validate.py
├── docs/
│   └── ANIMATED_HYPRLOCK_PREVIEW.md
├── greetd/                               # Separate system-level setup
│   ├── README.md
│   ├── process-login-video.sh
│   ├── regreet-static.toml
│   ├── regreet.css
│   ├── regreet.toml
│   └── stage-assets.sh
├── hypr/                                 # Stow
│   └── .config/hypr/
│       ├── assets/hyprlock/
│       │   ├── fox-den-lock-bg.png
│       │   └── fox-den-logo.png
│       ├── foxden/autostart.lua
│       ├── hyprland.lua
│       ├── hyprlock-animated.conf
│       ├── hyprlock.conf
│       ├── hyprpaper.conf
│       └── scripts/
│           ├── foxden-lock-animated-test.sh
│           └── foxden-record-toggle.sh
├── kitty/                                # Stow
│   └── .config/kitty/kitty.conf
├── spotify-player/                       # Stow
│   └── .config/spotify-player/
│       ├── app.toml
│       └── theme.toml
├── starship/                             # Stow
│   └── .config/starship.toml
├── swaync/                               # Stow
│   └── .config/swaync/
│       ├── config.json
│       └── style.css
├── systemd/                              # Separate optional user service
│   └── .config/systemd/user/proton-pass-ssh-agent.service
├── tests/
│   ├── test_network_sparkline.py
│   └── test_regreet_theme.py
├── waybar/                               # Stow
│   └── .config/waybar/
│       ├── config.jsonc
│       ├── foxden-launcher.rasi
│       ├── foxden-midnight.rasi
│       ├── quick-controls.rasi
│       ├── scripts/
│       │   ├── foxden-launcher.sh
│       │   ├── input-method.sh
│       │   ├── network-sparkline.py
│       │   └── quick-controls.sh
│       └── style.css
└── README.md
```

### Deployment and packaging inventory

The **seven GNU Stow home packages**, as listed in `ci/stow_smoke.py`, are:

| Stow package | Target in `$HOME` |
|---|---|
| `bash/` | `.bashrc`, `.bash_profile` |
| `hypr/` | `.config/hypr/` |
| `kitty/` | `.config/kitty/` |
| `spotify-player/` | `.config/spotify-player/` |
| `starship/` | `.config/starship.toml` |
| `swaync/` | `.config/swaync/` |
| `waybar/` | `.config/waybar/` |

`greetd/` is **not** a Stow home package. It contains a separately installed system login theme, media-preparation scripts, and the [ReGreet setup and rollback guide](greetd/README.md). The login MP4/JPG are generated from locally supplied video and are not tracked.

`systemd/` contains an **optional, separately managed** Proton Pass SSH-agent user unit. The file is tracked, but neither the Stow command nor CI installs or enables it; it requires a local Proton Pass CLI setup and intentional user-service management.

The CI archive includes `bash/`, `greetd/`, `hypr/`, `kitty/`, `spotify-player/`, `starship/`, `swaync/`, `waybar/`, and `README.md`. **It does not include `systemd/`, `ci/`, `docs/`, `tests/`, or `.github/`.** This archive inventory differs from the seven-package Stow deployment inventory.

## Fox Den Midnight — DenKit v0.1

This initial visual refresh preserves the desktop layout, fonts, wallpaper and
lock-screen artwork, keybindings, startup behavior, workspace rules, and shell
commands. It adds no runtime service, theme dependency, or package requirement.

### Theme tokens

| Token | Hex | Role |
|---|---|---|
| Midnight | `#0B1423` | Desktop fallback, terminal and application backgrounds |
| Slate | `#25384B` | Hover and secondary surfaces |
| Mint | `#97E7CA` | Focus, links, secondary actions, healthy states |
| Coral | `#F68D91` | Selected workspaces, tabs, launcher and music rows |
| Amber | `#F5AD66` | Warnings, information, warm branding accents |
| Cream | `#F7F5E9` | Primary text |
| Raised Surface | `#142335` | Inputs, notification cards, elevated surfaces |
| Border | `#36495D` | Subtle outlines and separators |
| Muted Text | `#AFC0D1` | Metadata, inactive labels, descriptions |
| Critical Red | `#EF5261` | Failures, conflicts, urgent states, root badge |

### Native integration

| Managed file | Integration |
|---|---|
| `hypr/.config/hypr/hyprland.lua` | Local Lua color table shared by both border declarations; mint focus, slate inactive border, navy shadow |
| `hypr/.config/hypr/hyprlock.conf` | Native color variables, cream password entry, mint outline, amber checking, red failure, nearly opaque raised panel |
| `kitty/.config/kitty/kitty.conf` | Native background, ANSI colors, cursor, links, marks, borders and tabs |
| `waybar/.config/waybar/style.css` | GTK named colors, opaque pills, subtle borders, coral active workspace, mint keyboard focus, distinct red urgency |
| `waybar/.config/waybar/config.jsonc` | Matching calendar markup colors only |
| `waybar/.config/waybar/foxden-midnight.rasi` | Shared native Rofi tokens imported by the existing launcher and Quick Controls themes |
| `swaync/.config/swaync/style.css` | Existing CSS custom-property mechanism, navy/raised surfaces, reduced glow and explicit mint keyboard focus |
| `starship/.config/starship.toml` | Native `palettes.fox_den_midnight` table referenced by prompt styles |
| `spotify-player/.config/spotify-player/theme.toml` | Existing `fox_den` theme ID retained, palette and component styles updated |
| `bash/.bashrc` | Only fzf color options and theme comments change |

Kitty and Spotify Player use their existing native color fields. Their literal
colors intentionally duplicate the tokens above because those formats do not
share CSS variables. The ANSI blue/cyan and green slots use mint, magenta uses
coral, yellow uses amber, and both red slots remain Critical Red. Terminal apps
that require more syntax-color distinctions may need a future extended palette.

Neovim is referenced as Kitty's editor, but this repository does not manage a
Neovim colorscheme. It also contains no GTK/Qt application theme package. Those
applications retain their own themes; do not assume their full interfaces inherit
these terminal colors. The existing wallpaper and lock-screen art are unchanged.

### Readability and review

Use Midnight foreground text on solid coral, mint, amber and critical-red badges;
use Cream on dark surfaces. Cream, Muted Text, Mint, Coral and Amber text on all
three dark surfaces exceed 4.5:1 in opaque sRGB contrast calculations. Critical
Red text is reserved for Midnight or Raised Surface, where it exceeds 4.5:1;
it does not meet that threshold on Slate. Borders are decorative, not text.

Urgency and failures retain their existing text, symbols, weight or an additional
inset edge; coral alone does not indicate an error. The root/SSH labels and lock
screen failure message remain explicit. Existing desktop animations and timing
are preserved; reduced-motion integration is a future desktop-level improvement.
Kitty's existing opacity is preserved, so contrast there also depends on the
wallpaper behind it. Verify that in the actual session before activation.

Run the existing checks below and inspect the Git diff before applying anything.
On Arch, a safe preview of the Stow link plan is:

```bash
stow --simulate --verbose -t "$HOME" bash hypr kitty spotify-player starship swaync waybar
```

This preview does not activate the theme. CI's Stow smoke check uses a temporary
home. Neither static checks nor CI establish live Hyprland, GTK, Rofi, Hyprlock or
Kitty rendering; a human should inspect selected/urgent workspaces, launcher
selection, notification focus, password failure and terminal transparency on the
target desktop. No desktop reload, active-home Stow operation or installation is
part of this change.

Future DenKit work can add native desktop screenshots, extended ANSI syntax
colors, a separately reviewed Neovim/GTK/Qt profile, and automatic cross-format
palette consistency checks.

## Installation

**Warning:** These configurations are tailored to my personal Arch Linux environment. They are not a complete Arch installation script or a universal desktop installer.

Some settings depend on installed applications, fonts, hardware, and local paths. In particular, the Hyprland Lua configuration requires a compatible Lua-enabled Hyprland setup; the repository does not install or validate the compositor at runtime.

### 1. Clone the repository

```bash
git clone \
  --branch dev \
  https://github.com/ItsFoxxin/Arch_Linux_Riced.git

cd Arch_Linux_Riced
```

### 2. Install GNU Stow

```bash
sudo pacman -S stow
```

Install and configure the required desktop applications and dependencies separately.

### 3. Deploy configuration packages

Review existing configuration files and back them up before continuing. Run the Stow `--simulate` preview shown above before making changes to your home directory. Only the seven packages listed below are deployed; do not add `greetd` or `systemd` to this command.

From the repository root:

```bash
stow -t "$HOME" \
  bash hypr kitty spotify-player \
  starship swaync waybar
```

Stow creates symbolic links into the target home directory.

Existing conflicting files may prevent deployment. Do not overwrite them without reviewing their contents.

### 4. Review local configuration

Before using the desktop configuration, check:

- Hyprland version and Lua configuration compatibility
- Installed fonts and icon fonts
- Monitor and hardware settings
- Application availability
- Local file paths: `hyprlock.conf` image paths and `hyprpaper.conf` wallpaper path use `/home/foxxin`
- Display assumptions: static Hyprlock layout targets 1920×1080; Hyprpaper and animated wallpaper autostart target `eDP-1`
- Locally supplied video files for the optional animated lock preview and ReGreet login screen (not committed)
- Fcitx5 and Korean font support (`Monaspace Radon NF` and `LXGW WenKai Mono KR` are referenced)
- External applications for optional capture workflows (`hyprshot`, `grim`, `slurp`, `satty`, `wf-recorder`); recordings are saved under `~/Videos/Captures` without audio by default
- Spotify Player availability and its separate authentication requirements for the optional workspace-2 TUI

Neither the [ReGreet system-login configuration](greetd/README.md) nor the `systemd/` user unit is automatically installed by these Stow commands. Review them independently; do not deploy either as part of a home-dotfile Stow operation.

## Keyboard Shortcuts

These are the bindings defined in [`hypr/.config/hypr/hyprland.lua`](hypr/.config/hypr/hyprland.lua), not a guarantee that optional commands are installed on another machine.

| Shortcut | Action |
|---|---|
| Super (release) | Open Fox Den Rofi launcher |
| Super + Alt + S | Open Quick Controls |
| Super + S | Toggle `magic` special workspace (scratchpad) |
| Super + Alt + Shift + S | Move active window to `special:magic` |
| Super + Q | Open Kitty terminal |
| Super + E | Open Dolphin file manager |
| Super + R | Launch Hyprlauncher |
| Super + C | Close active window |
| Super + V | Toggle floating window |
| Super + M | Run Hyprshutdown if available, otherwise Hyprland exit dispatch |
| Super + P | Toggle pseudotile |
| Super + J | Toggle Dwindle split |
| Super + 1–0 | Switch to workspaces 1–10 (`0` means 10) |
| Super + Shift + 1–0 | Move active window to workspaces 1–10 |
| Super + Arrow | Change focused window |
| Super + mouse wheel | Step through workspaces |
| Super + left/right mouse drag | Move/resize window |
| Super + Shift + S | Screenshot selected region to clipboard (`hyprshot`) |
| Print | Screenshot selected monitor to clipboard (`hyprshot`) |
| Super + Print | Screenshot selected window to clipboard (`hyprshot`) |
| Super + Shift + A | Capture and annotate a selected region with `grim`, `slurp`, and `satty` |
| Super + Shift + R | Start/stop region recording (`wf-recorder`, no audio by default) |

Three-finger horizontal gestures switch workspaces. Hardware multimedia keys control volume, brightness and playback when the necessary utilities are available. The `Super + S` special-workspace binding **does not** conflict with the `Super + Alt + S` Quick Controls binding.

## Development Workflow

Development takes place on `dev`, with reviewed changes proposed for `main`.

```text
Feature Development
        |
        v
      dev
        |
        v
  GitHub Actions
        |
   Validation
        |
      Tests
        |
    Packaging
        |
        v
  Pull Request
        |
        v
      main
```

### Continuous Integration

GitHub Actions runs on pushes and pull requests targeting `dev` and `main`.

The pipeline has three stages:

**1. Validation**

- JSON, JSONC, and TOML parsing
- Python, Bash, and Lua syntax checks
- ShellCheck error-level analysis

**2. Tests**

- Network sparkline and ReGreet theme regression tests (`tests/test_network_sparkline.py`, `tests/test_regreet_theme.py`)
- GNU Stow installation, restow, and removal checks
- Verification that deployed links resolve to the correct source files

**3. Packaging**

- Archive the seven home-dotfile packages **plus `greetd/` and `README.md`** (not the separately managed `systemd/` unit)
- Preserve hidden files and executable permissions
- Generate a SHA-256 checksum
- Upload the archive as a GitHub Actions artifact

Artifacts are retained for 14 days.

CI does not deploy changes to the local machine or automatically publish releases.

### Run Checks Locally

Install Python 3.11+, `json5` for Python (CI pins `json5==0.12.1`), ShellCheck, Lua 5.4, and GNU Stow. The commands below validate repository sources without touching desktop session settings.

```bash
python ci/validate.py

python -m unittest discover -s tests -v

python ci/stow_smoke.py
```

Additional syntax checks:

```bash
bash -n bash/.bashrc
bash -n bash/.bash_profile

shellcheck --shell=bash --severity=error bash/.bashrc bash/.bash_profile

while IFS= read -r -d '' file; do
  bash -n "$file"
  shellcheck --severity=error "$file"
done < <(git ls-files -z '*.sh')

while IFS= read -r -d '' file; do
  luac -p "$file"
done < <(git ls-files -z '*.lua')
```

These checks do not replace testing within a running Arch Linux and Hyprland session.

## Roadmap

Potential future improvements:

- [ ] Add automated drift checks for the documented keyboard shortcuts
- [ ] Remove hardcoded user-specific paths
- [ ] Document all runtime dependencies
- [ ] Add desktop screenshots
- [ ] Improve installation and restoration instructions
- [ ] Expand automated tests
- [ ] Add runtime verification for desktop components
- [ ] Continue refining the Fox Den Midnight theme

## About

Fox Den is an ongoing personal Linux customization project.

The goal is to create a desktop environment that is visually consistent, efficient to operate, and practical for development and system administration.

Rather than relying on a preconfigured desktop, this project emphasizes learning, configuration ownership, modularity, and continuous improvement.

**Built and maintained by [ItsFoxxin](https://github.com/ItsFoxxin).**
