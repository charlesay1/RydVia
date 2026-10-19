'use server';
import { redirect } from 'next/navigation';
import { adminConfig } from '../../lib/auth/config';
import { requestCode, verifyCode, type OtpDependencies, type OtpState } from '../../lib/auth/otp';
import { clearAdminCookies, getAdminAccess, serverSupabase } from '../../lib/auth/server';

async function dependencies(): Promise<OtpDependencies> {
  const config = adminConfig(process.env);
  const client = await serverSupabase();
  return {
    config,
    request: async phone => {
      // Staff accounts are provisioned through a trusted path; public admin signup is forbidden.
      const { error } = await client.auth.signInWithOtp({ phone, options: { shouldCreateUser: false } });
      return !error;
    },
    verify: async (phone, token) => {
      const { data, error } = await client.auth.verifyOtp({ phone, token, type: 'sms' });
      return !error && data.session !== null;
    },
    access: getAdminAccess,
    signOut: async () => {
      try { await client.auth.signOut({ scope: 'local' }); }
      finally { await clearAdminCookies(); }
    },
  };
}
export async function requestAdminCode(_previous: OtpState, form: FormData): Promise<OtpState> {
  try { return await requestCode(String(form.get('phone') ?? ''), await dependencies()); }
  catch { return { step: 'phone', message: 'Authentication is not configured or is unavailable.' }; }
}
export async function verifyAdminCode(_previous: OtpState, form: FormData): Promise<OtpState> {
  let result: Awaited<ReturnType<typeof verifyCode>>;
  try { result = await verifyCode(String(form.get('phone') ?? ''), String(form.get('code') ?? ''), await dependencies()); }
  catch { return { step: 'phone', message: 'Authentication is not configured or is unavailable.' }; }
  if ('authorized' in result) redirect('/');
  return result;
}
export async function signOutAdmin() {
  try { const client = await serverSupabase(); await client.auth.signOut({ scope: 'local' }); }
  catch { /* Local logout must remain possible during backend outages. */ }
  finally { await clearAdminCookies(); }
  redirect('/login');
}
