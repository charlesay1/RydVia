import React from 'react';
import { render, screen } from '@testing-library/react';
import { it,expect } from 'vitest';
import { BrandSlot } from '@rydvia/design-system/brand';
it('plain development label is explicitly pending, not an official wordmark image',()=>{
  render(<BrandSlot product="Admin"/>);
  expect(screen.getByRole('group',{name:/RydVia · Admin.*Development brand placeholder/})).toHaveAttribute('data-brand-status','development-placeholder');
  expect(screen.getByText('Artwork pending')).toBeVisible();
  expect(screen.queryByRole('img')).not.toBeInTheDocument();
});
it('duplicate decorative brand label stays out of the accessibility tree',()=>{
  render(<BrandSlot decorative/>);
  expect(screen.queryByRole('group')).not.toBeInTheDocument();
  expect(screen.getByText('Artwork pending').parentElement).toHaveAttribute('aria-hidden','true');
});
