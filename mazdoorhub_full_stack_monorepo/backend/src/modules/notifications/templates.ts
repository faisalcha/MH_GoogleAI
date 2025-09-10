import { Client } from 'pg';
export async function loadTemplate(c:Client, key:string, lang:'ur'|'en'){ const { rows } = await c.query('SELECT key, channel, lang, body FROM notification_templates WHERE key=$1 AND lang=$2',[key,lang]); return rows[0]||null; }
export function renderBody(body:any, params:Record<string,string|number>){ const json=JSON.stringify(body); const out=json.replace(/{{(.*?)}}/g, (_m,p1)=> String(params[p1.trim()] ?? '')); return JSON.parse(out); }
