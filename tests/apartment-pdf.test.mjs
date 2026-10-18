import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';
import * as parsing from '../src/lib/apartment-import.ts';
const exports={};
vm.runInNewContext(ts.transpileModule(fs.readFileSync('src/lib/apartment-pdf.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,{exports,require:()=>parsing});
const {apartmentsFromPdfPage}=exports;
test('provided Hebrew PDF extracts all 19 apartments with exact prices, gardens, terraces and wrapped directions',async()=>{
 const {getDocument}=await import('pdfjs-dist/legacy/build/pdf.mjs');
 const task=getDocument({data:new Uint8Array(fs.readFileSync('tests/fixtures/rashbag37-price.pdf')),isEvalSupported:false,useSystemFonts:true});
 try{
  const pdf=await task.promise;const text=await(await pdf.getPage(1)).getTextContent();
  const rows=parsing.validateApartments(apartmentsFromPdfPage(text.items.flatMap(i=>'str' in i?[{text:i.str,x:i.transform[4],y:i.transform[5],width:i.width}]:[])));
  assert.deepEqual(Array.from(rows,r=>[r.apartment_number,r.price]),[['2',4730100],['3',4565850],['4',4614600],['6',4658625],['8',3660525],['9',4589550],['11',3546000],['12',3547800],['13',4555125],['15',3487725],['16',3489525],['17',7472025],['18',4303350],['19',4296825],['20',4306950],['21',4291425],['22',6516900],['23',7087950],['24',7053300]]);assert.equal(rows.length,19);assert.equal(rows[0].price,4730100);assert.equal(rows[0].garden,27.22);assert.equal(rows[0].floor,0);
  const lot=number=>rows.find(r=>r.apartment_number===String(number));
  assert.equal(lot(15).price,3487725);assert.equal(lot(17).area,158.43);assert.equal(lot(17).rooms,6);assert.equal(lot(17).terrace,15.23);
  assert.ok(lot(17).direction.includes('דרום מערב'));assert.equal(lot(22).terrace,45.16);assert.equal(lot(24).price,7053300);assert.equal(lot(24).floor,6);
  assert.equal('parking' in lot(24),false);
 }finally{await task.destroy();}
});
test('PDF without a recognizable apartment table yields no invented rows',()=>{
 assert.equal(apartmentsFromPdfPage([]).length,0);
 assert.equal(apartmentsFromPdfPage([{text:'Apartment plan',x:1,y:1,width:100}]).length,0);
});
