export const handler = async (event:any)=>{ const route=event.requestContext?.routeKey; if(route==='$connect') return {statusCode:200,body:'connected'};
  if(route==='$disconnect') return {statusCode:200,body:'bye'}; return {statusCode:200,body:JSON.stringify({ok:true, echo:event.body||null})}; };
