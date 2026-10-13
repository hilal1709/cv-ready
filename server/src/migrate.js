// Creates the schema. Run once: npm run migrate (needs DATABASE_URL).
import { readFileSync } from 'node:fs';
import pg from 'pg';

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
await client.query(readFileSync(new URL('./schema.sql', import.meta.url), 'utf8'));
const r = await client.query("SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY 1");
console.log('Tables:', r.rows.map((x) => x.table_name).join(', '));
await client.end();
