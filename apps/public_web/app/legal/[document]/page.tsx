import Link from 'next/link';
import { notFound } from 'next/navigation';
export default async function Legal({params}: {params: Promise<{document: string}>}) {
  const {document} = await params;
  if (!['terms','privacy'].includes(document)) notFound();
  return <main id="main" className="container legal-content"><Link href="/">← RydVia</Link><h1 style={{marginTop:32}}>{document === 'terms' ? 'Terms & Conditions' : 'Privacy Policy'}</h1><p>Final legal text has not been supplied. This development build is not open for public onboarding, bookings, or payments.</p></main>;
}
