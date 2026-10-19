// @vitest-environment node
import { describe,it,expect,vi } from 'vitest';
const { gate,redirect }=vi.hoisted(()=>({gate:vi.fn(),redirect:vi.fn((url:string)=>{throw new Error(`redirect:${url}`);})}));
vi.mock('../../apps/admin_web/lib/auth/server',()=>({getAdminAccess:gate}));
vi.mock('../../apps/admin_web/app/login/actions',()=>({signOutAdmin:vi.fn()}));
vi.mock('next/navigation',()=>({redirect}));
import { GET } from '../../apps/admin_web/app/api/access/route';
import Page from '../../apps/admin_web/app/page';
describe('admin protected route integration',()=>{
  it.each([['unauthenticated',401],['forbidden',403],['unavailable',503],['authorized',200]])('returns %s / %s with private no-store headers',async(status,expected)=>{
    gate.mockResolvedValue({status,userId:'test-user'});
    const response=await GET();
    expect(response.status).toBe(expected);
    expect(response.headers.get('cache-control')).toContain('no-store');
    expect(await response.json()).toEqual({authorized:status==='authorized'});
  });
  it('redirects missing sessions before rendering the dashboard',async()=>{
    gate.mockResolvedValue({status:'unauthenticated'});
    await expect(Page()).rejects.toThrow('redirect:/login');
  });
  it('does not render protected dashboard content on forbidden or unavailable access',async()=>{
    for(const status of ['forbidden','unavailable']) {
      gate.mockResolvedValue({status});
      const element=await Page();
      expect(element.type).toBe('main');
    }
  });
});
