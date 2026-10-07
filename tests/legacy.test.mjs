import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {entities,fieldsFor,table,payloadFrom,normalizeRows,label,creationPayload,linksTable} from '../src/lib/model.ts';
const form=(values)=>{const f=new FormData();for(const [k,v] of Object.entries(values))f.set(k,v);return f;};
const schema=JSON.parse(fs.readFileSync(new URL('../supabase/audit/legacy-columns.json',import.meta.url),'utf8'));
test('every legacy form and creation field exists in the supplied schema',()=>{
 for(const entity of entities){const keys=new Set(schema.filter(c=>c.table===table(entity)).map(c=>c.column));for(const field of fieldsFor(entity,true))assert.ok(keys.has(field.key),`${table(entity)}.${field.key}`);for(const key of Object.keys(creationPayload(entity,{},'user')))assert.ok(keys.has(key));}
 assert.equal(table('activities'),'prospect_activities');assert.equal(linksTable,'prospect_apartments');
});
test('legacy prospects retain separate names, exact status and bigint relation strings',()=>{
 const data=payloadFrom('prospects',form({first_name:'Éli',last_name:'Haddad',status:'À rappeler',project_id:'9007199254740993'}),true);
 assert.equal(data.first_name,'Éli');assert.equal(data.last_name,'Haddad');assert.equal(data.status,'À rappeler');assert.equal(data.project_id,'9007199254740993');assert.equal('name' in data,false);assert.equal(label(normalizeRows([{id:12,...data}])[0]),'Éli Haddad');
});
test('legacy appointments preserve separate date and wall time without UTC conversion',()=>{
 const data=payloadFrom('appointments',form({title:'Visite',prospect_id:'1',appointment_date:'2026-10-09',appointment_time:'10:30'}),true);
 assert.equal(data.appointment_date,'2026-10-09');assert.equal(data.appointment_time,'10:30');assert.equal('starts_at' in data,false);
});
test('legacy tasks and apartment amenities use boolean columns',()=>{
 const task=payloadFrom('tasks',form({title:'Relancer',completed:'on',due_date:'2026-10-10'}),true);assert.equal(task.completed,true);assert.equal('priority' in task,false);assert.equal('status' in task,false);
 const flat=payloadFrom('apartments',form({project_id:'1',parking:'on'}),true);assert.equal(flat.parking,true);assert.equal(flat.storage,false);assert.equal('currency' in flat,false);
});
test('numeric ids normalize for relation matching and unsafe bigint numbers are rejected',()=>{
 const row=normalizeRows([{id:10,project_id:2,parking:true}])[0];assert.equal(row.id,'10');assert.equal(row.project_id,'2');assert.equal(row.parking,true);
 assert.throws(()=>normalizeRows([{id:9007199254740992}]),/unsafe-id/);
});
