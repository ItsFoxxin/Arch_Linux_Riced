"""No-network, no-credential regression tests for the optional SSH agent."""

from pathlib import Path
import shlex
import socket
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
BASHRC = ROOT / "bash/.bashrc"
UNIT = ROOT / "systemd/.config/systemd/user/proton-pass-ssh-agent.service"


class ShellAgentFallbackTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="foxden-agent-test-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        (self.home / ".ssh").mkdir(mode=0o700)
        self.bin_dir = self.home / "fake-bin"
        self.bin_dir.mkdir()
        mock = self.bin_dir / "ssh-add"
        mock.write_text(
            '#!/bin/sh\n'
            'if [ "$SSH_AUTH_SOCK" = "$FOX_TEST_PROTON" ]; then\n'
            '  exit "${FOX_TEST_PROTON_EXIT:-2}"\n'
            'fi\n'
            'if [ "$SSH_AUTH_SOCK" = "$FOX_TEST_OTHER" ]; then\n'
            '  exit "${FOX_TEST_OTHER_EXIT:-2}"\n'
            'fi\n'
            'exit 2\n',
            encoding="utf-8",
        )
        mock.chmod(0o755)
        self.proton = self.home / ".ssh/proton-pass-agent.sock"
        self.other = self.home / ".ssh/other-agent.sock"
        self.sockets = []
        self.addCleanup(self._close_sockets)

    def _close_sockets(self):
        for listener in self.sockets:
            listener.close()

    def _make_socket(self, path):
        listener = socket.socket(socket.AF_UNIX)
        listener.bind(str(path))
        listener.listen(1)
        self.sockets.append(listener)

    def _run_shell(self, *, previous=None, proton_status=2, other_status=2, provide_ssh_add=True):
        env = {
            "HOME": str(self.home),
            "PATH": str(self.bin_dir if provide_ssh_add else self.home / "empty-bin"),
            "TERM": "dumb",
            "FOX_TEST_PROTON": str(self.proton),
            "FOX_TEST_OTHER": str(self.other),
            "FOX_TEST_PROTON_EXIT": str(proton_status),
            "FOX_TEST_OTHER_EXIT": str(other_status),
            "FOX_TEST_BASHRC": str(BASHRC),
        }
        if previous is not None:
            env["SSH_AUTH_SOCK"] = str(previous)
        proc = subprocess.run(
            ["/bin/bash", "--noprofile", "--norc", "-ic",
             'source "$FOX_TEST_BASHRC"; printf "%s" "${SSH_AUTH_SOCK-UNSET}"'],
            env=env, capture_output=True, text=True, check=True,
        )
        return proc.stdout

    def test_live_proton_is_preferred_over_other_agent(self):
        self._make_socket(self.proton)
        self._make_socket(self.other)
        self.assertEqual(self._run_shell(previous=self.other, proton_status=0, other_status=0), str(self.proton))

    def test_proton_with_no_loaded_keys_is_still_live(self):
        self._make_socket(self.proton)
        self.assertEqual(self._run_shell(proton_status=1), str(self.proton))

    def test_missing_proton_socket_preserves_other_agent(self):
        self._make_socket(self.other)
        self.assertEqual(self._run_shell(previous=self.other, other_status=0), str(self.other))

    def test_unresponsive_proton_socket_preserves_other_agent(self):
        self._make_socket(self.proton)
        self._make_socket(self.other)
        self.assertEqual(self._run_shell(previous=self.other, proton_status=2, other_status=1), str(self.other))

    def test_missing_and_stale_sockets_do_not_advertise_agent(self):
        self.assertEqual(self._run_shell(), "UNSET")
        self._make_socket(self.proton)
        self._make_socket(self.other)
        self.assertEqual(self._run_shell(previous=self.other), "UNSET")

    def test_regular_file_cannot_masquerade_as_socket(self):
        self.proton.write_text("stale", encoding="utf-8")
        self.assertEqual(self._run_shell(proton_status=0), "UNSET")

    def test_missing_ssh_add_does_not_advertise_unverified_agent(self):
        self._make_socket(self.proton)
        self.assertEqual(self._run_shell(proton_status=0, provide_ssh_add=False), "UNSET")


class UserServiceSafetyTests(unittest.TestCase):
    def setUp(self):
        self.unit = UNIT.read_text(encoding="utf-8")
        self.condition = next(
            line.partition("=")[2] for line in self.unit.splitlines()
            if line.startswith("ExecCondition=")
        )

    def _run_condition(self, cli_status=None):
        with tempfile.TemporaryDirectory(prefix="foxden-passcli-test-") as temp:
            home = Path(temp)
            path = home / ".local/bin/pass-cli"
            if cli_status is not None:
                path.parent.mkdir(parents=True)
                path.write_text(
                    '#!/bin/sh\n'
                    '[ "$1" = "info" ] || exit 99\n'
                    f'exit {cli_status}\n',
                    encoding="utf-8",
                )
                path.chmod(0o700)
            command = shlex.split(self.condition)
            proc = subprocess.run(command, env={"HOME": str(home), "PATH": "/usr/bin:/bin"},
                                  capture_output=True, text=True)
            self.assertEqual(proc.stdout, "")
            self.assertEqual(proc.stderr, "")
            return proc.returncode

    def test_missing_cli_skips_service_start(self):
        self.assertEqual(self._run_condition(), 1)

    def test_unauthenticated_session_skips_service_start(self):
        self.assertEqual(self._run_condition(1), 1)

    def test_unexpected_auth_error_is_normalized_to_skip(self):
        self.assertEqual(self._run_condition(255), 1)

    def test_authenticated_session_allows_service_start(self):
        self.assertEqual(self._run_condition(0), 0)

    def test_unit_has_no_unattended_restart_or_login(self):
        self.assertIn("\nRestart=no\n", self.unit)
        self.assertIn("\nStartLimitBurst=3\n", self.unit)
        self.assertIn("\nStartLimitIntervalSec=5min\n", self.unit)
        self.assertIn("\nTimeoutStartSec=30\n", self.unit)
        self.assertIn("ssh-agent start --socket-path", self.unit)
        self.assertNotIn("pass-cli login", self.unit)


if __name__ == "__main__":
    unittest.main()
