# ExitKompass Coach-Proxy (Cloudflare Worker)

Schlanker Proxy zwischen App und **Gemini Flash**. Er hält den API-Key (die App
tut das **nie**), prüft die Premium-Berechtigung, spielt den System-Prompt ein
und ruft Gemini auf. Kosten am Start: **0 €** (Cloudflare-Free-Tier,
100.000 Requests/Tag); nur die Gemini-Nutzung kostet Cent-Beträge.

> **Noch nicht live.** Dieser Code ist einsatzbereit, aber es sind bewusst
> **keine Keys** eingecheckt und nichts deployt. Erst nach ausdrücklicher
> Freigabe deployen.

## Einmal einrichten

```bash
cd worker
npm install
npx wrangler login            # einmalig, öffnet den Browser

# Gemini-Key (aus Google AI Studio) als Secret setzen – NICHT in Dateien:
npx wrangler secret put GEMINI_API_KEY

# Optional, sobald die Premium-Prüfung scharf geschaltet wird:
npx wrangler secret put REVENUECAT_API_KEY
```

## Lokal testen (ohne Premium-Prüfung)

In `wrangler.toml` `ALLOW_ALL = "true"` setzen (nur zum Testen!), dann:

```bash
npx wrangler dev
# → lokale URL, z. B. http://localhost:8787
```

Test-Request:

```bash
curl -X POST http://localhost:8787 \
  -H 'content-type: application/json' \
  -d '{"system":"Du bist ...","messages":[{"role":"user","text":"Ich habe an einem Projekt gearbeitet, das ..."}]}'
# → {"reply":"…"}
```

### Datei-Uploads (Lebenslauf-Check)

Für den Unterlagen-Check kann eine Nachricht optional Dateien tragen (z. B. ein
Lebenslauf als PDF/Bild). Sie werden als Base64-`inline_data` an Gemini
weitergereicht (Gemini Flash liest PDFs/Bilder direkt):

```json
{
  "system": "…Extraktions- oder Analyse-Prompt…",
  "messages": [
    { "role": "user", "text": "Bitte extrahiere den Lebenslauf …",
      "files": [{ "mimeType": "application/pdf", "data": "<base64>" }] }
  ]
}
```

Die App liest die hochgeladene Datei **einmal** aus (Extraktion zu Klartext) und
arbeitet danach nur noch mit Text – die Datei wird also nicht bei jeder
Chat-Nachricht neu geschickt. Das `system`-Feld darf jetzt bis zu 20 000 Zeichen
tragen (damit ausgelesener Lebenslauf + Stellenanzeige als Kontext passen).

## Deploy

```bash
npx wrangler deploy
# → https://exitkompass-coach.<account>.workers.dev
```

## App anbinden

Die App bleibt standardmäßig auf dem lokalen Vorschau-Coach. Für den
Gemini-Coach beim Build den Endpoint übergeben:

```bash
flutter build apk --dart-define=COACH_PROXY_ENDPOINT=https://exitkompass-coach.<account>.workers.dev
```

`ALLOW_ALL` in Produktion **entfernen** und die RevenueCat-Prüfung aktivieren
(`REVENUECAT_API_KEY`, `PREMIUM_ENTITLEMENT`). Die App sendet dann die
RevenueCat-App-User-ID als `Authorization: Bearer <id>`, die der Proxy
gegen RevenueCat prüft.

## Datenschutz

Nur der Gesprächstext wird verarbeitet; der Worker **speichert nichts**.
Gemini-Paid-Tier trainiert nicht auf API-Daten. AVV (Art. 28 DSGVO) mit Google
abschließen. Nutzer werden über den Opt-in-Dialog informiert (siehe
`docs/AI_Coach_Konzept.md`).
