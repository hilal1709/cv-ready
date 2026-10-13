import express from 'express';

import { AiError, generate } from './ai.js';
import { createLimiter, hashPassword, issueToken, newSalt, safeEqual, verifyToken } from './security.js';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const MIN_PASSWORD = 8;
const MAX_PROMPT = 20000;
const MIN = 60_000;

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const str = (v) => (typeof v === 'string' ? v : '');
const resumeJson = (r) => ({
  id: r.id,
  title: r.title,
  template: r.template,
  data: r.data,
  createdAt: r.created_at.toISOString(),
  updatedAt: r.updated_at.toISOString(),
});
const userJson = (r) => ({ id: r.id, email: r.email, fullName: r.full_name });

/**
 * @param {{ query: (sql: string, params?: unknown[]) => Promise<{rows: any[]}> }} db
 * @param {Record<string, string | undefined>} env
 */
export function createApp(db, env) {
  if (!env.TOKEN_SECRET || env.TOKEN_SECRET.length < 32) {
    throw new Error('TOKEN_SECRET must be set to a random string of at least 32 characters.');
  }
  const secret = env.TOKEN_SECRET;
  const allow = createLimiter();
  const app = express();
  app.set('trust proxy', 1);
  app.disable('x-powered-by');
  app.use(express.json({ limit: '1mb' }));

  const wrap = (fn) => (req, res, next) => fn(req, res).catch(next);
  const limit = (key, n, windowMs, message) => {
    if (!allow(key, n, windowMs)) throw new HttpError(429, message ?? 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.');
  };

  const auth = (req, _res, next) => {
    const m = /^Bearer (.+)$/.exec(req.get('authorization') ?? '');
    const uid = m ? verifyToken(secret, m[1]) : null;
    if (!uid) return next(new HttpError(401, 'Sesi berakhir. Masuk lagi.'));
    req.userId = uid;
    next();
  };

  const idParam = (req) => {
    if (!UUID.test(req.params.id)) throw new HttpError(404, 'CV ini tidak ditemukan. Mungkin sudah dihapus.');
    return req.params.id;
  };

  app.get('/health', (_req, res) => res.json({ ok: true }));

  // ------------------------------------------------------------- accounts ---

  app.post(
    '/auth/register',
    wrap(async (req, res) => {
      limit(`reg:${req.ip}`, 10, 60 * MIN);
      const fullName = str(req.body?.fullName).trim();
      const email = str(req.body?.email).trim().toLowerCase();
      const password = str(req.body?.password);
      if (fullName.length < 2 || fullName.length > 120) throw new HttpError(400, 'Tulis nama lengkapmu.');
      if (!EMAIL.test(email) || email.length > 254) throw new HttpError(400, 'Email tidak valid.');
      if (password.length < MIN_PASSWORD) throw new HttpError(400, 'Kata sandi minimal 8 karakter.');
      if (password.length > 200) throw new HttpError(400, 'Kata sandi terlalu panjang.');

      const salt = newSalt();
      const hash = await hashPassword(password, salt);
      const r = await db.query(
        `INSERT INTO app_users (email, full_name, password_hash, password_salt)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (email) DO NOTHING
         RETURNING id::text, email, full_name`,
        [email, fullName, hash, salt],
      );
      if (r.rows.length === 0) throw new HttpError(409, 'Email ini sudah terdaftar. Coba masuk.');
      const user = userJson(r.rows[0]);
      res.status(201).json({ token: issueToken(secret, user.id), user });
    }),
  );

  // Hashed even for unknown emails so response time doesn't reveal which exist.
  const DUMMY_SALT = newSalt();

  app.post(
    '/auth/login',
    wrap(async (req, res) => {
      const email = str(req.body?.email).trim().toLowerCase();
      const password = str(req.body?.password);
      limit(`login-ip:${req.ip}`, 30, 15 * MIN);
      limit(`login-email:${email}`, 10, 15 * MIN);
      if (!email || !password || password.length > 200) throw new HttpError(401, 'Email atau kata sandi salah.');

      const r = await db.query(
        'SELECT id::text, email, full_name, password_hash, password_salt FROM app_users WHERE email = $1',
        [email],
      );
      const row = r.rows[0];
      const hash = await hashPassword(password, row ? row.password_salt : DUMMY_SALT);
      if (!row || !safeEqual(hash, row.password_hash)) throw new HttpError(401, 'Email atau kata sandi salah.');
      const user = userJson(row);
      res.json({ token: issueToken(secret, user.id), user });
    }),
  );

  app.get(
    '/me',
    auth,
    wrap(async (req, res) => {
      const r = await db.query('SELECT id::text, email, full_name FROM app_users WHERE id = $1', [req.userId]);
      if (r.rows.length === 0) throw new HttpError(401, 'Sesi berakhir. Masuk lagi.');
      res.json({ user: userJson(r.rows[0]) });
    }),
  );

  app.patch(
    '/me',
    auth,
    wrap(async (req, res) => {
      const fullName = str(req.body?.fullName).trim();
      if (fullName.length < 2 || fullName.length > 120) throw new HttpError(400, 'Tulis nama lengkapmu.');
      const r = await db.query(
        'UPDATE app_users SET full_name = $1 WHERE id = $2 RETURNING id::text, email, full_name',
        [fullName, req.userId],
      );
      if (r.rows.length === 0) throw new HttpError(401, 'Sesi berakhir. Masuk lagi.');
      res.json({ user: userJson(r.rows[0]) });
    }),
  );

  // --------------------------------------------------------------- resumes ---

  const COLS = 'id::text, title, template, data, created_at, updated_at';

  const readResume = (body) => {
    const title = str(body?.title).trim();
    const template = str(body?.template).trim();
    const data = body?.data;
    if (!title || title.length > 200) throw new HttpError(400, 'Judul CV tidak valid.');
    if (!template || template.length > 50) throw new HttpError(400, 'Template tidak valid.');
    if (data === null || typeof data !== 'object' || Array.isArray(data)) throw new HttpError(400, 'Isi CV tidak valid.');
    return { title, template, data: JSON.stringify(data) };
  };

  app.get(
    '/resumes',
    auth,
    wrap(async (req, res) => {
      const r = await db.query(`SELECT ${COLS} FROM resumes WHERE user_id = $1 ORDER BY updated_at DESC`, [req.userId]);
      res.json({ resumes: r.rows.map(resumeJson) });
    }),
  );

  app.post(
    '/resumes',
    auth,
    wrap(async (req, res) => {
      limit(`resume-create:${req.userId}`, 60, 60 * MIN);
      const { title, template, data } = readResume(req.body);
      const r = await db.query(
        `INSERT INTO resumes (user_id, title, template, data) VALUES ($1, $2, $3, $4::jsonb) RETURNING ${COLS}`,
        [req.userId, title, template, data],
      );
      res.status(201).json({ resume: resumeJson(r.rows[0]) });
    }),
  );

  app.put(
    '/resumes/:id',
    auth,
    wrap(async (req, res) => {
      const id = idParam(req);
      const { title, template, data } = readResume(req.body);
      const r = await db.query(
        `UPDATE resumes SET title = $1, template = $2, data = $3::jsonb, updated_at = now()
         WHERE id = $4 AND user_id = $5 RETURNING ${COLS}`,
        [title, template, data, id, req.userId],
      );
      if (r.rows.length === 0) throw new HttpError(404, 'CV ini tidak ditemukan. Mungkin sudah dihapus.');
      res.json({ resume: resumeJson(r.rows[0]) });
    }),
  );

  app.delete(
    '/resumes/:id',
    auth,
    wrap(async (req, res) => {
      const id = idParam(req);
      await db.query('DELETE FROM resumes WHERE id = $1 AND user_id = $2', [id, req.userId]);
      res.status(204).end();
    }),
  );

  // -------------------------------------------------------------------- AI ---

  app.post(
    '/ai',
    auth,
    wrap(async (req, res) => {
      limit(`ai:${req.userId}`, 30, 10 * MIN, 'Terlalu banyak permintaan AI. Tunggu beberapa menit lalu coba lagi.');
      limit(`ai-day:${req.userId}`, 300, 24 * 60 * MIN, 'Batas pemakaian AI hari ini tercapai. Coba lagi besok.');
      const prompt = str(req.body?.prompt);
      if (!prompt.trim()) throw new HttpError(400, 'Permintaan AI kosong.');
      if (prompt.length > MAX_PROMPT) throw new HttpError(413, 'Teks terlalu panjang untuk diproses AI.');
      const maxTokens = Math.min(Math.max(Math.trunc(Number(req.body?.maxTokens)) || 1000, 100), 4000);
      const text = await generate(env, { prompt, maxTokens, json: req.body?.json === true });
      res.json({ text });
    }),
  );

  // ---------------------------------------------------------------- errors ---

  app.use((_req, _res, next) => next(new HttpError(404, 'Tidak ditemukan.')));
  // eslint-disable-next-line no-unused-vars
  app.use((err, _req, res, _next) => {
    if (err instanceof HttpError || err instanceof AiError) return res.status(err.status).json({ error: err.message });
    if (err?.type === 'entity.too.large') return res.status(413).json({ error: 'Data terlalu besar.' });
    if (err?.type === 'entity.parse.failed') return res.status(400).json({ error: 'Permintaan tidak valid.' });
    console.error(err);
    res.status(500).json({ error: 'Server sedang bermasalah. Coba lagi nanti.' });
  });

  return app;
}
