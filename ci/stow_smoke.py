"""Test the actual Stow layout in an isolated disposable target."""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ["bash", "hypr", "kitty", "spotify-player", "starship", "swaync", "waybar"]


def main():
    with tempfile.TemporaryDirectory(prefix="foxden-stow-") as temporary:
        target = Path(temporary)
        command = ["stow", "--dir", str(ROOT), "--target", str(target)]
        tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
        sources = [ROOT / name for name in tracked if name and name.split("/")[0] in PACKAGES]
        for operation in ("--stow", "--restow"):
            subprocess.run([*command, operation, *PACKAGES], check=True)
            for source in sources:
                relative = source.relative_to(ROOT)
                deployed = target.joinpath(*relative.parts[1:])
                if not deployed.is_file() or deployed.resolve() != source.resolve():
                    raise RuntimeError(f"Incorrect Stow mapping: {relative}")
        subprocess.run([*command, "--delete", *PACKAGES], check=True)
        if any(path.is_symlink() or path.is_file() for path in target.rglob("*")):
            raise RuntimeError("Unstow left files or links behind")
        print(f"Stow install/restow/remove passed for {len(sources)} files")


if __name__ == "__main__":
    main()
