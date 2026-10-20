// @vitest-environment node
import { it,expect,vi } from 'vitest';
import { managementRead,summarizeAuth,reconciliationFindings,compareCatalogs,requireArray,queryValue } from '../../scripts/lib/supabase-audit.mjs';
import { localCatalog } from '../../scripts/lib/local-supabase-catalog.mjs';
it('limits management access to approved read-only endpoints and never follows redirects',async()=>{
  const fetcher=vi.fn(async()=>new Response('[]',{status:200}));
  await managementRead('/database/query/read-only','fixture-token',{fetcher,query:'select 1'});
  expect(fetcher.mock.calls[0][0]).toBe('https://api.supabase.com/v1/projects/kciwxgfvpozgmnaypyxb/database/query/read-only');
  expect(fetcher.mock.calls[0][1]).toMatchObject({method:'POST',redirect:'error'});
  await expect(managementRead('/database/query','fixture-token',{fetcher,query:'select 1'})).rejects.toThrow('DISALLOWED_ENDPOINT');
  await expect(managementRead('/config/auth','',{fetcher})).rejects.toThrow('MISSING_MANAGEMENT_ACCESS');
});
it('omits provider secrets, signing keys, test OTP values, and unrelated configuration',()=>{
  const summary=summarizeAuth({external_phone_enabled:true,sms_provider:'twilio',sms_otp_length:6,sms_twilio_auth_token:'sensitive-provider-secret',sms_test_otp:'sensitive-test-code',jwt_secret:'sensitive-signing-key'});
  expect(summary.phoneEnabled).toBe(true);
  expect(summary.providerFieldsPresent.sms_twilio_auth_token).toBe(true);
  expect(JSON.stringify(summary)).not.toContain('sensitive-');
});
it('never interprets malformed or unavailable inventory as empty schema/history',()=>{
  expect(()=>requireArray({error:'unavailable'})).toThrow('INVALID_RESPONSE');
  expect(()=>queryValue([],'inventory')).toThrow('INVALID_RESPONSE');
  expect(()=>queryValue([{inventory:null}],'inventory')).toThrow('INVALID_RESPONSE');
  expect(queryValue([{user_count:0}],'user_count')).toBe(0);
});
it('does not print remote error bodies or tokens and never approves automatic migrations',async()=>{
  const fetcher=vi.fn(async()=>new Response('private body fixture-token',{status:403}));
  await expect(managementRead('/config/auth','fixture-token',{fetcher})).rejects.toThrow('HTTP_403');
  expect(reconciliationFindings({relations:[{schema:'public',name:'profiles',kind:'r',rls:false}],functions:[]},['profiles'])).toMatchObject({autoApplyAllowed:false,status:'existing_objects_require_comparison',publicTablesWithoutRls:['profiles']});
  expect(reconciliationFindings({relations:[],functions:[]},['profiles']).autoApplyAllowed).toBe(false);
  expect(reconciliationFindings(null,['profiles']).status).toBe('unverified');
});
it('derives a fresh local baseline and detects RLS, view, grant, and policy drift without authorizing changes',async()=>{
  const local=await localCatalog(new URL('../../',import.meta.url));
  expect(local.migrations).toEqual(['20261019000000','20261019000100','20261019000200','20261019000300']);
  expect(compareCatalogs(local.inventory,local.inventory)).toMatchObject({status:'matching_objects_require_migration_history_and_data_review',autoApplyAllowed:false});
  const changed=structuredClone(local.inventory);
  changed.relations.find((row:{name:string})=>row.name==='profiles').rls=false;
  changed.relations.find((row:{name:string})=>row.name==='available_services').securityInvoker=false;
  changed.policies.push({schema:'public',table:'profiles',name:'unexpected_allow_all'});
  changed.functionGrants.push({schema:'public',name:'complete_onboarding',arguments:'display_name_input text, requested_role text',role:'anon',privilege:'EXECUTE'});
  const result=compareCatalogs(changed,local.inventory);
  expect(result.autoApplyAllowed).toBe(false);
  expect(result.differences.map((row:{issue:string})=>row.issue)).toEqual(expect.arrayContaining(['different_rls','different_securityInvoker','additional_live_policy_requires_review','additional_function_grant_anon']));
});
