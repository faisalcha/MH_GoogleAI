import { Router } from 'express'; import { pgc } from '../../db/pg'; import crypto from 'crypto';
export const paymentsRouter = Router();
paymentsRouter.get('/health', (_req,res)=>res.json({ok:true}));
paymentsRouter.post('/intent', async (req,res)=>{ const { job_id, amount, method } = req.body; if(!job_id||!amount) return res.status(400).json({error:'job_id & amount required'});
  const c=await pgc(); try{ await c.query('BEGIN'); const ref='pi_'+crypto.randomBytes(6).toString('hex');
    const { rows } = await c.query(`INSERT INTO payment_intents (job_id, amount, method, status, reference) VALUES ($1,$2,$3,'CREATED',$4) RETURNING id`,[job_id,amount,method||'HOSTED',ref]);
    await c.query(`INSERT INTO ledger_entries (intent_id, account, debit, credit, meta) VALUES ($1,'EmployerHolding',$2,0,'{"event":"intent_created"}')`, [rows[0].id, amount]);
    await c.query('COMMIT'); res.json({ ok:true, intent_id: rows[0].id, reference: ref }); } catch(e:any){ await c.query('ROLLBACK'); res.status(500).json({error:e.message}); } finally { await c.end(); } });
paymentsRouter.post('/webhook', async (req,res)=>{ const { reference, status } = req.body; if(!reference||!status) return res.status(400).json({error:'reference & status required'});
  const c=await pgc(); try{ await c.query('BEGIN'); const q=await c.query('SELECT id, amount, status FROM payment_intents WHERE reference=$1 FOR UPDATE',[reference]);
    if(q.rowCount===0) throw new Error('intent not found'); const pi=q.rows[0]; if(pi.status==='CAPTURED'){ await c.query('COMMIT'); return res.json({ok:true, idempotent:true}); }
    if(status==='CAPTURED'){ await c.query('UPDATE payment_intents SET status=$2, captured_at=now() WHERE id=$1',[pi.id,'CAPTURED']);
      const workerShare=Math.round(pi.amount*0.9), fee=pi.amount-workerShare;
      await c.query(`INSERT INTO ledger_entries(intent_id, account, debit, credit, meta) VALUES
        ($1,'EmployerHolding',0,$2,'{"event":"capture"}'),
        ($1,'WorkerReceivable',$3,0,'{"event":"capture"}'),
        ($1,'PlatformRevenue',$4,0,'{"event":"capture"}')`, [pi.id, pi.amount, workerShare, fee]);
    } else if(status==='FAILED'){ await c.query('UPDATE payment_intents SET status=$2 WHERE id=$1',[pi.id,'FAILED']); }
    await c.query('COMMIT'); res.json({ok:true}); } catch(e:any){ await c.query('ROLLBACK'); res.status(500).json({error:e.message}); } finally { await c.end(); } });
paymentsRouter.post('/refund/request', async (req,res)=>{ const { intent_id, amount, reason, opened_by } = req.body; if(!intent_id||!amount) return res.status(400).json({error:'intent_id & amount required'});
  const c=await pgc(); try{ const { rows } = await c.query(`INSERT INTO refund_requests (intent_id, amount, reason, opened_by, status) VALUES ($1,$2,$3,$4,'OPEN') RETURNING id`, [intent_id,amount,reason||null,opened_by||null]);
    res.json({ ok:true, refund_request_id: rows[0].id }); } catch(e:any){ res.status(500).json({error:e.message}); } finally { await c.end(); } });
paymentsRouter.post('/refund/decision', async (req,res)=>{ const { refund_request_id, approve, reviewer_id } = req.body; const c=await pgc();
  try{ await c.query('BEGIN'); const q=await c.query('SELECT * FROM refund_requests WHERE id=$1 FOR UPDATE',[refund_request_id]);
    if(q.rowCount===0) throw new Error('refund not found'); const rr=q.rows[0]; if(rr.status!=='OPEN'){ await c.query('COMMIT'); return res.json({ok:true, already:true}); }
    if(approve){ await c.query('UPDATE refund_requests SET status=$2, reviewed_by=$3, reviewed_at=now() WHERE id=$1',[refund_request_id,'APPROVED',reviewer_id||null]);
      const intent = await c.query('SELECT amount FROM payment_intents WHERE id=$1',[rr.intent_id]); const amt=Math.min(rr.amount, intent.rows[0].amount);
      const workerShare=Math.round(amt*0.9), fee=amt-workerShare;
      await c.query(`INSERT INTO ledger_entries(intent_id, account, debit, credit, meta) VALUES
        ($1,'EmployerHolding',$2,0,'{"event":"refund"}'),
        ($1,'WorkerReceivable',0,$3,'{"event":"refund"}'),
        ($1,'PlatformRevenue',0,$4,'{"event":"refund"}')`, [rr.intent_id, amt, workerShare, fee]);
    } else { await c.query('UPDATE refund_requests SET status=$2, reviewed_by=$3, reviewed_at=now() WHERE id=$1',[refund_request_id,'REJECTED',reviewer_id||null]); }
    await c.query('COMMIT'); res.json({ok:true}); } catch(e:any){ await c.query('ROLLBACK'); res.status(500).json({error:e.message}); } finally { await c.end(); } });
