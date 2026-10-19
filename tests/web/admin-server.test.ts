// @vitest-environment node
import { beforeEach,afterEach,it,expect,vi } from 'vitest';
const mock=vi.hoisted(()=>({
  getUser:vi.fn(),rpc:vi.fn(),create:vi.fn(),setCookie:vi.fn(),
  getCookies:vi.fn(()=>[{name:'rydvia-admin-auth.0',value:'fixture-session'},{name:'unrelated',value:'untouched'}]),
}));
vi.mock('server-only',()=>({}));
vi.mock('next/headers',()=>({cookies:async()=>({getAll:mock.getCookies,set:mock.setCookie})}));
vi.mock('@supabase/ssr',()=>({createServerClient:mock.create}));
import { getAdminAccess,serverSupabase,clearAdminCookies } from '../../apps/admin_web/lib/auth/server';

beforeEach(()=>{
  vi.clearAllMocks();
  vi.stubEnv('SUPABASE_URL','https://example.supabase.co');
  vi.stubEnv('SUPABASE_PUBLISHABLE_KEY','sb_publishable_fixture');
  mock.create.mockReturnValue({auth:{getUser:mock.getUser},rpc:mock.rpc});
  mock.getUser.mockResolvedValue({data:{user:{id:'verified-user'}},error:null});
  mock.rpc.mockResolvedValue({data:{user_id:'verified-user',roles:['admin']},error:null});
});
afterEach(()=>vi.unstubAllEnvs());
it('verifies the user through Auth and checks roles using that session, not getSession or metadata',async()=>{
  expect(await getAdminAccess()).toEqual({status:'authorized',userId:'verified-user'});
  expect(mock.getUser).toHaveBeenCalledOnce();
  expect(mock.rpc).toHaveBeenCalledWith('access_profile');
  const options=mock.create.mock.calls[0][2];
  expect(options.cookieOptions).toMatchObject({httpOnly:true,sameSite:'lax',path:'/'});
});
it('treats missing sessions as unauthenticated and never queries roles',async()=>{
  mock.getUser.mockResolvedValue({data:{user:null},error:{name:'AuthSessionMissingError'}});
  expect(await getAdminAccess()).toEqual({status:'unauthenticated'});
  expect(mock.rpc).not.toHaveBeenCalled();
});
it('fails closed if role reads or the Auth service fail',async()=>{
  mock.rpc.mockResolvedValue({data:null,error:{message:'private database detail'}});
  expect(await getAdminAccess()).toEqual({status:'unavailable'});
  mock.getUser.mockResolvedValue({data:{user:null},error:{status:503}});
  expect(await getAdminAccess()).toEqual({status:'unavailable'});
});
it('marks production cookies secure/HttpOnly and clears only its own chunks on logout',async()=>{
  vi.stubEnv('NODE_ENV','production');
  await serverSupabase();
  const options=mock.create.mock.calls[0][2];
  expect(options.cookieOptions.secure).toBe(true);
  options.cookies.setAll([{name:'rydvia-admin-auth.0',value:'fixture-session',options:{httpOnly:false}}]);
  expect(mock.setCookie).toHaveBeenCalledWith('rydvia-admin-auth.0','fixture-session',expect.objectContaining({httpOnly:true,secure:true}));
  mock.setCookie.mockClear();
  await clearAdminCookies();
  expect(mock.setCookie).toHaveBeenCalledTimes(1);
  expect(mock.setCookie).toHaveBeenCalledWith('rydvia-admin-auth.0','',expect.objectContaining({maxAge:0,httpOnly:true,secure:true}));
});
