import serverlessExpress from '@vendia/serverless-express';
import express from 'express'; import bodyParser from 'body-parser';
import { jobsRouter } from './modules/jobs/jobs.http';
import { paymentsRouter } from './modules/payments/payments.http';
import { notificationsRouter } from './modules/notifications/notifications.http';
import { trustRouter } from './modules/trust/trust.http';
const app = express(); app.use(bodyParser.json({limit:'2mb'}));
app.get('/health', (_req,res)=>res.json({ok:true, ts:new Date().toISOString()}));
app.use('/jobs', jobsRouter); app.use('/payments', paymentsRouter);
app.use('/notifications', notificationsRouter); app.use('/trust', trustRouter);
let server:any; export const handler = async (event:any, context:any) => {
  if(!server) server = serverlessExpress({ app }); return server(event, context);
};
