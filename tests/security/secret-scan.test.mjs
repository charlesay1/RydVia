import assert from 'node:assert/strict';
import { spawnSync, execFileSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, renameSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import { scanContent, sensitivePath } from '../../scripts/lib/secret-scan.mjs';

const cli = fileURLToPath(new URL('../../scripts/scan-secrets.mjs', import.meta.url));
// Inert synthetic values assembled at runtime. No real credential is used or
// committed; the same strong patterns still apply to this test file in CI.
const forbidden = 'sb_secret_' + 'X'.repeat(24);
const payload = 'X'.repeat(32);
function jwt(role) {
  const segment = data => Buffer.from(JSON.stringify(data)).toString('base64url');
  return `${segment({ alg: 'HS256' })}.${segment({ role })}.synthetic`;
}

test('retains every existing strong credential rule', () => {
  const cases = [
    ['private-key', ['-----BEGIN ', 'PRIVATE KEY-----'].join('')],
    ['private-key', ['-----BEGIN ', 'DSA PRIVATE KEY-----'].join('')],
    ['supabase-secret', forbidden],
    ['supabase-management-token', 'sbp_' + payload],
    ['github-token', 'ghp_' + payload],
    ['github-token', 'github_pat_' + payload],
    ['aws-access-key', 'AKIA' + 'X'.repeat(16)],
    ['stripe-secret', 'sk_live_' + payload],
    ['slack-token', 'xoxb-' + payload],
    ['credential-url', 'postgresql://' + 'user:' + payload + '@example.invalid/db'],
  ];
  for (const [rule, value] of cases) assert.ok(scanContent(value).includes(rule), rule);
});

test('recognizes service-role and other embedded JWTs without returning values', () => {
  assert.deepEqual(scanContent(jwt('service_role')), ['service-role-jwt']);
  assert.deepEqual(scanContent(jwt('authenticated')), ['embedded-jwt-review']);
});

test('distinguishes detection strings and fixtures from literal assignments', () => {
  for (const text of ['service_role', 'sb_secret_', 'sb_secret_test', 'process.env.SUPABASE_ACCESS_TOKEN',
    'TWILIO_AUTH_TOKEN="env(SERVER_SMS_TOKEN)"', 'JWT_SECRET: "sensitive-fixture"',
    'SUPABASE_ACCESS_TOKEN="${SERVER_TOKEN}"']) {
    assert.deepEqual(scanContent(text), []);
  }
  for (const key of ['SUPABASE_SECRET_KEY', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_ACCESS_TOKEN',
    'DATABASE_PASSWORD', 'PGPASSWORD', 'TWILIO_AUTH_TOKEN', 'sms_twilio_auth_token', 'SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN', 'JWT_SECRET', 'API_SECRET']) {
    for (const value of [payload, `"${payload}"`, `'${payload}'`]) {
      assert.ok(scanContent(`${key}=${value}`).includes('credential-assignment'), key);
      assert.ok(scanContent(JSON.stringify({ [key]: payload })).includes('credential-assignment'), key);
    }
  }
  assert.ok(scanContent('fixture-' + forbidden).includes('supabase-secret'));
});

test('protects sensitive paths while permitting blank public templates', () => {
  for (const path of ['.env', '.env.local', '.env.production.local', 'apps/admin_web/.env',
    'signing.p8', 'signing.pem', 'credentials.json', '.ssh/id_rsa', '.aws/credentials', 'key.properties']) {
    assert.equal(sensitivePath(path), true, path);
  }
  for (const path of ['.env.example', 'apps/admin_web/.env.example', 'src/auth.ts']) assert.equal(sensitivePath(path), false);
});

function repository(fn) {
  const prefix = join(tmpdir(), 'rydvia-secret-scan-');
  const root = mkdtempSync(prefix);
  const git = (...args) => execFileSync('git', args, {
    cwd: root, stdio: ['ignore', 'pipe', 'pipe'],
    env: { ...process.env, GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: process.platform === 'win32' ? 'NUL' : '/dev/null' },
  });
  const commit = () => {
    git('add', '.');
    git('-c', 'user.name=Scanner Test', '-c', 'user.email=scanner@example.invalid', '-c', 'commit.gpgsign=false', 'commit', '-m', 'Scanner fixture');
  };
  const run = (...args) => spawnSync(process.execPath, [cli, ...args], { cwd: root, encoding: 'utf8' });
  try { git('init', '--quiet'); fn({ root, git, commit, run }); }
  finally {
    // Delete only the directory created above, never a computed repository path.
    assert.ok(resolve(root).startsWith(resolve(prefix)));
    rmSync(root, { recursive: true, force: true });
  }
}

function redactedFailure(result, value) {
  assert.equal(result.status, 1);
  assert.ok(!result.stdout.includes(value));
  assert.ok(!result.stderr.includes(value));
  const output = JSON.parse(result.stdout);
  assert.equal(output.status, 'FAIL');
  assert.ok(output.findings.length > 0);
  assert.ok(output.findings.every(f => f.value === '[REDACTED]'));
  return output;
}

test('CLI fails safely on forbidden content and passes after removal', () => repository(({ root, run }) => {
  writeFileSync(join(root, 'fixture.txt'), forbidden);
  redactedFailure(run(), forbidden);
  writeFileSync(join(root, 'fixture.txt'), 'No credentials');
  assert.equal(run().status, 0);
}));

test('staged scan inspects index blobs rather than cleaner working files', () => repository(({ root, git, run }) => {
  writeFileSync(join(root, 'fixture.txt'), forbidden);
  git('add', 'fixture.txt');
  writeFileSync(join(root, 'fixture.txt'), 'No credentials');
  assert.equal(run().status, 0);
  redactedFailure(run('--staged'), forbidden);
}));

test('redacts a forbidden value even if it appears in a filename', () => repository(({ root, run }) => {
  writeFileSync(join(root, forbidden + '.txt'), forbidden);
  const result = redactedFailure(run(), forbidden);
  assert.ok(result.findings.every(f => f.file === '[REDACTED PATH]'));
}));

test('full history detects credentials removed from the current checkout', () => repository(({ root, commit, run }) => {
  writeFileSync(join(root, 'fixture.txt'), forbidden);
  commit();
  writeFileSync(join(root, 'fixture.txt'), 'No credentials');
  commit();
  assert.equal(run().status, 0);
  const output = redactedFailure(run('--history'), forbidden);
  assert.ok(output.findings.some(f => f.scope === 'history'));
}));

test('history scan refuses a shallow repository instead of silently passing', () => repository(({ root, git, commit, run }) => {
  writeFileSync(join(root, 'fixture.txt'), 'No credentials');
  commit();
  writeFileSync(join(root, '.git', 'shallow'), git('rev-parse', 'HEAD').toString());
  const result = run('--history');
  assert.equal(result.status, 2);
  assert.match(result.stderr, /Details suppressed/);
}));

test('history checks sensitive paths even when blob content is already known', () => repository(({ root, commit, run }) => {
  writeFileSync(join(root, 'fixture.txt'), 'Non-secret placeholder');
  commit();
  renameSync(join(root, 'fixture.txt'), join(root, '.env'));
  commit();
  renameSync(join(root, '.env'), join(root, 'fixture.txt'));
  commit();
  assert.equal(run().status, 0);
  const result = run('--history');
  assert.equal(result.status, 1);
  assert.ok(JSON.parse(result.stdout).findings.some(f => f.file === '.env' && f.scope === 'history'));
}));

test('invalid arguments fail closed with no raw subprocess output', () => {
  const result = spawnSync(process.execPath, [cli, '--invalid-option'], { encoding: 'utf8' });
  assert.equal(result.status, 2);
  assert.match(result.stderr, /Details suppressed/);
});

test('Git failures do not leak raw subprocess diagnostics', () => {
  const diagnostic = join(tmpdir(), 'rydvia-scanner-missing-git-dir');
  const result = spawnSync(process.execPath, [cli], { encoding: 'utf8', env: { ...process.env, GIT_DIR: diagnostic } });
  assert.equal(result.status, 2);
  assert.ok(!result.stderr.includes(diagnostic));
  assert.match(result.stderr, /Details suppressed/);
});
