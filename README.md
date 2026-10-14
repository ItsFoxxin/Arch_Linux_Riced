Personal Riced Arch Linux Build!

## Included

- Hyprland
- Waybar
- Kitty

## Development and CI

Develop on `dev`, then propose reviewed changes to `main`.
The GitHub Actions workflow runs on pushes and pull requests to either branch.
Its three layers run in order; a failed layer blocks later layers:

1. **Validation:** parse JSON, JSONC and TOML; check Python, Bash and Lua
   syntax; run ShellCheck at error severity. Desktop startup code is never sourced.
2. **Tests:** run network sparkline regression tests and install, restow, and
   remove all seven GNU Stow packages in a temporary target. Each deployed file
   must resolve to its expected source.
3. **Packaging:** archive the tested Git commit's dotfile packages, preserving
   hidden files and executable bits, and include a SHA-256 checksum. Download
   the artifact from the successful Actions run; artifacts expire after 14 days.

CI has read-only repository permissions and does not deploy to your computer
or publish releases. Pull requests are validated and packaged too.
Action revisions are pinned; Dependabot is configured to propose updates to
`dev` (GitHub activates this configuration once it is on the default branch).
The manual Actions trigger also becomes available once the workflow is on the
default branch; pushes to `dev` work immediately.

### Run checks locally

On Arch, install `python`, `python-json5`, `shellcheck`, `lua`, and `stow`.
Use Python 3.11 or newer. From the repository root:

```bash
python ci/validate.py
python -m unittest discover -s tests -v
python ci/stow_smoke.py
bash -n bash/.bashrc
bash -n bash/.bash_profile
find waybar -name '*.sh' -exec bash -n {} \;
find waybar -name '*.sh' -exec shellcheck --severity=error {} \;
find hypr -name '*.lua' -exec luac -p {} \;
```

These checks validate syntax, selected helper behavior, and Stow layout.
They do not validate live Hyprland APIs, GTK CSS rendering, Rofi themes,
hardware-specific settings, installed applications, or a running Wayland
session. CI uses Ubuntu tools; verify desktop behavior on Arch before merging.
