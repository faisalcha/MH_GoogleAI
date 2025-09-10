import { Router } from 'express'; import { pgc } from '../../db/pg'; import { randomBytes } from 'crypto'; export const trustRouter = Router();
trustRouter.post('/reference/request', async (req,res)=>{ const { worker_user_id, ref_name, ref_phone } = req.body; if(!worker_user_id||!ref_name||!ref_phone) return res.status(400).json({error:'missing'});
  const c=await pgc(); try{ const token=randomBytes(24).toString('hex'); const r=await c.query(`INSERT INTO references_requests(worker_user_id, ref_name, ref_phone, token, status) VALUES($1,$2,$3,$4,'SENT') RETURNING id, token`,[worker_user_id,ref_name,ref_phone,token]); res.json({ok:true, reference_id:r.rows[0].id, token:r.rows[0].token}); } catch(e:any){ res.status(500).json({error:e.message}); } finally { await c.end(); } });
trustRouter.post('/reference/respond', async (req,res)=>{ const { token, rating, text } = req.body; if(!token||typeof rating!=='number') return res.status(400).json({error:'token & rating'});
  const c=await pgc(); try{ const q=await c.query('SELECT id FROM references_requests WHERE token=$1',[token]); if(q.rowCount===0) return res.status(404).json({error:'invalid'});
    await c.query(`UPDATE references_requests SET status='RESPONDED', response_rating=$2, response_text=$3, responded_at=now() WHERE token=$1`,[token,rating,text||null]); res.json({ok:true}); } catch(e:any){ res.status(500).json({error:e.message}); } finally { await c.end(); } });
trustRouter.post('/admin/reference/:id/verify', async (req,res)=>{ const { id }=req.params; const { verify } = req.body; const c=await pgc(); try{
    await c.query('BEGIN'); const q=await c.query('SELECT * FROM references_requests WHERE id=$1 FOR UPDATE',[id]); if(q.rowCount===0) throw new Error('not found'); const rr=q.rows[0];
    const newStatus = verify ? 'VERIFIED' : 'REJECTED'; await c.query(`UPDATE references_requests SET status=$2, verified_at=now() WHERE id=$1`,[id,newStatus]);
    if(verify && rr.response_rating){ await c.query(`INSERT INTO worker_stats(user_id, jobs_completed, total_rating, rating_count, rated_pro) VALUES($1,0,$2,1,false)
      ON CONFLICT(user_id) DO UPDATE SET total_rating=worker_stats.total_rating+EXCLUDED.total_rating, rating_count=worker_stats.rating_count+1, updated_at=now()`, [rr.worker_user_id, rr.response_rating]); }
    await c.query('COMMIT'); res.json({ok:true,status:newStatus}); } catch(e:any){ await c.query('ROLLBACK'); res.status(500).json({error:e.message}); } finally { await c.end(); } });
trustRouter.get('/admin/references', async (req,res)=>{ const status=(req.query.status as string|undefined); const c=await pgc(); try{
    let sql=`SELECT * FROM trust_reference_queue`; const r = status ? await c.query(`SELECT * FROM references_requests WHERE status=$1 ORDER BY created_at ASC`,[status]) : await c.query(sql); res.json(r.rows);
  } catch(e:any){ res.status(500).json({error:e.message}); } finally { await c.end(); } });
