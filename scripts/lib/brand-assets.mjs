import { readFileSync, readdirSync, existsSync, realpathSync } from 'node:fs';
import { resolve, sep, relative } from 'node:path';
import { createHash } from 'node:crypto';

export const requiredBrandSlots = ['primary-symbol','primary-wordmark','horizontal-lockup','stacked-lockup','light-variation','dark-variation','monochrome-variation','app-icon-master','customer-launcher','driver-launcher','business-launcher','web-favicon','pwa-icons','apple-touch-icon','brand-guidelines','clear-space'];
function inventory(directory) {
  if (!existsSync(directory)) return [];
  return readdirSync(directory, { withFileTypes: true }).flatMap(entry => entry.isDirectory() ? inventory(resolve(directory, entry.name)) : [resolve(directory, entry.name)]);
}

export function inspectBrandAssets(root, catalog = JSON.parse(readFileSync(resolve(root,'assets/brand/manifest.json'),'utf8'))) {
  const issues = [];
  const canonical = realpathSync(resolve(root,'assets/brand'));
  const registered = new Set();
  const verified = new Set();
  const requirements = catalog.requirements ?? [];
  if (catalog.version !== 1 || catalog.canonicalSource !== 'assets/brand' || requirements.length !== requiredBrandSlots.length ||
    new Set(requirements.map(entry=>entry.id)).size !== requiredBrandSlots.length ||
    requiredBrandSlots.some(id=>!requirements.some(entry=>entry.id===id))) issues.push('Invalid or incomplete canonical brand register');
  for (const entry of [...requirements, ...(catalog.references ?? [])]) {
    const slot = requiredBrandSlots.indexOf(entry.id);
    const expectedDirectory = slot === 0 ? 'symbol' : slot <= 6 ? 'logo' : slot <= 10 ? 'app-icons' : slot <= 13 ? 'web-icons' : 'guidelines';
    if (slot >= 0 && entry.directory !== expectedDirectory) issues.push(`Incorrect canonical slot directory: ${entry.id}`);
    if (!['missing','provisional','reference-only','approved'].includes(entry.status)) issues.push(`Invalid classification: ${entry.id}`);
    if (entry.status === 'missing' && (entry.path !== null || entry.approval !== null)) issues.push(`Missing slot must not declare artwork: ${entry.id}`);
    if (entry.status !== 'missing' && !entry.path) issues.push(`Artwork path missing: ${entry.id}`);
    if (entry.status !== 'approved' && entry.approval) issues.push(`Unapproved slot must not claim approval: ${entry.id}`);
    const approvalValid = !!entry.approval?.approvedBy && !!entry.approval?.source &&
      Number.isFinite(Date.parse(entry.approval?.approvedAt)) && /^[a-f0-9]{64}$/.test(entry.approval?.sha256 ?? '');
    if (entry.status === 'approved' && !approvalValid) issues.push(`Verified approval record required: ${entry.id}`);
    if (!entry.path) continue;
    const path = resolve(root, entry.path);
    if (!path.startsWith(canonical + sep) || !existsSync(path) || !realpathSync(path).startsWith(canonical + sep)) {
      issues.push(`Missing or non-canonical artwork: ${entry.id}`); continue;
    }
    registered.add(realpathSync(path));
    const slotValid = slot < 0 || (path.startsWith(resolve(canonical,expectedDirectory)+sep) && (slot > 6 || /\.svg$/i.test(path)));
    if (!slotValid) issues.push(`Wrong source format or slot path: ${entry.id}`);
    if (entry.status === 'approved') {
      const hash = createHash('sha256').update(readFileSync(path)).digest('hex');
      if (hash !== entry.approval?.sha256) issues.push(`Artwork differs from approval record: ${entry.id}`);
      else if (slot >= 0 && slotValid && approvalValid) verified.add(entry.id);
    }
  }
  for (const file of inventory(canonical)) {
    if (/\.(svg|png|jpe?g|webp|avif|ico|pdf|ai|eps)$/i.test(file) && !registered.has(realpathSync(file))) issues.push(`Unregistered brand artwork: ${relative(root,file).replaceAll('\\','/')}`);
  }
  const mobile = ['customer','driver','business'].map(role => {
    const app = resolve(root,`apps/${role}_app`);
    const manifest = readFileSync(resolve(app,'android/app/src/main/AndroidManifest.xml'),'utf8');
    const slots = JSON.parse(readFileSync(resolve(app,'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'),'utf8')).images;
    const densities = ['mdpi','hdpi','xhdpi','xxhdpi','xxxhdpi'];
    const missingAndroid = densities.filter(density=>!existsSync(resolve(app,`android/app/src/main/res/mipmap-${density}/ic_launcher.png`)));
    for (const layer of ['foreground','background','monochrome']) {
      if (!inventory(resolve(app,'android/app/src/main/res')).some(file=>new RegExp(`ic_launcher_${layer}\\.(xml|png|webp)$`).test(file))) missingAndroid.push(`adaptive-${layer}`);
    }
    const iosReady = slots.length >= 10 && slots.every(slot=>slot.filename && existsSync(resolve(app,'ios/Runner/Assets.xcassets/AppIcon.appiconset',slot.filename)));
    return { app: `${role}_app`, androidIconDeclared: /android:icon=/.test(manifest), missingAndroid, iosSlots: slots.length, iosReady,
      status: missingAndroid.length || !iosReady || !/android:icon=/.test(manifest) ? 'BLOCKED BY APPROVED MASTER ARTWORK' : 'exports require approval review' };
  });
  const web = ['admin_web','public_web'].map(app=>({app,status:'BLOCKED BY APPROVED MASTER ARTWORK',
    faviconPresent: ['app/favicon.ico','public/favicon.ico'].some(path=>existsSync(resolve(root,`apps/${app}/${path}`))),
    pwaManifestPresent: ['app/manifest.ts','app/manifest.json','public/manifest.json','public/manifest.webmanifest'].some(path=>existsSync(resolve(root,`apps/${app}/${path}`))),
    appleTouchPresent: ['app/apple-icon.png','public/apple-touch-icon.png'].some(path=>existsSync(resolve(root,`apps/${app}/${path}`))) }));
  const missing = requirements.filter(entry=>!verified.has(entry.id)).map(entry=>entry.id);
  const productionBlockers = [...missing.map(id=>`Approved artwork missing: ${id}`)];
  if (catalog.uiIntegration !== 'approved-assets') productionBlockers.push('UI uses development brand placeholders; approved rendering integration pending');
  if (mobile.some(entry=>entry.status==='BLOCKED BY APPROVED MASTER ARTWORK')) productionBlockers.push('Approved native launcher exports incomplete');
  if (web.some(entry=>!entry.faviconPresent || !entry.pwaManifestPresent || !entry.appleTouchPresent)) productionBlockers.push('Approved web icon exports/configuration incomplete');
  return { mode:'development-audit', issues, approvedMasters:verified.size, missing, mobile, web,
    productionReady:issues.length===0 && productionBlockers.length===0, productionBlockers };
}
