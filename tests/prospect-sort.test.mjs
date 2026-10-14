import test from 'node:test';
import assert from 'node:assert/strict';
import {compareReception} from '../src/lib/prospect-sort.ts';

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
