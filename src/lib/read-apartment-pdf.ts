import {apartmentsFromPdfPage} from './apartment-pdf';
export async function readApartmentPdf(file:File){
 const pdfjs=await import('pdfjs-dist');
 pdfjs.GlobalWorkerOptions.workerSrc=new URL('pdfjs-dist/build/pdf.worker.min.mjs',import.meta.url).toString();
 const task=pdfjs.getDocument({data:new Uint8Array(await file.arrayBuffer()),useSystemFonts:true});
 try{
  const pdf=await task.promise;if(pdf.numPages>50)throw Error('pdf-size');
  const rows:Record<string,unknown>[]=[];let tablePages=0;
  for(let i=1;i<=pdf.numPages;i++){
   const page=await pdf.getPage(i);const text=await page.getTextContent();
   const result=apartmentsFromPdfPage(text.items.flatMap(item=>'str' in item?[{text:item.str,x:item.transform[4],y:item.transform[5],width:item.width}]:[]));
   if(result.length)tablePages++;rows.push(...result.map(row=>({...row,notes:`${file.name} — page ${i}. ${row.notes??''}`})));page.cleanup();
   if(rows.length>1000)throw Error('rows');
  }
  if(!rows.length)throw Error('pdf-table');return {rows,pages:pdf.numPages,tablePages};
 }finally{await task.destroy();}
}
