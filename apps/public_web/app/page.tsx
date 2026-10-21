import React from 'react';
import Link from 'next/link';
import { ThemeControl } from '@rydvia/design-system/theme';
import { CampaignPhoto } from '@rydvia/design-system/photography';
import { BrandSlot } from '@rydvia/design-system/brand';

const services = [
  { id: 'ride', title: 'Rides', subtitle: 'Your next stop, made simpler.', text: 'A considered way to connect people and places, from everyday trips to planned journeys.', link: 'Explore rides' },
  { id: 'deliveries', title: 'Deliveries', subtitle: 'From your hands to theirs.', text: 'A delivery experience designed around packages, local businesses, and the people waiting for them.', link: 'Explore deliveries' },
  { id: 'business', title: 'For Business', subtitle: 'More room to grow.', text: 'One connected workspace for orders, delivery requests, and business transportation.', link: 'Explore business' },
  { id: 'drive', title: 'Drive with RydVia', subtitle: 'Move forward, together.', text: 'A driver experience designed to bring eligible ride and delivery opportunities into one place.', link: 'Become a partner' },
];
export default function Home() {
  return <div className="container"><header className="site-header"><Link href="/" className="site-name"><BrandSlot /></Link><nav aria-label="Main navigation" className="site-nav"><Link href="/">Home</Link><a href="#ride">Ride</a><a href="#deliveries">Deliveries</a><a href="#business">For Business</a><a href="#drive">Drive with RydVia</a><a href="#about">About</a></nav><ThemeControl /></header>
    <main id="main"><section className="hero"><div><p className="eyebrow">Designed for movement · Ghana</p><h1>Welcome to<br/>RydVia</h1><h2>Ride. Deliver. Move.</h2><p className="hero-copy muted">A modern platform for rides, deliveries, local commerce, and smart mobility.</p><div className="row"><Link className="button" href="/get-started">Get Started <span aria-hidden="true">↗</span></Link><Link className="button secondary" href="/partners">Become a Partner</Link></div><p className="muted" style={{marginTop: 24}}>In development. Service availability and app downloads will be announced at launch.</p></div>
      <figure className="campaign-hero"><CampaignPhoto asset="ecosystem" priority alt="A customer checks her phone beside a driver and a neighborhood shop." /><figcaption><p className="eyebrow">People. Places. Possibilities.</p><strong>A better-connected everyday.</strong></figcaption></figure>
    </section>
    <section className="people-section" aria-labelledby="people-heading"><p className="eyebrow muted">Made for the way Ghana moves.</p><h2 id="people-heading">Your everyday. More connected.</h2><div className="people-grid">
      <article className="people-card"><CampaignPhoto asset="customer" alt="A customer uses her phone beside a sedan on a tree-lined street." /><div><h3>Ride. Deliver. Move.</h3><p className="muted">For everyday journeys and the things you need to send.</p></div></article>
      <article className="people-card"><CampaignPhoto asset="driver" alt="An independent driver-partner stands beside a practical SUV." /><div><h3>Drive. Earn. Move.</h3><p className="muted">For independent professionals moving their communities forward.</p></div></article>
      <article className="people-card"><CampaignPhoto asset="business" alt="A shop owner manages orders with a tablet, parcels and a card reader." /><div><h3>Sell. Manage. Grow.</h3><p className="muted">For shops, services and the people building local businesses.</p></div></article>
    </div></section>
    <section className="service-section" aria-labelledby="service-heading"><p className="eyebrow muted">One platform. More possibilities.</p><h2 id="service-heading">However your day moves.</h2><div className="service-grid">{services.map((service, index) => <article id={service.id} className="panel service-card" key={service.id}><span className="number" aria-hidden="true">0{index+1}</span><h3>{service.title}</h3><strong>{service.subtitle}</strong><p className="muted">{service.text}</p><Link href={service.id === 'drive' || service.id === 'business' ? '/partners' : '/get-started'}>{service.link} →</Link></article>)}</div></section>
    <section id="about" className="cta-band"><p className="eyebrow">Effortless movement.</p><h2>Built around real journeys.</h2><p>RydVia is being built for mobility, deliveries, logistics, moving, towing, and local businesses across Ghana. Services will open as operational readiness and local availability are confirmed.</p><Link href="/partners">Explore partnership opportunities →</Link></section></main>
    <footer className="row"><BrandSlot decorative /><span className="muted">Premium mobility. Warm technology. Effortless movement.</span><Link href="/support">Support</Link><Link href="/legal/terms">Terms</Link><Link href="/legal/privacy">Privacy</Link></footer></div>;
}
