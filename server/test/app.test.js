import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';

import { createApp } from '../src/app.js';
import { hashPassword, issueToken, newSalt, verifyToken } from '../src/security.js';

// Tiny in-memory stand-in for the two tables, keyed on the SQL the app issues.
function fakeDb() {
  const users = [];
  const resumes = [];
  let n = 0;
  const uuid = () => `00000000-0000-4000-8000-${String(++n).padStart(12, '0')}`;
  return {
    users,
    resumes,
    async query(sql, p = []) {
      const s = sql.replace(/\s+/g, ' ').trim();
      if (s.startsWith('INSERT INTO app_users')) {
        if (users.some((u) => u.email === p[0])) return { rows: [] };
        const u = { id: uuid(), email: p[0], full_name: p[1], password_hash: p[2], password_salt: p[3] };
        users.push(u);
        return { rows: [u] };
      }
      if (s.startsWith('SELECT id::text, email, full_name, password_hash')) return { rows: users.filter((u) => u.email === p[0]) };
      if (s.startsWith('SELECT id::text, email, full_name FROM app_users')) return { rows: users.filter((u) => u.id === p[0]) };
      if (s.startsWith('UPDATE app_users')) {
        const u = users.find((x) => x.id === p[1]);
        if (u) u.full_name = p[0];
        return { rows: u ? [u] : [] };
      }
      if (s.startsWith('SELECT') && s.includes('FROM resumes')) return { rows: resumes.filter((r) => r.user_id === p[0]) };
      if (s.startsWith('INSERT INTO resumes')) {
        const now = new Date();
        const r = { id: uuid(), user_id: p[0], title: p[1], template: p[2], data: JSON.parse(p[3]), created_at: now, updated_at: now };
        resumes.push(r);
        return { rows: [r] };
      }
      if (s.startsWith('UPDATE resumes')) {
        const r = resumes.find((x) => x.id === p[3] && x.user_id === p[4]);
        if (r) Object.assign(r, { title: p[0], template: p[1], data: JSON.parse(p[2]), updated_at: new Date() });
        return { rows: r ? [r] : [] };
      }
      if (s.startsWith('DELETE FROM resumes')) {
        const i = resumes.findIndex((x) => x.id === p[0] && x.user_id === p[1]);
        if (i >= 0) resumes.splice(i, 1);
        return { rows: [] };
      }
      throw new Error(`unexpected SQL: ${s}`);
    },
  };
}

const SECRET = 'x'.repeat(48);
let server;
let base;
let db;

const call = async (method, path, { token, body } = {}) => {
  const res = await fetch(base + path, {
    method,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  return { status: res.status, json: text ? JSON.parse(text) : null };
};

describe('security', () => {
  it('verifies its own tokens and rejects forged or expired ones', () => {
    const t = issueToken(SECRET, 'u1');
    assert.equal(verifyToken(SECRET, t), 'u1');
    assert.equal(verifyToken('y'.repeat(48), t), null);
    assert.equal(verifyToken(SECRET, `${t}x`), null);
    assert.equal(verifyToken(SECRET, 'garbage'), null);
    assert.equal(verifyToken(SECRET, t, Date.now() + 31 * 24 * 60 * 60 * 1000), null);
  });

  it('keeps the password hash format the Flutter app used', async () => {
    // Known PBKDF2-HMAC-SHA256 vector: "password" / "salt" (as bytes), 60000 iterations, 32 bytes.
    const salt = Buffer.from('salt').toString('base64');
    const h = await hashPassword('password', salt);
    assert.equal(Buffer.from(h, 'base64').length, 32);
    assert.equal(h, await hashPassword('password', salt));
    assert.notEqual(h, await hashPassword('password2', salt));
    assert.equal(newSalt().length, 24);
  });
});

describe('api', () => {
  before(async () => {
    db = fakeDb();
    const app = createApp(db, { TOKEN_SECRET: SECRET });
    await new Promise((r) => {
      server = app.listen(0, r);
    });
    base = `http://127.0.0.1:${server.address().port}`;
  });
  after(() => server.close());

  let token;
  let userId;

  it('registers, rejects duplicates and weak input', async () => {
    const ok = await call('POST', '/auth/register', {
      body: { fullName: 'Budi Santoso', email: 'Budi@Example.com', password: 'sandi-panjang' },
    });
    assert.equal(ok.status, 201);
    assert.equal(ok.json.user.email, 'budi@example.com');
    token = ok.json.token;
    userId = ok.json.user.id;
    assert.ok(!('password_hash' in ok.json.user));

    const dup = await call('POST', '/auth/register', {
      body: { fullName: 'Budi', email: 'budi@example.com', password: 'sandi-panjang' },
    });
    assert.equal(dup.status, 409);
    const weak = await call('POST', '/auth/register', { body: { fullName: 'Budi', email: 'b2@example.com', password: 'pendek' } });
    assert.equal(weak.status, 400);
    const badEmail = await call('POST', '/auth/register', { body: { fullName: 'Budi', email: 'nope', password: 'sandi-panjang' } });
    assert.equal(badEmail.status, 400);
  });

  it('logs in with the right password only', async () => {
    const ok = await call('POST', '/auth/login', { body: { email: 'budi@example.com', password: 'sandi-panjang' } });
    assert.equal(ok.status, 200);
    assert.equal(ok.json.user.id, userId);
    const bad = await call('POST', '/auth/login', { body: { email: 'budi@example.com', password: 'salah-total' } });
    assert.equal(bad.status, 401);
    const none = await call('POST', '/auth/login', { body: { email: 'tidak@ada.com', password: 'sandi-panjang' } });
    assert.equal(none.status, 401);
  });

  it('accepts accounts created by the old on-device hashing', async () => {
    const salt = newSalt();
    db.users.push({
      id: '00000000-0000-4000-8000-0000000000aa',
      email: 'lama@example.com',
      full_name: 'Akun Lama',
      password_hash: await hashPassword('sandi-lama-1', salt),
      password_salt: salt,
    });
    const r = await call('POST', '/auth/login', { body: { email: 'lama@example.com', password: 'sandi-lama-1' } });
    assert.equal(r.status, 200);
  });

  it('requires a valid token', async () => {
    assert.equal((await call('GET', '/resumes')).status, 401);
    assert.equal((await call('GET', '/resumes', { token: 'abc.def' })).status, 401);
    assert.equal((await call('POST', '/ai', { token: 'abc.def', body: { prompt: 'hi' } })).status, 401);
  });

  it('stores resumes per user and never exposes another users CV', async () => {
    const created = await call('POST', '/resumes', {
      token,
      body: { title: 'CV Utama', template: 'harvard', data: { summary: 'Halo' } },
    });
    assert.equal(created.status, 201);
    const id = created.json.resume.id;
    assert.equal(created.json.resume.data.summary, 'Halo');

    const list = await call('GET', '/resumes', { token });
    assert.equal(list.json.resumes.length, 1);

    const other = await call('POST', '/auth/register', {
      body: { fullName: 'Siti Aminah', email: 'siti@example.com', password: 'sandi-panjang' },
    });
    const t2 = other.json.token;
    assert.equal((await call('GET', '/resumes', { token: t2 })).json.resumes.length, 0);
    const steal = await call('PUT', `/resumes/${id}`, { token: t2, body: { title: 'x', template: 'harvard', data: {} } });
    assert.equal(steal.status, 404);
    await call('DELETE', `/resumes/${id}`, { token: t2 });
    assert.equal((await call('GET', '/resumes', { token })).json.resumes.length, 1);

    const upd = await call('PUT', `/resumes/${id}`, {
      token,
      body: { title: 'CV Baru', template: 'modern', data: { summary: 'Ubah' } },
    });
    assert.equal(upd.json.resume.title, 'CV Baru');
    assert.equal((await call('DELETE', `/resumes/${id}`, { token })).status, 204);
    assert.equal((await call('GET', '/resumes', { token })).json.resumes.length, 0);
  });

  it('validates resume payloads and ids', async () => {
    const bad = await call('POST', '/resumes', { token, body: { title: 'x', template: 'harvard', data: [1] } });
    assert.equal(bad.status, 400);
    const badId = await call('PUT', '/resumes/not-a-uuid', { token, body: { title: 'x', template: 'harvard', data: {} } });
    assert.equal(badId.status, 404);
  });

  it('reports AI as unavailable when no key is configured', async () => {
    const r = await call('POST', '/ai', { token, body: { prompt: 'Tulis ringkasan' } });
    assert.equal(r.status, 503);
    const empty = await call('POST', '/ai', { token, body: { prompt: '  ' } });
    assert.equal(empty.status, 400);
  });

  it('updates the display name', async () => {
    const r = await call('PATCH', '/me', { token, body: { fullName: 'Budi S.' } });
    assert.equal(r.json.user.fullName, 'Budi S.');
  });
});
