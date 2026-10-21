import { fileURLToPath } from 'node:url';
import { inspectBrandAssets } from './lib/brand-assets.mjs';
try {
  const args = process.argv.slice(2);
  if (args.some(arg=>arg!=='--release')) throw new Error('Invalid arguments');
  const report = inspectBrandAssets(fileURLToPath(new URL('../',import.meta.url)));
  const fail = report.issues.length > 0 || (args.includes('--release') && !report.productionReady);
  console.log(JSON.stringify({status:fail?'BLOCKED':'PASS',...report,mode:args.includes('--release')?'release-gate':'development-audit'}));
  if (fail) process.exitCode=1;
} catch { console.error('BLOCKED: brand audit could not complete. No release approval granted.'); process.exitCode=2; }
