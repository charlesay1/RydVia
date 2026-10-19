import type { NextConfig } from 'next';
const config: NextConfig = { transpilePackages: ['@rydvia/design-system'], poweredByHeader: false,
  async headers() { return [{ source: '/(.*)', headers: [
    { key: 'X-Content-Type-Options', value: 'nosniff' },
    { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
    { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
  ] }]; } };
export default config;
