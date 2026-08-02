#!/usr/bin/env python3
"""Continuously provide a network activity sparkline to Waybar."""

from collections import deque
import json
from pathlib import Path
import time

BLOCKS = "\u2581\u2582\u2583\u2584\u2585\u2586\u2587\u2588"
SAMPLE_SECONDS = 1.0
HISTORY_LENGTH = 6


def find_default_interface() -> str | None:
    """Return the interface that owns the active IPv4 default route."""
    route_file = Path("/proc/net/route")

    for line in route_file.read_text(encoding="utf-8").splitlines()[1:]:
        fields = line.split()
        if len(fields) < 4:
            continue

        interface = fields[0]
        destination = fields[1]
        flags = int(fields[3], 16)

        # Destination 00000000 is the IPv4 default route. Flag 0x1 means up.
        if destination == "00000000" and flags & 0x1:
            return interface

    return None


def read_counter(interface: str, counter: str) -> int:
    """Read an interface byte counter from /proc/net/dev."""
    counter_indexes = {
        "rx_bytes": 0,
        "tx_bytes": 8,
    }

    try:
        counter_index = counter_indexes[counter]
    except KeyError as error:
        raise ValueError(f"Unsupported counter: {counter}") from error

    lines = Path("/proc/net/dev").read_text(encoding="utf-8").splitlines()[2:]

    for line in lines:
        if ":" not in line:
            continue

        name, values = line.split(":", 1)
        if name.strip() != interface:
            continue

        fields = values.split()
        if len(fields) <= counter_index:
            raise OSError(f"Incomplete statistics for interface {interface}")

        return int(fields[counter_index])

    raise OSError(f"Interface not found: {interface}")


def format_rate(bytes_per_second: float) -> str:
    """Convert bytes per second into a readable rate."""
    value = max(0.0, bytes_per_second)

    for unit in ("B/s", "KiB/s", "MiB/s", "GiB/s"):
        if value < 1024.0 or unit == "GiB/s":
            precision = 0 if unit == "B/s" else 1
            return f"{value:.{precision}f} {unit}"
        value /= 1024.0

    return "0 B/s"


def make_sparkline(samples: deque[float]) -> str:
    """Scale recent samples across eight Unicode graph levels."""
    peak = max(samples, default=0.0)
    if peak <= 0:
        return BLOCKS[0] * len(samples)

    highest = len(BLOCKS) - 1
    return "".join(
        BLOCKS[min(highest, round((sample / peak) * highest))]
        for sample in samples
    )


def output(payload: dict[str, object]) -> None:
    """Write one complete JSON update for Waybar."""
    print(json.dumps(payload, ensure_ascii=False), flush=True)


def main() -> None:
    history: deque[float] = deque(
        [0.0] * HISTORY_LENGTH,
        maxlen=HISTORY_LENGTH,
    )

    previous_interface: str | None = None
    previous_rx: int | None = None
    previous_tx: int | None = None
    previous_time = time.monotonic()

    while True:
        cycle_started = time.monotonic()

        try:
            interface = find_default_interface()

            if interface is None:
                history.append(0.0)
                previous_interface = None
                previous_rx = None
                previous_tx = None
                previous_time = time.monotonic()

                output(
                    {
                        "text": make_sparkline(history),
                        "tooltip": "No active IPv4 default route",
                        "class": "offline",
                        "alt": "offline",
                    }
                )
            else:
                rx_bytes = read_counter(interface, "rx_bytes")
                tx_bytes = read_counter(interface, "tx_bytes")
                now = time.monotonic()

                if (
                    interface != previous_interface
                    or previous_rx is None
                    or previous_tx is None
                ):
                    download_rate = 0.0
                    upload_rate = 0.0
                else:
                    elapsed = max(now - previous_time, 0.001)
                    download_rate = max(0, rx_bytes - previous_rx) / elapsed
                    upload_rate = max(0, tx_bytes - previous_tx) / elapsed

                history.append(download_rate + upload_rate)

                output(
                    {
                        "text": make_sparkline(history),
                        "tooltip": (
                            f"Interface: {interface}\n"
                            f"Download: {format_rate(download_rate)}\n"
                            f"Upload: {format_rate(upload_rate)}\n"
                            f"History: {HISTORY_LENGTH} seconds"
                        ),
                        "class": "online",
                        "alt": "online",
                    }
                )

                previous_interface = interface
                previous_rx = rx_bytes
                previous_tx = tx_bytes
                previous_time = now

        except (OSError, ValueError) as error:
            history.append(0.0)
            previous_interface = None
            previous_rx = None
            previous_tx = None
            previous_time = time.monotonic()

            output(
                {
                    "text": make_sparkline(history),
                    "tooltip": f"Network graph error: {error}",
                    "class": "error",
                    "alt": "error",
                }
            )

        elapsed_cycle = time.monotonic() - cycle_started
        time.sleep(max(0.1, SAMPLE_SECONDS - elapsed_cycle))


if __name__ == "__main__":
    main()
