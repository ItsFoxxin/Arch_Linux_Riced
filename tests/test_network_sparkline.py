"""Exercise Linux input parsing and Waybar output without a live desktop."""
from collections import deque
import importlib.util
import io
import json
from pathlib import Path
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "waybar/.config/waybar/scripts/network-sparkline.py"
spec = importlib.util.spec_from_file_location("network_sparkline", SCRIPT)
network = importlib.util.module_from_spec(spec)
spec.loader.exec_module(network)


class NetworkTests(unittest.TestCase):
    def test_rate_boundaries(self):
        for value, expected in [(-1, "0 B/s"), (1023, "1023 B/s"), (1024, "1.0 KiB/s"), (1024**2, "1.0 MiB/s")]:
            with self.subTest(value=value):
                self.assertEqual(network.format_rate(value), expected)

    def test_sparkline_idle_and_scaling(self):
        self.assertEqual(network.make_sparkline(deque()), "")
        self.assertEqual(network.make_sparkline(deque([0, 0])), "▁▁")
        self.assertEqual(network.make_sparkline(deque([0, 10])), "▁█")

    def test_default_route_ignores_down_and_nondefault(self):
        data = "header\nshort\neth0 00000000 0 0000\neth1 00000001 0 0001\nwlan0 00000000 0 0003\n"
        with patch.object(Path, "read_text", return_value=data):
            self.assertEqual(network.find_default_interface(), "wlan0")
        with patch.object(Path, "read_text", return_value="header\n"):
            self.assertIsNone(network.find_default_interface())

    def test_counter_columns_and_missing_interface(self):
        data = "header\nheader\n eth0: 123 1 2 3 4 5 6 7 456 9 10 11 12 13 14 15\n"
        with patch.object(Path, "read_text", return_value=data):
            self.assertEqual(network.read_counter("eth0", "rx_bytes"), 123)
            self.assertEqual(network.read_counter("eth0", "tx_bytes"), 456)
            with self.assertRaises(OSError):
                network.read_counter("missing", "rx_bytes")
        with self.assertRaises(ValueError):
            network.read_counter("eth0", "unknown")

    def test_truncated_statistics_fail(self):
        with patch.object(Path, "read_text", return_value="header\nheader\neth0: 1\n"):
            with self.assertRaises(OSError):
                network.read_counter("eth0", "tx_bytes")

    def test_waybar_output_is_one_json_record(self):
        payload = {"text": "▁█", "tooltip": "Line one\nLine two", "class": "online"}
        with patch("sys.stdout", new_callable=io.StringIO) as stream:
            network.output(payload)
            lines = stream.getvalue().splitlines()
        self.assertEqual(len(lines), 1)
        self.assertEqual(json.loads(lines[0]), payload)


if __name__ == "__main__":
    unittest.main()
