import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve, dirname } from 'node:path';
import sharp from 'sharp';

// Canonical package assets -> responsive, byte-stable web exports. --check is
// read-only; normal sync writes only missing/different files, never the sources.
const root = fileURLToPath(new URL('../', import.meta.url));
const check = process.argv.includes('--check');
const manifest = JSON.parse(await readFile(resolve(root, 'assets/photography/manifest.json'), 'utf8'));
for (const image of manifest.images) {
  const source = await readFile(resolve(root, image.source));
  const metadata = await sharp(source).metadata();
  if (metadata.width !== 1536 || metadata.height !== 1024) throw new Error(`Invalid campaign dimensions: ${image.id}`);
  const small = await sharp(source).resize({ width: 768, withoutEnlargement: true }).webp({ quality: 82, effort: 6 }).toBuffer();
  for (const app of image.webApps) {
    for (const [suffix, bytes] of [['', source], ['-768', small]]) {
      const path = resolve(root, `apps/${app}/public/photography/${image.id}${suffix}.webp`);
      const existing = await readFile(path).catch(error => { if (error.code !== 'ENOENT') throw error; return null; });
      if (existing?.equals(bytes)) continue;
      if (check) throw new Error(`Stale or missing campaign export: ${image.id}${suffix} (${app})`);
      await mkdir(dirname(path), { recursive: true });
      await writeFile(path, bytes);
    }
  }
}
console.log(`PASS: ${manifest.images.length} campaign assets and responsive web exports ${check ? 'verified' : 'synchronized'}.`);
