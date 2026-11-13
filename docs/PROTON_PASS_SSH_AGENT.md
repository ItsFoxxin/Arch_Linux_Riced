# Proton Pass CLI SSH agent — acceptance and rollback

> **Issue #11:** source-only hardening. No login, vault access, user-service modification, credential changes or live SSH tests were performed by this Worker. CI mocks do not establish runtime recovery.

## Design and failure containment

Previously, the optional user service used `Restart=on-failure` with a five-second retry, despite an unauthenticated Proton Pass CLI. Bash independently exported `~/.ssh/proton-pass-agent.sock` regardless of whether an agent existed. Both conditions were observed during Issue #7 validation.

The new service checks the **pre-existing** local CLI session with `pass-cli info` in a non-interactive `ExecCondition=`. Missing CLI, expired authentication or failed checks skip the service start without running `pass-cli login` or logging account metadata. `Restart=no` prevents an authentication failure or crash from restarting indefinitely; `StartLimitBurst=3` in five minutes bounds repeated manual starts. An owner must deliberately start the service after authentication. A skipped unit may show as inactive without having failed.

The updated interactive Bash config selects Proton Pass only when the configured path is a Unix socket owned by the current user and `ssh-add -l` returns 0 or 1. **Every probe runs under GNU/coreutils `timeout -k 1s 2s`**: if an agent stops answering, `timeout` sends TERM after two seconds and KILL one second later if necessary. A timed-out probe (normally status 124, or 137 after forced termination) is unavailable. If `timeout` or `ssh-add` is missing, the shell fails closed rather than running an unbounded query. OpenSSH returns 2 when unable to contact the agent. Status 1 can mean no identities and is treated only as a *reachability heuristic*, not proof of the right key or successful authentication. When Proton is absent or unresponsive, Bash keeps a **different** inherited agent only if it passes the same bounded checks; otherwise it unsets `SSH_AUTH_SOCK`. A duplicate inherited Proton path is not probed twice. Both separate probes may add up to approximately six seconds in the worst normal timeout path; system scheduling or uninterruptible kernel operations can exceed timer targets. No service or CLI authentication is initiated from Bash.

**Important:** a host-specific OpenSSH `IdentityAgent` setting overrides `SSH_AUTH_SOCK` for that host. `IdentityFile` and `IdentitiesOnly` can also affect key selection. This PR intentionally does not edit `~/.ssh/config`; a different explicitly configured socket must be verified separately.

## Phase 1: owner-only source review and installation planning

1. Review the exact PR commit and compare the source `bash/.bashrc` and `systemd/.config/systemd/user/proton-pass-ssh-agent.service` with installed workstation files. Confirm the CLI version and supported command options locally using `pass-cli --version` and `pass-cli ssh-agent start --help`.
2. From a recoverable TTY or terminal, record existing SSH agent and service state. **Issue #7 reported this service stopped but still enabled**: a later login can activate it again. Decide separately whether login-time activation is desired before replacing the installed unit.
3. Back up the current installed `~/.bashrc` **content** and existing `~/.config/systemd/user/proton-pass-ssh-agent.service` outside the repository. If a file is a Stow symlink, preserve its target content as well as the link information. Do not use `stow --adopt`. The `systemd/` directory is *not* deployed with the seven standard Stow packages.
4. Only with explicit approval, install the reviewed optional unit, run `systemctl --user daemon-reload` and test a new interactive Bash session. Authentication, starting/stopping/enabling/disabling the service, and any other machine changes are separate owner actions. Merely merging a PR does not deploy either file.

Read-only preflight:

```bash
systemctl --user is-enabled proton-pass-ssh-agent.service
systemctl --user is-active proton-pass-ssh-agent.service
systemctl --user show proton-pass-ssh-agent.service -p NRestarts -p ActiveState -p UnitFileState
printf 'SSH_AUTH_SOCK=%s\n' "${SSH_AUTH_SOCK-<unset>}"
[[ -n "${SSH_AUTH_SOCK:-}" && -S "$SSH_AUTH_SOCK" ]] && echo 'Selected socket exists'
ls -ld -- "$HOME/.ssh"
```

On a development machine, `systemd-analyze verify systemd/.config/systemd/user/proton-pass-ssh-agent.service` parses the unit. An executable-not-found warning on a machine without the intended user-local `pass-cli` is not proof the unit syntax is invalid.

## Phase 2: owner-controlled authentication and live acceptance

Proton documents web-based CLI sign-in and `pass-cli info` as a session check. An **owner may choose** to run the following locally; do not place passwords, personal access tokens, SSH private keys, recovery codes or session output into GitHub comments or CI. PAT sessions have a two-hour lifetime, so they should not be treated as a permanent unattended credential.

```bash
# Owner-operated after choosing to authenticate:
"$HOME/.local/bin/pass-cli" login
"$HOME/.local/bin/pass-cli" info >/dev/null && echo 'CLI session available'

# Owner-operated only after reviewing/installing the service template:
systemctl --user start proton-pass-ssh-agent.service
systemctl --user is-active proton-pass-ssh-agent.service
```

Open a **new** interactive Bash shell and inspect:

```bash
printf 'SSH_AUTH_SOCK=%s\n' "${SSH_AUTH_SOCK-<unset>}"
[[ -n "${SSH_AUTH_SOCK:-}" && -S "$SSH_AUTH_SOCK" ]] && echo 'Socket path exists'
ssh-add -l  # 0: identities listed; 1: may be empty; 2: cannot contact agent
ssh -G YOUR_SSH_HOST_ALIAS | grep -Ei '^(identityagent|identityfile|identitiesonly) '
```

Require the intended public-key fingerprint to appear before a test against a **known authorized destination**. An agent answering requests with no matching key is not a successful SSH login. Verify any explicit host `IdentityAgent` path independently, especially if it differs from `~/.ssh/proton-pass-agent.sock`. Redact potentially identifying SSH hosts, vault metadata, session information, fingerprints and journal output before sharing any evidence.

On the owner's schedule, confirm that a missing authentication session causes the service to **skip** without restarts and that Bash preserves a working alternate socket or unsets a dead one. Do not deliberately log out of a needed account solely to test failure behavior. Record service counters only after approval.

## Recovery (owner-operated only)

If SSH selection breaks, recover from a known-good terminal or TTY, restore the backed-up `.bashrc` content/symlink, or reverse only this Bash fragment. For the **current shell only**, `export SSH_AUTH_SOCK=/path/to/a/verified/agent.sock` selects a known agent; `unset SSH_AUTH_SOCK` stops advertising a dead one. Verify with `ssh-add -l` before retrying SSH.

For service failure, the owner may stop it, restore the backed-up unit and run `systemctl --user daemon-reload`. Review enabled state separately because a stopped but enabled service can start at login. If repeated manual starts hit the rate limiter, investigate first; the owner may then use `systemctl --user reset-failed proton-pass-ssh-agent.service` before a deliberate retry. Do not delete active sockets, erase CLI session data, force-kill another agent or automate authentication as a quick fix.

## References and residual gates

- [Proton Pass CLI login and session checks](https://protonpass.github.io/pass-cli/commands/login/)
- [Proton Pass CLI SSH-agent and systemd example](https://protonpass.github.io/pass-cli/commands/ssh-agent/)
- [systemd ExecCondition semantics](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html)
- [Arch OpenSSH ssh-add exit statuses](https://man.archlinux.org/man/ssh-add.1)
- [Arch Linux coreutils timeout flags and exit codes](https://man.archlinux.org/man/coreutils/timeout.1.en)

**Not yet verified:** installed Proton CLI version and authenticated state, actual user-systemd execution/skip, real socket ownership and reachability, vault identities, per-host `IdentityAgent` behavior, a successful authorized SSH login and owner-approved rollback rehearsal. CI passing does not replace these gates. Report to the Coordinator; merges and workstation activation require the owner's approval.
