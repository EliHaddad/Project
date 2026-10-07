export async function GET(request:Request){
 try{
  const url=new URL(new URL(request.url).searchParams.get('url')??'');
  if(url.protocol!=='https:'||url.hostname!=='elihaddad-agents.com'||url.port||url.username||url.password||!url.pathname.startsWith('/wp-content/uploads/')||!/^.*\.(jpg|jpeg|png|webp)$/i.test(url.pathname))return new Response('Invalid image',{status:400});
  const response=await fetch(url,{redirect:'error',signal:AbortSignal.timeout(15000)});
  const type=response.headers.get('content-type')?.split(';')[0]??'';
  if(!response.ok||!['image/jpeg','image/png','image/webp'].includes(type))throw new Error('image');
  const bytes=await response.arrayBuffer();if(bytes.byteLength>15000000)throw new Error('size');
  return new Response(bytes,{headers:{'Content-Type':type,'Cache-Control':'private, max-age=3600','X-Content-Type-Options':'nosniff'}});
 }catch{return new Response('Image unavailable',{status:502});}
}
