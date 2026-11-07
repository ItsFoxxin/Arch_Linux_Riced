# Fox Den Midnight animated lock screen — test preview

This optional preview uses the local five-second Fox Den server-room animation as a
live Hyprlock backdrop, with a compact LEFT-aligned Midnight glass panel by the bench, bilingual lock hints,
24-hour Pennsylvania and Seoul clocks, and PAM password authentication.

It does **not** replace `hyprlock.conf`, change a lock keybinding, or launch at login.

### Bench-side revision

On the intended 1920×1080 display, the panel is centered near x=350 rather than
x=960 (the original center), keeping its edges around x=70–630. This leaves
most of the right half free for the animated fox. The panel is 560×610, with a
slightly translucent Midnight fill, mint accent rule, quieter typography, and
preserved Pennsylvania/Seoul 24-hour clocks. No video crop or placement changes
are required to test this layout. The panel uses fixed pixel positioning and
will need adjustments for a different display resolution or scale.

If an older isolated worktree already exists, refresh it instead of running
`git worktree add` again:

```bash
cd ~/Projects/Arch_Linux_Riced
git fetch origin feat/foxden-animated-hyprlock
git -C ../Arch_Linux_Riced_locktest switch --detach origin/feat/foxden-animated-hyprlock
```

The switch will refuse to overwrite incompatible local changes in the test
worktree. It does not change your main desktop repository or its branch.

## Prerequisites

- Hyprland with Lua config, Hyprlock, mpvpaper, jq, and both fonts from the existing
  static lock theme (`Monaspace Radon NF` and `LXGW WenKai Mono KR`).
- One active display, named `eDP-1`; use a numbered workspace.
- The video at `~/Pictures/Wallpapers/FoxDen/foxden_hyprlock_animated.mp4`.
- No installation is required for the first test. Fetch the feature branch into
  an isolated worktree, preserving your current branch and its local edits:

  ```bash
  cd ~/Projects/Arch_Linux_Riced
  git fetch origin feat/foxden-animated-hyprlock
  git worktree add --detach ../Arch_Linux_Riced_locktest origin/feat/foxden-animated-hyprlock
  ```

## Run

```bash
bash "$HOME/Projects/Arch_Linux_Riced_locktest/hypr/.config/hypr/scripts/foxden-lock-animated-test.sh"
```

The launcher resolves `hyprlock-animated.conf` beside its own script, including
when run from an installed Stow package. You may override `FOX_DEN_LOCK_VIDEO`
or `FOX_DEN_LOCK_CONFIG` to test alternative local file paths.

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
