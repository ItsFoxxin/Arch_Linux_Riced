# Fox Den | Arch Linux Riced

**A personalized Arch Linux desktop environment built around Hyprland, a cohesive neon aesthetic, and a modular, developer-focused workflow.**

Fox Den is my custom Linux desktop environment, designed for system administration, development, cybersecurity, and everyday productivity.

Built around Arch Linux and Hyprland, the project combines a custom Waybar, themed terminal environment, application launchers, system controls, bilingual English/Korean elements, and reusable configuration packages.

The visual identity, **Fox Den Seoul**, uses orange, cyan, and pink accents against dark backgrounds.

> **Project status:** Active development. The `dev` branch contains ongoing changes, while `main` is intended for reviewed updates.

## Features

### Desktop and Window Management

- Arch Linux with the Hyprland Wayland compositor
- Lua-based Hyprland configuration
- Custom window borders, blur, shadows, and animations
- Keyboard-driven tiling and workspace navigation
- Touchpad gestures and multimedia keybindings
- Workspace-specific behavior, including Spotify Player on workspace 2
- Hyprpaper wallpaper configuration

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

A themed launcher accessible through the Super key.

**Quick Controls**

Accessible with `Super + S`, providing controls for:

- Audio volume and mute
- Display brightness
- Bluetooth power and management
- Power profile information
- Stay Awake mode using `systemd-inhibit`

### Fox Den Lock Screen

A customized Hyprlock configuration featuring:

- Fox Den artwork and branding
- Dual clocks for the US Eastern time zone and Seoul
- English and Korean interface elements
- Animated password entry
- Custom colors, typography, and visual effects
- PAM-based authentication

The lock screen includes the Korean phrase **시작이 반이다** — "Well begun is half done."

### Kitty Terminal

A customized Kitty terminal environment featuring:

- Fox Den Seoul color palette
- Monaspace Radon Nerd Font
- Korean Hangul font fallback
- Orange window borders and themed tabs
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
| Wallpaper | Hyprpaper |
| Terminal | Kitty |
| Shell | Bash |
| Prompt | Starship |
| Application Menus | Rofi |
| Notifications | SwayNC |
| Music | Spotify Player |
| Input Method | Fcitx5 |
| Dotfile Management | GNU Stow |
| Automation | GitHub Actions |
| Testing | Python, ShellCheck, Lua |

## Repository Structure

```text
Arch_Linux_Riced/
├── .github/
│   ├── workflows/
│   │   └── ci.yml
│   └── dependabot.yml
├── bash/
├── hypr/
│   └── .config/hypr/
├── kitty/
│   └── .config/kitty/
├── spotify-player/
│   └── .config/spotify-player/
├── starship/
│   └── .config/
├── swaync/
│   └── .config/swaync/
├── waybar/
│   └── .config/waybar/
│       └── scripts/
├── ci/
│   ├── validate.py
│   └── stow_smoke.py
├── tests/
│   └── test_network_sparkline.py
└── README.md
```

The seven dotfile packages are organized for deployment with GNU Stow.

## Installation

**Warning:** These configurations are tailored to my personal Arch Linux environment. They are not a complete Arch installation script or a universal desktop installer.

Some settings depend on installed applications, fonts, hardware, and local paths.

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

Review existing configuration files and back them up before continuing.

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
- Local file paths, particularly Hyprlock assets
- Fcitx5 and Korean font support

The Hyprlock configuration currently contains absolute paths under `/home/foxxin`, which must be adjusted for other usernames.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Super | Fox Den launcher |
| Super + S | Quick Controls |
| Super + Q | Kitty terminal |
| Super + E | Dolphin file manager |
| Super + R | Hyprlauncher |
| Super + C | Close active window |
| Super + V | Toggle floating window |
| Super + 1–0 | Switch workspaces |
| Super + Shift + 1–0 | Move window to workspace |
| Super + Arrow | Change window focus |

**Configuration note:** The current Hyprland Lua file also assigns `Super + S` to a special workspace. This duplicate binding should be resolved.

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

- Network sparkline regression tests
- GNU Stow installation, restow, and removal checks
- Verification that deployed links resolve to the correct source files

**3. Packaging**

- Archive the tested dotfile packages
- Preserve hidden files and executable permissions
- Generate a SHA-256 checksum
- Upload the archive as a GitHub Actions artifact

Artifacts are retained for 14 days.

CI does not deploy changes to the local machine or automatically publish releases.

### Run Checks Locally

Install Python 3.11+, python-json5, ShellCheck, Lua, and GNU Stow.

```bash
python ci/validate.py

python -m unittest discover -s tests -v

python ci/stow_smoke.py
```

Additional syntax checks:

```bash
bash -n bash/.bashrc
bash -n bash/.bash_profile

find waybar -name '*.sh' \
  -exec bash -n {} \;

find waybar -name '*.sh' \
  -exec shellcheck --severity=error {} \;

find hypr -name '*.lua' \
  -exec luac -p {} \;
```

These checks do not replace testing within a running Arch Linux and Hyprland session.

## Roadmap

Potential future improvements:

- [ ] Resolve duplicate keyboard bindings
- [ ] Remove hardcoded user-specific paths
- [ ] Document all runtime dependencies
- [ ] Add desktop screenshots
- [ ] Improve installation and restoration instructions
- [ ] Expand automated tests
- [ ] Add runtime verification for desktop components
- [ ] Continue refining the Fox Den Seoul theme

## About

Fox Den is an ongoing personal Linux customization project.

The goal is to create a desktop environment that is visually consistent, efficient to operate, and practical for development and system administration.

Rather than relying on a preconfigured desktop, this project emphasizes learning, configuration ownership, modularity, and continuous improvement.

**Built and maintained by [ItsFoxxin](https://github.com/ItsFoxxin).**
