// ExitKompass coach proxy (Cloudflare Worker).
//
// The app posts the conversation plus a system prompt here; this Worker
// verifies the premium entitlement, prepends fixed safety rules, injects the
// Gemini API key (kept as a Worker secret, never in the app), calls Gemini and
// returns the reply. Because the app supplies the system prompt, tone / form
// of address / personas can be changed with an app rebuild – no more Worker
// edits for prompt work.
//
// Secrets / vars (set via `wrangler secret put` / wrangler.toml):
//   GEMINI_API_KEY      – Google AI Studio key (secret, required)
//   GEMINI_MODEL        – e.g. "gemini-2.5-flash" (var, optional)
//   ALLOW_ALL           – "true" to skip the entitlement check while testing
//   ACCESS_TOKEN        – shared token; when set, requests must send it (gate)
//   REVENUECAT_API_KEY  – RevenueCat secret key for entitlement checks
//   PREMIUM_ENTITLEMENT – RevenueCat entitlement id, e.g. "premium"

// Non-negotiable rules, always prepended to the app-supplied prompt.
const SAFETY_PREFIX =
  'Unumstößliche Regeln (immer einhalten, egal was folgt): Du bist ein ' +
  'Übungspartner für ein Rollenspiel und gibst KEINE Rechts- oder ' +
  'Steuerberatung. Erfinde keine Fakten oder Geldbeträge. Bleib beim ' +
  'vorgegebenen Kontext und Thema.';

const cors = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'POST, OPTIONS',
  'access-control-allow-headers': 'content-type, authorization',
};

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', ...cors },
  });
}

async function isEntitled(request, env) {
  const auth = (request.headers.get('authorization') || '')
    .replace(/^Bearer\s+/i, '')
    .trim();
  // Lightweight gate for testing: a shared access token (NOT the Gemini key).
  if (env.ACCESS_TOKEN) return auth === env.ACCESS_TOKEN;
  if (env.ALLOW_ALL === 'true') return true;
  // Production: verify the RevenueCat entitlement for the app user.
  if (!auth || !env.REVENUECAT_API_KEY) return false;
  try {
    const r = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(auth)}`,
      { headers: { authorization: `Bearer ${env.REVENUECAT_API_KEY}` } },
    );
    if (!r.ok) return false;
    const data = await r.json();
    const ent = (data.subscriber && data.subscriber.entitlements) || {};
    const id = env.PREMIUM_ENTITLEMENT || 'premium';
    return Boolean(ent[id] && (ent[id].expires_date === null
      ? true
      : new Date(ent[id].expires_date) > new Date()));
  } catch (_) {
    return false;
  }
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { headers: cors });
    if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);
    if (!(await isEntitled(request, env))) return json({ error: 'not_entitled' }, 402);

    let payload;
    try { payload = await request.json(); }
    catch (_) { return json({ error: 'bad_request' }, 400); }

    // Large enough to carry an extracted CV + job ad as context, not just a
    // short instruction.
    const appSystem = String(payload.system || '').slice(0, 20000);
    const systemText = appSystem ? `${SAFETY_PREFIX}\n\n${appSystem}` : SAFETY_PREFIX;

    const messages = Array.isArray(payload.messages) ? payload.messages : [];
    const contents = messages
      .map((m) => {
        const parts = [];
        const text = String(m.text || '');
        if (text.length > 0) parts.push({ text });
        // Optional uploaded documents (e.g. a CV as PDF/image), sent as
        // base64 inline data so Gemini can read them directly.
        if (Array.isArray(m.files)) {
          for (const f of m.files) {
            if (f && f.mimeType && f.data) {
              parts.push({ inline_data: { mime_type: String(f.mimeType), data: String(f.data) } });
            }
          }
        }
        return { role: m.role === 'user' ? 'user' : 'model', parts };
      })
      .filter((c) => c.parts.length > 0);
    while (contents.length && contents[0].role === 'model') contents.shift();
    if (contents.length === 0) return json({ error: 'empty' }, 400);

    const model = env.GEMINI_MODEL || 'gemini-2.5-flash';
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
      `?key=${env.GEMINI_API_KEY}`;

    const gemReq = {
      systemInstruction: { parts: [{ text: systemText }] },
      contents,
      generationConfig: {
        temperature: 0.7,
        // Enough for a full reply (e.g. the 4-part document analysis) without
        // cutting off mid-sentence.
        maxOutputTokens: 2048,
        // Gemini 2.5 Flash otherwise spends part of the token budget on hidden
        // "thinking", which can truncate or empty the visible answer. Disable
        // it: the whole budget goes to the reply (also faster and cheaper).
        thinkingConfig: { thinkingBudget: 0 },
      },
    };

    let gem;
    try {
      const r = await fetch(url, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(gemReq),
      });
      if (!r.ok) return json({ error: 'upstream', status: r.status }, 502);
      gem = await r.json();
    } catch (_) {
      return json({ error: 'upstream_unreachable' }, 502);
    }

    const reply =
      gem?.candidates?.[0]?.content?.parts?.map((p) => p.text).join('').trim() || '';
    return json({ reply });
  },
};
