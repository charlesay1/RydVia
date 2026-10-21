import React from 'react';

/** Development slot only. Plain UI text must never be represented as the
 * official custom wordmark. Integrate verified masters before release. */
export function BrandSlot({ product, decorative = false }: { product?: 'Admin' | 'Customer' | 'Driver' | 'Business'; decorative?: boolean }) {
  const label = product ? `RydVia · ${product}` : 'RydVia';
  return <span className="brand-slot" role={decorative ? undefined : 'group'} aria-hidden={decorative || undefined} aria-label={decorative ? undefined : `${label}. Development brand placeholder; official artwork pending.`} data-brand-status="development-placeholder">
    <span aria-hidden="true">{label}</span><small aria-hidden="true">Artwork pending</small>
  </span>;
}
