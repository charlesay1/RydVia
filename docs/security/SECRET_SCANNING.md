# CI secret scanning

The `secret-scan` job in `.github/workflows/ci.yml` runs on pushes to `main` and
pull requests. Flutter, web/database and disposable Supabase jobs depend on its
success. Permissions remain `contents: read`; the scan checkout uses
`fetch-depth: 0` and `persist-credentials: false`. No production credentials or
package installation are required by this job.

`scripts/lib/secret-scan.mjs` promotes the existing checkpoint scanner's rules into
the tracked source of truth. `scripts/verify-repository.ps1` now delegates to it,
retaining origin and environment/signing ignore checks. The earlier ignored
`.artifacts/checkpoint-scan.mjs` is a historical local artifact, not the CI scanner.

Commands (Node 24 and Git required):

```sh
node --test tests/security/secret-scan.test.mjs
node scripts/scan-secrets.mjs
node scripts/scan-secrets.mjs --staged
node scripts/scan-secrets.mjs --history
```

The default scans tracked and non-ignored untracked files, without extension
filtering. `--staged` scans index blobs. `--history` also checks all blobs/paths
reachable from fetched refs and HEAD, including credentials removed from current
files. Shallow history, unreadable files and Git errors fail closed. Ignored,
untracked local secrets, unfetched remote refs and unreachable Git objects are
outside this CI scan. Symlinks are inspected without following external targets.

Detection retains private-key, Supabase secret/management, GitHub, AWS, Stripe,
Slack, embedded JWT, credential URL, literal-assignment and sensitive-path rules.
Literal assignment coverage additionally includes Supabase secret-key variables,
JWT secrets and SMS-provider token fields. Existing placeholder/environment
references and short negative-validation fixtures remain supported. Strong token
and private-key patterns apply to tests too; no directory-wide bypass is used.

Output includes only scope, path, rule, optional commit and `[REDACTED]`; suspicious
paths are redacted too. Subprocess stderr and raw matched lines are never emitted.
Exit codes: 0 clean, 1 findings, 2 incomplete/error. Reports are not written to disk.
Tests assemble inert forbidden values at runtime in temporary repositories and
prove failure/redaction, staged/history coverage and shallow-checkout refusal.

This is pattern-based detection, not a guarantee against every novel/encoded
secret. Branch protection must require `secret-scan` (or all validation jobs) to
block merging; this repository change does not configure GitHub rulesets. Review
findings without pasting values, and handle any confirmed exposure through a
separately authorized incident process.

References: [checkout behavior](https://github.com/actions/checkout),
[workflow permissions and dependencies](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).
