import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { computeStage } from '../scripts/status.mjs';

const dir = join(dirname(fileURLToPath(import.meta.url)), 'fixtures');
for (const f of readdirSync(dir).filter((x) => x.endsWith('.json'))) {
  const { name, branches, artifacts, expected } = JSON.parse(readFileSync(join(dir, f), 'utf8'));
  test(name ?? f, () => assert.deepEqual(computeStage({ branches, artifacts }), expected));
}
