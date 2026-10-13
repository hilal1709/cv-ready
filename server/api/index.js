// Vercel entry point: the same Express app, exported as a serverless handler.
// vercel.json routes every path here.
import pg from 'pg';

import { createApp } from '../src/app.js';

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  // Each function instance is small; Neon's pooler fans these in.
  max: 3,
  idleTimeoutMillis: 10_000,
  connectionTimeoutMillis: 15_000,
});
pool.on('error', (e) => console.error('pg pool:', e.message));

export default createApp(pool, process.env);
