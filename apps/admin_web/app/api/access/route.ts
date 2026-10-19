import { getAdminAccess } from '../../../lib/auth/server';
export const dynamic = 'force-dynamic';
export async function GET() {
  const access = await getAdminAccess();
  const status = { authorized: 200, unauthenticated: 401, forbidden: 403, unavailable: 503 }[access.status];
  return Response.json({ authorized: access.status === 'authorized' }, { status, headers: { 'Cache-Control': 'private, no-store', 'Pragma': 'no-cache' } });
}
