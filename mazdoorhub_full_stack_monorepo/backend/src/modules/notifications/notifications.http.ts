import { Router } from 'express'; import { enqueue, flush } from './outbox';
export const notificationsRouter = Router();
notificationsRouter.post('/enqueue', async (req,res)=>{ try{ const out=await enqueue(req.body); res.json({ok:true,id:out.id}); } catch(e:any){ res.status(400).json({error:e.message}); }});
notificationsRouter.post('/flush', async (_req,res)=> res.json(await flush()));
notificationsRouter.get('/templates', async (_req,res)=>{ res.json({ whatsapp:['job_summary','reference_request'], push:['push_generic_en','push_generic_ur']}); });
