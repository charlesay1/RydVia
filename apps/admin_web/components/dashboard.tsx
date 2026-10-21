'use client';
import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { ThemeControl } from '@rydvia/design-system/theme';
import { BrandSlot } from '@rydvia/design-system/brand';
import { FixtureDashboardRepository, summarize, type Booking, type DashboardRepository } from '../lib/dashboard-repository';

const defaultRepository = new FixtureDashboardRepository();
const sections = ['Overview','Live Operations','Bookings','Services','Customers','Drivers','Businesses','Pricing','Service Zones','Payments','Payouts','Disputes','Support','Safety','Analytics','Settings'];
export function Dashboard({repository = defaultRepository}: {repository?: DashboardRepository}) {
  const [section, setSection] = useState('Overview');
  const [days, setDays] = useState(7);
  const [service, setService] = useState('All');
  const [rows, setRows] = useState<readonly Booking[]>([]);
  const [state, setState] = useState<'loading'|'ready'|'error'>('loading');
  const [retry, setRetry] = useState(0);
  useEffect(() => {
    let current = true;
    Promise.resolve().then(() => { if (current) setState('loading'); });
    repository.bookings({days,service}).then(data => { if(current) {setRows(data);setState('ready');} }).catch(() => {if(current) setState('error');});
    return () => {current = false;};
  }, [days,service,repository,retry]);
  const metrics = summarize(rows);
  const visibleRows = section === 'Live Operations' ? rows.filter(row => row.status === 'active') : rows;
  const isBookingSection = ['Overview','Bookings','Live Operations','Analytics'].includes(section);
  return <><div className="fixture-banner" role="status">Fixture preview · All metrics and bookings below are synthetic. Operational records are fixtures, not live production data.</div><div className="admin-shell"><aside className="sidebar"><Link href="/" className="site-name"><BrandSlot product="Admin" /></Link><nav aria-label="Admin navigation">{sections.map(item => <button key={item} onClick={() => setSection(item)} aria-current={section === item ? 'page' : undefined}>{item}</button>)}</nav></aside><main id="main" className="admin-main"><header className="admin-header"><div><p className="eyebrow muted">Your operations workspace</p><h1>Welcome to RydVia Admin</h1><strong>Control. Monitor. Grow.</strong><p className="muted">Manage customers, drivers, businesses, services, and operations from one powerful dashboard.</p></div><ThemeControl /></header>
    <div className="row"><h2 style={{marginBottom:0}}>{section}</h2><span className="muted">Preview workspace</span></div>
    {isBookingSection && <div className="filters"><label>Date range<select value={days} onChange={event=>setDays(Number(event.target.value))}><option value={7}>Last 7 days</option><option value={30}>Last 30 days</option><option value={90}>Last 90 days</option></select></label><label>Service<select value={service} onChange={event=>setService(event.target.value)}>{['All','Ride','Delivery','Moving','Towing'].map(value=><option key={value}>{value}</option>)}</select></label></div>}
    {state === 'loading' ? <p role="status">Loading fixture data…</p> : state === 'error' ? <div className="panel" role="alert"><h2>Could not load dashboard data</h2><button onClick={()=>setRetry(value=>value+1)}>Try again</button></div> : isBookingSection ? <>
      <section className="kpis" aria-label="Preview metrics">{[
        ['Total Customers',metrics.customers,'In filtered fixture bookings'],['Active Drivers',metrics.live,'Synthetic active assignments'],['Partner Businesses','—','Not connected'],['Total Bookings',metrics.bookings,'Filtered fixture bookings'],
      ].map(([label,value,note])=><article className="panel" key={label}><p className="muted">{label}</p><span className="kpi-value">{value}</span><small>{note}</small></article>)}</section>
      <div className="dashboard-grid"><section className="panel"><h3>Bookings Trend</h3><p className="muted">Fixture counts by age of booking</p><div className="bar-chart" role="img" aria-label={Array.from({length:7},(_,day)=>`${day} days ago: ${rows.filter(row=>row.day===day).length} bookings`).join('; ')}>{Array.from({length:7},(_,index)=>6-index).map(day=>{const count=rows.filter(row=>row.day===day).length;return <div key={day} className="chart-column"><strong>{count}</strong><div className="chart-bar" style={{height:`${count*45}px`}}/><span>{day === 0 ? 'Today' : `${day}d ago`}</span></div>;})}</div></section><section className="panel"><h3>Live Operations</h3><p><span className="kpi-value positive">{metrics.live}</span>● Active fixture booking{metrics.live===1?'':'s'}</p><p><strong>{metrics.completed}</strong> completed in this selection</p><h3>Service Breakdown</h3>{['Ride','Delivery','Moving','Towing'].map(name=><p key={name} className="row"><span>{name}</span><strong>{rows.filter(row=>row.service===name).length}</strong></p>)}</section></div>
      <section className="panel"><h3>Recent Bookings</h3>{visibleRows.length === 0 ? <p>No fixture bookings match this selection.</p> : <div className="table-scroll" tabIndex={0} role="region" aria-label="Recent bookings, scroll horizontally"><table><caption className="muted">Synthetic bookings · GHS estimates</caption><thead><tr>{['Booking','Customer','Service','Journey','Fare','Status'].map(label=><th scope="col" key={label}>{label}</th>)}</tr></thead><tbody>{visibleRows.map(row=><tr key={row.id}><th scope="row">{row.id}</th><td>{row.customer}</td><td>{row.service}</td><td>{row.route}</td><td>{new Intl.NumberFormat('en-GH',{style:'currency',currency:'GHS'}).format(row.fare)}</td><td><span className={`status ${row.status}`}>{row.status}</span></td></tr>)}</tbody></table></div>}</section>
    </> : <section className="panel" style={{marginTop:24}}><h3>{section} configuration</h3><p>This module is not connected to production. Live access requires verified admin authentication, server-side authorization, and an approved data adapter.</p>{section === 'Services' && <p>Cars, Motorbike, Pragya, Delivery, Aboboyaa, Van, Pickup, Truck, Moving, Towing, Scheduled, Intercity, and Business are defined in the local service migration. No live settings are changed from this preview.</p>}</section>}
  </main></div></>;
}
