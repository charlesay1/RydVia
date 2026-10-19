import { redirect } from 'next/navigation';
import { AdminLogin } from '../../components/admin-login';
import { getAdminAccess } from '../../lib/auth/server';
import { adminConfig } from '../../lib/auth/config';
export const dynamic = 'force-dynamic';
export default async function LoginPage() {
  const access = await getAdminAccess();
  if (access.status === 'authorized') redirect('/');
  let config;
  try { config = adminConfig(process.env); }
  catch { return <main id="main" className="container legal-content"><h1>Admin authentication unavailable</h1><p>Configure the server environment with the project URL and public publishable key. No dashboard access is available until server-side session and role checks succeed.</p></main>; }
  return <main id="main" className="container legal-content"><h1>RydVia Admin</h1><AdminLogin otpLength={config.otpLength} resendSeconds={config.resendSeconds}/></main>;
}
