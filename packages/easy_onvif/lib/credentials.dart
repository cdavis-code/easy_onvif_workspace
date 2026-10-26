/// Encrypted, multi-device credential storage.
///
/// Replaces the plaintext `~/.onvif/credentials.json`: an AES-256-GCM envelope
/// holding a flat device list, sealed against a key from the environment, a
/// `0600` key file, the OS keychain, or an Argon2id-derived passphrase.
///
/// The pure parts ([DeviceBundle], [sealBundle], [openBundle], [KdfSpec])
/// compile to the VM, dart2js and dartwasm; [CredentialStore] is the file- and
/// OS-backed layer and resolves to an unsupported stub in a browser.
library;

export 'src/credentials/bundle.dart';
export 'src/credentials/envelope.dart';
export 'src/credentials/keys.dart';
export 'src/credentials/store.dart';
