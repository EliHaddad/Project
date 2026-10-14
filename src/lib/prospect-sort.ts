import type {Row} from './model';

// ISO dates and local reception times sort chronologically without UTC conversion.
export function compareReception(a: Row, b: Row, order: 'asc' | 'desc') {
 const aDate=String(a.received_on??''),bDate=String(b.received_on??'');
 if(!aDate||!bDate)return aDate?-1:bDate?1:0;
 const comparison=aDate.localeCompare(bDate)||String(a.received_time??'').localeCompare(String(b.received_time??''));
 return order==='asc'?comparison:-comparison;
}
