# Enable local HTTPS for a development project

Use a local certificate authority (CA) only when a project needs HTTPS. A CA is
a trusted issuer of certificates. This manual task changes local trust and must
follow the device owner's policy; it is not a production certificate procedure.

## Before you start

Confirm the intended project directory and exact development hostnames. Preserve
existing certificates and configuration. Obtain IT approval on a managed Mac.
Never share or commit the CA private key.

## 1. Install mkcert if selected and missing

```bash
brew install mkcert
```

Expected result: `mkcert -version` reports the tool. Homebrew owns this installation.

## 2. Establish local trust

```bash
mkcert -install
```

Expected result: the local development CA is installed in the supported trust
stores after the required approval. Do not bypass a managed-policy rejection.

## 3. Inspect the CA location

Run `mkcert -CAROOT`.

Expected result: the machine-local CA directory. Treat its private key as a secret;
do not copy it to colleagues, a repository, chat or support ticket.

## 4. Prepare the project's certificate directory

Create `.certs` in the intended repository, and add `.certs/` to its ignore rules
before generating files. Inspect an existing directory rather than overwriting it.

Expected result: Git ignores the selected certificate output location.

## 5. Generate certificates for explicit local names

```bash
mkcert -cert-file .certs/localhost.pem \
  -key-file .certs/localhost-key.pem \
  localhost 127.0.0.1 ::1
```

Expected result: the two named files are created for these local names. Point the
project's development server at them using its documented HTTPS settings.

## Verify

Open the intended HTTPS development URL in the actual browser. Confirm the
hostname and certificate issuer and check that Git does not stage the key.
A generated file alone does not prove that the server is using it.

## Troubleshooting and recovery

A name mismatch requires a certificate for the actual approved development name.
A trust failure requires checking the browser/store and policy, not disabling
TLS verification. To remove this development trust, use `mkcert -uninstall`.
Review generated project certificates separately and preserve anything still
needed before deletion. Production certificates come from the deployment owner.

The [mkcert project](https://github.com/FiloSottile/mkcert) documents supported
trust stores and client-specific requirements.
