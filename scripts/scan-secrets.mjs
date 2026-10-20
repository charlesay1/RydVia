import { scanRepository } from './lib/secret-scan.mjs';

try {
  const args = process.argv.slice(2);
  if (args.some(arg => !['--staged', '--history'].includes(arg))) throw new Error('Invalid arguments');
  const result = scanRepository(process.cwd(), { staged: args.includes('--staged'), history: args.includes('--history') });
  console.log(JSON.stringify({ status: result.findings.length ? 'FAIL' : 'PASS', ...result }));
  if (result.findings.length) process.exitCode = 1;
} catch {
  console.error('FAIL: secret scan could not complete. Check Git access, readable files and full history (--history requires a non-shallow checkout). Details suppressed to protect credentials.');
  process.exitCode = 2;
}
