import React from 'react';
import { render, screen } from '@testing-library/react';
import { it, expect } from 'vitest';
import Home from '../../apps/public_web/app/page';
it('public shell exposes working navigation and describes launch status honestly', () => {
  render(<Home />);
  expect(screen.getByRole('heading',{name:'Ride. Deliver. Move.',level:2})).toBeInTheDocument();
  expect(screen.getByRole('link',{name:/Get Started/})).toHaveAttribute('href','/get-started');
  expect(screen.getByRole('link',{name:'Become a Partner'})).toHaveAttribute('href','/partners');
  expect(screen.getByRole('link',{name:'Privacy'})).toHaveAttribute('href','/legal/privacy');
  expect(screen.getByText(/In development. Service availability/)).toBeInTheDocument();
  for (const title of ['Rides','Deliveries','For Business','Drive with RydVia']) {
    expect(screen.getByRole('heading',{name:title})).toBeInTheDocument();
  }
});
