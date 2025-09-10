import { Router } from 'express'; import { pgc } from '../../db/pg'; export const jobsRouter = Router();
jobsRouter.post('/', async (req,res)=>{ const { employer_user_id, category, price, lat, lng, description } = req.body;
  if(!employer_user_id || !category || lat==null || lng==null) return res.status(400).json({error:'missing fields'});
  const c = await pgc(); try{ const { rows } = await c.query(`INSERT INTO jobs (employer_user_id, category, price, geom, description)
    VALUES ($1,$2,$3, ST_SetSRID(ST_MakePoint($4,$5),4326), $6) RETURNING id, created_at`, [employer_user_id, category, price||0, Number(lng), Number(lat), description||null]);
    res.json({ ok:true, id: rows[0].id, created_at: rows[0].created_at }); } catch(e:any){ res.status(500).json({error:e.message}); } finally { await c.end(); } });
jobsRouter.get('/', async (req,res)=>{ const lat=Number(req.query.lat), lng=Number(req.query.lng), radius=Number(req.query.radius||5000);
  if(Number.isNaN(lat)||Number.isNaN(lng)) return res.status(400).json({error:'lat,lng required'});
  if(Number.isNaN(radius)||radius<=0) return res.status(400).json({error:'invalid radius'});
  const c=await pgc();
  try{ const safeRadius=Math.min(radius,50000); const { rows } = await c.query(`SELECT id, employer_user_id, category, price, description, created_at, ST_Y(geom::geometry) AS lat, ST_X(geom::geometry) AS lng
      FROM jobs WHERE ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint($1,$2),4326)::geography, $3) ORDER BY created_at DESC LIMIT 100`, [lng,lat,safeRadius]);
    res.json(rows);} catch(e:any){ res.status(500).json({error:e.message}); } finally { await c.end(); } });
