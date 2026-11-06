# Fox Den Midnight animated lock screen — test preview

This optional preview uses the local five-second Fox Den server-room animation as a
live Hyprlock backdrop, with a central Midnight glass panel, bilingual lock hints,
24-hour Pennsylvania and Seoul clocks, and PAM password authentication.

It does **not** replace `hyprlock.conf`, change a lock keybinding, or launch at login.

## Prerequisites

- Hyprland with Lua config, Hyprlock, mpvpaper, jq, and both fonts from the existing
  static lock theme (`Monaspace Radon NF` and `LXGW WenKai Mono KR`).
- One active display, named `eDP-1`; use a numbered workspace.
- The video at `~/Pictures/Wallpapers/FoxDen/foxden_hyprlock_animated.mp4`.
- Stow the `hypr` package (or copy the two new files into matching `~/.config/hypr`
  locations) before testing. Example from the repository root:

  ```bash
  stow --simulate --verbose -t "$HOME" hypr
  stow -t "$HOME" hypr
  ```

## Run

```bash
bash "$HOME/.config/hypr/scripts/foxden-lock-animated-test.sh"
```

The launcher checks prerequisites, requires session-lock xray to start **off**,
switches to a temporary empty workspace, plays the video on the overlay layer,
enables xray just for the preview, and invokes Hyprlock. After successful unlock or
an ordinary script exit, its trap disables xray **before** removing the player and
returns to the original workspace.

The attached source video is 2944×1248 (24 fps, ~5.17 seconds); `--panscan=1.0`
fills a 16:9 screen without letterboxing, cropping some side content. The animation
is not committed because it belongs in the user's local Wallpapers directory.

## Security and recovery

- `session_lock_xray` displays live content behind the lock. This launcher refuses
  multi-monitor previews and uses an empty workspace; do not manually launch the
  animated `.conf` on top of an occupied workspace.
- A force kill, power loss, compositor crash, or detached process can prevent the
  shell cleanup trap from running. After an unusual exit, explicitly turn xray off
  before resuming normal desktop use:

  ```bash
  hyprctl eval 'hl.config({ misc = { session_lock_xray = false } })'
  hyprctl getoption misc:session_lock_xray
  ```

- Never terminate `hyprlock` while locked. Authenticate normally. If a lock fails,
  use a trusted recovery session; do not enable unsafe lock restoration globally.
- The regular static `hyprlock.conf` remains the fallback. The video is visual only;
  it does not handle authentication.

## After testing

Check: full-bleed frame, smooth looping, fox visible on the right, readable clocks,
working password and failure indicators, return to original workspace, player
stopped, and `session_lock_xray` = `false` after unlocking. Do not wire this into
the production lock action until the safety and rendering checks pass on-device.
