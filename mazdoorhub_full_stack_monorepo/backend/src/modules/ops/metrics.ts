import { pgc } from '../../db/pg'; import { CloudWatchClient, PutMetricDataCommand } from "@aws-sdk/client-cloudwatch";
const NAMESPACE='MazdoorHub/Ops'; export const handler = async ()=>{ const cw=new CloudWatchClient({}); const c=await pgc();
  try{ const q1=await c.query("SELECT count(*)::int AS n FROM disputes WHERE status='ESCALATED'"); const q2=await c.query("SELECT count(*)::int AS n FROM sos_events WHERE status='ESCALATED'");
    await cw.send(new PutMetricDataCommand({ Namespace:NAMESPACE, MetricData:[ {MetricName:'DisputesEscalated',Timestamp:new Date(),Value:q1.rows[0]?.n??0,Unit:'Count'}, {MetricName:'SosEscalated',Timestamp:new Date(),Value:q2.rows[0]?.n??0,Unit:'Count'} ] })); return {ok:true};
  } finally { await c.end(); } };
