import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import '@rydvia/design-system/styles.css';
import { themeBootstrap, SafeErrorBoundary } from '@rydvia/design-system/theme';
import { manrope } from '@rydvia/design-system/font';
export const metadata: Metadata = { title: 'RydVia Admin — Fixture Preview', robots: { index: false, follow: false } };
export default function Layout({ children }: { children: ReactNode }) {
  return <html lang="en-GH" className={manrope.variable} suppressHydrationWarning><head><script dangerouslySetInnerHTML={{__html: themeBootstrap}} /></head><body><a className="skip" href="#main">Skip to content</a><SafeErrorBoundary>{children}</SafeErrorBoundary></body></html>;
}
