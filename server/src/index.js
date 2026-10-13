import pg from 'pg';

import { createApp } from './app.js';

if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL is not set.');
  process.exit(1);
}

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  max: 5,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 15_000,
});
// Neon drops idle connections; without this an idle-client error would crash the process.
pool.on('error', (e) => console.error('pg pool:', e.message));

const app = createApp(pool, process.env);
const port = Number(process.env.PORT) || 8080;
app.listen(port, () => console.log(`CV Ready API listening on :${port}`));
