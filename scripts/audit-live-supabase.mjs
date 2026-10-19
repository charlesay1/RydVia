import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve, dirname } from 'node:path';
import { managementRead, summarizeAuth, reconciliationFindings, compareCatalogs, requireArray, queryValue, projectRef } from './lib/supabase-audit.mjs';
import { localCatalog } from './lib/local-supabase-catalog.mjs';

const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const token=process.env.SUPABASE_ACCESS_TOKEN;
if(!token) {
  console.error('MISSING_MANAGEMENT_ACCESS: connect Supabase or supply an authorized token through the process environment, never arguments or a client .env file.');
  process.exitCode=2;
} else {
  const catalog=await readFile(resolve(root,'supabase/audit/catalog.sql'),'utf8');
  const baseline=await readFile(resolve(root,'supabase/migrations/20261019000100_identity_services.sql'),'utf8');
  const tables=[...baseline.matchAll(/create table public\.([a-z_]+)/g)].map(match=>match[1]);
  const report={projectRef,capturedAt:new Date().toISOString(),mode:'read-only',sections:{}};
  const requests=[
    ['project','',value=>({status:value.status??null})],
    ['auth','/config/auth',summarizeAuth],
    ['migrations','/database/migrations',value=>requireArray(value).map(row=>({version:typeof row==='string'?row:row.version}))],
    ['storage','/storage/buckets',value=>requireArray(value).map(row=>({id:row.id,name:row.name,public:row.public}))],
    ['realtime','/config/realtime',value=>({privateOnly:typeof value.private_only==='boolean'?value.private_only:null})],
    ['edgeFunctions','/functions',value=>requireArray(value).map(row=>({slug:row.slug,status:row.status,verifyJwt:row.verify_jwt,version:row.version}))],
    ['catalog','/database/query/read-only',value=>queryValue(value,'inventory'),catalog],
    ['authUserCount','/database/query/read-only',value=>queryValue(value,'user_count'),'select pg_catalog.count(*)::bigint as user_count from auth.users;'],
  ];
  for(const [name,path,summarize,query] of requests) {
    try { report.sections[name]={status:'read',summary:summarize(await managementRead(path,token,{query}))}; }
    catch(error) { report.sections[name]={status:'unavailable',reason:error.code??'AUDIT_FAILED'}; }
  }
  report.findings=reconciliationFindings(report.sections.catalog?.summary,tables);
  const expected=await localCatalog(new URL('../',import.meta.url));
  report.localMigrations=expected.migrations;
  report.comparison=compareCatalogs(report.sections.catalog?.summary,expected.inventory);
  const output=resolve(root,'.artifacts/supabase-audit.json');
  await mkdir(dirname(output),{recursive:true});
  await writeFile(output,JSON.stringify(report,null,2)+'\n',{mode:0o600});
  const complete=Object.values(report.sections).every(section=>section.status==='read')
    && Array.isArray(report.sections.catalog?.summary?.relations)
    && typeof report.sections.auth?.summary?.phoneEnabled==='boolean';
  console.log(`${complete?'READ_COMPLETE':'READ_PARTIAL'}: sanitized audit saved under ignored .artifacts; no migrations or configuration changes performed.`);
  if(!complete) process.exitCode=2;
}
