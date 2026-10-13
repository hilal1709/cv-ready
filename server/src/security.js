import crypto from 'node:crypto';

// Same parameters the app used when hashing on the phone, so accounts created
// before the backend existed can still sign in: PBKDF2-HMAC-SHA256, 60000
// iterations, 32-byte key, base64 hash + base64 16-byte salt.
const ITERATIONS = 60000;
const KEY_LEN = 32;

export function newSalt() {
  return crypto.randomBytes(16).toString('base64');
}

export function hashPassword(password, saltB64) {
  return new Promise((resolve, reject) => {
    crypto.pbkdf2(password, Buffer.from(saltB64, 'base64'), ITERATIONS, KEY_LEN, 'sha256', (err, key) =>
      err ? reject(err) : resolve(key.toString('base64')),
    );
  });
}

export function safeEqual(a, b) {
  const x = Buffer.from(String(a));
  const y = Buffer.from(String(b));
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}

const TOKEN_TTL_MS = 30 * 24 * 60 * 60 * 1000;

function sign(secret, body) {
  return crypto.createHmac('sha256', secret).update(body).digest('base64url');
}

/** Stateless signed token: base64url({sub, exp}).signature */
export function issueToken(secret, userId, now = Date.now()) {
  const body = Buffer.from(JSON.stringify({ sub: userId, exp: now + TOKEN_TTL_MS })).toString('base64url');
  return `${body}.${sign(secret, body)}`;
}

/** Returns the user id, or null when the token is malformed, forged or expired. */
export function verifyToken(secret, token, now = Date.now()) {
  if (typeof token !== 'string') return null;
  const [body, sig, extra] = token.split('.');
  if (!body || !sig || extra !== undefined) return null;
  if (!safeEqual(sig, sign(secret, body))) return null;
  try {
    const { sub, exp } = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    return typeof sub === 'string' && typeof exp === 'number' && exp > now ? sub : null;
  } catch {
    return null;
  }
}

/** Fixed-window counter. In-memory: fine for a single instance. */
export function createLimiter() {
  const hits = new Map();
  return function allow(key, limit, windowMs, now = Date.now()) {
    const h = hits.get(key);
    if (!h || h.reset <= now) {
      hits.set(key, { n: 1, reset: now + windowMs });
      if (hits.size > 10000) for (const [k, v] of hits) if (v.reset <= now) hits.delete(k);
      return true;
    }
    h.n += 1;
    return h.n <= limit;
  };
}
