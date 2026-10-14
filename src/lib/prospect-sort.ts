import type {Row} from './model';

export function compareProspects(a: Row, b: Row, key: string, order: 'asc'|'desc', locale: string) {
 if(key==='receivedOn')return compareReception(a,b,order);
 const value=(row:Row)=>key==='first_name'?`${row.first_name??''} ${row.last_name??''}`.trim():String(row[key]??'').trim();
 const av=value(a),bv=value(b);
 if(!av||!bv)return av?-1:bv?1:0;
 const comparison=key==='budget'?Number(av)-Number(bv):av.localeCompare(bv,locale,{numeric:true,sensitivity:'base'});
 return order==='asc'?comparison:-comparison;
}

// ISO dates and local reception times sort chronologically without UTC conversion.
export function compareReception(a: Row, b: Row, order: 'asc' | 'desc') {
 const aDate=String(a.received_on??''),bDate=String(b.received_on??'');
 if(!aDate||!bDate)return aDate?-1:bDate?1:0;
 const comparison=aDate.localeCompare(bDate)||String(a.received_time??'').localeCompare(String(b.received_time??''));
 return order==='asc'?comparison:-comparison;
}
