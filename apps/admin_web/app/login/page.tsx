import { redirect } from 'next/navigation';
import { AdminLogin } from '../../components/admin-login';
import { getAdminAccess } from '../../lib/auth/server';
import { adminConfig } from '../../lib/auth/config';
import { CampaignPhoto } from '@rydvia/design-system/photography';
export const dynamic = 'force-dynamic';
export default async function LoginPage() {
  const access = await getAdminAccess();
  if (access.status === 'authorized') redirect('/');
  let config: ReturnType<typeof adminConfig> | null = null;
  try { config = adminConfig(process.env); }
  catch { /* Configuration errors keep the login closed; no credentials are rendered. */ }
  const content = config ? <AdminLogin otpLength={config.otpLength} resendSeconds={config.resendSeconds}/> : <section role="status"><h2>Admin authentication unavailable</h2><p>Configure the server environment with the project URL and public publishable key. No dashboard access is available until server-side session and role checks succeed.</p></section>;
  return <main id="main" className="container admin-welcome"><div className="admin-welcome-copy"><p className="eyebrow muted">People. Places. Possibilities.</p><h1>RydVia Admin</h1><p className="muted">A considered workspace for the people behind the movement.</p>{content}</div><figure className="campaign-hero"><CampaignPhoto asset="ecosystem" priority alt="" /><figcaption><strong>Connected people. Considered operations.</strong></figcaption></figure></main>;
}
