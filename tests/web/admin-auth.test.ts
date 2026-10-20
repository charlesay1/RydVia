// @vitest-environment node
import { describe, it, expect, vi } from 'vitest';
import { authorizeAdmin, type AdminAccess } from '../../apps/admin_web/lib/auth/access';
import { adminConfig, ghanaPhone } from '../../apps/admin_web/lib/auth/config';
import { requestCode, verifyCode, type OtpDependencies } from '../../apps/admin_web/lib/auth/otp';

const config = { url:'https://example.supabase.co', publishableKey:'sb_publishable_fixture', otpLength:6, resendSeconds:60 };
function otpDependencies(access: AdminAccess = { status:'authorized',userId:'verified-user' }): OtpDependencies {
  return { config, request:vi.fn(async()=>true), verify:vi.fn(async()=>true), access:vi.fn(async()=>access), signOut:vi.fn(async()=>{}) };
}
describe('server-side admin authorization',()=>{
  it('rejects unverified cookies without consulting role data',async()=>{
    const accessProfile=vi.fn();
    expect(await authorizeAdmin({verifiedUser:async()=>null,accessProfile})).toEqual({status:'unauthenticated'});
    expect(accessProfile).not.toHaveBeenCalled();
  });
  it.each([['customer'],['driver'],['business'],['operations'],[],['administrator']])('denies non-admin roles %j',async(...roles)=>{
    expect(await authorizeAdmin({verifiedUser:async()=>({id:'user'}),accessProfile:async()=>({user_id:'user',roles})})).toEqual({status:'forbidden'});
  });
  it('checks profile identity and grants only server-backed admin membership',async()=>{
    expect(await authorizeAdmin({verifiedUser:async()=>({id:'user'}),accessProfile:async()=>({user_id:'other',roles:['admin']})})).toEqual({status:'forbidden'});
    expect(await authorizeAdmin({verifiedUser:async()=>({id:'user'}),accessProfile:async()=>({user_id:'user',roles:['admin']})})).toEqual({status:'authorized',userId:'user'});
  });
  it('fails closed during role-source or auth outages',async()=>{
    expect(await authorizeAdmin({verifiedUser:async()=>({id:'user'}),accessProfile:async()=>{throw new Error('sensitive backend detail');}})).toEqual({status:'unavailable'});
  });
});
describe('admin phone OTP boundary',()=>{
  it('uses the same strict Ghana national/international contract as mobile',async()=>{
    for (const value of ['0233123456','233123456','+233233123456']) {
      expect(ghanaPhone(value)).toBe('+233233123456');
    }
    for (const value of ['0244163371','024 416 3371','24 416 3371','+233244163371','+233 24 416 3371','233244163371',' (024) 416-3371 ']) {
      expect(ghanaPhone(value)).toBe('+233244163371');
      const deps=otpDependencies();
      const state=await requestCode(value,deps);
      expect(deps.request).toHaveBeenCalledWith('+233244163371');
      expect(state.phone).toBe('+233244163371');
      await verifyCode(state.phone!,'123456',deps);
      expect(deps.verify).toHaveBeenCalledWith('+233244163371','123456');
    }
    for (const value of ['', 'letters','0244','02441633711','+2330244163371','2330244163371','00233244163371','++233244163371','+233233244163371','+234244163371','0244.163371']) {
      expect(ghanaPhone(value)).toBeNull();
      const deps=otpDependencies();
      await requestCode(value,deps);
      await verifyCode(value,'123456',deps);
      expect(deps.request).not.toHaveBeenCalled();
      expect(deps.verify).not.toHaveBeenCalled();
    }
  });
  it('validates phone and OTP before invoking providers',async()=>{
    const deps=otpDependencies();
    expect((await requestCode('bad',deps)).step).toBe('phone');
    expect(deps.request).not.toHaveBeenCalled();
    await verifyCode('0241234567','12x456',deps);
    expect(deps.verify).not.toHaveBeenCalled();
    expect(ghanaPhone('+233241234567')).toBe('+233241234567');
  });
  it('uses a countdown and advances only after verification plus admin authorization',async()=>{
    const deps=otpDependencies();
    const state=await requestCode('0241234567',deps);
    expect(state.step).toBe('code'); expect(state.resendAt).toBeGreaterThan(Date.now());
    expect(deps.request).toHaveBeenCalledWith('+233241234567');
    expect(await verifyCode('0241234567','123456',deps)).toEqual({authorized:true});
    expect(deps.access).toHaveBeenCalledOnce();
  });
  it('rejects verified non-admins and clears their local session',async()=>{
    const deps=otpDependencies({status:'forbidden'});
    expect(await verifyCode('0241234567','123456',deps)).toMatchObject({step:'phone',message:'This account does not have admin access.'});
    expect(deps.signOut).toHaveBeenCalledOnce();
  });
  it('keeps invalid/expired OTPs retryable without exposing provider errors',async()=>{
    const deps=otpDependencies(); deps.verify=async()=>false;
    expect(await verifyCode('0241234567','123456',deps)).toMatchObject({step:'code'});
    expect(deps.access).not.toHaveBeenCalled();
    deps.request=async()=>{throw new Error('private provider response');};
    expect(JSON.stringify(await requestCode('0241234567',deps))).not.toContain('private provider');
  });
  it('rejects privileged keys and invalid OTP configuration',()=>{
    expect(()=>adminConfig({SUPABASE_URL:config.url,SUPABASE_PUBLISHABLE_KEY:'sb_secret_test'})).toThrow();
    const privileged='eyJfixture.'+Buffer.from(JSON.stringify({role:'service_role'})).toString('base64url')+'.fixture';
    expect(()=>adminConfig({SUPABASE_URL:config.url,SUPABASE_PUBLISHABLE_KEY:privileged})).toThrow();
    expect(()=>adminConfig({SUPABASE_URL:config.url,SUPABASE_PUBLISHABLE_KEY:config.publishableKey,AUTH_OTP_LENGTH:'0'})).toThrow();
    expect(adminConfig({SUPABASE_URL:config.url,SUPABASE_PUBLISHABLE_KEY:config.publishableKey}).otpLength).toBe(6);
  });
});
