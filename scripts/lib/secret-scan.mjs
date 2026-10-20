import { execFileSync } from 'node:child_process';
import { lstatSync, readFileSync, readlinkSync } from 'node:fs';
import { resolve } from 'node:path';

// Promoted from the existing checkpoint scanner. Strong credential patterns
// apply even to tests: construct inert negative-test values at runtime instead
// of adding a directory-wide allowlist.
const rules = [
  ['private-key', /-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----/],
  ['supabase-secret', /sb_secret_[A-Za-z0-9_-]{20,}/],
  ['supabase-management-token', /sbp_[A-Za-z0-9]{20,}/],
  ['github-token', /(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,})/],
  ['aws-access-key', /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/],
  ['stripe-secret', /\bsk_(?:live|test)_[A-Za-z0-9]{20,}/],
  ['slack-token', /\bxox[baprs]-[A-Za-z0-9-]{20,}/],
  ['credential-url', /\b(?:postgres(?:ql)?|https?):\/\/[^\s/:]+:[^\s@/]+@/],
];

export function scanContent(content) {
  const found = new Set(rules.filter(([, pattern]) => pattern.test(content)).map(([name]) => name));
  for (const match of content.matchAll(/\beyJ[A-Za-z0-9_-]+\.([A-Za-z0-9_-]+)\.[A-Za-z0-9_-]+/g)) {
    try {
      const claims = JSON.parse(Buffer.from(match[1], 'base64url').toString());
      found.add(claims.role === 'service_role' ? 'service-role-jwt' : 'embedded-jwt-review');
    } catch { /* Preserve malformed, synthetic key-validation fixtures. */ }
  }
  // Retain existing placeholder handling; provider-specific patterns above
  // cannot be bypassed by putting a fixture marker before a forbidden token.
  const assignment = /\b(?:SUPABASE_SECRET_KEY|SUPABASE_SERVICE_ROLE_KEY|SUPABASE_ACCESS_TOKEN|DATABASE_PASSWORD|PGPASSWORD|(?:SUPABASE_AUTH_SMS_|sms_)?TWILIO_AUTH_TOKEN|JWT_SECRET|API_SECRET)\b["']?\s*[:=]\s*(?:"([^"\r\n]*)"|'([^'\r\n]*)'|([^\s,;#}\]]+))/gi;
  for (const match of content.matchAll(assignment)) {
    const value = match[1] ?? match[2] ?? match[3];
    if (value && !/^(?:fixture|test|example|placeholder|\$\{|\$\(|env\(|process\.|sensitive-)/i.test(value)) {
      found.add('credential-assignment');
    }
  }
  return [...found];
}

export function sensitivePath(file) {
  return (/(^|\/)\.env(?:$|\.)/.test(file) && file !== '.env.example' && !file.endsWith('/.env.example')) ||
    /(?:\.(?:pem|key|p8|p12|pfx|jks|keystore|mobileprovision|provisionprofile)$|(^|\/)(?:\.git-credentials|\.netrc|_netrc|\.npmrc|\.pypirc|credentials\.json|key\.properties)$|(^|\/)(?:\.aws|\.ssh|\.tools|\.artifacts|node_modules|\.next|\.dart_tool)\/)/i.test(file);
}

// Git errors may include captured file content. Never forward subprocess errors
// or raw stderr to CI. All scanner errors fail closed with a fixed message.
function git(root, ...args) {
  return execFileSync('git', args, {
    cwd: root, maxBuffer: 64 * 1024 * 1024, stdio: ['ignore', 'pipe', 'pipe'],
    env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' },
  });
}

function safePath(file) {
  return scanContent(file).length ? '[REDACTED PATH]' : file;
}

export function scanRepository(root, { staged = false, history = false } = {}) {
  // A relative invocation from a package still scans the whole repository.
  root = git(root, 'rev-parse', '--show-toplevel').toString().trim();
  const files = [...new Set(git(root, 'ls-files', ...(staged ? ['--cached'] : ['--cached', '--others', '--exclude-standard']), '-z').toString().split('\0').filter(Boolean))];
  const findings = [];
  function inspect(file, content, scope, commit) {
    const detected = scanContent(content);
    if (sensitivePath(file)) detected.push('sensitive-or-generated-path');
    for (const rule of detected) findings.push({ file: safePath(file), rule, scope, ...(commit ? { commit } : {}), value: '[REDACTED]' });
  }
  for (const file of files) {
    let bytes;
    if (staged) bytes = git(root, 'show', `:${file}`);
    else {
      const path = resolve(root, file);
      // Inspect the link itself, never follow a tracked link outside the repo.
      bytes = lstatSync(path).isSymbolicLink() ? Buffer.from(readlinkSync(path)) : readFileSync(path);
    }
    inspect(file, bytes.toString('utf8'), staged ? 'staged' : 'working-tree');
  }
  let historyBlobs = 0;
  if (history) {
    if (git(root, 'rev-parse', '--is-shallow-repository').toString().trim() !== 'false') {
      throw new Error('Full history required');
    }
    const commits = git(root, 'rev-list', '--all', 'HEAD').toString().trim().split('\n').filter(Boolean);
    const seen = new Set();
    const contents = new Map();
    for (const commit of commits) {
      const entries = git(root, 'ls-tree', '-r', '-z', commit).toString().split('\0').filter(Boolean);
      for (const entry of entries) {
        const tab = entry.indexOf('\t');
        const [, type, object] = entry.slice(0, tab).split(' ');
        if (type !== 'blob') continue;
        const file = entry.slice(tab + 1);
        const key = `${object}\0${file}`;
        if (seen.has(key)) continue;
        seen.add(key);
        // Deduplicate content reads, but check every historical path as well.
        if (!contents.has(object)) contents.set(object, git(root, 'cat-file', 'blob', object).toString('utf8'));
        inspect(file, contents.get(object), 'history', commit);
      }
    }
    historyBlobs = contents.size;
  }
  return { mode: staged ? 'staged' : 'working-tree', files: files.length, history, historyBlobs, findings };
}
