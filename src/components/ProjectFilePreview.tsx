'use client';
import {useEffect,useId,useRef,useState} from 'react';
import {createPortal} from 'react-dom';
import {useTranslations} from 'next-intl';
export type PreviewFile={name:string;load:()=>Promise<Blob>};
export default function ProjectFilePreview({file,onClose}:{file:PreviewFile;onClose:()=>void}){
 const t=useTranslations(),title=useId();const dialog=useRef<HTMLDialogElement>(null);
 const [url,setUrl]=useState(''),[error,setError]=useState(false);
 const pdf=/\.pdf$/i.test(file.name);
 useEffect(()=>{const element=dialog.current;element?.showModal();return()=>element?.close();},[]);
 useEffect(()=>{
  let active=true,objectUrl='';setUrl('');setError(false);
  async function load(){try{
   const extension=file.name.split('.').pop()?.toLowerCase();
   const type=extension==='pdf'?'application/pdf':extension==='jpg'||extension==='jpeg'?'image/jpeg':extension==='png'?'image/png':extension==='webp'?'image/webp':null;
   if(!type)throw Error('format');const blob=await file.load();if(!blob.size)throw Error('empty');if(!active)return;
   // Never render Storage responses as HTML, even if their server MIME type is incorrect.
   objectUrl=URL.createObjectURL(new Blob([blob],{type}));setUrl(objectUrl);
  }catch{if(active)setError(true);}}
  void load();return()=>{active=false;if(objectUrl)URL.revokeObjectURL(objectUrl);};
 },[file]);
 return createPortal(<dialog ref={dialog} onCancel={onClose} aria-labelledby={title} style={{width:'min(1100px, 95vw)',maxWidth:'95vw',maxHeight:'95vh',padding:'1rem',borderRadius:'12px',border:'1px solid #ddd'}}><div className="flex items-center justify-between gap-4 mb-4"><h2 id={title} style={{overflowWrap:'anywhere'}}>{file.name}</h2><button type="button" autoFocus onClick={onClose}>{t('dossierPreviewClose')}</button></div>{error?<p role="alert" className="error">{t('dossierPreviewError')}</p>:!url?<p role="status">{t('loading')}</p>:pdf?<><iframe title={file.name} src={`${url}#view=FitH`} style={{width:'100%',height:'70vh',border:0}}/><p className="muted">{t('dossierPdfPreviewHelp')}</p></>:<div style={{maxHeight:'75vh',overflow:'auto',textAlign:'center'}}><img src={url} alt={file.name} style={{maxWidth:'100%',height:'auto',margin:'auto'}} onError={()=>setError(true)}/></div>}</dialog>,document.body);
}
