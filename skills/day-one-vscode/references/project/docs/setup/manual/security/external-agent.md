# Use an existing SSH agent

Use this task when an approved external agent already owns your private keys.
Do not generate another key merely to satisfy this setup. You need the agent's
installation, unlock and recovery instructions from its owner.

## 1. Start or unlock the approved agent

Follow that product's approved local procedure.

Expected result: the agent's socket, a local connection path, is available
through `SSH_AUTH_SOCK` or a provider-specific SSH `IdentityAgent` setting.
Use the path supplied by the agent's approved configuration.

## 2. Inspect offered public identities

Choose the check that matches the agent configuration.

If `SSH_AUTH_SOCK` already selects the approved agent, run:

```bash
/usr/bin/ssh-add -l
```

If SSH selects the agent only through `IdentityAgent`, replace the placeholder
with that agent's absolute socket path, then run:

```bash
SSH_AUTH_SOCK='/absolute/path/to/approved-agent.sock' /usr/bin/ssh-add -l
```

This assignment selects the socket for this command only. `ssh-add` does not
read SSH's `IdentityAgent` setting, so an empty default agent says nothing about
the identities offered by the configured external agent.

Expected result: the intended SHA-256 fingerprint is listed. No identities is
different from an unavailable agent. Confirm the fingerprint with the owner;
do not copy private key material.

## 3. Register the public key

Follow [provider registration and host verification](ssh-signing-and-recovery.md#register-public-keys-and-test-authentication).

Expected result: the intended provider account lists the matching public key.
An agent being available does not prove that account has repository access.

## 4. Test the actual client

Run the [repository read check](../git/setup.md#6-verify-a-repository-read) from
the terminal or IDE that will use Git.

Expected result: the authorised repository is readable with the expected
identity. Repeat after a new session or lock/unlock as required by the agent.

## Troubleshooting and recovery

If `ssh-add` cannot connect, confirm that the selected socket exists and the
agent is unlocked. Compare the command's socket with the approved agent path.
If the wrong key is offered, use provider-specific configuration
with the agent owner's instructions. Restore the previous reviewed host block
if an edit prevents access. Lost keys and revoked sessions require the owning
service's recovery process; changing a socket path cannot recover a private key.

Next: finish [Git and provider configuration](../git/setup.md).
