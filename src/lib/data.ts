'use client';
import {supabase} from './supabase';
import {table,linksTable,legacyMode,normalizeRows,type Entity,type Row} from './model';
export function scoped(entity:Entity|'prospect_apartments',userId:string,columns='*',options?:{count:'exact';head?:boolean}){
 const query=supabase().from(entity==='prospect_apartments'?linksTable:table(entity)).select(columns,options);
 return legacyMode?query:query.eq('owner_id',userId);
}
// Page through PostgREST to avoid silently losing rows at its default row limit.
export async function fetchAll(entity:Entity|'prospect_apartments',ownerId:string,filters:Record<string,string>={}) {
 const result:Row[]=[];const size=250;
 for(let offset=0;;offset+=size){
  let query=scoped(entity,ownerId).order('created_at',{ascending:false}).order('id').range(offset,offset+size-1);
  for(const [key,value] of Object.entries(filters))query=query.eq(key,value);
  const {data,error}=await query;if(error)throw error;
  result.push(...normalizeRows(data??[]));if(!data?.length||data.length<size)break;
 }
 return result;
}
