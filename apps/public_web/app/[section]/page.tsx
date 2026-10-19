import Link from 'next/link';
import { notFound } from 'next/navigation';
const copy: Record<string, {title: string; body: string}> = {
  'get-started': {title: 'Your next journey starts here', body: 'The RydVia Customer App is in development. Verified app-store links and service availability will appear here when public onboarding opens.'},
  partners: {title: 'Move forward with RydVia', body: 'Driver and business onboarding is being prepared. Eligibility checks, required documents, service coverage, and an official application channel will be published before onboarding opens.'},
  support: {title: 'RydVia support', body: 'Public support channels have not been published yet. This foundation build does not accept bookings, payments, or personal information.'},
};
export default async function Information({params}: {params: Promise<{section: string}>}) {
  const {section} = await params; const content = copy[section]; if (!content) notFound();
  return <main id="main" className="container legal-content"><Link href="/">← RydVia</Link><h1 style={{marginTop:32}}>{content.title}</h1><p>{content.body}</p><Link className="button" href="/">Back to RydVia</Link></main>;
}
