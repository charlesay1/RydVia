import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
import { adminConfig } from './lib/auth/config';

export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request });
  const privateHeaders = () => {
    response.headers.set('Cache-Control', 'private, no-store, max-age=0');
    response.headers.set('Pragma', 'no-cache');
    response.headers.set('Expires', '0');
  };
  try {
    const config = adminConfig(process.env);
    const client = createServerClient(config.url, config.publishableKey, {
      cookieOptions: { name: 'rydvia-admin-auth', httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax', path: '/' },
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: updates => {
          for (const { name, value } of updates) request.cookies.set(name, value);
          response = NextResponse.next({ request });
          for (const { name, value, options } of updates) response.cookies.set(name, value, { ...options, httpOnly: true, secure: process.env.NODE_ENV === 'production', sameSite: 'lax', path: '/' });
        },
      },
      global: { fetch: (input, init) => fetch(input, { ...init, cache: 'no-store' }) },
    });
    // Refresh/validate only; the page and API independently enforce database roles.
    await client.auth.getUser();
  } catch { /* Missing configuration or outages must never bypass the server gate. */ }
  privateHeaders();
  return response;
}
export const config = { matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'] };
