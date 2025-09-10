import { Client } from 'pg';
export async function pgc(){ const c=new Client({host:process.env.DB_HOST,port:parseInt(process.env.DB_PORT||'5432',10),user:process.env.DB_USER,password:process.env.DB_PASSWORD,database:process.env.DB_NAME,ssl:process.env.DB_SSL==='true'?{rejectUnauthorized:false}:false}); await c.connect(); return c; }
