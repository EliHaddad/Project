import test from 'node:test';
import assert from 'node:assert/strict';
import {payloadFrom} from '../src/lib/model.ts';
const form=(values)=>{const data=new FormData();for(const [k,v] of Object.entries(values))data.set(k,v);return data;};
test('canonical DB values are retained exactly',()=>{
 const data=payloadFrom('prospects',form({name:'Éli',status:'À rappeler',source:'המלצה'}),false);
 assert.equal(data.status,'À rappeler');assert.equal(data.source,'המלצה');assert.equal(data.phone,null);
});
test('reject negative budget and non-integral floor',()=>{
 assert.throws(()=>payloadFrom('prospects',form({name:'Éli',budget:'-1'}),false),/number/);
 assert.throws(()=>payloadFrom('apartments',form({reference:'A1',project_id:'uuid',currency:'ILS',floor:'1.5'}),false),/number/);
});
test('appointment end must be after start and dates stored in UTC',()=>{
 assert.throws(()=>payloadFrom('appointments',form({title:'Visit',prospect_id:'uuid',starts_at:'2026-10-07T12:00:00Z',ends_at:'2026-10-07T11:00:00Z'}),false),/date/);
 const data=payloadFrom('appointments',form({title:'Visit',prospect_id:'uuid',starts_at:'2026-10-07T12:00:00+03:00',ends_at:'2026-10-07T13:00:00+03:00'}),false);
 assert.equal(data.starts_at,'2026-10-07T09:00:00.000Z');
});
test('whitelist rejects client owner injection and requires name',()=>{
 assert.throws(()=>payloadFrom('prospects',form({name:'   '}),false),/required/);
 assert.equal('owner_id' in payloadFrom('prospects',form({name:'A',owner_id:'attacker'}),false),false);
});
