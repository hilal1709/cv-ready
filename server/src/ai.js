// AI proxy. The system prompt and model choice live here so the endpoint
// can't be used as a general-purpose LLM.
const CLAUDE_MODEL = 'claude-haiku-5-5';
const GEMINI_BACKUP = 'gemini-flash-lite-latest';

const SYSTEM = `You are an expert international recruiter and CV writer. You write for ATS (applicant tracking systems) and human recruiters at the same time.
Rules:
- Write in the same language as the user's input. If the input is Indonesian, answer in Indonesian; otherwise English.
- No first-person pronouns. Start bullets with a strong past-tense action verb (present tense for a current role).
- Prefer concrete outcomes and numbers. Never invent numbers, employers, tools or achievements: if a metric is unknown, write the sentence so it reads well without one, or use a bracketed placeholder like [X%] the user can fill in.
- Plain text only. No markdown, no headings, no quotes around the answer, no commentary.`;

export class AiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function aiConfigured(env) {
  return Boolean(env.ANTHROPIC_API_KEY || env.GEMINI_API_KEY);
}

function callClaude(env, prompt, maxTokens) {
  return fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: maxTokens,
      system: SYSTEM,
      messages: [{ role: 'user', content: prompt }],
    }),
    signal: AbortSignal.timeout(90_000),
  });
}

function callGemini(env, model, prompt, maxTokens, json, timeoutMs) {
  return fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-goog-api-key': env.GEMINI_API_KEY },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: SYSTEM }] },
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      // Thinking tokens count against maxOutputTokens; keep them low so the answer isn't cut off.
      generationConfig: {
        maxOutputTokens: maxTokens + 1500,
        thinkingConfig: { thinkingLevel: 'low' },
        ...(json ? { responseMimeType: 'application/json' } : {}),
      },
    }),
    signal: AbortSignal.timeout(timeoutMs),
  });
}

function failFor(status, msg) {
  const m = String(msg).toLowerCase();
  if (status === 401 || status === 403 || (status === 400 && m.includes('api key'))) {
    return new AiError(502, 'Layanan AI belum dikonfigurasi dengan benar di server.');
  }
  if (status === 429) return new AiError(429, 'Batas pemakaian AI tercapai. Coba lagi beberapa menit lagi.');
  if (status >= 500) return new AiError(502, 'Layanan AI sedang gangguan. Coba lagi nanti.');
  return new AiError(502, `AI gagal: ${msg}`);
}

function readClaude(body) {
  if (body.stop_reason === 'refusal') throw new AiError(422, 'AI menolak permintaan ini. Ubah teksnya lalu coba lagi.');
  return (body.content ?? [])
    .filter((b) => b.type === 'text')
    .map((b) => b.text)
    .join('')
    .trim();
}

function readGemini(body) {
  const c = body.candidates;
  if (!c || c.length === 0) throw new AiError(422, 'AI menolak permintaan ini. Ubah teksnya lalu coba lagi.');
  const parts = c[0]?.content?.parts ?? [];
  return parts
    .filter((p) => p.thought !== true)
    .map((p) => p.text ?? '')
    .join('')
    .trim();
}

export async function generate(env, { prompt, maxTokens, json }) {
  if (!aiConfigured(env)) throw new AiError(503, 'Fitur AI belum diaktifkan di server.');
  let res;
  try {
    if (env.ANTHROPIC_API_KEY) {
      res = await callClaude(env, prompt, maxTokens);
    } else {
      const model = env.GEMINI_MODEL || 'gemini-3.1-flash-lite';
      const backup = model === GEMINI_BACKUP ? 'gemini-flash-latest' : GEMINI_BACKUP;
      // Free-tier models are often overloaded (503) or hang; try a second model once.
      try {
        res = await callGemini(env, model, prompt, maxTokens, json, 20_000);
      } catch {
        res = null;
      }
      if (!res || res.status === 503 || res.status === 429) {
        res = await callGemini(env, backup, prompt, maxTokens, json, 40_000);
      }
    }
  } catch {
    throw new AiError(504, 'Layanan AI tidak merespons. Coba lagi.');
  }

  const body = await res.json().catch(() => ({}));
  if (!res.ok) throw failFor(res.status, body?.error?.message ?? `HTTP ${res.status}`);
  const text = env.ANTHROPIC_API_KEY ? readClaude(body) : readGemini(body);
  if (!text) throw new AiError(502, 'AI tidak memberi jawaban. Coba lagi.');
  return text;
}
