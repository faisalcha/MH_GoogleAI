import { flush } from './outbox'; export const handler = async ()=> await flush(100);
