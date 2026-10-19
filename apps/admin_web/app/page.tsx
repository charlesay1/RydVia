import { Dashboard } from '../components/dashboard';
import { redirect } from 'next/navigation';
import { getAdminAccess } from '../lib/auth/server';
import { signOutAdmin } from './login/actions';
export const dynamic = 'force-dynamic';
export default async function Page() {
  const access = await getAdminAccess();
  if (access.status === 'unauthenticated') redirect('/login');
  if (access.status !== 'authorized') return <main id="main" className="container legal-content"><h1>{access.status === 'forbidden' ? 'Admin access required' : 'Admin authentication unavailable'}</h1><p>{access.status === 'forbidden' ? 'This verified account does not have an active server-backed admin role.' : 'Secure service configuration or authorization is unavailable. No dashboard data can be accessed.'}</p><form action={signOutAdmin}><button>Sign out / return to sign in</button></form></main>;
  return <><form action={signOutAdmin} className="container" style={{paddingTop:16,paddingBottom:16}}><button>Sign out</button></form><Dashboard /></>;
}
