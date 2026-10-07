export const entities = ['prospects','projects','apartments','appointments','activities','tasks'] as const;
export type Entity = typeof entities[number];
export type Row = {id:string;[key:string]:string|number|boolean|null|undefined};
export type Field = {key:string;type?:'text'|'email'|'tel'|'number'|'textarea'|'datetime-local'|'date'|'time'|'checkbox'|'relation';required?:boolean;relation?:Entity;min?:number;step?:string};
export const legacyMode = process.env.NEXT_PUBLIC_DATABASE_MODE !== 'reconstruction';
const reconstructedFields: Record<Entity,Field[]> = {
 prospects:[{key:'name',required:true},{key:'email',type:'email'},{key:'phone',type:'tel'},{key:'status'},{key:'source'},{key:'budget',type:'number',min:0},{key:'city'},{key:'notes',type:'textarea'}],
 projects:[{key:'name',required:true},{key:'city'},{key:'address'},{key:'developer'},{key:'status'},{key:'delivery_date',type:'date'},{key:'notes',type:'textarea'}],
 apartments:[{key:'reference',required:true},{key:'project_id',type:'relation',relation:'projects',required:true},{key:'floor',type:'number',step:'1'},{key:'rooms',type:'number',min:0,step:'0.5'},{key:'area',type:'number',min:0,step:'0.01'},{key:'price',type:'number',min:0},{key:'currency',required:true},{key:'status'},{key:'notes',type:'textarea'}],
 appointments:[{key:'title',required:true},{key:'prospect_id',type:'relation',relation:'prospects',required:true},{key:'apartment_id',type:'relation',relation:'apartments'},{key:'starts_at',type:'datetime-local',required:true},{key:'ends_at',type:'datetime-local'},{key:'location'},{key:'status'},{key:'notes',type:'textarea'}],
 activities:[{key:'title',required:true},{key:'prospect_id',type:'relation',relation:'prospects',required:true},{key:'kind'},{key:'occurred_at',type:'datetime-local',required:true},{key:'notes',type:'textarea'}],
 tasks:[{key:'title',required:true},{key:'prospect_id',type:'relation',relation:'prospects'},{key:'due_at',type:'datetime-local'},{key:'status'},{key:'priority'},{key:'notes',type:'textarea'}]
};
const legacyFields:Record<Entity,Field[]>={
 prospects:[{key:'first_name',required:true},{key:'last_name',required:true},{key:'email',type:'email'},{key:'phone',type:'tel'},{key:'language'},{key:'country'},{key:'status'},{key:'source'},{key:'budget',type:'number',min:0},{key:'rooms',type:'number',min:0,step:'1'},{key:'city'},{key:'project_id',type:'relation',relation:'projects'},{key:'notes',type:'textarea'}],
 projects:[{key:'name',required:true},{key:'city'},{key:'address'},{key:'neighborhood'},{key:'developer'},{key:'status'},{key:'delivery_date',type:'date'},{key:'starting_price',type:'number',min:0},{key:'apartment_types'},{key:'brochure_url'},{key:'google_maps_url'},{key:'description',type:'textarea'}],
 apartments:[{key:'apartment_number'},{key:'reference'},{key:'project_id',type:'relation',relation:'projects',required:true},{key:'floor',type:'number',step:'1'},{key:'rooms',type:'number',min:0,step:'0.5'},{key:'area',type:'number',min:0},{key:'surface',type:'number',min:0},{key:'terrace',type:'number',min:0},{key:'garden',type:'number',min:0},{key:'parking',type:'checkbox'},{key:'storage',type:'checkbox'},{key:'price',type:'number',min:0},{key:'direction'},{key:'status'},{key:'notes',type:'textarea'}],
 appointments:[{key:'title',required:true},{key:'prospect_id',type:'relation',relation:'prospects',required:true},{key:'project_id',type:'relation',relation:'projects'},{key:'apartment_id',type:'relation',relation:'apartments'},{key:'appointment_type'},{key:'appointment_date',type:'date',required:true},{key:'appointment_time',type:'time',required:true},{key:'status'},{key:'notes',type:'textarea'}],
 activities:[{key:'prospect_id',type:'relation',relation:'prospects',required:true},{key:'activity_type'},{key:'description',type:'textarea',required:true},{key:'activity_date',type:'datetime-local',required:true},{key:'follow_up_date',type:'datetime-local'},{key:'follow_up_done',type:'checkbox'}],
 tasks:[{key:'title',required:true},{key:'prospect_id',type:'relation',relation:'prospects'},{key:'due_date',type:'date'},{key:'completed',type:'checkbox'},{key:'description',type:'textarea'}]
};
export const fields=legacyMode?legacyFields:reconstructedFields;
export function fieldsFor(entity:Entity,legacy=legacyMode){return (legacy?legacyFields:reconstructedFields)[entity];}
export function isEntity(value:string):value is Entity {return entities.includes(value as Entity);}
export function label(row:Row) {return String(row.name || [row.first_name,row.last_name].filter(Boolean).join(' ') || row.reference || row.apartment_number || row.title || row.description || row.id);}
export function table(entity:Entity) {return legacyMode?(entity==='activities'?'prospect_activities':entity):`yi_${entity}`;}
export const linksTable=legacyMode?'prospect_apartments':'yi_prospect_apartments';
export function creationPayload(entity:Entity,payload:Record<string,string|number|boolean|null>,userId:string){
 if(!legacyMode)return {...payload,owner_id:userId};
 const userColumn=['projects','apartments','activities'].includes(entity)?'created_by':'assigned_to';
 return {...payload,[userColumn]:userId};
}
export function normalizeRows(rows:unknown[]):Row[]{return rows.map(row=>{
 if(typeof row!=='object'||row===null||Array.isArray(row)||!('id' in row))throw new Error('invalid-row');
 const result:Record<string,unknown>={...row};for(const key of Object.keys(result)){if(key==='id'||key.endsWith('_id')){const value=result[key];if(typeof value==='number'&&!Number.isSafeInteger(value))throw new Error('unsafe-id');if(value!==null&&value!==undefined)result[key]=String(value);}}
 return result as Row;
});}
export function localDate(value:string) {const date=new Date(value);return new Date(date.getTime()-date.getTimezoneOffset()*60000).toISOString().slice(0,16);}
export function payloadFrom(entity:Entity,form:FormData,legacy=legacyMode) {
 const payload:Record<string,string|number|boolean|null>={};
 for(const field of fieldsFor(entity,legacy)) {
  const raw=String(form.get(field.key)??'');
  if(field.required&&!raw.trim())throw new Error('required');
  if(field.type==='checkbox'){payload[field.key]=raw==='on'||raw==='true';continue;}
  if(raw===''){payload[field.key]=null;continue;}
  if(field.type==='relation'&&legacy&&!/^\d+$/.test(raw))throw new Error('relation');
  if(field.type==='number'){const value=Number(raw);if(!Number.isFinite(value)||(field.min!==undefined&&value<field.min)||(field.key==='floor'&&!Number.isInteger(value)))throw new Error('number');payload[field.key]=value;}
  else if(field.type==='datetime-local'){const date=new Date(raw);if(Number.isNaN(date.getTime()))throw new Error('date');payload[field.key]=date.toISOString();}
  else payload[field.key]=raw;
 }
 if(!legacy&&entity==='appointments'&&payload.ends_at&&String(payload.ends_at)<=String(payload.starts_at))throw new Error('date');
 return payload;
}
