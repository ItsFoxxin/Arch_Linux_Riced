"""Regression checks for the Fox Den Midnight login theme."""

from pathlib import Path
import re
import subprocess
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1] / "greetd"
MEDIA_DIR = Path("/usr/share/backgrounds/foxden")


class ReGreetThemeTests(unittest.TestCase):
    def test_animated_and_static_configs_are_valid_and_equivalent(self):
        parsed = []
        for name in ("regreet.toml", "regreet-static.toml"):
            with self.subTest(name=name):
                with (ROOT / name).open("rb") as handle:
                    settings = tomllib.load(handle)
                self.assertFalse(settings["skip_selection"])
                self.assertEqual(settings["background"]["fit"], "Cover")
                self.assertEqual(settings["widget"]["clock"]["timezone"], "America/New_York")
                self.assertEqual(settings["appearance"]["greeting_msg"], "어서 와, Fox! 🦊")
                self.assertEqual(Path(settings["background"]["path"]).parent, MEDIA_DIR)
                parsed.append(settings)

        self.assertEqual(parsed[0]["GTK"], parsed[1]["GTK"])
        self.assertEqual(parsed[0]["widget"], parsed[1]["widget"])
        self.assertEqual(parsed[0]["background"]["path"], str(MEDIA_DIR / "foxden-greeter.mp4"))
        self.assertEqual(parsed[1]["background"]["path"], str(MEDIA_DIR / "foxden-greeter.jpg"))

    def test_local_media_workflow_is_documented_and_valid(self):
        processor = ROOT / "process-login-video.sh"
        staging = ROOT / "stage-assets.sh"
        for script in (processor, staging):
            with self.subTest(script=script.name):
                self.assertTrue(script.is_file())
                subprocess.run(["bash", "-n", str(script)], check=True)
        processor_text = processor.read_text(encoding="utf-8")
        staging_text = staging.read_text(encoding="utf-8")
        self.assertIn("foxden_login_animated.mp4", processor_text)
        self.assertIn("foxden_login_processed.mp4", staging_text)
        self.assertIn("foxden-greeter.jpg", staging_text)
        self.assertIn("-an", staging_text)
        self.assertNotIn("greetd/assets/foxden-greeter.mp4", staging_text)

    def test_login_panel_layout_is_left_shifted_without_changing_clock(self):
        css = (ROOT / "regreet.css").read_text(encoding="utf-8")
        login = re.search(
            r"(?m)^overlay\s*>\s*frame\.background:nth-child\(2\)\s*\{([^{}]*)\}", css
        )
        self.assertIsNotNone(login, "Only the second GtkOverlay child should move")
        # ReGreet 0.5.0's clock has no .widget-clock class, so excluding
        # that class alone would inadvertently move the clock too.
        self.assertNotIn("frame.background:not(.widget-clock)", css)
        rules = login.group(1)
        shift = re.search(r"\bmargin-right:\s*(\d+(?:\.\d+)?)%;", rules)
        self.assertIsNotNone(shift, "Use a viewport-relative right margin")
        self.assertGreaterEqual(float(shift.group(1)), 20)
        self.assertLessEqual(float(shift.group(1)), 35)
        self.assertRegex(rules, r"\bpadding:\s*16px\s+14px\s*;")
        self.assertNotRegex(rules, r"\bmin-width\s*:")
        self.assertIsNotNone(re.search(r"(?m)^frame\.widget-clock\s*\{", css))

    def test_theme_contains_shared_palette_and_focus_states(self):
        css = (ROOT / "regreet.css").read_text(encoding="utf-8")
        for token in ("#0B1423", "#142335", "#97E7CA", "#F68D91", "#F5AD66", "#F7F5E9"):
            with self.subTest(token=token):
                self.assertIn(token, css)
        self.assertIn("frame.widget-clock", css)
        self.assertIn("passwordentry:focus", css)
        self.assertIn("button.suggested-action", css)
        self.assertIn("button.destructive-action", css)


if __name__ == "__main__":
    unittest.main()
