import {NextResponse} from 'next/server';
export async function GET(){
 try{
  const response=await fetch('https://boi.org.il/PublicApi/GetExchangeRates',{cache:'no-store',signal:AbortSignal.timeout(10000)});
  if(!response.ok)throw new Error('rate');
  const data=await response.json();
  const euro=data.exchangeRates?.find((item:{key:string})=>item.key==='EUR');
  if(!euro||euro.unit!==1||!Number.isFinite(euro.currentExchangeRate)||euro.currentExchangeRate<=0||!Number.isFinite(Date.parse(euro.lastUpdate)))throw new Error('rate');
  return NextResponse.json({rate:euro.currentExchangeRate,date:euro.lastUpdate,source:'https://boi.org.il/PublicApi/GetExchangeRates'},{headers:{'Cache-Control':'no-store'}});
 }catch{return NextResponse.json({error:'unavailable'},{status:503});}
}
