"""Parse tracked structured configs without executing desktop startup code."""
import ast
import json
from pathlib import Path
import subprocess
import tomllib

import json5

ROOT = Path(__file__).resolve().parents[1]


def main():
    names = subprocess.check_output(
        ["git", "ls-files", "-z"], cwd=ROOT
    ).decode().split("\0")
    checked = 0
    for name in filter(None, names):
        path = ROOT / name
        suffix = path.suffix
        if suffix not in {".json", ".jsonc", ".toml", ".py"}:
            continue
        text = path.read_text(encoding="utf-8")
        if suffix == ".json":
            json.loads(text)
        elif suffix == ".jsonc":
            json5.loads(text, allow_duplicate_keys=False)
        elif suffix == ".toml":
            tomllib.loads(text)
        else:
            ast.parse(text, filename=name)
        checked += 1
        print(f"OK {name}")
    if not checked:
        raise SystemExit("No supported files found")
    print(f"Validated {checked} files")


if __name__ == "__main__":
    main()
