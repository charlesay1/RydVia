import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { Dashboard } from '../../apps/admin_web/components/dashboard';
import { FixtureDashboardRepository, summarize } from '../../apps/admin_web/lib/dashboard-repository';

describe('dashboard', () => {
  it('filters fixtures consistently by service and date', async () => {
    const repo = new FixtureDashboardRepository();
    const seven = await repo.bookings({days:7,service:'All'});
    const ninety = await repo.bookings({days:90,service:'All'});
    expect(ninety.length).toBeGreaterThan(seven.length);
    const ride = await repo.bookings({days:7,service:'Ride'});
    expect(ride.every(row=>row.service==='Ride')).toBe(true);
    expect(summarize(ride).bookings).toBe(ride.length);
  });
  it('labels synthetic data and applies interactive filters', async () => {
    render(<Dashboard />);
    expect(screen.getByText(/All metrics and bookings below are synthetic/)).toBeInTheDocument();
    await screen.findByText('DEMO-1048');
    fireEvent.change(screen.getByLabelText('Service'), {target:{value:'Towing'}});
    await screen.findByText('DEMO-1044');
    await waitFor(()=>expect(screen.queryByText('DEMO-1048')).not.toBeInTheDocument());
    fireEvent.click(screen.getByRole('button',{name:'Services',exact:true}));
    expect(screen.getByText(/No live settings are changed/)).toBeInTheDocument();
  });
  it('shows a retryable error without leaking raw exceptions', async () => {
    render(<Dashboard repository={{bookings:async()=>{throw new Error('private server detail');}}} />);
    expect(await screen.findByRole('alert')).toHaveTextContent('Could not load dashboard data');
    expect(screen.queryByText('private server detail')).not.toBeInTheDocument();
    expect(screen.getByRole('button',{name:'Try again'})).toBeInTheDocument();
  });
  it('shows an empty result explicitly', async () => {
    render(<Dashboard repository={{bookings:async()=>[]}} />);
    expect(await screen.findByText('No fixture bookings match this selection.')).toBeInTheDocument();
  });
});
