'use client';
import {useEffect,useState,type ReactNode} from 'react';
import {useTranslations} from 'next-intl';
import {supabase} from '@/lib/supabase';

export function MfaGate({children,userId}:{children:ReactNode;userId:string}){
 const t=useTranslations();const [ready,setReady]=useState(false),[factor,setFactor]=useState(''),[error,setError]=useState(false);
 async function check(){setReady(false);setError(false);try{const db=supabase();const [f,a]=await Promise.all([db.auth.mfa.listFactors(),db.auth.mfa.getAuthenticatorAssuranceLevel()]);if(f.error||a.error)throw Error();const verified=f.data.totp.find(x=>x.status==='verified');setFactor(verified&&a.data.currentLevel!=='aal2'?verified.id:'');setReady(true);}catch{setError(true);}}
 useEffect(()=>{void check();},[userId]);
 if(error)return <section className="panel"><p role="alert">{t('securityError')}</p><button onClick={check}>{t('securityRetry')}</button></section>;
 if(!ready)return <p role="status">{t('loading')}</p>;
 if(factor)return <AccountSecurity challengeFactor={factor} onVerified={check}/>;
 return children;
}

export default function AccountSecurity({challengeFactor,onVerified}:{challengeFactor?:string;onVerified?:()=>void}){
 const t=useTranslations();const [factor,setFactor]=useState(challengeFactor||''),[qr,setQr]=useState(''),[code,setCode]=useState(''),[busy,setBusy]=useState(false),[error,setError]=useState(false),[enabled,setEnabled]=useState(false);
 useEffect(()=>{if(challengeFactor)return;supabase().auth.mfa.listFactors().then(({data,error})=>{if(error)setError(true);else setEnabled(Boolean(data.totp.some(f=>f.status==='verified')));});},[challengeFactor]);
 async function enroll(){setBusy(true);setError(false);try{const result=await supabase().auth.mfa.enroll({factorType:'totp',friendlyName:'Yonathan CRM '+Date.now()});if(result.error)throw result.error;setFactor(result.data.id);setQr(result.data.totp.qr_code);}catch{setError(true);}finally{setBusy(false);}}
 async function verify(e:React.FormEvent){e.preventDefault();setBusy(true);setError(false);try{const r=await supabase().auth.mfa.challengeAndVerify({factorId:factor,code});if(r.error)throw r.error;setQr('');setCode('');setEnabled(true);onVerified?.();}catch{setError(true);}finally{setBusy(false);}}
 return <section className="panel max-w-lg mx-auto"><h1>{t('accountSecurity')}</h1><p>{t('securityHelp')}</p>{enabled?<p role="status" className="success">{t('securityEnabled')}</p>:factor?<><p>{t(challengeFactor?'securityChallenge':'securityScan')}</p>{qr&&<img src={qr} alt={t('securityScan')} width={220} height={220}/>}<form onSubmit={verify} className="grid gap-4"><label>{t('securityCode')}<input inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} required value={code} onChange={e=>setCode(e.target.value.replace(/\D/g,''))}/></label><button disabled={busy}>{t('securityVerify')}</button></form></>:<button disabled={busy} onClick={enroll}>{t('securityActivate')}</button>}{error&&<p role="alert" className="error">{t('securityError')}</p>}{challengeFactor&&<button onClick={()=>supabase().auth.signOut()}>{t('signOut')}</button>}</section>;
}
