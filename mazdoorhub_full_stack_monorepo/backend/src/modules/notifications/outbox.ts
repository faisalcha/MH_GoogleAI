import { pgc } from '../../db/pg'; import { loadTemplate, renderBody } from './templates'; import { sendWhatsAppTemplate } from './whatsapp.client';
export async function enqueue(n:any){ const c=await pgc(); try{ const { rows } = await c.query(`INSERT INTO notification_outbox(channel, template_key, lang, to_phone, to_id, params)
  VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`, [n.channel, n.template_key, n.lang||'ur', n.to_phone||null, n.to_id||null, JSON.stringify(n.params||{})]); return { id: rows[0].id }; } finally { await c.end(); } }
export async function flush(limit=50){ const c=await pgc(); let sent=0, failed=0; try{
  const { rows } = await c.query(`SELECT * FROM notification_outbox WHERE status='PENDING' ORDER BY created_at ASC LIMIT $1`,[limit]);
  for(const item of rows){ try{ const tpl=await loadTemplate(c, item.template_key, item.lang); if(!tpl) throw new Error('template not found'); const body=renderBody(tpl.body, item.params||{});
    if(item.channel==='whatsapp'){ if(!item.to_phone) throw new Error('to_phone required'); await sendWhatsAppTemplate(item.to_phone, body);
      await c.query(`UPDATE notification_outbox SET status='SENT', attempts=attempts+1, sent_at=now() WHERE id=$1`,[item.id]);
      await c.query(`INSERT INTO notification_logs(outbox_id, channel, status) VALUES ($1,$2,$3)`,[item.id,'whatsapp','SENT']); }
    else { await c.query(`UPDATE notification_outbox SET status='SENT', attempts=attempts+1, sent_at=now() WHERE id=$1`,[item.id]);
      await c.query(`INSERT INTO notification_logs(outbox_id, channel, status) VALUES ($1,$2,$3)`,[item.id,'push','SENT']); }
    sent++; } catch(e:any){ failed++; await c.query(`UPDATE notification_outbox SET status='FAILED', attempts=attempts+1, last_error=$2 WHERE id=$1`,[item.id,String(e.message).slice(0,4000)]); } }
} finally { await c.end(); } return { sent, failed }; }
