// Release-time check for the `easy-onvif-mcp` bin wiring.
//
// npm publishes a `bin` entry as the command an MCP host launches, so a missing
// target, a missing shebang, or a non-executable mode produces a package that
// installs cleanly and then never starts. Verified here instead of on a host.

import assert from 'node:assert/strict';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const pkg = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const { bin } = JSON.parse(readFileSync(resolve(pkg, 'package.json'), 'utf8'));

const entries = Object.entries(bin ?? {});
assert.ok(entries.length > 0, 'package.json declares no bin entries');

for (const [command, target] of entries) {
  const file = resolve(pkg, target);
  assert.ok(existsSync(file), `${command}: bin target missing (${target})`);
  assert.match(
    readFileSync(file, 'utf8'),
    /^#!.*\bnode\b/,
    `${command}: ${target} has no node shebang`,
  );
  assert.ok(
    statSync(file).mode & 0o111,
    `${command}: ${target} is not executable`,
  );
}

console.log(`OK: ${entries.length} bin entr${entries.length === 1 ? 'y' : 'ies'} wired.`);
