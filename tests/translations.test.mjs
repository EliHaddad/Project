import fs from 'node:fs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {entities,fields} from '../src/lib/model.ts';
test('FR HE EN have the same complete translation keys',()=>{
 const dictionaries=['fr','he','en'].map(l=>JSON.parse(fs.readFileSync(new URL(`../messages/${l}.json`,import.meta.url),'utf8')));
 for(const dictionary of dictionaries){assert.deepEqual(Object.keys(dictionary).sort(),Object.keys(dictionaries[0]).sort());for(const e of entities){assert.ok(dictionary[e]);for(const f of fields[e])assert.ok(dictionary[f.key]);}for(const v of Object.values(dictionary))assert.equal(typeof v,'string');}
});
