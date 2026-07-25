import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { projectIssue } from '../scripts/adapter.mjs';

const fixture = JSON.parse(
  readFileSync(new URL('./fixtures/issue-view.json', import.meta.url), 'utf8')
);

test('projectIssue maps scalar fields', () => {
  const t = projectIssue(fixture);
  assert.equal(t.id, 23464);
  assert.equal(t.title, fixture.title);
  assert.equal(t.body, fixture.body);
});

test('projectIssue passes comments through as {author, body, createdAt}, dropping extra keys', () => {
  const t = projectIssue(fixture);
  assert.equal(t.comments.length, 2);
  assert.deepEqual(t.comments[0], {
    author: { login: 'github-actions' },
    body: 'Hi there @reporter! Thanks for reporting this issue.',
    createdAt: '2026-07-23T09:27:53Z',
  });
  // faithful dump: author stays an object (TA7), not flattened to a string
  assert.equal(typeof t.comments[1].author, 'object');
});

test('projectIssue flattens labels to names', () => {
  const t = projectIssue(fixture);
  assert.deepEqual(t.labels, ['state/needs-investigation', 'area/backoffice']);
});

test('projectIssue leaves enriching fields empty (A6)', () => {
  const t = projectIssue(fixture);
  assert.equal(t.severity, undefined);
  assert.deepEqual(t.attachments, []);
  assert.deepEqual(t.links, []);
});
