import {apartmentHeaderAliases,normalizeApartmentHeader} from './apartment-import';
export type PdfCell={text:string;x:number;y:number;width:number};
const clean=(s:string)=>s.replace(/[\u200e\u200f\u202a-\u202e\u2066-\u2069]/g,'').trim();
export function apartmentsFromPdfPage(cells:PdfCell[]):Record<string,unknown>[] {
 const sorted=cells.filter(c=>clean(c.text)).map(c=>({...c,text:clean(c.text)})).sort((a,b)=>b.y-a.y||a.x-b.x);
 const identifier=sorted.find(c=>['apartment_number','reference'].includes(apartmentHeaderAliases[normalizeApartmentHeader(c.text)]));
 if(!identifier)return [];
 const headers=sorted.filter(c=>Math.abs(c.y-identifier.y)<4).map(c=>({...c,key:apartmentHeaderAliases[normalizeApartmentHeader(c.text)]??'',center:c.x+c.width/2})).sort((a,b)=>a.center-b.center);
 if(new Set(headers.map(h=>h.key).filter(Boolean)).size<3)return [];
 const nearest=(cell:PdfCell)=>headers.reduce((best,h)=>Math.abs(h.center-cell.x-cell.width/2)<Math.abs(best.center-cell.x-cell.width/2)?h:best);
 const below=sorted.filter(c=>c.y<identifier.y-5);
 const anchors=below.filter(c=>['apartment_number','reference'].includes(nearest(c).key)&&/^[\p{L}\d][\p{L}\d./_-]{0,30}$/u.test(c.text)&&/\d/.test(c.text));
 if(!anchors.length)return [];
 const gaps=anchors.slice(1).map((c,i)=>Math.abs(c.y-anchors[i].y)).filter(n=>n>4).sort((a,b)=>a-b);
 const tolerance=Math.min(14,(gaps[Math.floor(gaps.length/2)]??20)/2-0.5);
 const rows=anchors.map(()=>({} as Record<string,string>));
 for(const cell of below){
  const key=nearest(cell).key;if(!key)continue;
  let index=0;for(let i=1;i<anchors.length;i++)if(Math.abs(anchors[i].y-cell.y)<Math.abs(anchors[index].y-cell.y))index=i;
  if(Math.abs(anchors[index].y-cell.y)>tolerance)continue;
  rows[index][key]=[rows[index][key],cell.text].filter(Boolean).join(' ');
 }
 const floors:Record<string,string>={'קרקע':'0','א':'1','ב':'2','ג':'3','ד':'4','ה':'5','ו':'6','ז':'7','ח':'8','ט':'9','י':'10',rdc:'0',ground:'0'};
 for(const row of rows)if(row.floor){const key=normalizeApartmentHeader(row.floor);if(floors[key]!==undefined)row.floor=floors[key];}
 return rows;
}
