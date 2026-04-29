// npm-level smoke test: does `loadEasyOnvif()` expose the expected surface?

import { loadEasyOnvif } from '../index.mjs';

const api = await loadEasyOnvif();

const required = [
  'connect',
  'disconnect',
  'getDeviceInformation',
  'getProfiles',
  'getStreamUri',
  'getSnapshotUri',
  'absoluteMove',
  'probe',
];

const missing = required.filter((name) => typeof api[name] !== 'function');

if (missing.length > 0) {
  console.error('FAIL: missing methods:', missing.join(', '));
  process.exit(1);
}

console.log('OK: easy-onvif-node loaded with methods:', required.join(', '));
