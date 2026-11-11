# Fox Den Midnight animated Hyprlock — isolated manual preview

> **PREVIEW ONLY:** The animated lock screen is **not** the production lock, a login screen, an autostart service, or a replacement for `hyprlock.conf`. It uses the user's local lock animation, a transparent Hyprlock background and Hyprland `session_lock_xray` to render an overlay. Review the security and recovery section **before** attempting it.

## Current source location — no obsolete feature branch required

The preview files have already been merged into `dev`:

- `hypr/.config/hypr/hyprlock-animated.conf`
- `hypr/.config/hypr/scripts/foxden-lock-animated-test.sh`

**Do not fetch or switch to `feat/foxden-animated-hyprlock`** as previous revisions of this guide advised. The standalone preview can run **directly from an existing reviewed `dev` checkout**, without installing either file into `~/.config`, changing lock bindings or replacing the running desktop's Stow links:

```bash
# Run from the repository root containing the two tracked preview files.
bash hypr/.config/hypr/scripts/foxden-lock-animated-test.sh
```

If you specifically want a separate worktree, fetch `dev` and create it **once**, from a clean primary repository:

```bash
git fetch origin dev
git worktree add --detach ../Arch_Linux_Riced_locktest origin/dev
bash ../Arch_Linux_Riced_locktest/hypr/.config/hypr/scripts/foxden-lock-animated-test.sh
```

The `worktree add` command fails if that directory is already a registered worktree. **Do not rerun it over an existing directory.** To reuse one, inspect `git worktree list` and `git -C ../Arch_Linux_Riced_locktest status --short --branch`; only if its changes are safely saved, update that worktree to the reviewed `origin/dev` revision. Never discard uncommitted desktop modifications just to preview a lock. You do **not** need a worktree if your main checkout is already at the desired reviewed revision.

The preview script resolves the `.conf` relative to its own location, so it works from a checkout or an installed Stow package. Override the local video/config with `FOX_DEN_LOCK_VIDEO` and `FOX_DEN_LOCK_CONFIG` **only after checking each file**.

## Intended layout and prerequisites

The lock panel is approximately **560 × 610** pixels near the **left bench** on the intended **1920 × 1080** laptop display, keeping the fox visible on the right. It contains a mint rule, a small bilingual status line, Pennsylvania and Seoul 24-hour clocks, and a password field handled by PAM. The static layout uses fixed pixel offsets; other screen dimensions and scales require human visual review.

The tracked launcher enforces these prerequisites **before** it opens a lock:

- Running Hyprland session with `hyprctl`, `hyprlock`, `mpvpaper` and `jq` available.
- Exactly **one active monitor**, named `eDP-1`.
- Current workspace with a positive integer ID; no special workspace.
- `hyprctl getoption misc:session_lock_xray` reporting **`bool: false`** at start.
- Readable `~/Pictures/Wallpapers/FoxDen/foxden_hyprlock_animated.mp4` (local-only, not in Git).
- Readable animated config and the two theme fonts `Monaspace Radon NF` and `LXGW WenKai Mono KR` for matching appearance.

The full source-video resolution and frame rate are **not verified from repository contents**, because the MP4 is intentionally untracked. The command uses `mpvpaper` with `--panscan=1.0` and infinite looping to fill the preview layer; a wide source may be cropped. The preview does **not** alter or re-encode the video.

## How the launcher works

The script first verifies the environment and records the current workspace ID. It selects a temporary named, empty workspace, starts `mpvpaper --layer overlay` on `eDP-1`, verifies the player remains alive, enables `misc:session_lock_xray` temporarily, and launches:

```bash
hyprlock --config "<path resolved beside the preview launcher>"
```

This command is explanatory; prefer executing the guarded **launcher** above rather than running `hyprlock-animated.conf` directly. The config sets `disable_screencopy = true` and a transparent background, but **xray can still display live underlying workspace content**. That is why the launcher insists on a temporary empty workspace and single monitor. Do not use xray behind a lock on a normal populated desktop.

After an ordinary unlock or normal script termination, the `EXIT` trap attempts to (1) disable xray **first**, (2) stop and reap the video process, and (3) return to the original workspace. This cleanup is not guaranteed if the compositor dies, the machine loses power or the shell is killed with an untrappable signal.

## Security and exceptional recovery

- The password is authenticated by the normal Hyprlock PAM module; the MP4 is **visual-only**. Do not change PAM or bypass authentication to debug art.
- Do **not** bind the preview to the normal Lock command, use it on multiple displays, or start `hyprlock-animated.conf` alone. The normal launcher in `waybar/.config/waybar/scripts/foxden-launcher.sh` calls static `hyprlock`.
- If the test exits abnormally, once you are safely back in a working unlocked Hyprland session, explicitly turn off xray **before** interacting with sensitive windows:

  ```bash
  hyprctl eval 'hl.config({ misc = { session_lock_xray = false } })'
  hyprctl getoption misc:session_lock_xray
  ```

- Inspect `mpvpaper` processes only after a normal unlock; if the preview's video player survived unexpectedly, stop the specific preview process. Never kill `hyprlock` while locked to force access. Use a trusted TTY/recovery session if compositor or authentication fails.
- For ordinary locking, retain `hypr/.config/hypr/hyprlock.conf`, which uses the two tracked static PNGs and **does not require xray or the local MP4**. Fix its host-specific absolute asset paths when moving between users.
- If the configuration looks wrong on a different resolution, stop after a safe unlock, inspect the fixed offsets and local clip outside a lock. Do not relax the single-display or xray precondition as a cosmetic workaround.

## Owner-only acceptance checks

After the owner intentionally runs the test on a recoverable device, record:

- [ ] The correct local lock video plays full-bleed and loops acceptably; the fox remains visible to the right of the bench-side panel.
- [ ] Both clocks, Korean labels, focus and password check/failure feedback remain readable.
- [ ] Normal PAM authentication unlocks without a forced kill.
- [ ] The original numbered workspace is restored.
- [ ] The preview player is gone and `misc:session_lock_xray` reports **`bool: false`**.
- [ ] The normal static lock path still works; no production binding or greeter files changed.

These are **not** CI checks and have not been executed for Issue #6. See [full manual runtime checklist](VALIDATION_RUNTIME_CHECKLIST.md), [desktop configuration](DESKTOP_CONFIGURATION.md), and [greeter/media recovery](GREETER_WALLPAPER_RECOVERY.md).
