import test from 'node:test';
import assert from 'node:assert/strict';
import {compareReception,compareProspects} from '../src/lib/prospect-sort.ts';

test('reception sorting uses date then time and keeps missing dates last in both directions',()=>{
 const rows=[
  {id:'unknown',received_on:null,created_at:'2030-01-01'},
  {id:'late',received_on:'2026-10-14',received_time:'15:00:00'},
  {id:'old',received_on:'2026-09-30',received_time:'18:00:00'},
  {id:'early',received_on:'2026-10-14',received_time:'09:00:00'},
  {id:'blank',received_on:''},
 ];
 assert.deepEqual([...rows].sort((a,b)=>compareReception(a,b,'desc')).map(r=>r.id),['late','early','old','unknown','blank']);
 assert.deepEqual([...rows].sort((a,b)=>compareReception(a,b,'asc')).map(r=>r.id),['old','early','late','unknown','blank']);
 assert.equal(compareReception(rows[1],rows[1],'asc'),0);
});

test('prospect columns sort names, text and numeric budgets with empty values last',()=>{
 const rows=[{id:'a',first_name:'Alice',last_name:'Z',budget:100,city:'Paris',status:'Client',phone:'10'},
 {id:'b',first_name:'Alice',last_name:'A',budget:20,city:'Lyon',status:'À contacter',phone:'2'},
 {id:'c',first_name:'',budget:null,city:null,status:'',phone:''}];
 for(const key of ['first_name','budget','city','status','phone']) {
  assert.deepEqual([...rows].sort((a,b)=>compareProspects(a,b,key,'asc','fr')).map(r=>r.id),['b','a','c']);
  assert.deepEqual([...rows].sort((a,b)=>compareProspects(a,b,key,'desc','fr')).map(r=>r.id),['a','b','c']);
 }
 assert.ok(compareProspects({id:'zero',budget:0},{id:'missing',budget:null},'budget','desc','fr')<0);
});
