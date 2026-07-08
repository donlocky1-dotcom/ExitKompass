# KI-Coach für ExitKompass – Konzept & Architektur-Entscheidung

*Stand 08.07.2026 · Entwurf zur Entscheidung · Android-first · Premium-Feature*

Gesprächs-Simulation (Bewerbung & Verhandlung) als kostenpflichtiges
Premium-Feature – ohne das lokale, cloudfreie Versprechen der Kern-App
aufzuweichen.

## Ziel & Umfang

- **Bewerbungsgespräch-Simulation (MVP, zuerst):** Die KI spielt die
  interviewende Person, stellt dynamische Nachfragen (Fragenkatalog, STAR,
  Value-Selling) und gibt am Ende strukturiertes Feedback (Inhalt, Aufbau,
  Wirkung). Geringes Rechtsrisiko, hoher Übungswert.
- **Verhandlungs-Simulation (Ausbau, später):** KI spielt HR/Vorgesetzte im
  Aufhebungs-/Abfindungsgespräch. **Die Zahlen liefert die Engine** (Abfindungs-
  band, Sperrzeit, Netto); die KI übernimmt nur die Gesprächsführung als
  **Übung** – keine Rechts- oder Steuerberatung.

## Drei Wege im Vergleich

| Kriterium | **Cloud, Premium · empfohlen** | On-Device (offline) | Cloud Free-Tier |
|---|---|---|---|
| Kosten für euch | ~0,1–2 ct/Gespräch (durch Premium gedeckt) | 0 € pro Nutzung | 0 €, aber Limits |
| Datenschutz | Cloud – lösbar per Opt-in & No-Training | perfekt, verlässt Gerät nie | Daten oft fürs Training |
| Qualität (dt. Dialog) | sehr gut | okay, schwach bei feiner Jura-Sprache | sehr gut |
| Geräte-Abdeckung | alle Android-Geräte | nur leistungsstarke, ~1–3 GB Download | alle |
| Offline nutzbar | nein | ja | nein |
| Aufwand | + kleiner Backend-Proxy | Modell-Integration, Größe | Limits, ToS-Risiko |

Free-Tiers (Gemini, Groq) sind für ein Produkt nicht verlässlich (Rate-Limits,
ToS) und würden das Datenschutz-Versprechen brechen.

## Empfehlung: Cloud, Premium-gated

Sobald es ein Bezahl-Feature ist, ist Cloud die klare Wahl: die paar Cent pro
Gespräch sind durch Premium gedeckt, die Qualität ist deutlich besser, es läuft
auf **jedem** Android-Gerät ohne Riesen-Download – und es ist der schnellste
Weg zum Launch. Einziger Zusatzaufwand: ein **winziger Backend-Proxy** (der
API-Schlüssel darf nicht in die App). On-Device bleibt als späterer
„100 % offline“-Ausbau ohne Umbau möglich.

## Architektur (austauschbare KI-Schicht)

```
ExitKompass-App              Backend-Proxy                  LLM-API
(Flutter, CoachEngine)  →   (Cloudflare Worker:        →   z. B. Claude Haiku /
                             hält Key, prüft Premium,       Gemini Flash
                             Rate-Limits)
```

- KI liegt hinter einem Interface `CoachEngine` – heute Cloud, später on-device
  (Gemma) **ohne App-Umbau** nachrüstbar.
- Proxy prüft die **RevenueCat**-Berechtigung (Paywall ohnehin auf der Roadmap),
  setzt Limits, schützt den Schlüssel.
- **Kern-App bleibt 100 % lokal**; nur der KI-Coach ist ein bewusstes Opt-in.

## Anbietervergleich

| Anbieter / Modell | Kosten/Gespräch* | Training auf API-Daten | Deutsch | Anmerkung |
|---|---|---|---|---|
| Anthropic – Claude Haiku | ~0,3–1 ct | nein (API-Standard) | sehr gut | starkes Instruction-Following, gute Guardrails |
| Google – Gemini Flash | ~0,1–0,5 ct | nein im Paid-Tier | sehr gut | günstigste Option, schnell |
| OpenAI – GPT (mini) | ~0,2–0,8 ct | nein (API by default) | sehr gut | breit erprobt |
| Open-Source, selbst gehostet | Serverkosten | volle Kontrolle | modellabhängig | volle Datenhoheit, mehr Betrieb |

\* Grobe Richtwerte für ein Übungsgespräch (~10–30 Turns); Preise ändern sich,
vor Festlegung aktuell prüfen. MVP-Empfehlung: günstiges, starkes Modell mit
No-Training-Zusage, hinter dem austauschbaren Interface.

## Datenschutz & Recht

- **Trennung:** Kern-App bleibt lokal/cloudfrei; der KI-Coach ist ein separates,
  klar gekennzeichnetes **Opt-in** mit eigenem Einwilligungs-Dialog.
- **Kein Training:** Anbieter/Tarif mit No-Training-Zusage; **AVV** (Art. 28
  DSGVO) abschließen.
- **Datensparsamkeit:** nur Gesprächstext geht raus, Klarnamen/Details
  vermeiden/anonymisieren; **keine serverseitige Speicherung**.
- **Recht (RDG/StBerG):** als *Rollenspiel/Übung* rahmen, keine Rechts-/
  Steuerberatung; sichtbarer Disclaimer; Zahlen aus der Engine, nicht aus der KI.

**Einwilligungstext (Entwurf):** „Für das KI-Coaching wird dein eingegebener
Gesprächstext an einen sicheren KI-Dienst gesendet und dort verarbeitet, um
Antworten zu erzeugen. Der Anbieter nutzt diese Daten nicht zum Training. Gib
keine sensiblen personenbezogenen Daten ein. Das Coaching ist eine Übung und
ersetzt keine Rechts- oder Steuerberatung. Du kannst das jederzeit in den
Einstellungen deaktivieren.“

## Leitplanken (System-Prompt)

- Rolle klar: Übungspartner/Coach, kein Berater; keine Rechts-/Steuerauskunft.
- **Keine erfundenen Zahlen** – Beträge kommen als Kontext aus der Engine.
- Konstruktiv, respektvoll, deutsch; am Ende strukturiertes Feedback
  (Stärken / 2–3 konkrete Verbesserungen).
- Themenanker: bleibt beim Bewerbungs-/Verhandlungskontext.

## Aufwand & Kosten (grob)

| Baustein | Aufwand |
|---|---|
| Backend-Proxy + Paywall-Check (RevenueCat) | 1–2 Tage |
| Chat-UI + `CoachEngine`-Interface + Interview-Prompting | 3–5 Tage |
| Verhandlungs-Sim mit Engine-Anbindung | später, separat |
| Laufende Modellkosten | ~0,1–2 ct/Gespräch |

## Fahrplan

1. **Prototyp lokal** – `CoachEngine`-Interface + Interview-Sim; Cloud gestubbt,
   kein Live-Key nötig.
2. **Backend-Proxy & Anbieter** – Worker, Anbieter/Tarif (No-Training), AVV,
   Rate-Limits.
3. **Premium-Gate** – RevenueCat-Entitlement in App & Proxy; Opt-in + Disclaimer.
4. **Launch Bewerbungs-Coach** – als Premium-Feature, Feedback sammeln.
5. **Ausbau** – Verhandlungs-Sim (Engine liefert Zahlen); optional On-Device.

## Offene Entscheidungen

- **Anbieter/Modell** fürs MVP (Empfehlung: günstiges, starkes Modell mit
  No-Training-Zusage).
- **Premium-Modell & Preis** – Teil eines Abos oder eigener Aufpreis?
- **Backend-Host** (Cloudflare Worker vorgeschlagen) und Betrieb.
- **Umfang MVP** – nur Bewerbungs-Sim, oder gleich beide?

*Nächster konkreter Schritt bei grünem Licht: den lokal testbaren Prototyp
(Schritt 1) bauen – ganz ohne Live-Keys oder Kosten.*
