import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { it, expect } from 'vitest';
import { CampaignPhoto } from '@rydvia/design-system/photography';

it('campaign photo provides local responsive sources, descriptive alt text and a stable failure surface', () => {
  render(<CampaignPhoto asset="customer" alt="A customer beside a sedan." priority />);
  const image = screen.getByRole('img', { name: 'A customer beside a sedan.' });
  expect(image).toHaveAttribute('width', '1536');
  expect(image).toHaveAttribute('height', '1024');
  expect(image.getAttribute('srcset')).toContain('/photography/customer-768.webp');
  expect(image.getAttribute('srcset')).toContain('/photography/customer.webp');
  expect(image).toHaveAttribute('loading', 'eager');
  fireEvent.error(image);
  expect(screen.getByRole('img', { name: 'A customer beside a sedan.' }).tagName).toBe('DIV');
});
