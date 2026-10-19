'use client';
import { useActionState, useEffect, useState } from 'react';
import { requestAdminCode, verifyAdminCode } from '../app/login/actions';
import type { OtpState } from '../lib/auth/otp';
const initial: OtpState = { step: 'phone', message: '' };
export function AdminLogin({otpLength,resendSeconds}: {otpLength:number;resendSeconds:number}) {
  const [request, requestAction, requesting] = useActionState(requestAdminCode, initial);
  const [verification, verifyAction, verifying] = useActionState(verifyAdminCode, initial);
  const [now, setNow] = useState(0);
  useEffect(() => { const timer = window.setInterval(()=>setNow(Date.now()),1000); return ()=>window.clearInterval(timer); },[]);
  const remaining = Math.min(resendSeconds, Math.max(0, Math.ceil(((request.resendAt ?? 0) - now)/1000)));
  if (request.step !== 'code') return <form action={requestAction} className="panel stack"><h2>Sign in to RydVia Admin</h2><p>Use your provisioned staff account. Verification alone does not grant admin access.</p><label className="stack">Mobile number · 🇬🇭 +233<input name="phone" type="tel" autoComplete="tel-national" required placeholder="Enter your mobile number" /></label>{request.message && <p role="status">{request.message}</p>}<button disabled={requesting}>{requesting ? 'Requesting code…' : 'Continue'}</button></form>;
  return <div className="panel stack"><form action={verifyAction} className="stack"><h2>Enter Code</h2><p>{request.message}</p><input type="hidden" name="phone" value={request.phone ?? ''}/><label className="stack">{otpLength}-digit verification code<input name="code" type="text" inputMode="numeric" autoComplete="one-time-code" pattern={`[0-9]{${otpLength}}`} minLength={otpLength} maxLength={otpLength} autoFocus required /></label>{verification.message && <p role="alert">{verification.message}</p>}<button disabled={verifying}>{verifying ? 'Verifying…' : 'Continue'}</button></form><form action={requestAction}><input type="hidden" name="phone" value={request.phone ?? ''}/><button disabled={remaining > 0 || requesting}>{remaining > 0 ? `Resend code in ${remaining}s` : 'Resend code'}</button></form><button className="button secondary" onClick={()=>window.location.reload()}>Change number</button></div>;
}
