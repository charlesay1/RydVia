import next from 'eslint-config-next/core-web-vitals';
const config = [...next, { ignores: ['.next/**', 'out/**', 'next-env.d.ts'] }];
export default config;
