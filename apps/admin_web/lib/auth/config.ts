export type AdminConfig = { url: string; publishableKey: string; otpLength: number; resendSeconds: number };

/** Key validation is a misuse guard, not cryptographic verification of a session. */
export function adminConfig(env: Record<string, string | undefined>): AdminConfig {
  const url = new URL(env.SUPABASE_URL ?? '');
  const key = env.SUPABASE_PUBLISHABLE_KEY ?? '';
  if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash) throw new Error('Invalid configuration');
  if (key.startsWith('eyJ')) {
    try {
      const claims = JSON.parse(Buffer.from(key.split('.')[1], 'base64url').toString('utf8'));
      if (claims.role !== 'anon') throw new Error();
    } catch { throw new Error('Public client key required'); }
  } else if (!key.startsWith('sb_publishable_') || key.length <= 'sb_publishable_'.length) {
    throw new Error('Public client key required');
  }
  const otpLength = Number(env.AUTH_OTP_LENGTH ?? '6');
  const resendSeconds = Number(env.AUTH_RESEND_SECONDS ?? '60');
  if (!Number.isInteger(otpLength) || otpLength < 6 || otpLength > 10 || !Number.isInteger(resendSeconds) || resendSeconds < 30 || resendSeconds > 3600) throw new Error('Invalid authentication settings');
  return { url: url.origin, publishableKey: key, otpLength, resendSeconds };
}

export function ghanaPhone(value: string): string | null {
  let digits = value.replace(/[\s()-]/g, '');
  if (digits.startsWith('+233')) digits = digits.slice(4);
  else if (digits.startsWith('233') && digits.length === 12) digits = digits.slice(3);
  if (digits.startsWith('0')) digits = digits.slice(1);
  return /^[25][0-9]{8}$/.test(digits) ? `+233${digits}` : null;
}
