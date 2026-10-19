export const projectRef = 'kciwxgfvpozgmnaypyxb';
const base = `https://api.supabase.com/v1/projects/${projectRef}`;
const getPaths = new Set(['', '/config/auth', '/database/migrations', '/storage/buckets', '/config/realtime', '/functions']);

export class AuditError extends Error {
  constructor(code) { super(code); this.code=code; }
}
export function requireArray(value) {
  if(!Array.isArray(value)) throw new AuditError('INVALID_RESPONSE');
  return value;
}
export function queryValue(value, field) {
  const rows=requireArray(value);
  if(!rows[0] || !Object.hasOwn(rows[0],field) || rows[0][field]===null) throw new AuditError('INVALID_RESPONSE');
  return rows[0][field];
}
export async function managementRead(path, token, { fetcher=fetch, query }={}) {
  if (!token) throw new AuditError('MISSING_MANAGEMENT_ACCESS');
  const isQuery=path==='/database/query/read-only';
  if ((!isQuery && !getPaths.has(path)) || (isQuery && typeof query!=='string')) throw new AuditError('DISALLOWED_ENDPOINT');
  let response;
  try {
    response=await fetcher(base+path,{method:isQuery?'POST':'GET',redirect:'error',signal:AbortSignal.timeout(15000),
      headers:{Authorization:`Bearer ${token}`,...(isQuery?{'Content-Type':'application/json'}:{})},
      ...(isQuery?{body:JSON.stringify({query})}:{})});
  } catch { throw new AuditError('NETWORK_UNAVAILABLE'); }
  // Never include management response/error bodies in exceptions or logs.
  if (!response.ok) throw new AuditError(`HTTP_${response.status}`);
  try { return await response.json(); } catch { throw new AuditError('INVALID_RESPONSE'); }
}
const bool=value=>typeof value==='boolean'?value:null;
const number=value=>typeof value==='number'&&Number.isFinite(value)?value:null;
export function summarizeAuth(raw) {
  const providers=['twilio','twilio_verify','messagebird','vonage','textlocal'];
  return {
    phoneEnabled:bool(raw.external_phone_enabled), signupDisabled:bool(raw.disable_signup),
    phoneAutoConfirm:bool(raw.sms_autoconfirm), captchaEnabled:bool(raw.security_captcha_enabled),
    smsProvider:providers.includes(raw.sms_provider)?raw.sms_provider:'unknown',
    otpLength:number(raw.sms_otp_length), otpExpirySeconds:number(raw.sms_otp_exp),
    testOtpConfigured:typeof raw.sms_test_otp==='string'&&raw.sms_test_otp.length>0,
    smsTemplatePresent:typeof raw.sms_template==='string'&&raw.sms_template.length>0,
    providerFieldsPresent:Object.fromEntries([
      'sms_twilio_account_sid','sms_twilio_auth_token','sms_twilio_message_service_sid',
      'sms_twilio_verify_account_sid','sms_twilio_verify_auth_token','sms_twilio_verify_message_service_sid',
      'sms_messagebird_access_key','sms_vonage_api_key','sms_vonage_api_secret','sms_textlocal_api_key',
    ].map(key=>[key,typeof raw[key]==='string'&&raw[key].length>0])),
    // Presence does not prove credentials, sender registration, or delivery work.
  };
}
export function reconciliationFindings(inventory, localTables) {
  if (!inventory || !Array.isArray(inventory.relations)) return {status:'unverified',autoApplyAllowed:false};
  const collisions=inventory.relations.filter(row=>row.schema==='public'&&localTables.includes(row.name)).map(row=>row.name);
  const routines=(inventory.functions??[]).filter(row=>['access_profile','complete_onboarding','require_available_service','has_admin','bootstrap_profile'].includes(row.name)).map(row=>`${row.schema}.${row.name}`);
  const unprotected=inventory.relations.filter(row=>row.schema==='public'&&['r','p'].includes(row.kind)&&!row.rls).map(row=>row.name);
  return {status:collisions.length||routines.length?'existing_objects_require_comparison':'baseline_candidate_requires_review',
    collidingTables:collisions,collidingFunctions:routines,publicTablesWithoutRls:unprotected,autoApplyAllowed:false,
    dataPreservation:'Estimates do not prove empty tables. Confirm aggregate counts, backups, identities, and migration history before any migration.'};
}

export function compareCatalogs(live, expected) {
  if(!live || !Array.isArray(live.relations)) return {status:'unverified',autoApplyAllowed:false,differences:[]};
  const differences=[];
  for(const target of expected.relations.filter(row=>['public','private'].includes(row.schema))) {
    const actual=live.relations.find(row=>row.schema===target.schema&&row.name===target.name);
    if(!actual) {differences.push({object:`${target.schema}.${target.name}`,issue:'missing_relation'});continue;}
    for(const field of ['kind','rls','forceRls','securityInvoker','viewDefinitionHash']) if(actual[field]!==target[field]) differences.push({object:`${target.schema}.${target.name}`,issue:`different_${field}`});
    for(const column of target.columns) {
      const actualColumn=actual.columns?.find(value=>value.name===column.name);
      if(!actualColumn || ['type','notNull','hasDefault','defaultHash'].some(key=>actualColumn[key]!==column[key])) differences.push({object:`${target.schema}.${target.name}.${column.name}`,issue:'missing_or_different_column'});
    }
    for(const column of actual.columns??[]) if(!target.columns.some(value=>value.name===column.name)) differences.push({object:`${target.schema}.${target.name}.${column.name}`,issue:'additional_live_column_preserve'});
  }
  for(const [section,keys] of [['policies',['schema','table','name']],['functions',['schema','name','arguments']],['constraints',['schema','table','name']],['triggers',['schema','table','name']]]) {
    const targets=(expected[section]??[]).filter(row=>section==='triggers'?row.name==='rydvia_auth_user_created':['public','private'].includes(row.schema));
    for(const target of targets) {
      const actual=(live[section]??[]).find(row=>keys.every(key=>row[key]===target[key]));
      if(!actual || canonical(actual)!==canonical(target)) differences.push({object:keys.map(key=>target[key]).join('.'),issue:`missing_or_different_${section}`});
    }
    // Extra permissive policies can silently bypass otherwise-correct RLS.
    if(section==='policies') for(const actual of live.policies??[]) {
      if(expected.relations.some(row=>row.schema===actual.schema&&row.name===actual.table)&&!targets.some(target=>keys.every(key=>actual[key]===target[key]))) differences.push({object:`${actual.schema}.${actual.table}.${actual.name}`,issue:'additional_live_policy_requires_review'});
    }
  }
  const expectedGrants=(expected.grants??[]).filter(row=>['public','private'].includes(row.schema));
  for(const target of expectedGrants) if(!(live.grants??[]).some(actual=>['schema','table','role','privilege'].every(key=>actual[key]===target[key]))) differences.push({object:`${target.schema}.${target.table}`,issue:`missing_grant_${target.role}_${target.privilege}`});
  for(const actual of live.grants??[]) {
    if(expected.relations.some(row=>row.schema===actual.schema&&row.name===actual.table)&&!expectedGrants.some(target=>['schema','table','role','privilege'].every(key=>actual[key]===target[key]))) differences.push({object:`${actual.schema}.${actual.table}`,issue:`additional_live_grant_${actual.role}_${actual.privilege}`});
  }
  for(const target of expected.functionGrants??[]) if(!(live.functionGrants??[]).some(actual=>canonical(actual)===canonical(target))) differences.push({object:`${target.schema}.${target.name}`,issue:'missing_function_grant'});
  for(const actual of live.functionGrants??[]) if(expected.functions.some(row=>row.schema===actual.schema&&row.name===actual.name)&&!(expected.functionGrants??[]).some(target=>canonical(actual)===canonical(target))) differences.push({object:`${actual.schema}.${actual.name}`,issue:`additional_function_grant_${actual.role}`});
  for(const actual of live.triggers??[]) if(actual.schema==='auth'&&actual.table==='users'&&!expected.triggers.some(target=>target.schema===actual.schema&&target.table===actual.table&&target.name===actual.name)) differences.push({object:`auth.users.${actual.name}`,issue:'additional_signup_trigger_preserve_review'});
  return {status:differences.length?'reconciliation_required':'matching_objects_require_migration_history_and_data_review',autoApplyAllowed:false,differences};
}
function canonical(value) {
  if(Array.isArray(value)) return JSON.stringify(value.map(item=>JSON.parse(canonical(item))));
  if(value&&typeof value==='object') return JSON.stringify(Object.fromEntries(Object.keys(value).sort().map(key=>[key,JSON.parse(canonical(value[key]))])));
  return JSON.stringify(value);
}
