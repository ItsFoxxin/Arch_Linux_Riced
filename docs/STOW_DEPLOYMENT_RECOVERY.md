# GNU Stow: preflight, deployment, conflict handling and rollback

> **Safety:** this is an operator runbook, **not** a deployment executed by this PR. Back up existing dotfiles and ensure a working TTY/login path before changing shell, Hyprland or greeter settings. Run all Stow commands from the **repository root**. Do not run `stow --adopt` for unknown conflicts.

## Package layout

| Stow source package | Target paths under `$HOME` |
| --- | --- |
| `bash/` | `.bashrc`, `.bash_profile` |
| `hypr/` | `.config/hypr/hyprland.lua`, `foxden/autostart.lua`, `hyprlock.conf`, `hyprlock-animated.conf`, `hyprpaper.conf`, scripts and tracked lock PNG assets |
| `kitty/` | `.config/kitty/kitty.conf` |
| `spotify-player/` | `.config/spotify-player/app.toml`, `theme.toml` |
| `starship/` | `.config/starship.toml` |
| `swaync/` | `.config/swaync/config.json`, `style.css` |
| `waybar/` | `.config/waybar/config.jsonc`, `style.css`, `.rasi` themes and scripts |

These seven names exactly match `ci/stow_smoke.py` and the documented Stow command in `README.md`. `greetd/` is managed under `/etc/greetd` plus `/usr/share/backgrounds/foxden` **separately**. The `systemd/` tree contains one optional user service and is **not** in the standard Stow set.

## 1. Prepare a recoverable starting point

- Save unsaved work. Keep a working TTY (e.g., Ctrl+Alt+F2/F3) and the ability to log in independently of Hyprland. Changing `.bash_profile` can affect the next TTY1 login.
- Confirm your actual login shell, monitor output names, fonts, compositor compatibility and local wallpaper paths; see [prerequisites](INSTALLATION_DEPENDENCIES.md).
- Do not assume a fresh checkout is deployable on another username. `hyprlock.conf` and `hyprpaper.conf` contain absolute workstation-specific paths; the autostart script requires local wallpaper media.
- Record which files are currently real files and which are symlinks. Preserve existing `.bashrc` and `.bash_profile` especially carefully; any existing SSH agent or startup configuration may be important.

Example **read-only** review commands:

```bash
git status --short --branch
git diff --check
ls -ld "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.config/hypr" "$HOME/.config/waybar" 2>/dev/null
```

Make a **separate, outside-repository** backup directory (the location is up to the operator), and copy any files/config directories that might be replaced there. To back up a specific existing file while preserving metadata, for example:

```bash
backup_dir="$HOME/foxden-dotfile-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p -- "$backup_dir"
if [[ -e "$HOME/.bashrc" || -L "$HOME/.bashrc" ]]; then
  cp -a -- "$HOME/.bashrc" "$backup_dir/.bashrc"
fi
```

Repeat **deliberately** for each pre-existing target; include nested configurations and `.bash_profile` as applicable. Verify the backups are readable. A copied symlink remains a symlink with `cp -a`; if its target may disappear, also preserve the target's contents. For an entire directory, choose a backup structure that keeps its path and files recognizable.

## 2. Simulate Stow, then resolve each conflict

From a checkout of `dev` at the reviewed commit:

```bash
stow --simulate --verbose -t "$HOME" \
  bash hypr kitty spotify-player starship swaync waybar
```

Simulation reports proposed linking and refuses collisions. **Do not deploy until every unexpected conflict has been individually classified.** In particular:

- A pre-existing regular file is **not** automatically safe to replace. Compare it against the repository version and preserve it first.
- A symlink may point to another dotfile manager or different checkout. Identify its target; do not delete a link you cannot account for.
- Stow may fold directory trees into symlinks as an optimization. Review directory-level effects, especially when `~/.config` already contains other applications.
- If a conflict is caused by an old Fox Den Stow checkout, inspect its current Stow-managed state and plan an orderly unstow/migration. Avoid running two Stow sources against the same targets.
- **Do not** use `--adopt` as a shortcut: it pulls existing target content into the repository source and can overwrite or expose private workstation state in later commits.

One possible **owner-controlled** way to remove a conflicting file after confirming a backup is to move that individual file to your backup directory. Do not recursively move all of `~/.config` or blindly overwrite a working environment. Repeat the simulation afterwards.

## 3. Deploy only after passing preflight (manual, optional)

The current repository's normal installation command is:

```bash
stow -t "$HOME" \
  bash hypr kitty spotify-player starship swaync waybar
```

This creates links; it does not install the binaries, initialize Fcitx5, supply local media, activate a user service or configure greetd. Check a small sample of installed links and their resolved paths:

```bash
ls -l "$HOME/.bashrc" "$HOME/.config/hypr/hyprland.lua" "$HOME/.config/waybar/config.jsonc"
readlink -f "$HOME/.config/hypr/hyprland.lua"
```

Do not restart a desktop or log out until any config-specific hazards are addressed. Re-running Stow as `--restow` can be useful **after** a controlled update, but it should not be used to sweep unknown conflicts away.

## 4. Undo the managed links

From **the same checkout and source directory** used for Stow:

```bash
stow --simulate --verbose --delete -t "$HOME" \
  bash hypr kitty spotify-player starship swaync waybar
```

Review the unlink plan. Only when correct, run:

```bash
stow --delete -t "$HOME" \
  bash hypr kitty spotify-player starship swaync waybar
```

Inspect the affected targets. Restore backed-up files **only at paths you own and have verified are no longer Stow-managed**. A backup of a previous symlink is not necessarily a backup of its original file content. Restoring `.bash_profile` and `.bashrc` may change behavior at your next login; keep a reliable TTY until tested.

If a Stow command fails midway, stop and inspect the exact error and link state instead of deleting directories or repeating the command with `--force`/ `--adopt`. Manual recovery should be path-specific.

## 5. Component-specific fallbacks

| Failure after deployment | Safest initial approach |
| --- | --- |
| Shell prompt malformed | Start a clean shell without reading the managed rc file, then inspect the `bash/` links and recover your backed-up rc file; Starship is optional and `.bashrc` has a fallback PS1 if it cannot find Starship. |
| TTY1 unexpectedly starts Hyprland | Use another working TTY; review or restore `.bash_profile` before using TTY1 again. |
| Hyprland starts but desktop modules fail | Keep the session active; inspect the target binaries, `hyprland.lua`, autostart, Waybar/Rofi paths, and local media. Do not assume CI validated your compositor version. |
| Missing or unreadable lock background | Review both absolute PNG paths in `hyprlock.conf`; use the normal static config, not the animated preview, as the intended default. |
| ReGreet failure | **Not a Stow rollback.** Use a TTY and restore previous `/etc/greetd` files as in [greeter recovery](GREETER_WALLPAPER_RECOVERY.md). |
| Proton Pass agent not running | Do not enable the user unit automatically. Managed Bash verifies socket reachability and preserves another live inherited agent; review the [agent acceptance and rollback guide](PROTON_PASS_SSH_AGENT.md) for manual recovery. |

## Source and scope

The target paths above come from the tracked tree, and `ci/stow_smoke.py` exercises `--stow`, `--restow`, and `--delete` against a **temporary home**. That test establishes neither a conflict-free real `$HOME` nor working GUI services, shell startup or authentication. See the [validation and manual checklist](VALIDATION_RUNTIME_CHECKLIST.md).
