# exitkompass_app

Flutter-App des ExitKompass (iOS + Android). Baut auf dem reinen Dart-Package
[`exit_engine`](../packages/exit_engine) auf.

## Stand (v1, Woche 3–4)

- Onboarding mit Pflicht-Disclaimer (§ 9)
- 4-Schritt-Wizard: Situation · Person & Steuer · Job · Angebot
- Abfindungshöhe-Schätzer (M6): Bandbreite je Verhandlungsposition
  (§ 1a/§ 10 KSchG), Mittelwert per Klick übernehmen. Der im Wizard
  erfasste Kündigungsgrund (betriebs-/verhaltens-/personenbedingt)
  wird gespeichert und schlägt die Start-Verhandlungsstärke vor
  (ASSUMPTIONS.md A9.6).
- Ergebnis: Szenario-Vergleich der vier Optionen (4-Balken-Chart, bestes
  Szenario, Delta zur Baseline „Bleiben")
- „Liquidität"-Tab (M7): „Reicht mein Geld bis zum neuen Job?" – Rücklagen +
  Szenario-Einkommen − Ausgaben, Kontostand-Verlauf als Chart, Warnung wann
  die Deckungslücke entsteht (ASSUMPTIONS.md A11)
- „Passende Hilfe"-Panel (dezent, aufklappbar unter dem Vergleich):
  neutrale Anlaufstellen (Fachanwalt, Rechtsschutz, Beratungshilfe,
  Agentur für Arbeit, Krankenkasse, Betriebsrat) – **ohne** Tracking,
  Werbung oder Vermittlung; die für die Situation relevanten Einträge
  werden nach oben sortiert (ASSUMPTIONS.md A10)
- Detail je Szenario: monatlicher Netto-Cashflow (fl_chart) + Risiko-/
  Info-Hinweise
- „Fristen"-Tab: personalisierte Deadline-Timeline aus den Eingaben
  (§ 4 KSchG, § 38/§ 141 SGB III, KV, Zeugnis)
- „Ratgeber"-Tab: belegte, datierte Wissens-Artikel (Verhandlung,
  Rechtsgrundlagen, Arbeitsagentur) – allgemeine Rechtsinfo, keine
  Einzelfallberatung (siehe ASSUMPTIONS.md A8)
- PDF-Dossier: „Entscheidungs-Dossier" (Eingaben, Szenario-Vergleich,
  Hinweise, Verhandlungs-Bandbreite, Fristen, „Passende Hilfe", Disclaimer)
  via Teilen-Button; eingebettete DejaVu-Schrift für korrekte
  €/Umlaut-Darstellung. Bandbreite und Hilfe-Liste nutzen dieselbe Logik wie
  im Rechner (ASSUMPTIONS.md A9.7, A10.4)
- Einstellungen (§4/§9): Parameterjahr, Disclaimer, Impressum/
  Datenschutz (Platzhalter bis Release), Analytics-Opt-in (aus),
  „Daten löschen" mit Bestätigung
- State: Riverpod; Eingaben werden lokal via Drift (SQLite) gespeichert
  und beim Start wiederhergestellt (Szenario-Ergebnisse bleiben
  in-memory, Spec §6). Schema-Migrationen laufen automatisch
  (v2: `kuendigungs_art`; v3: `monthly_expenses_euro` + `savings_euro`) und
  erhalten bereits gespeicherte Profile.

Noch offen (Woche 5–6): RevenueCat/Paywall, lokale Push-Erinnerungen
für die Fristen.

## Entwicklung

```bash
flutter pub get
flutter analyze     # ohne Findings
flutter test        # Widget- und Flow-Tests
flutter run         # auf Gerät/Emulator
```
