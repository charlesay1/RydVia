// @vitest-environment node
import { readFileSync, mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname, resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { it, expect } from 'vitest';
import { inspectBrandAssets, requiredBrandSlots } from '../../scripts/lib/brand-assets.mjs';
const root = fileURLToPath(new URL('../../',import.meta.url));
const catalog = () => JSON.parse(readFileSync(new URL('../../assets/brand/manifest.json',import.meta.url),'utf8'));

it('reports all sixteen missing masters without inventing production readiness',()=>{
  const report=inspectBrandAssets(root);
  expect(report.issues).toEqual([]);
  expect(report.approvedMasters).toBe(0);
  expect(report.missing).toEqual(requiredBrandSlots);
  expect(report.productionReady).toBe(false);
  expect(report.mobile).toHaveLength(3);
  for(const entry of report.mobile) {
    expect(entry.status).toBe('BLOCKED BY APPROVED MASTER ARTWORK');
    expect(entry.iosSlots).toBe(19);
    expect(entry.iosReady).toBe(false);
    expect(entry.missingAndroid).toHaveLength(8);
  }
  for(const entry of report.web) expect(entry.faviconPresent||entry.pwaManifestPresent||entry.appleTouchPresent).toBe(false);
});
it('refuses an approval claim without provenance, file and hash',()=>{
  const changed=catalog();changed.requirements[0].status='approved';
  const report=inspectBrandAssets(root,changed);
  expect(report.issues).toContain('Verified approval record required: primary-symbol');
  expect(report.issues).toContain('Artwork path missing: primary-symbol');
  expect(report.approvedMasters).toBe(0);
  expect(report.productionReady).toBe(false);
});
it('rejects a photograph, missing file or outside path as canonical logo artwork',()=>{
  for(const path of ['packages/rydvia_ui/assets/photography/customer.webp','assets/brand/symbol/missing.svg','../outside.svg']) {
    const changed=catalog();Object.assign(changed.requirements[0],{status:'reference-only',path});
    expect(inspectBrandAssets(root,changed).issues).toContain('Missing or non-canonical artwork: primary-symbol');
  }
});
it('release CLI fails closed while development auditing succeeds',()=>{
  const script=fileURLToPath(new URL('../../scripts/verify-brand-assets.mjs',import.meta.url));
  const audit=spawnSync(process.execPath,[script],{encoding:'utf8'});
  expect(audit.status).toBe(0);
  const release=spawnSync(process.execPath,[script,'--release'],{encoding:'utf8'});
  expect(release.status).toBe(1);
  expect(JSON.parse(release.stdout)).toMatchObject({status:'BLOCKED',mode:'release-gate',productionReady:false});
});
it('classifies generated photographs as backgrounds, never authoritative logo assets',()=>{
  const photos=JSON.parse(readFileSync(new URL('../../assets/photography/manifest.json',import.meta.url),'utf8'));
  for(const photo of photos.images) expect(photo).toMatchObject({classification:'BACKGROUND-ONLY',authoritativeBrandAsset:false,embeddedRydViaLogo:false});
});
it('rejects unregistered artwork and tampering with an approval hash',()=>{
  const prefix=join(tmpdir(),'rydvia-brand-audit-');const temporary=mkdtempSync(prefix);
  try {
    mkdirSync(join(temporary,'assets/brand/symbol'),{recursive:true});
    for(const role of ['customer','driver','business']) for(const path of ['android/app/src/main/AndroidManifest.xml','ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json']) {
      const target=join(temporary,`apps/${role}_app/${path}`);mkdirSync(dirname(target),{recursive:true});
      writeFileSync(target,readFileSync(join(root,`apps/${role}_app/${path}`)));
    }
    // An empty SVG parser fixture, not logo artwork; exists only in this temp tree.
    const fixture='<svg xmlns="http://www.w3.org/2000/svg"/>';
    const path='assets/brand/symbol/fixture.svg';writeFileSync(join(temporary,path),fixture);
    const changed=catalog();changed.references=[];
    expect(inspectBrandAssets(temporary,changed).issues).toContain(`Unregistered brand artwork: ${path}`);
    Object.assign(changed.requirements[0],{status:'approved',path,approval:{approvedBy:'Fixture reviewer',source:'Inert parser test only',approvedAt:'2026-10-20',sha256:'0'.repeat(64)}});
    expect(inspectBrandAssets(temporary,changed).issues).toContain('Artwork differs from approval record: primary-symbol');
    changed.requirements[0].approval.sha256=createHash('sha256').update(fixture).digest('hex');
    expect(inspectBrandAssets(temporary,changed).issues).toEqual([]);
    expect(inspectBrandAssets(temporary,changed).productionReady).toBe(false);
  } finally {
    expect(resolve(temporary).startsWith(resolve(prefix))).toBe(true);
    rmSync(temporary,{recursive:true,force:true});
  }
});
