# Use an existing SSH agent

Use this task when an approved external agent already owns your private keys.
Do not generate another key merely to satisfy this setup. You need the agent's
installation, unlock and recovery instructions from its owner.

## 1. Start or unlock the approved agent

Follow that product's approved local procedure.

Expected result: its socket is available in this session or through an explicit
provider `IdentityAgent` setting. Never source an unknown script to obtain it.

## 2. Inspect offered public identities

```bash
/usr/bin/ssh-add -l
```

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

If `ssh-add` cannot connect, inspect `SSH_AUTH_SOCK` and the configured agent
path locally. If the wrong key is offered, use provider-specific configuration
with the agent owner's instructions. Restore the previous reviewed host block
if an edit prevents access. Lost keys and revoked sessions require the owning
service's recovery process; changing a socket path cannot recover a private key.

Next: finish [Git and provider configuration](../git/setup.md).
