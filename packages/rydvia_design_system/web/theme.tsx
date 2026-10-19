'use client';
import React, { Component, useEffect, useState, type ReactNode } from 'react';

export type ThemeMode = 'system' | 'light' | 'dark';
export function setTheme(mode: ThemeMode) {
  if (mode === 'system') document.documentElement.removeAttribute('data-theme');
  else document.documentElement.dataset.theme = mode;
  try { localStorage.setItem('rydvia.theme', mode); } catch { /* OS theme still works without storage. */ }
}
// Constant script executes before content paint. Never interpolate configuration or user input.
export const themeBootstrap = `(function(){try{var t=localStorage.getItem('rydvia.theme');if(t==='light'||t==='dark')document.documentElement.dataset.theme=t;}catch(e){}})();`;

export function ThemeControl() {
  const [mode, update] = useState<ThemeMode>('system');
  useEffect(() => {
    try { const stored = localStorage.getItem('rydvia.theme'); if (stored === 'light' || stored === 'dark') update(stored); } catch { /* fallback to system */ }
  }, []);
  return <label className="theme-control"><span>Appearance</span><select aria-label="Appearance" value={mode} onChange={event => {
    const next = event.target.value as ThemeMode; setTheme(next); update(next);
  }}><option value="system">System</option><option value="light">Light</option><option value="dark">Dark</option></select></label>;
}

export class SafeErrorBoundary extends Component<{children: ReactNode}, {failed: boolean}> {
  state = { failed: false };
  static getDerivedStateFromError() { return { failed: true }; }
  render() { return this.state.failed ? <div role="alert" className="panel"><h2>Something went wrong</h2><p>Reload this page to try again.</p><button onClick={() => window.location.reload()}>Reload</button></div> : this.props.children; }
}
