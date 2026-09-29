[← Security setup](security.md)

# SSH registration, signing and recovery

**Document type:** shared how-to and troubleshooting reference. Complete either
the [1Password](1password.md) or [Keychain](keychain-ssh.md) tutorial first.

## Understand the four separate checks

| Check | What success proves | What it does not prove |
|---|---|---|
| CLI browser login (`gh` / `az`) | This CLI has an account session | SSH works or every repository is accessible |
| SSH authentication | The server recognises an offered key | Correct Git author metadata or a signed commit |
| Repository read | This identity can read that repository | Write permission to a protected branch |
| Commit signature verification | A trusted key signed these commit bytes | The code is safe, reviewed or approved for release |

A public key can be shared with its intended provider. A private key must not
leave its approved storage. A **host fingerprint** identifies the remote server;
your own key's fingerprint identifies your credential. They are different.

## Register public keys and test authentication

1. Open the public `.pub` file from the chosen tutorial, or the public-key field
   in 1Password. Check its fingerprint against the key you intended to use.
2. For GitHub, open account **Settings → SSH and GPG keys → New SSH key** and
   register it as an **Authentication key**. Complete any organisation SSO
   authorisation required by policy.
3. For Azure DevOps, open your profile's **SSH public keys** and add the RSA
   public key. Check expiry/organisation policy. Azure's
   [SSH instructions](https://learn.microsoft.com/en-us/azure/devops/repos/git/use-ssh-keys-to-authenticate?view=azure-devops)
   cover RSA support and provider-specific access requirements.
4. Before accepting a first connection, compare the displayed server fingerprint
   with [GitHub's published fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)
   or Azure's fingerprint shown by its SSH-key instructions/profile. Do not accept
   a changed host key until independently explained.

Run only the selected provider test:

```bash
/usr/bin/ssh -T git@github.com
/usr/bin/ssh -T git@ssh.dev.azure.com
```

GitHub should identify the expected account and explain that shell access is not
provided. Azure can report that shell access is unsupported after authentication.
These tests may return non-zero despite successful authentication; inspect the
actual response, not just an exit code. A password prompt, wrong account, timeout
or `Permission denied (publickey)` is not success.

The current scripted Phase 4 uses `StrictHostKeyChecking=accept-new`; that is not
evidence of your independent fingerprint review. Do the manual trust check first.
Never solve a trust failure by disabling host checking or deleting all known hosts.

For repository access, copy an authorised repository's SSH URL from the provider
and run `git ls-remote` followed by that URL. This reads remote refs without a
push. Private URLs and ref names can be sensitive; keep the output local. Use
the provider's **HTTPS** URL instead when HTTPS is the selected route.

## Verify a real signature

SSH signing requires a compatible Git (2.34 or later). Test in a new local repo
before changing global defaults; nothing below pushes or rewrites history.
Replace the author values with your intended name and verified provider email
(a provider no-reply address can protect your personal email).

```bash
git --version
signing_test_dir="$(mktemp -d)"
git -C "$signing_test_dir" init
git -C "$signing_test_dir" config user.name "Example Developer"
git -C "$signing_test_dir" config user.email "developer@example.com"
git -C "$signing_test_dir" config gpg.format ssh
```

Choose **one** signer setup, in the same terminal:

**1Password:** use the public pin matching the selected vault key. For a dedicated
signing key, save its public part separately and substitute that path. The
1Password app's **Configure Commit Signing → Copy Snippet** is another way to
obtain the selected key/signer settings; scope them to this test repository.

```bash
signing_public_key="$HOME/.ssh/github-auth.pub"
git -C "$signing_test_dir" config user.signingkey "$(cat "$signing_public_key")"
git -C "$signing_test_dir" config gpg.ssh.program /Applications/1Password.app/Contents/MacOS/op-ssh-sign
```

This uses 1Password's signer rather than relying on the terminal's agent socket.
See [1Password signing](https://developer.1password.com/docs/ssh/git-commit-signing/)
for its configuration and app UI.

**Keychain:** use the public key corresponding to the private key already loaded
into the macOS agent. Substitute `id_rsa_azure.pub` if that is your chosen key:

```bash
signing_public_key="$HOME/.ssh/id_ed25519.pub"
git -C "$signing_test_dir" config user.signingkey "$signing_public_key"
git -C "$signing_test_dir" config gpg.ssh.program /usr/bin/ssh-keygen
```

Now create a test-only trust file in this newly created directory. It maps the
committer email to the public key you trust, not to private material:

```bash
printf '%s %s\n' "$(git -C "$signing_test_dir" config user.email)" "$(cat "$signing_public_key")" > "$signing_test_dir/allowed_signers"
git -C "$signing_test_dir" config gpg.ssh.allowedSignersFile "$signing_test_dir/allowed_signers"
git -C "$signing_test_dir" -c core.hooksPath=/dev/null commit --allow-empty -S -m "test: verify SSH signing"
git -C "$signing_test_dir" verify-commit HEAD
git -C "$signing_test_dir" log --show-signature -1
printf 'Inspect the disposable test at: %s\n' "$signing_test_dir"
```

Expect a good signature from your selected key and principal. The test disables
hooks only for that one empty commit so unrelated global hooks do not execute.
Keep the directory for inspection, then move that specific directory to Trash.
Do not use its temporary trust-file path in permanent Git configuration.

For regular use, place the reviewed allowed-signers file at a persistent private
configuration path, then set `gpg.format`, `user.signingkey`, signer and trust-file
settings in the intended repository (or a reviewed identity-specific include).
Optionally enable `commit.gpgsign=true` there after the test. For GitHub's hosted
verification, register the public key separately as a **Signing key**, even if
it is already an authentication key. A local pass is not a hosted `Verified`
badge; test that only in a repository where a push is authorised. See
[GitHub signing configuration](https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key).
Do not infer Azure hosted verification from local signing.

## Troubleshoot without weakening the boundary

| Symptom | Inspect first | Safe next step |
|---|---|---|
| Agent unavailable / no identities | App lock, agent socket, selected vault/key, `/usr/bin/ssh-add -l` | Unlock/enable the intended agent; load the intended Keychain key |
| Wrong account / too many authentication failures | `/usr/bin/ssh -G HOST`, public pin and earlier `Host *`/includes | Correct the specific block; offer only the intended identity |
| `Permission denied (publickey)` | Public-key registration, expiry, SSO and actual key fingerprint | Correct registration/authorisation; do not regenerate blindly |
| Host key changed | Independent provider notice and published fingerprint | Stop until explained; update only the verified host entry |
| Invalid `--apple-use-keychain` option | Which `ssh-add` binary ran | Use `/usr/bin/ssh-add` on macOS |
| Passphrase requested repeatedly | Agent choice, Keychain loading, effective host block | Repair the selected integration; do not remove the passphrase |
| Signature missing or untrusted | `git config --show-origin --get-regexp '^(user\.|gpg\.|commit\.gpgsign)'` locally | Check local overrides, key, signer and allowed-signers principal |
| CLI logged in but Git fails | Git remote URL/protocol and credential route | Match the URL to SSH or HTTPS and test repository access separately |

Verbose SSH/config output can expose identities, paths and private hosts. Redact
it before sharing. Do not enable automatic secret logging while troubleshooting.

## Rotate, recover or change modes

For planned rotation: create the replacement in the intended owner, register its
public key, test authentication and signing, update scoped configuration, then
revoke the old provider registrations. If a key is suspected compromised, revoke
it promptly rather than waiting for a convenient migration. Review both its
authentication and signing registrations and any active account sessions.

Changing modes is a migration, not an uninstall. Preserve the prior config, inspect
`SSH_AUTH_SOCK`, host `IdentityAgent`, public/private `IdentityFile` paths and
`gpg.ssh.program`, then change only the selected identity. In the scripted route,
preview the new required-phase plan and follow Phase 3/4 gates; do not rely on an
old completion marker. Test before retiring the old route.

If chezmoi owns edited configuration, reconcile the intended source using the
[chezmoi daily guide](../20-reference/MANAGING-DOTFILES-WITH-CHEZMOI.md) and review
the diff. Preserve templates instead of blindly replacing them with machine-local
values. No recovery procedure requires committing private keys or session tokens.
