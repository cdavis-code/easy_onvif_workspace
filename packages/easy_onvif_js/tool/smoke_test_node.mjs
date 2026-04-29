// Smoke-test the dart2js Node build.
//
// Loads the compiled `easy_onvif.js` (dart2js bundle with Node preamble),
// which registers `globalThis.EasyOnvif` via `@JSExport()`, and confirms
// the expected method surface exists. Does NOT require a real ONVIF device.
//
// Usage:
//   node tool/smoke_test_node.mjs

import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const BUILD_DIR = resolve(__dirname, '..', 'build', 'node');
const require = createRequire(import.meta.url);

// Inject require into globalThis so Dart's @JS('globalThis.require') works
globalThis.__easyOnvifRequire = require;

require(resolve(BUILD_DIR, 'easy_onvif.js'));

const api = globalThis.EasyOnvif;

if (!api) {
  console.error('FAIL: globalThis.EasyOnvif was not set by dart2js bundle');
  process.exit(1);
}

// The new service-object API uses getter methods that return service proxies.
// Verify the core surface.
const required = [
  'connect',
  'disconnect',
  'getDeviceManagement',
  'getMedia',
  'getPtz',
  'getImaging',
  'getSearch',
  'getRecordings',
  'getReplay',
  'probe',
];

const missing = required.filter((name) => typeof api[name] !== 'function');

if (missing.length > 0) {
  console.error(
    `FAIL: missing expected methods on EasyOnvif: ${missing.join(', ')}`,
  );
  console.error('available keys:', Object.keys(api));
  process.exit(1);
}

console.log('OK: EasyOnvif service-object surface present.');
console.log('    methods:', required.join(', '));

// Verify that service-object methods are actually callable JS functions.
// We invoke them with an invalid handle (999); a properly bound method
// will return a Promise that rejects with "No ONVIF connection registered".
// If the method is not a JS function, the typeof check or the call itself
// throws "x is not a function".
const deviceMgmt = api.getDeviceManagement(999);
const expected = [
  'getDeviceInformation',
  'getServiceCapabilities',
  'getServices',
  'getCapabilities',
  'getHostname',
  'getUsers',
];
const notFns = expected.filter((m) => typeof deviceMgmt[m] !== 'function');
if (notFns.length > 0) {
  console.error(
    `FAIL: deviceManagement methods not callable: ${notFns.join(', ')}`,
  );
  console.error('keys:', Object.keys(deviceMgmt));
  process.exit(1);
}

// Actually call one and verify it returns a Promise.
const result = deviceMgmt.getDeviceInformation();
if (!result || typeof result.then !== 'function') {
  console.error('FAIL: getDeviceInformation() did not return a Promise');
  console.error('got:', result);
  process.exit(1);
}

try {
  await result;
  console.error('FAIL: call with invalid handle should have rejected');
  process.exit(1);
} catch (err) {
  // Success criteria: the Promise rejected with a Dart-thrown error. Before
  // the fix, calling a service method threw a synchronous JS TypeError
  // ("x is not a function") because jsify()'d Dart closures were opaque.
  // Now the call reaches Dart, so the rejection carries the Dart stack.
  const stringified = String(err);
  const isDartRejection =
    stringified.includes('Dart exception thrown') ||
    stringified.includes('handle 999') ||
    (err && err.error); // presence of boxed Dart error
  if (isDartRejection) {
    console.log('OK: service-object methods are callable JS functions.');
    console.log('    (a Dart-side Future rejected — proving the JS call');
    console.log('     crossed the interop boundary and Dart code executed)');
  } else {
    console.error('FAIL: unexpected rejection:', stringified);
    process.exit(1);
  }
}
