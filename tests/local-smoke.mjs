// Run with a production server already started: node tests/local-smoke.mjs
import assert from 'node:assert/strict';
const base=process.env.SMOKE_URL??'http://localhost:3100';
for(const [locale,dir,title] of [['fr','ltr','Configurer Supabase'],['he','rtl','הגדרת Supabase'],['en','ltr','Configure Supabase']]) {
 const response=await fetch(`${base}/${locale}`);assert.equal(response.status,200);
 const html=await response.text();assert.ok(html.includes(`lang="${locale}"`));assert.ok(html.includes(`dir="${dir}"`));assert.ok(html.includes(title));
 assert.ok(html.includes('Yonathan Immobilier'));
 console.log(`${locale}: HTTP 200, locale, direction, title verified`);
}
const root=await fetch(base,{redirect:'manual'});assert.equal(root.status,307);assert.equal(root.headers.get('location'),'/fr');
const unknown=await fetch(`${base}/de`);assert.equal(unknown.status,404);
console.log('Default redirect and unsupported locale verified');
