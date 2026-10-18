import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';
function setup(picker){
 const events=[];const exports={};const anchor={remove:()=>events.push('remove'),click:()=>events.push('click')};
 vm.runInNewContext(ts.transpileModule(fs.readFileSync('src/lib/save-file.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,{exports,window:{isSecureContext:true,showSaveFilePicker:picker},document:{body:{append:()=>events.push('append')},createElement:()=>anchor},URL:{createObjectURL:()=>{events.push('object-url');return 'blob:test'},revokeObjectURL:()=>events.push('revoke')},DOMException,setTimeout:callback=>callback()});
 return {save:exports.saveFile,events,anchor};
}
test('opens destination picker before network and confirms only after writing and closing',async()=>{
 const steps=[];const blob=new Blob(['PDF bytes']);
 const {save}=setup(async options=>{assert.equal(options.suggestedName,'תוכנית.pdf');steps.push('picker');return {createWritable:async()=>({write:async data=>{assert.equal(data,blob);steps.push('write')},close:async()=>steps.push('close'),abort:async()=>steps.push('abort')})}});
 const result=await save(async()=>{steps.push('load');return blob},'תוכנית.pdf');assert.equal(result,'saved');assert.deepEqual(steps,['picker','load','write','close']);
});
test('canceling the folder picker does not fetch or report success',async()=>{
 const {save}=setup(async()=>{throw new DOMException('Cancelled','AbortError')});assert.equal(await save(async()=>{assert.fail('must not load')},'plan.jpeg'),'cancelled');
});
test('write failure aborts the stream and does not return saved',async()=>{
 let aborted=false;const {save}=setup(async()=>({createWritable:async()=>({write:async()=>{throw Error('disk-full')},close:async()=>assert.fail('must not close'),abort:async()=>{aborted=true}})}));
 await assert.rejects(()=>save(async()=>new Blob(['image']),'plan.jpeg'),/disk-full/);assert.equal(aborted,true);
});
test('unsupported browsers get an attached download anchor and preserve the filename',async()=>{
 const {save,events,anchor}=setup();assert.equal(await save(async()=>new Blob(['image']),'plan.jpeg'),'downloaded');assert.equal(anchor.download,'plan.jpeg');assert.deepEqual(events,['object-url','append','click','remove','revoke']);
});
test('empty responses do not start downloads',async()=>{
 const {save,events}=setup();await assert.rejects(()=>save(async()=>new Blob([]),'plan.pdf'),/empty-file/);assert.deepEqual(events,[]);
});
