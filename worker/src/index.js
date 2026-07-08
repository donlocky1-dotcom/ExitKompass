// ExitKompass coach proxy (Cloudflare Worker).
//
// The app posts the conversation here; this Worker verifies the premium
// entitlement, injects the system prompt and the Gemini API key (kept as a
// Worker secret, never in the app), calls Gemini Flash, and returns the reply.
//
// Secrets / vars (set via `wrangler secret put` / wrangler.toml):
//   GEMINI_API_KEY   – Google AI Studio key (secret, required)
//   GEMINI_MODEL     – e.g. "gemini-2.0-flash" (var, optional)
//   ALLOW_ALL        – "true" to skip the entitlement check while testing (var)
//   REVENUECAT_API_KEY – RevenueCat secret key for entitlement checks (secret)
//   PREMIUM_ENTITLEMENT – RevenueCat entitlement id, e.g. "premium" (var)
//
// No key or secret is committed to the repo.

const SYSTEM_PROMPTS = {
  interview:
    'Du bist ein Coach, der auf Deutsch ein Bewerbungsgespräch simuliert. Du ' +
    'spielst die interviewende Person und stellst nacheinander realistische ' +
    'Fragen.\n' +
    'Regeln:\n' +
    '- Du bist Übungspartner, kein Berater. Gib KEINE Rechts- oder ' +
    'Steuerberatung.\n' +
    '- Stelle immer nur EINE Frage pro Nachricht. Nach der Antwort: kurzes, ' +
    'konkretes und freundliches Feedback (1–2 Sätze) mit einem Tipp zur ' +
    'STAR-Struktur, dann die nächste Frage.\n' +
    '- Bleib beim Bewerbungskontext. Erfinde keine Fakten über die Person.\n' +
    '- Kurz und klar, Deutsch, per Du.\n' +
    '- Nach etwa sechs Fragen: fasse Stärken und 2–3 konkrete Verbesserungen ' +
    'zusammen.',
  negotiation:
    'Du simulierst auf Deutsch ein Abfindungs-/Aufhebungsgespräch und spielst ' +
    'die Personalleitung. Du bist Übungspartner, KEIN Rechts- oder ' +
    'Steuerberater und nennst keine konkreten Zahlen selbst – Beträge kommen ' +
    'ausschließlich aus dem mitgelieferten Kontext. Bleib sachlich, gib nach ' +
    'dem Gespräch kurzes Feedback zur Verhandlungsführung.',
};

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
  // When set, the bare URL without the token is rejected – closes the open
  // endpoint. In a web build the token is not fully secret, but it stops
  // casual abuse of a billing-enabled key.
  if (env.ACCESS_TOKEN) return auth === env.ACCESS_TOKEN;
  if (env.ALLOW_ALL === 'true') return true;
  // Production: verify the RevenueCat entitlement for the app user.
  const appUserId = auth;
  if (!appUserId || !env.REVENUECAT_API_KEY) return false;
  // Verify the RevenueCat entitlement for this app user.
  try {
    const r = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
      { headers: { authorization: `Bearer ${env.REVENUECAT_API_KEY}` } },
    );
    if (!r.ok) return false;
    const data = await r.json();
    const ent = (data.subscriber && data.subscriber.entitlements) || {};
    const id = env.PREMIUM_ENTITLEMENT || 'premium';
    return Boolean(ent[id] && ent[id].expires_date === null
      ? true
      : ent[id] && new Date(ent[id].expires_date) > new Date());
  } catch (_) {
    return false;
  }
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { headers: cors });
    if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

    if (!(await isEntitled(request, env))) {
      return json({ error: 'not_entitled' }, 402);
    }

    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return json({ error: 'bad_request' }, 400);
    }

    const mode = payload.mode === 'negotiation' ? 'negotiation' : 'interview';
    const messages = Array.isArray(payload.messages) ? payload.messages : [];
    // Character/persona instruction supplied by the app (flavour only – the
    // safety guardrails above always apply). Bounded to keep it in check.
    const personaPrompt = String(payload.personaPrompt || '').slice(0, 600);
    const systemText = personaPrompt
      ? `${SYSTEM_PROMPTS[mode]}\n\nRolle/Charakter des Gegenübers: ${personaPrompt}`
      : SYSTEM_PROMPTS[mode];

    const contents = messages
      .map((m) => ({
        role: m.role === 'user' ? 'user' : 'model',
        parts: [{ text: String(m.text || '') }],
      }))
      .filter((c) => c.parts[0].text.length > 0);
    // Gemini expects the first turn to be from the user.
    while (contents.length && contents[0].role === 'model') contents.shift();
    if (contents.length === 0) return json({ error: 'empty' }, 400);

    const model = env.GEMINI_MODEL || 'gemini-2.5-flash';
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
      `?key=${env.GEMINI_API_KEY}`;

    const gemReq = {
      systemInstruction: { parts: [{ text: systemText }] },
      contents,
      generationConfig: { temperature: 0.7, maxOutputTokens: 500 },
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
