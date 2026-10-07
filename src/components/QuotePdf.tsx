'use client';
import {useEffect,useState,useRef} from 'react';
import {createPortal} from 'react-dom';
import {useLocale,useTranslations} from 'next-intl';
import PaymentSheet from './PaymentSheet';
import {type PaymentTemplate} from '@/lib/payment-template';

export default function QuotePdf({title,value,text,disabled=false}:{title:string;value?:PaymentTemplate;text?:string;disabled?:boolean}){
 const t=useTranslations(),locale=useLocale();
 const [open,setOpen]=useState(false);
 const documentRef=useRef<HTMLElement>(null);
 const [generating,setGenerating]=useState(false),[error,setError]=useState('');
 async function download(){
  if(!documentRef.current||generating)return;
  setGenerating(true);setError('');
  try{
   await document.fonts.ready;
   const [{toCanvas},{jsPDF}]=await Promise.all([import('html-to-image'),import('jspdf')]);
   const canvas=await toCanvas(documentRef.current,{width:800,height:documentRef.current.scrollHeight,pixelRatio:2,backgroundColor:'#ffffff',cacheBust:true,skipFonts:true,style:{width:'800px',maxWidth:'800px',minWidth:'800px',margin:'0',boxSizing:'border-box',direction:locale==='he'?'rtl':'ltr',overflow:'visible'}});
   const context=canvas.getContext('2d');if(!context||!canvas.width||!canvas.height)throw new Error('empty');
   const pixels=context.getImageData(0,0,canvas.width,canvas.height).data;
   let visible=false;for(let i=0;i<pixels.length;i+=4){if(pixels[i]<220||pixels[i+1]<220||pixels[i+2]<220){visible=true;break;}}
   if(!visible)throw new Error('empty');
   const pdf=new jsPDF({orientation:'portrait',unit:'mm',format:'a4'});
   pdf.setProperties({title:`Yonathan Immobilier - ${title}`,creator:'Yonathan Immobilier'});
   const width=182,height=269,pagePixels=Math.floor(canvas.width*height/width);
   for(let offset=0;offset<canvas.height;offset+=pagePixels){
    if(offset)pdf.addPage();
    const page=document.createElement('canvas');page.width=canvas.width;page.height=Math.min(pagePixels,canvas.height-offset);
    const pageContext=page.getContext('2d');if(!pageContext)throw new Error('canvas');
    pageContext.drawImage(canvas,0,offset,canvas.width,page.height,0,0,page.width,page.height);
    pdf.addImage(page.toDataURL('image/png'),'PNG',14,14,width,page.height*width/page.width);
   }
   pdf.save(`Devis-Yonathan-${title.replace(/[<>:"/\\|?*\x00-\x1f]/g,'-').slice(0,80)}.pdf`);
  }catch{setError(t('pdfError'));}finally{setGenerating(false);}
 }
 useEffect(()=>{if(!open)return;const previous=document.title;document.title=`Yonathan Immobilier - ${t('quote')} - ${title}`;return()=>{document.title=previous;};},[open,title,t]);
 return <><button type="button" disabled={disabled} onClick={()=>setOpen(true)}>{t('generateQuotePdf')}</button>{open&&createPortal(<div className="quote-overlay" role="dialog" aria-modal="true" aria-labelledby="quote-heading" dir={locale==='he'?'rtl':'ltr'}><div className="quote-tools"><p>{t('pdfInstructions')}</p><div className="flex gap-3"><button type="button" autoFocus disabled={generating} onClick={download}>{t(generating?'pdfGenerating':'savePdf')}</button><button type="button" disabled={generating} onClick={()=>setOpen(false)}>{t('closeQuote')}</button></div></div>{error&&<p role="alert" className="error">{error}</p>}<article ref={documentRef} className="quote-document" dir={locale==='he'?'rtl':'ltr'}><header className="quote-header"><strong>Yonathan Immobilier</strong><h1 id="quote-heading">{t('quote')}</h1><p>{new Date().toLocaleDateString(locale)}</p></header>{value?<PaymentSheet title={title} value={value}/>:<><h2>{title}</h2><p className="quote-text">{text}</p></>}<footer>{t('quoteFooter')}</footer></article></div>,document.body)}</>;
}
