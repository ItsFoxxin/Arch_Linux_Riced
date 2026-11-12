"""Starship 1.27.0 regression: TOML decoding and runtime stash-format parsing."""

from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "starship/.config/starship.toml"
GOOD_ASSIGNMENT = r"stashed = '[\$${count}](bold fg:mint)'"
BAD_ASSIGNMENT = r'stashed = "[\u0024${count}](bold fg:mint)"'
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


class StarshipConfigTests(unittest.TestCase):
    def test_stash_symbol_is_escaped_after_toml_decoding(self):
        source = CONFIG.read_text(encoding="utf-8")
        self.assertEqual(source.count(GOOD_ASSIGNMENT), 1)
        config = tomllib.loads(source)
        self.assertEqual(config["git_status"]["stashed"], r"[\$${count}](bold fg:mint)")

    def test_original_toml_escape_lost_the_starship_escape(self):
        config = tomllib.loads(BAD_ASSIGNMENT)
        self.assertEqual(config["stashed"], r"[$${count}](bold fg:mint)")


class StarshipRuntimeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.binary = shutil.which("starship")
        if cls.binary is None:
            raise unittest.SkipTest("Starship unavailable; CI installs pinned 1.27.0")
        version = subprocess.run(
            [cls.binary, "--version"], capture_output=True, text=True, check=True
        ).stdout.strip()
        if "1.27.0" not in version:
            raise unittest.SkipTest(f"Runtime cases require Starship 1.27.0; found {version}")
        cls.temp = tempfile.TemporaryDirectory(prefix="foxden-starship-")
        cls.directory = Path(cls.temp.name)
        cls.clean_repo = cls._init_repo("clean")
        cls.stashed_repo = cls._init_repo("stashed")
        (cls.stashed_repo / "tracked.txt").write_text("modified\n", encoding="utf-8")
        cls._git(cls.stashed_repo, "stash", "push", "--quiet", "-m", "test-stash")
        assert len(cls._git(cls.stashed_repo, "stash", "list").stdout.splitlines()) == 1

        source = CONFIG.read_text(encoding="utf-8")
        assert source.count(GOOD_ASSIGNMENT) == 1
        cls.bad_config = cls.directory / "old-starship.toml"
        cls.bad_config.write_text(
            source.replace(GOOD_ASSIGNMENT, BAD_ASSIGNMENT), encoding="utf-8"
        )

    @classmethod
    def tearDownClass(cls):
        if hasattr(cls, "temp"):
            cls.temp.cleanup()

    @classmethod
    def _git(cls, directory, *args):
        return subprocess.run(
            ["git", *args], cwd=directory, capture_output=True, text=True,
            check=True, timeout=15,
        )

    @classmethod
    def _init_repo(cls, name):
        directory = cls.directory / name
        directory.mkdir()
        cls._git(directory, "init", "-q", "-b", "main")
        (directory / "tracked.txt").write_text("initial\n", encoding="utf-8")
        cls._git(directory, "add", "tracked.txt")
        cls._git(
            directory, "-c", "user.name=CI Fixture",
            "-c", "user.email=ci-fixture@example.invalid",
            "commit", "-qm", "initial",
        )
        return directory

    @classmethod
    def _render(cls, config, repo, *args):
        env = os.environ.copy()
        env.update({
            "STARSHIP_CONFIG": str(config),
            "STARSHIP_LOG": "warn",
            "STARSHIP_CACHE": str(cls.directory / "cache"),
            "NO_COLOR": "1",
            "TERM": "xterm",
        })
        return subprocess.run(
            [cls.binary, *args, "--path", str(repo)],
            cwd=repo, env=env, capture_output=True, text=True, timeout=30,
        )

    def test_original_format_reproduces_parser_warning_with_stash(self):
        rendered = self._render(
            self.bad_config, self.stashed_repo, "module", "git_status"
        )
        self.assertEqual(rendered.returncode, 0, rendered.stderr)
        self.assertIn("Error parsing format string", rendered.stderr)
        self.assertIn("git_status.stashed", rendered.stderr)
        self.assertNotIn("$1", ANSI.sub("", rendered.stdout))

    def test_corrected_format_shows_literal_dollar_and_stash_count(self):
        rendered = self._render(
            CONFIG, self.stashed_repo, "module", "git_status"
        )
        self.assertEqual(rendered.returncode, 0, rendered.stderr)
        self.assertNotIn("Error parsing format string", rendered.stderr)
        self.assertIn("$1", ANSI.sub("", rendered.stdout))

    def test_repository_without_stash_has_no_stash_indicator_or_warning(self):
        rendered = self._render(
            CONFIG, self.clean_repo, "module", "git_status"
        )
        self.assertEqual(rendered.returncode, 0, rendered.stderr)
        self.assertNotIn("Error parsing format string", rendered.stderr)
        self.assertNotIn("$1", ANSI.sub("", rendered.stdout))

    def test_full_prompt_retains_frame_and_stash_indicator(self):
        rendered = self._render(
            CONFIG, self.stashed_repo, "prompt", "--terminal-width", "120"
        )
        self.assertEqual(rendered.returncode, 0, rendered.stderr)
        self.assertNotIn("Error parsing format string", rendered.stderr)
        output = ANSI.sub("", rendered.stdout)
        self.assertIn("╭─", output)
        self.assertIn("╰─", output)
        self.assertIn("$1", output)


if __name__ == "__main__":
    unittest.main()
