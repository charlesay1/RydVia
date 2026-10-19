import 'server-only';
import { cookies } from 'next/headers';
import { createServerClient } from '@supabase/ssr';
import { adminConfig } from './config';
import { authorizeAdmin, type AdminAccess } from './access';

export const authCookieName = 'rydvia-admin-auth';
export async function serverSupabase() {
  const config = adminConfig(process.env);
  const cookieStore = await cookies();
  return createServerClient(config.url, config.publishableKey, {
    cookieOptions: { name: authCookieName, httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax', path: '/' },
    cookies: {
      getAll: () => cookieStore.getAll(),
      setAll: updates => {
        // Server Components cannot write cookies. Proxy/actions perform refresh.
        try { for (const { name, value, options } of updates) cookieStore.set(name, value, { ...options, httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax', path: '/' }); }
        catch { /* The server gate still validates the session on every request. */ }
      },
    },
    global: { fetch: (input, init) => fetch(input, { ...init, cache: 'no-store' }) },
  });
}

export async function getAdminAccess(): Promise<AdminAccess> {
  try {
    const client = await serverSupabase();
    return authorizeAdmin({
      verifiedUser: async () => {
        const { data, error } = await client.auth.getUser();
        if (error) {
          if (error.status === 401 || error.status === 403 || error.name === 'AuthSessionMissingError') return null;
          throw new Error('Authentication unavailable');
        }
        return data.user ? { id: data.user.id } : null;
      },
      accessProfile: async () => {
        const { data, error } = await client.rpc('access_profile');
        if (error) throw new Error('Authorization unavailable');
        return data;
      },
    });
  } catch { return { status: 'unavailable' }; }
}

export async function clearAdminCookies() {
  const store = await cookies();
  for (const cookie of store.getAll()) {
    if (cookie.name === authCookieName || cookie.name.startsWith(`${authCookieName}.`) || cookie.name.startsWith(`${authCookieName}-`)) {
      store.set(cookie.name, '', { maxAge: 0, httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax', path: '/' });
    }
  }
}
