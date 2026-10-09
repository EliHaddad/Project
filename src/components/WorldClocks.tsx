'use client';
import {useEffect,useState} from 'react';
import {useLocale,useTranslations} from 'next-intl';

const locations=[{key:'clockFrance',zone:'Europe/Paris',flag:'🇫🇷'},{key:'clockNewYork',zone:'America/New_York',flag:'🇺🇸'},{key:'clockIsrael',zone:'Asia/Jerusalem',flag:'🇮🇱'}] as const;
export default function WorldClocks(){
 const t=useTranslations(),locale=useLocale();
 const [now,setNow]=useState<Date|null>(null);
 useEffect(()=>{setNow(new Date());const timer=setInterval(()=>setNow(new Date()),1000);return()=>clearInterval(timer);},[]);
 return <section className="world-clocks" aria-label={t('worldClocks')}>{locations.map(({key,zone,flag})=>{
  const parts=now?new Intl.DateTimeFormat('en-GB',{timeZone:zone,hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'}).formatToParts(now):[];
  const part=(type:string)=>Number(parts.find(p=>p.type===type)?.value??0);
  const hour=part('hour'),minute=part('minute'),second=part('second');
  return <article className="world-clock" key={zone}><div className="clock-face" aria-hidden="true">{Array.from({length:12},(_,i)=><span className="clock-tick" key={i} style={{transform:`rotate(${i*30}deg)`}}/>)}<span className="clock-hand clock-hour" style={{transform:`rotate(${hour*30+minute*.5}deg)`}}/><span className="clock-hand clock-minute" style={{transform:`rotate(${minute*6+second*.1}deg)`}}/><span className="clock-center"/></div><div className="clock-copy"><h2><span aria-hidden="true">{flag}</span> {t(key)}</h2><time dateTime={now?.toISOString()} dir="ltr">{now?new Intl.DateTimeFormat(locale,{timeZone:zone,hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).format(now):'--:--'}</time><p>{now?new Intl.DateTimeFormat(locale,{timeZone:zone,weekday:'short',day:'numeric',month:'short'}).format(now):'—'}</p></div></article>;
 })}</section>;
}
