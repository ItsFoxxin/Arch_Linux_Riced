"""Low-cost regression checks for the Fox Den ReGreet assets and settings."""

from pathlib import Path
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

    def test_media_are_present_with_expected_signatures(self):
        video = ROOT / "assets" / "foxden-greeter.mp4"
        still = ROOT / "assets" / "foxden-greeter.jpg"
        self.assertGreater(video.stat().st_size, 100_000)
        self.assertGreater(still.stat().st_size, 50_000)
        self.assertEqual(video.read_bytes()[4:8], b"ftyp")
        self.assertEqual(still.read_bytes()[:2], b"\xff\xd8")

    def test_theme_contains_the_shared_palette_and_focus_states(self):
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
