// Node.js entry point for easy-onvif-node.
//
// Loads the dart2js bundle from `./dist/easy_onvif.js`. That script
// runs its `main()` on load, which stashes `globalThis.EasyOnvif`.

import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DIST = resolve(__dirname, 'dist');

// We use CommonJS `require` so the compiled dart2js bundle (which is a
// classic script, not an ES module) executes in the current global scope
// and can see `globalThis`. `import()` would wrap it in a module scope
// and strip the global side-effect we depend on.
const require = createRequire(import.meta.url);

let _apiPromise = null;

/**
 * Loads the dart2js bundle (once, lazily) and returns the ONVIF API
 * object. Subsequent calls return the same cached instance.
 *
 * IMPORTANT: call this from inside an async function / `.then()` callback,
 * **not** from a top-level module `await`. dart2js compiles Dart's async
 * scheduler as a microtask trampoline; when driven from a top-level module
 * `await` in Node.js >= 25 some checkpoint ticks are skipped, which breaks
 * dgram 'message' callbacks (WS-Discovery). Wrapping in an IIFE is safe:
 *
 *   (async () => {
 *     const api = await loadEasyOnvif();
 *     const matches = await api.probe(3);
 *   })();
 *
 * @returns {Promise<EasyOnvifApi>}
 */
export async function loadEasyOnvif() {
  if (_apiPromise) return _apiPromise;

  _apiPromise = (async () => {
    // Side-effect import: running the bundle registers `globalThis.EasyOnvif`.
    // We pre-inject the CJS `require` function on `globalThis` so that Dart's
    // `@JS('globalThis.require')` bindings (used for `node:dgram` etc.) work
    // when this package is loaded from an ES-module context, where `require`
    // is not on `globalThis` by default.
    globalThis.__easyOnvifRequire = require;
    require(resolve(DIST, 'easy_onvif.js'));

    const api = globalThis.EasyOnvif;

    if (!api) {
      throw new Error(
        'easy-onvif-node: dart2js bundle did not expose globalThis.EasyOnvif.',
      );
    }

    return api;
  })();

  return _apiPromise;
}

export default loadEasyOnvif;
