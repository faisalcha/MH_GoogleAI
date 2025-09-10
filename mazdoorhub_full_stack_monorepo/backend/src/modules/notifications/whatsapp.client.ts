export async function sendWhatsAppTemplate(toPhoneE164:string, body:any){ const token=process.env.WHATSAPP_TOKEN||''; const phoneId=process.env.WHATSAPP_PHONE_ID||'';
  if(!token||!phoneId) throw new Error('WhatsApp credentials missing'); const url=`https://graph.facebook.com/v20.0/${phoneId}/messages`;
  const payload={ messaging_product:"whatsapp", to: toPhoneE164, type:"template", template:{ name:"mh_dynamic_text", language:{code:"ur"}, components:[{ type:"body", parameters:Object.keys(body).map(k=>({type:'text', text:String(body[k])})) }] } };
  const res = await fetch(url,{ method:'POST', headers:{'Authorization':'Bearer '+token,'Content-Type':'application/json'}, body: JSON.stringify(payload) });
  const data = await res.json(); if(!res.ok) throw new Error('WhatsApp error: '+JSON.stringify(data)); return data;
}