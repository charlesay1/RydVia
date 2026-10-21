// @vitest-environment node
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';
import { it, expect } from 'vitest';

const root = new URL('../../', import.meta.url);
const manifest = JSON.parse(readFileSync(new URL('assets/photography/manifest.json', root), 'utf8'));
it('all campaign assets have valid dimensions, bounded size, provenance, declarations and responsive web copies', async () => {
  const pubspec = readFileSync(new URL('packages/rydvia_ui/pubspec.yaml', root), 'utf8');
  expect(manifest.provenance).toContain('Generated');
  expect(manifest.releaseApproval).toContain('Pending');
  expect(manifest.images.map((image: {id:string}) => image.id).sort()).toEqual(['business','customer','driver','ecosystem']);
  for (const image of manifest.images) {
    const source = readFileSync(new URL(image.source, root));
    const metadata = await sharp(source).metadata();
    expect(metadata).toMatchObject({width:1536,height:1024,format:'webp'});
    expect(source.length).toBeLessThan(250_000);
    expect(image.prompt).toBeTruthy();
    expect(pubspec).toContain(`assets/photography/${image.id}.webp`);
    for (const app of image.webApps) {
      const base = `apps/${app}/public/photography/${image.id}`;
      expect(readFileSync(new URL(`${base}.webp`,root)).equals(source)).toBe(true);
      const small = await sharp(fileURLToPath(new URL(`${base}-768.webp`,root))).metadata();
      expect(small).toMatchObject({width:768,height:512,format:'webp'});
    }
  }
});
