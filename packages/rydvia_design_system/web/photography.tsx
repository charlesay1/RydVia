'use client';
import React, { useState } from 'react';
import Image, { type ImageLoaderProps } from 'next/image';

export type CampaignAsset = 'customer' | 'driver' | 'business' | 'ecosystem';
function campaignLoader({ src, width }: ImageLoaderProps) {
  const file = width <= 768 ? src.replace('.webp', '-768.webp') : src;
  return `${file}?w=${width}`;
}

/** Locally hosted responsive exports, shared by marketing and Admin welcome.
 * The original 3:2 frame is preserved; copy always lives on a solid surface. */
export function CampaignPhoto({ asset, alt = '', priority = false }: { asset: CampaignAsset; alt?: string; priority?: boolean }) {
  const [failed, setFailed] = useState(false);
  return <div className={`campaign-photo campaign-${asset}`}>
    {failed ? <div className="campaign-photo-fallback" role={alt ? 'img' : undefined} aria-label={alt || undefined} aria-hidden={!alt}>
      <span aria-hidden="true">↗</span>
    </div> : <Image src={`/photography/${asset}.webp`} loader={campaignLoader} width={1536} height={1024}
      alt={alt} sizes="(max-width: 700px) calc(100vw - 40px), (max-width: 1000px) 50vw, 640px"
      loading={priority ? 'eager' : 'lazy'} fetchPriority={priority ? 'high' : 'auto'}
      onError={() => setFailed(true)} className="campaign-image" />}
  </div>;
}
