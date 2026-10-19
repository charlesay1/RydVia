import { ghanaPhone, type AdminConfig } from './config';
import type { AdminAccess } from './access';

export type OtpState = { step: 'phone' | 'code'; message: string; phone?: string; resendAt?: number };
export type OtpDependencies = {
  config: AdminConfig;
  request(phone: string): Promise<boolean>;
  verify(phone: string, code: string): Promise<boolean>;
  access(): Promise<AdminAccess>;
  signOut(): Promise<void>;
};
export async function requestCode(value: string, deps: OtpDependencies): Promise<OtpState> {
  const phone = ghanaPhone(value);
  if (!phone) return { step: 'phone', message: 'Enter a valid Ghana mobile number.' };
  try {
    if (!await deps.request(phone)) return { step: 'phone', message: 'A code could not be requested. Check service availability or try again later.' };
    return { step: 'code', message: 'If this account is eligible to sign in, a code will be delivered.', phone, resendAt: Date.now() + deps.config.resendSeconds * 1000 };
  } catch { return { step: 'phone', message: 'Authentication is unavailable. Try again later.' }; }
}
export async function verifyCode(phoneValue: string, code: string, deps: OtpDependencies): Promise<OtpState | { authorized: true }> {
  const phone = ghanaPhone(phoneValue);
  if (!phone) return { step: 'phone', message: 'Enter a valid Ghana mobile number.' };
  if (!new RegExp(`^[0-9]{${deps.config.otpLength}}$`).test(code)) return { step: 'code', phone, message: `Enter the ${deps.config.otpLength}-digit verification code.` };
  try {
    if (!await deps.verify(phone, code)) return { step: 'code', phone, message: 'This code is invalid or expired, or verification is unavailable. Check the code or request a new one.' };
    const access = await deps.access();
    if (access.status === 'authorized') return { authorized: true };
    await deps.signOut();
    return { step: 'phone', message: access.status === 'forbidden' ? 'This account does not have admin access.' : 'Admin authorization is unavailable. Please try again later.' };
  } catch {
    try { await deps.signOut(); } catch { /* The action clears local auth cookies too. */ }
    return { step: 'phone', message: 'Authentication is unavailable. Please try again later.' };
  }
}
