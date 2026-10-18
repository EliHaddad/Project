'use client';
type SaveHandle={createWritable:()=>Promise<{write:(data:Blob)=>Promise<void>;close:()=>Promise<void>;abort:()=>Promise<void>}>};
type PickerWindow=Window&{showSaveFilePicker?:(options:{suggestedName:string;types?:{description:string;accept:Record<string,string[]>}[]})=>Promise<SaveHandle>};
export async function saveFile(load:()=>Promise<Blob>,name:string):Promise<'saved'|'downloaded'|'cancelled'>{
 const picker=(window as PickerWindow).showSaveFilePicker;let handle:SaveHandle|undefined;
 if(picker&&window.isSecureContext){
  // Open before awaiting the network request, while the click still has user activation.
  try{handle=await picker.call(window,{suggestedName:name});}catch(error){if(error instanceof DOMException&&error.name==='AbortError')return 'cancelled';throw error;}
 }
 const blob=await load();if(!blob.size)throw Error('empty-file');
 if(handle){
  const writable=await handle.createWritable();
  try{await writable.write(blob);await writable.close();}catch(error){try{await writable.abort();}catch{}throw error;}
  return 'saved';
 }
 const url=URL.createObjectURL(blob);const anchor=document.createElement('a');
 anchor.href=url;anchor.download=name;document.body.append(anchor);
 try{anchor.click();}finally{anchor.remove();setTimeout(()=>URL.revokeObjectURL(url),60000);}
 return 'downloaded';
}
