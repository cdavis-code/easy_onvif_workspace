#!/usr/bin/env node

// discover_and_info.mjs
//
// Demonstrates the two main ONVIF workflows:
//   1. WS-Discovery — probe the local network for ONVIF cameras.
//   2. SOAP device interrogation — connect to a camera, query device
//      information, list media profiles, and fetch stream URIs.
//
// Usage:
//   node discover_and_info.mjs
//
// The script gracefully handles missing PTZ and optional features like
// snapshot URIs, making it suitable for test servers.
//
// Test server (happytime-rtsp-server) defaults:
//   CAMERA_HOST=localhost:6554
//   CAMERA_USERNAME=admin
//   CAMERA_PASSWORD=123456

import { loadEasyOnvif } from '../../../npm/easy-onvif-node/index.mjs';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Ask a question on the terminal and return the typed answer. */
function ask(query) {
  // We deliberately avoid `node:readline` because its import registers
  // internal stdin handlers that interfere with dgram socket events on
  // Node.js >= 25 (the socket fires a transient error before any
  // WS-Discovery responses arrive). A direct stdin read is sufficient
  // for the simple single-line prompts this script uses.
  return new Promise((resolve) => {
    process.stdout.write(query);
    process.stdin.setEncoding('utf8');
    process.stdin.once('data', (chunk) => {
      process.stdin.pause();
      resolve(String(chunk).replace(/\r?\n$/, '').trim());
    });
    process.stdin.resume();
  });
}

/** Pretty-print a JS object to the console. */
function show(label, obj) {
  console.log(`\n═══ ${label} ═══`);
  console.log(JSON.stringify(obj, null, 2));
}

/**
 * Extract the real error message from a rejected JSPromise.
 *
 * When a Dart Future.toJS promise rejects, the rejection value is a JS object
 * with `.error` and `.stack` properties. This helper unwraps it.
 */
function unwrapDartError(err) {
  // Dart wraps the thrown value under `.error`.
  const inner = (err && typeof err.error !== 'undefined') ? err.error : err;
  if (inner == null) return 'unknown error';
  // Node.js errors have a `message` and often a `code` field.
  if (inner.message) {
    return inner.code ? `${inner.code}: ${inner.message}` : inner.message;
  }
  return String(inner);
}

/** @returns {boolean} true when a camera was configured via env vars. */
function hasEnvConfig() {
  return !!(
    process.env.CAMERA_HOST ||
    process.env.SERVER_HOST
  );
}

// ---------------------------------------------------------------------------
// Main
//
// IMPORTANT: wrap in an async IIFE so that dart2js's async scheduler runs
// inside a Promise .then() microtask context, not at the top-level of the
// ES-module evaluation phase. The root cause is that `globalThis.require`
// is not available in an ES-module context; the npm loader works around this
// by injecting `globalThis.__easyOnvifRequire` before calling require(), and
// the Node preamble in easy_onvif.js picks that up. For belt-and-suspenders,
// keeping the IIFE also avoids any top-level await interaction with dart2js's
// microtask trampoline.
// ---------------------------------------------------------------------------

(async () => {
  // 1. Load the ONVIF engine (lazy; cached after first call).
  console.log('Loading easy-onvif-node…');
  const onvif = await loadEasyOnvif();

  // ── Discovery phase ──────────────────────────────────────────────
  const doDiscovery =
    !hasEnvConfig() &&
    !process.env.SKIP_DISCOVERY;

  let matches = [];
  if (doDiscovery) {
    console.log(
      '\nProbing the network for ONVIF devices (3 s timeout)…',
    );
    try {
      matches = await onvif.probe(3);
    } catch (probeErr) {
      // Probe can fail when no UDP multicast route exists (e.g. VPN,
      // container, or a test server not on the same subnet).
      console.warn(
        '  ⚠ WS-Discovery probe failed (non-fatal):',
        unwrapDartError(probeErr),
      );
      console.warn('  Falling back to manual configuration.\n');
    }

    if (matches.length === 0) {
      console.log('No devices discovered on the local network.');
      console.log('  • Ensure your camera is connected to the same subnet.');
      console.log('  • For the test server, set env vars instead:');
      console.log('      CAMERA_HOST=localhost:6554');
      console.log('      CAMERA_USERNAME=admin');
      console.log('      CAMERA_PASSWORD=123456\n');
    } else {
      console.log(`Discovered ${matches.length} device(s):\n`);
      for (let i = 0; i < matches.length; i++) {
        const m = matches[i];
        console.log(`  [${i}] ${m.types}`);
        console.log(`      XAddrs: ${m.xAddrs}`);
        console.log(`      Scopes: ${m.scopes}`);
        console.log(`      Metadata Version: ${m.metadataVersion}`);
        console.log(`      EPR: ${m.endpointReference.address}\n`);
      }
    }
  } else {
    console.log('Skipping network discovery (env config or SKIP_DISCOVERY set).');
  }

  // ── Connection phase ─────────────────────────────────────────────

  // Determine target camera from env, discovered matches, or prompt.
  const envHost = process.env.CAMERA_HOST || process.env.SERVER_HOST;

  let host = envHost ?? '';
  let username = process.env.CAMERA_USERNAME ?? 'admin';
  let password = process.env.CAMERA_PASSWORD ?? '';

  if (!host && matches.length > 0) {
    // Pick the first discovered device.
    const firstXAddr = matches[0].xAddrs;
    // xAddrs is an array of URLs; use the first.
    host = Array.isArray(firstXAddr) ? firstXAddr[0] : firstXAddr.split(/\s+/)[0];
    // Strip protocol prefix if present (get just host:port).
    host = host.replace(/^https?:\/\//, '').replace(/\/.*$/, '');

    console.log(`Using first discovered device: ${host}\n`);
  } else if (!host) {
    console.log('\nNo camera configured. You can:');
    console.log('  1. Run without SKIP_DISCOVERY on a network with ONVIF cameras.');
    console.log('  2. Set env vars for a known device or test server:');
    console.log('       CAMERA_HOST=localhost:6554 CAMERA_PASSWORD=123456');
    console.log('');
    process.exit(0);
  }

  if (!password) {
    const pwd = await ask(`Password for ${host} [${username}]: `);
    if (pwd) password = pwd;
  }

  // 2. Connect — establish a SOAP session.
  console.log(`Connecting to ${host} as ${username}…`);
  const handle = await onvif.connect({
    host,
    username,
    password,
  });
  console.log('  ✓ Connected (handle =', handle, ')\n');

  // 3. Device Information via deviceManagement service.
  const deviceMgmt = onvif.getDeviceManagement(handle);
  const info = await deviceMgmt.getDeviceInformation();
  show('Device Information', info);

  // 4. Media profiles via media service.
  const media = onvif.getMedia(handle);
  const profiles = await media.getProfiles();
  show('Media Profiles', profiles);

  if (profiles.length > 0) {
    const token = profiles[0].token;

    // 5. Stream URI for the first profile.
    const streamUri = await media.getStreamUri(token);
    show('RTSP Stream URI (profile: ' + token + ')', streamUri);

    // 6. Snapshot URI (may not be supported by all servers — non-fatal).
    try {
      const snapshotUri = await media.getSnapshotUri(token);
      show('HTTP Snapshot URI (profile: ' + token + ')', snapshotUri);
    } catch (snapErr) {
      console.warn('  ⚠ getSnapshotUri not available:', unwrapDartError(snapErr));
    }

    // 7. PTZ capabilities check.
    try {
      const ptz = onvif.getPtz(handle);
      const ptzCaps = await ptz.getServiceCapabilities();
      show('PTZ Service Capabilities', ptzCaps);

      const presets = await ptz.getPresets(token);
      if (presets.length > 0) {
        show('PTZ Presets (profile: ' + token + ')', presets);
      } else {
        console.log('\n═══ PTZ Presets ═══\n  (none configured)');
      }

      const status = await ptz.getStatus(token);
      show('PTZ Status (profile: ' + token + ')', status);
    } catch (ptzErr) {
      console.warn('  ⚠ PTZ service not available:', unwrapDartError(ptzErr));
    }
  }

  // 7. Disconnect.
  onvif.disconnect(handle);
  console.log('\n  ✓ Disconnected.\n');

  console.log('Done. All API calls succeeded.');
})().catch((err) => {
  console.error('\n✗ Fatal error:', unwrapDartError(err));
  process.exit(1);
});
