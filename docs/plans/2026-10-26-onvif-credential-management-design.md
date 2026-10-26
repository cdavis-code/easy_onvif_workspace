# ONVIF Credential Management — Design

**Status:** approved 2026-10-26
**Scope:** replace the plaintext `~/.onvif/credentials.json` with an encrypted,
multi-device credential bundle and a pluggable key-provider chain, usable by the
CLI, the MCP server (Dart VM and Node builds), the browser build and the Flutter
example app.

## 1. Problem

Every entry point today reads one flat file:

```json
{ "host": "192.168.1.10", "username": "admin", "password": "…" }
```

Readers: `easy_onvif_cli` (`initializeOnvif()`, `--config-file`, default
`~/.onvif/credentials.json`), `easy_onvif_mcp` (`lib/vm.dart`,
`ONVIF_CONFIG_FILE`). The JS bundle is env-only. Two deficiencies:

1. **Plaintext at rest.** The file lands in backups, cloud sync, repo
   checkouts and support bundles.
2. **One device per file.** A site with dozens of cameras needs a list, not a
   file per camera.

ONVIF itself defines no client-side credential store — it standardises the wire
(`UsernameToken` digest, HTTP Digest/Basic, TLS) and nothing about how a client
remembers secrets. The at-rest format is ours.

## 2. Threat model & non-goals

**Closed by this design**

- Credentials in backups, cloud sync, git repos, support bundles, stolen disk.
- Casual reading of a config file (`cat`, `grep`).
- Wrong key surfacing as a distant "auth failed": the error names both key ids.

**Explicitly not claimed**

- A compromised live host where the attacker can read both the bundle and its
  key source. The security boundary is *where the key lives*, not the cipher.
- root/admin, keyloggers, memory scraping of the running process.
- HSM, KMS, FIPS, per-device ACLs, audit trails. No provider slot is designed
  for them; the provider chain can gain one later without a format change.

**Consequence:** the browser build persists nothing. It accepts ciphertext plus
a key in memory and keeps them for the page's lifetime only.

## 3. Envelope format

One versioned JSON object. The header fields are authenticated as AEAD
additional data (AAD), so tampering with them invalidates the tag instead of
silently downgrading the algorithm.

```json
{
  "v": 1,
  "alg": "A256GCM",
  "kid": "a1b2c3d4e5f60718",
  "kdf": "none",
  "nonce": "<base64, 12 bytes>",
  "ct": "<base64, ciphertext || tag>"
}
```

- `kid`: first 8 bytes of `SHA-256(key)`, lowercase hex. Lets a wrong key be
  reported as *"bundle encrypted with key a1b2c3d4e5f60718, current key is
  9f8e7d6c5b4a3210"* rather than an unexplained MAC failure.
- `kdf`:
  - `"none"` — the key was supplied directly (env, key file, keychain, host).
  - `"argon2id:m=19456,t=2,p=1,salt=<base64>"` — derived from a passphrase.
    `m` is KiB (19 MiB), `t` iterations, `p` lanes: the OWASP baseline, and
    19 MiB is safe inside wasm.
- `nonce`: random 12 bytes generated on every write. The bundle is always
  written whole and never appended to, so nonce reuse cannot occur.
- Plaintext is the bundle of §4, UTF-8 encoded JSON.
- Cipher: AES-256-GCM from `package:cryptography` 2.9.0 — pure Dart, so the
  same file compiles to the VM, dart2js and dart2wasm. No FFI, no
  hand-written crypto, no platform-specific cipher.
- AAD is the canonical string `v|alg|kid|kdf`.

## 4. Bundle (plaintext payload)

Flat device list. `site` is an attribute, not a level of nesting: a tree buys
nothing at lookup time and costs a migration every time a camera moves site.

```json
{
  "version": 1,
  "default": "cam-lobby",
  "devices": [
    {
      "id": "cam-lobby",
      "name": "Lobby",
      "site": "plant-a",
      "host": "192.168.1.10:8080",
      "username": "operator",
      "password": "…",
      "tags": ["entrance"]
    }
  ]
}
```

- `id` is operator-chosen, unique, slug-shaped, and stable across renames of
  `name` or `host`.
- `default` is optional; when absent, selection requires `--device`.
- Selection order: `--device <id>` → `ONVIF_DEVICE` → `default` → error listing
  the available ids.
- `site` and `tags` exist for `credentials list --site/--tag`; nothing else
  depends on them.
- **Legacy compatibility:** a file whose top level has `host`/`username`/
  `password` and no `ct` is read as one device with `id: "default"`. It is
  never rewritten automatically; a one-line stderr warning suggests
  `onvif credentials migrate`.
- **Environment override (unchanged):** when `ONVIF_HOST`, `ONVIF_USERNAME` and
  `ONVIF_PASSWORD` are all set, they describe one device and take precedence
  over any bundle and over `--device`. This is the container/CI path: no file,
  no key, nothing at rest. If only some of the three are set, startup fails
  naming the missing ones — a partial override would silently mix a bundle
  device with an ambient host.

## 5. Key providers

First success wins. An explicit flag beats the environment so an automated job
can pin its provider.

| # | Provider | Source | Available on |
|---|---|---|---|
| 1 | `--key-file <path>` | `ONVIF_KEY_FILE`; 32 raw bytes or hex/base64 text; warns if mode is not `0600` | Dart VM |
| 2 | `ONVIF_KEY` | base64 or hex, 32 bytes | Dart VM and Node |
| 3 | OS keychain | macOS `security find-generic-password -s easy_onvif -a easy_onvif`, Linux `secret-tool lookup service easy_onvif account easy_onvif`, Windows DPAPI unseal via `powershell -NoProfile -Command` | Dart VM |
| 4 | Passphrase prompt | `--prompt`, or automatic when stdin is a TTY and 1–3 matched nothing; input hidden with `stdin.echoMode = false`; key derived with the `kdf` block of the envelope | Dart VM |
| 5 | Host-supplied | `ONVIF_BUNDLE` (envelope JSON; Node has no filesystem) + `ONVIF_KEY`; in a browser, the JS call of §6 | Node, browser |

- No provider matched → exit code 2, a message listing all five and the
  flag/env that selects each. The loader never falls back to plaintext.
- `onvif credentials key init` generates 32 random bytes, stores them in the
  keychain (or writes a `0600` file with `--key-file`), and prints the `kid`.
- `onvif credentials key rotate` generates a new key and re-seals the bundle;
  the old key is removed from the keychain.
- There is no `key export`: exporting the key to disk defeats the design.

## 6. Consumer integration

| Consumer | Bundle source | Key source | Change |
|---|---|---|---|
| CLI, every command | `--config-file` (plaintext or encrypted, detected by the presence of `ct`) | providers 1–4 | `initializeOnvif()` resolves the device via `--device`; new `credentials` command group |
| MCP, Dart VM | `ONVIF_CONFIG_FILE` or `~/.onvif/credentials.json` | providers 1–4 | `lib/vm.dart` loads the bundle and selects the device |
| MCP, Node (dart2js) | `ONVIF_BUNDLE` | `ONVIF_KEY` | `lib/src/js/runtime_node.dart` decrypts in memory at startup |
| `easy-onvif/web` (dart2wasm) | host passes the envelope | host passes the key | new method on the JS API: `loadCredentials(String envelopeJson, String keyBase64)` (positional strings — `@JSExport` cannot take Dart objects) |
| Flutter example app | `assets/config.json.enc` | `flutter_secure_storage` | replaces plaintext `assets/config.yaml`; operator pastes the key once |

MCP remains one device per process: the static `Transport` state
(`timeDelta`, `builder`) is serialized today and that does not change. Running
two cameras means two host entries, each with its own `ONVIF_DEVICE`.

## 7. CLI surface

New command group; existing commands keep their names and flags.

```
onvif credentials init                 # create an encrypted bundle (refuses to overwrite)
onvif credentials add                  # add/replace a device entry
onvif credentials remove <id>
onvif credentials list [--site S] [--tag T]   # ids, names, sites; never secrets
onvif credentials default <id>
onvif credentials migrate              # plaintext -> encrypted, verifies, then deletes plaintext
onvif credentials key init|rotate
```

- Global flags added: `--device <id>`, `--key-file <path>`, `--prompt`.
- `init`/`add` read the password from a hidden prompt, or from stdin when not a
  TTY (pipes, CI), never from a command-line argument.
- The existing `onvif authorize` becomes an alias for `credentials init`: it no
  longer writes a plaintext file. Its previous output shape is still *read* (see
  §4, legacy compatibility), so existing installations keep working until they
  migrate.

## 8. Errors

- Fail closed with a specific remedy, not a stack trace:
  - no key → list providers (exit 2)
  - `kid` mismatch → print both ids
  - malformed envelope → same error class as an invalid config file
  - unknown `--device` → list available ids
- Atomic writes: serialise to `<name>.tmp` in the same directory, `rename`
  into place, create with mode `0600`.
- `migrate` re-reads and verifies the encrypted file before deleting the
  plaintext. The plaintext is deleted, not overwritten in place — overwriting
  is theatre on copy-on-write and SSD storage, and claiming otherwise would be
  dishonest.

## 9. Code layout

Inside the core package, behind the existing `platform/` seam (io vs web stub);
no new package and no interface with a single implementation.

```
packages/easy_onvif/lib/credentials.dart                     # public barrel
packages/easy_onvif/lib/src/credentials/envelope.dart        # seal/open, kid, AAD, A256GCM
packages/easy_onvif/lib/src/credentials/bundle.dart          # DeviceBundle / DeviceEntry, legacy parse
packages/easy_onvif/lib/src/credentials/keys.dart            # parse, generate, argon2id derive
packages/easy_onvif/lib/src/credentials/providers_io.dart    # env, key file, keychain, prompt
packages/easy_onvif/lib/src/credentials/providers_stub.dart  # web: UnsupportedError, host-supplied path
packages/easy_onvif_cli/lib/src/command/credentials_command.dart
```

Dependencies: one addition, `cryptography: ^2.9.0` in `easy_onvif`.

Versions: `easy_onvif` and `easy_onvif_cli` → `3.3.0` (additive API, pair stays
locked); `easy_onvif_mcp` → `0.3.0`; no new npm package — the existing Node
and browser builds gain the decrypt entry point.

## 10. Testing

`package:test`, no new frameworks. One test per risk:

1. Round-trip seal → open returns an identical bundle for raw, hex and base64
   keys.
2. Tamper: flipping one byte of `ct`, or one character of `alg`/`kid` (AAD),
   throws and yields no partial data.
3. Wrong key throws and names both `kid`s.
4. Argon2id: identical salt + passphrase derive the same key; a different salt
   derives a different one; parameters round-trip through the `kdf` string.
5. Legacy flat file parses as a single `default` device; after `migrate` the
   encrypted file re-reads and the plaintext is gone.
6. Provider precedence (flag > env > file > keychain > prompt) with fake
   providers; no OS access needed.
7. Keychain integration tests are `skip:`-ed when `security` / `secret-tool` is
   absent, so Linux CI stays green.
8. Node bundle: a handshake with `ONVIF_BUNDLE` + `ONVIF_KEY` still serves the
   full tool registry. Browser decryption is covered by test 1 against the same
   `envelope.dart` that compiles to wasm; no headless browser is added.

## 11. Rollout

1. Core: envelope, bundle, keys, providers (+ tests 1–6).
2. CLI: `credentials` command group, `--device`, encrypted-or-plaintext loader,
   `migrate`; docs (`easy_onvif_cli` README, MCP README credentials section).
3. MCP: VM loader + Node `ONVIF_BUNDLE`; `--version` bumps to `0.3.0`.
4. Browser JS: `loadCredentials(envelopeJson, keyBase64)`; Flutter example uses
   `flutter_secure_storage` + an encrypted asset.

Steps 1–2 are the minimum that removes plaintext from the primary path; 3–4
bring the remaining builds to parity. Each step is independently releasable.

## Implementation status (2026-10-26)

Shipped in `easy_onvif` / `easy_onvif_cli` 3.3.0 and `easy_onvif_mcp` 0.3.0:

- §3–§5 core: `lib/src/credentials/{bundle,envelope,keys,store_io,store_stub}.dart`
  behind `package:easy_onvif/credentials.dart`, plus `cryptography: ^2.9.0`.
- §6 CLI and MCP VM/Node readers; §6 browser `loadCredentials(envelopeJson,
  keyBase64)` on the JS API (`connect()` falls back to that device).
- §7 CLI `credentials` group with `authorize` as an alias.
- §10 tests: `packages/easy_onvif/test/credentials_test.dart` (16, one skipped
  keychain case gated behind `ONVIF_TEST_KEYCHAIN=1` so a routine run never
  touches the operator's keychain), wired into CI.

Verified end to end: CLI init/list/migrate with a `0600` key file, fail-closed
exit 2 without a key, Node MCP bundle decrypting `ONVIF_BUNDLE` + `ONVIF_KEY`
(right key reaches the network, wrong key reports both kids), and the browser
runtime compiling the crypto to dartwasm (dart2js needs the `window` /
`isSecureContext` polyfill now in `tool/node_preamble.js`).

Deferred, unchanged from §11 step 4's second half: the Flutter example app still
loads `assets/config.yaml`. Moving it to an encrypted asset plus
`flutter_secure_storage` is its own change (plugin dependency, asset pipeline,
key bootstrap) and does not block the CLI, MCP or browser paths.
