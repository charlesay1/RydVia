import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { it, expect } from 'vitest';
import { ThemeControl, setTheme, themeBootstrap } from '../../packages/rydvia_design_system/web/theme';
it('persists explicit themes and returns to system following', () => {
  render(<ThemeControl />);
  fireEvent.change(screen.getByLabelText('Appearance'),{target:{value:'dark'}});
  expect(document.documentElement.dataset.theme).toBe('dark');
  expect(localStorage.getItem('rydvia.theme')).toBe('dark');
  setTheme('system');
  expect(document.documentElement.hasAttribute('data-theme')).toBe(false);
  expect(localStorage.getItem('rydvia.theme')).toBe('system');
});
it('bootstrap restores only valid stored theme values', () => {
  localStorage.setItem('rydvia.theme','light');
  window.eval(themeBootstrap);
  expect(document.documentElement.dataset.theme).toBe('light');
  delete document.documentElement.dataset.theme;
  localStorage.setItem('rydvia.theme','unexpected');
  window.eval(themeBootstrap);
  expect(document.documentElement.hasAttribute('data-theme')).toBe(false);
});
