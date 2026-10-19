import { spawn } from 'node:child_process';
import { setTimeout } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import { resolve, dirname } from 'node:path';
import assert from 'node:assert/strict';

const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const child=spawn(process.execPath,[resolve(root,'node_modules/next/dist/bin/next'),'start','--hostname','127.0.0.1','--port','3101'],{
  cwd:resolve(root,'apps/admin_web'),stdio:'ignore',windowsHide:true,
  env:{...process.env,NODE_ENV:'production',NEXT_TELEMETRY_DISABLED:'1',SUPABASE_URL:'',SUPABASE_PUBLISHABLE_KEY:''},
});
let failed=false;
child.on('error',()=>{failed=true;});
const base='http://127.0.0.1:3101';
try {
  let ready=false;
  for(let attempt=0;attempt<100;attempt++) {
    if(failed || child.exitCode!==null) throw new Error('ADMIN_TEST_SERVER_START_FAILED');
    try {await fetch(base+'/api/access',{signal:AbortSignal.timeout(500)});ready=true;break;} catch {await setTimeout(100);}
  }
  assert(ready,'ADMIN_TEST_SERVER_TIMEOUT');
  const access=await fetch(base+'/api/access');
  assert.equal(access.status,503);
  assert.deepEqual(await access.json(),{authorized:false});
  assert.match(access.headers.get('cache-control')??'',/no-store/);
  for(const path of ['/','/login']) {
    const response=await fetch(base+path);
    const html=await response.text();
    assert(html.includes('Admin authentication unavailable'));
    assert(!html.includes('DEMO-1048'));
    assert(!html.includes('Welcome to RydVia Admin'));
  }
  const forged=await fetch(base+'/api/access',{headers:{Cookie:'rydvia-admin-auth.0=forged-admin-session'}});
  assert.equal(forged.status,503);
  console.log('PASS: production Next.js HTTP checks fail closed without configuration; page/API expose no fixture dashboard, including a forged-cookie request. No live credentials or OTPs used.');
} finally {
  child.kill();
}
