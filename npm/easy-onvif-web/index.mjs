// Browser entry point for easy-onvif-web.
//
// Fetches `./dist/easy_onvif.wasm` relative to this module, instantiates it
// via the dart2wasm init loader, and returns the `globalThis.EasyOnvif`
// API object.
//
// Works in any modern browser that supports WasmGC (Chromium 119+, Firefox
// 120+, Safari 18.2+).

let _apiPromise = null;

/**
 * Resolves the URL of a bundled asset relative to this module. Host
 * bundlers (Vite, webpack 5, Parcel) understand `new URL(..., import.meta.url)`
 * and will emit the WASM file into the output directory automatically.
 */
function assetUrl(relative) {
  return new URL(relative, import.meta.url).toString();
}

/**
 * Loads the WebAssembly bundle (once, lazily) and returns the ONVIF API.
 *
 * @returns {Promise<EasyOnvifApi>}
 */
export async function loadEasyOnvif() {
  if (_apiPromise) return _apiPromise;

  _apiPromise = (async () => {
    const { compileStreaming } = await import(
      assetUrl('./dist/easy_onvif.mjs')
    );

    const response = fetch(assetUrl('./dist/easy_onvif.wasm'));
    const app = await compileStreaming(response);
    const instance = await app.instantiate({});

    // main() registers globalThis.EasyOnvif
    instance.invokeMain();

    const api = globalThis.EasyOnvif;

    if (!api) {
      throw new Error(
        'easy-onvif-web: WASM module did not expose globalThis.EasyOnvif.',
      );
    }

    return api;
  })();

  return _apiPromise;
}

export default loadEasyOnvif;
