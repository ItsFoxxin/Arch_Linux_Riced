# Validation: CI versus a real Arch/Hyprland session

> **Status:** this is a **manual test plan** and description of existing repository checks, not a report that the desktop has been tested or modified. No local Arch login, greeter, lock, workstation Stow or service activation was performed by Issue #6.

## Source-controlled checks

The existing `.github/workflows/ci.yml` runs on pushes and pull requests to `dev` and `main`, plus manual dispatch. The jobs form a chain:

| Job | What it tests | What it does **not** test |
| --- | --- | --- |
| **1 — Validate** | `ci/validate.py` parses tracked JSON, JSONC, TOML and Python. `bash -n` + ShellCheck cover Bash rc/profile and tracked `.sh` scripts. `luac5.4 -p` parses tracked Lua. | Runtime Hyprland `hl.*` compatibility, executable availability, `.rasi` rendering, GTK CSS, systemd behavior, fonts or PAM |
| **2 — Test** | `python3 -m unittest discover -s tests -v` (network helper and ReGreet configuration/theme assertions); `ci/stow_smoke.py` deploys/restows/deletes the seven packages into a **temporary home**, verifying links point to their sources | Collisions and permissions in the user's real `$HOME`, running services, graphics, audio, physical monitors, video decoders or actual authentication |
| **3 — Package** | Archives the tested source packages with `git archive`, generates/checks SHA-256 and uploads a 14-day artifact | A desktop installation or publication; its tracked archive inputs currently **exclude `docs/`** |

The CI runner is **Ubuntu 24.04**, not the intended Arch laptop. A green CI check is valuable for syntax and packaging but is **not a release-to-desktop approval**. Existing `tests/test_regreet_theme.py` does not spawn ReGreet; `tests/test_network_sparkline.py` mocks Linux text files and captures JSON output.

## Local static test commands (operator/dev environment)

From the repository root, after installing the validator dependencies in [prerequisites](INSTALLATION_DEPENDENCIES.md), these commands mirror the existing test entry points:

```bash
python3 ci/validate.py
python3 -m unittest discover -s tests -v
python3 ci/stow_smoke.py
```

The CI workflow additionally performs these syntax analyses:

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

On the Ubuntu runner, the last command is `luac5.4 -p`; `luac` is the usual local executable name if Lua 5.4 is installed and mapped to it. If `luac` is absent, do not treat that as a compositor error. Parsing Lua does not execute the `hl` APIs.

Read-only review and Stow preview:

```bash
git diff --check
git status --short --branch
stow --simulate --verbose -t "$HOME" \
  bash hypr kitty spotify-player starship swaync waybar
```

Do not deploy to your active home simply because a simulation succeeded. **Stow smoke tests use a disposable home**, whereas the simulated plan above examines your real target paths without applying them.

## Owner-only runtime verification checklist

Complete the following **on a recoverable, local Arch session**. Record the exact revision, Hyprland/Kitty/ReGreet versions, monitor outputs, whether each check passed, and relevant logs. Each checkbox below is **untested by this documentation PR**.

### Preflight and environment

- [ ] Preserve originals of `.bashrc`, `.bash_profile`, and impacted `~/.config` files; verify backups; confirm TTY login and identify a way to undo symlinks.
- [ ] Check the installed Hyprland version actually supports the Lua `hl.*` config; confirm `start-hyprland` if relying on TTY1 autostart.
- [ ] Confirm real monitor name(s), the `eDP-1` assumption, local-only wallpaper files, readable lock PNGs, fonts and Korean glyph fallback.
- [ ] Perform a real-home Stow **simulation** and review all conflicts before deploying; do not use `--adopt` to overwrite them.
- [ ] Verify Fcitx5 Hangul engine, keyboard switch and Wayland input behavior separately from the Waybar display indicator.

### Desktop and applications

- [ ] Start/return to Hyprland normally; check border focus, compositor animations, desktop wallpaper, Waybar, SwayNC and the effects of the autostart actions.
- [ ] Verify Super-release launcher, Super+Alt+S Quick Controls and Super+S special workspace separately.
- [ ] Confirm Waybar workspaces, both clocks, network/sparkline, CPU, RAM, battery, tray and Fcitx5 indicator. Do not expect configured-but-unmounted WirePlumber/backlight/power-profile modules to appear.
- [ ] Open Rofi Applications/Windows/Power & Sessions menus. Check that Quick Controls reports missing optional helpers gracefully, and that volume/Bluetooth/brightness/network controls work **only where supported**.
- [ ] Test Stay Awake enabling and disabling, verify the inhibitor doesn't persist unexpectedly and check its PID state after interruption.
- [ ] Verify screenshots and Satty annotation; if testing capture, check start/stop/finalization and privacy (the recorder intentionally omits audio).
- [ ] Open Kitty; check tabs, panes, cursor, trail, Hangul rendering, opacity and paste confirmation. Verify Bash/Starship prompts plus fallback in a recoverable shell.
- [ ] Verify SwayNC notifications and control center, DND/MPRIS behavior where applicable.
- [ ] Check workspace-2 Spotify Player automatic launch on an **empty newly created** workspace; verify external login/device availability without exposing or committing account data.
- [ ] Check the Proton Pass SSH agent unit **only if intentionally installed**; ensure `SSH_AUTH_SOCK` resolves to a working agent or restore the previous agent environment.

### Lock, greeter and recovery

- [ ] Validate the **static** Hyprlock first: correct PNGs, clock readability, keyboard focus, known-good password, failed-password message and normal unlock. Do not force-kill a locked authenticator.
- [ ] Before any animated preview, read [the preview guide](ANIMATED_HYPRLOCK_PREVIEW.md). Check single-monitor `eDP-1`, numbered workspace, `session_lock_xray=false`; then inspect video, panel/fox placement, unlock, workspace restoration, player cleanup and xray reset.
- [ ] Prepare greeter source only from the intended **login** video; verify processed video codec, smooth loop and matching still. Staging is a privileged system-media write, not a dry run.
- [ ] Preview `regreet --demo` with video **and** static fallback; check GTK styling, font/Hangul, clock, user/session selection and input controls.
- [ ] **If** the owner chooses a live greetd change: back up installed theme files, prove TTY login and restore path, confirm greetd launch flags, then verify a real login. Do not bypass or weaken PAM.
- [ ] Deliberately exercise and record at least one **safe** rollback rehearsal: inspect Stow `--delete --simulate`, verify backups, and document how to restore a failed shell/Waybar/Hyprland theme and ReGreet from TTY.

## Evidence expected before Coordinator sign-off

Provide check output/status for the PR's exact head SHA, enumerate changed files, confirm every change is under `docs/`, and identify what **was not executed**. Do not report visual checks as passing without actual owner-supplied screenshots or on-device testimony.

No current automated test covers the complete live Hyprland Lua lifecycle, `eDP-1` GPU behavior, a ReGreet video playback session, an actual password unlock, or the optional Proton Pass agent. These remain **manual owner-only tests** even when CI is green.

## Recovery links

- [Stow deployment and rollback](STOW_DEPLOYMENT_RECOVERY.md) — collisions, backups, unstow and shell recoverability.
- [Greeter, media and optional user service](GREETER_WALLPAPER_RECOVERY.md) — still fallback, TTY, `/etc/greetd` restoration and SSH agent.
- [Animated Hyprlock preview](ANIMATED_HYPRLOCK_PREVIEW.md) — session-lock xray hazards, cleanup and recovery.

For test results, distinguish **static checks**, **CI GitHub Actions status**, and **manual live session verification**; one is not a substitute for another.
