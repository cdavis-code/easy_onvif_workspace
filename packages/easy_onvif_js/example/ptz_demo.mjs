#!/usr/bin/env node

// ptz_demo.mjs
//
// Demonstrates PTZ (pan-tilt-zoom) control on an ONVIF camera.
//
// Usage:
//   node ptz_demo.mjs
//
// Environment variables:
//   CAMERA_HOST      e.g. 192.168.1.64:8000
//   CAMERA_USERNAME  default: admin
//   CAMERA_PASSWORD  (required)
//   PROFILE_TOKEN    optional; if omitted the script picks the first profile
//
// Note:
//   The test server (happytime-rtsp-server) does NOT support PTZ — the script
//   will detect this and exit gracefully. Run against a real ONVIF PTZ camera
//   to exercise the full move sequence.

import { loadEasyOnvif } from '../../../npm/easy-onvif-node/index.mjs';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Extract the real error message from a rejected JSPromise.
 */
function unwrapDartError(err) {
  if (err && typeof err.error !== 'undefined') {
    return String(err.error);
  }
  return err?.message ?? String(err ?? 'unknown error');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const host = process.env.CAMERA_HOST ?? '';
const username = process.env.CAMERA_USERNAME ?? 'admin';
const password = process.env.CAMERA_PASSWORD ?? '';
const profileToken = process.env.PROFILE_TOKEN ?? null;

if (!host || !password) {
  console.error(`
Usage:
  CAMERA_HOST=192.168.1.64:8000 \
  CAMERA_PASSWORD=secret \
  node ptz_demo.mjs

Optional:
  PROFILE_TOKEN=<token>   (uses first profile if omitted)

Note:
  The happytime-rtsp-server test server does NOT support PTZ. Use a real
  ONVIF PTZ camera to exercise this script.
`);
  process.exit(1);
}

try {
  const onvif = await loadEasyOnvif();

  console.log(`Connecting to ${host} as ${username}…`);
  const handle = await onvif.connect({ host, username, password });
  console.log('  ✓ Connected (handle =', handle, ')\n');

  // Resolve profile token.
  const token =
    profileToken ?? (await onvif.getProfiles(handle))[0]?.token;

  if (!token) {
    console.error('No media profiles found on the device.');
    process.exit(1);
  }
  console.log(`Using profile: ${token}\n`);

  // ── Probe PTZ availability ───────────────────────────────────────
  //
  // Before running a full move sequence, test with a single absoluteMove.
  // If the device doesn't support PTZ (like the test server), report and
  // exit gracefully instead of printing a confusing stack trace.

  console.log('  Probing PTZ support…');
  try {
    await onvif.absoluteMove(handle, token, 0, 0, 0);
    console.log('  ✓ PTZ is available.\n');
  } catch (ptzErr) {
    console.warn('  ⚠ PTZ not supported on this device.');
    console.warn('    ', unwrapDartError(ptzErr));
    console.warn('');
    console.warn('  This is expected with the happytime-rtsp-server test server.');
    console.warn('  Connect to a real ONVIF PTZ camera to run the full demo.');
    console.warn('');
    onvif.disconnect(handle);
    process.exit(0);
  }

  // ── Absolute move walk ───────────────────────────────────────────
  //
  // AbsoluteMove sends the camera to an exact pan/tilt/zoom position.
  // Coordinates are normalised 0.0 – 1.0 for each axis.
  //
  //   (pan=0, tilt=0, zoom=0)  →  home / centre
  //   (pan=0.5, tilt=0, zoom=0) → pan right
  //   (pan=0, tilt=0.5, zoom=0) → tilt down
  //   (pan=0, tilt=0, zoom=0.5) → zoom in by half

  const moves = [
    { label: 'Centre (home)',   x: 0,   y: 0,   zoom: 0 },
    { label: 'Pan right (0.5)', x: 0.5, y: 0,   zoom: 0 },
    { label: 'Pan left (0.0)',  x: 0,   y: 0,   zoom: 0 },
    { label: 'Tilt down (0.5)', x: 0,   y: 0.5, zoom: 0 },
    { label: 'Tilt up (0.0)',   x: 0,   y: 0,   zoom: 0 },
    { label: 'Zoom in (0.5)',   x: 0,   y: 0,   zoom: 0.5 },
    { label: 'Zoom out (0.0)',  x: 0,   y: 0,   zoom: 0 },
  ];

  for (const move of moves) {
    console.log(`  AbsoluteMove → ${move.label}`);
    const ok = await onvif.absoluteMove(handle, token, move.x, move.y, move.zoom);
    console.log(`    ${ok ? '✓' : '✗'} done`);
    // Allow the camera to settle between moves.
    await new Promise((r) => setTimeout(r, 1200));
  }

  console.log('\nPTZ demo complete.');

  onvif.disconnect(handle);
  console.log('  ✓ Disconnected.');
} catch (err) {
  console.error('\n✗ Fatal error:', unwrapDartError(err));
  process.exit(1);
}
