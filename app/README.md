# exitkompass_app

Flutter-App des ExitKompass (iOS + Android). Baut auf dem reinen Dart-Package
[`exit_engine`](../packages/exit_engine) auf.

## Stand (v1, Woche 3–4)

- Onboarding mit Pflicht-Disclaimer (§ 9)
- 4-Schritt-Wizard: Situation · Person & Steuer · Job · Angebot
- Ergebnis: Szenario-Vergleich der vier Optionen (4-Balken-Chart, bestes
  Szenario, Delta zur Baseline „Bleiben")
- Detail je Szenario: monatlicher Netto-Cashflow (fl_chart) + Risiko-/
  Info-Hinweise
- „Fristen"-Tab: personalisierte Deadline-Timeline aus den Eingaben
  (§ 4 KSchG, § 38/§ 141 SGB III, KV, Zeugnis)
- „Ratgeber"-Tab: belegte, datierte Wissens-Artikel (Verhandlung,
  Rechtsgrundlagen, Arbeitsagentur) – allgemeine Rechtsinfo, keine
  Einzelfallberatung (siehe ASSUMPTIONS.md A8)
- PDF-Dossier: „Entscheidungs-Dossier" (Eingaben, Szenario-Vergleich,
  Hinweise, Fristen, Disclaimer) via Teilen-Button; eingebettete
  DejaVu-Schrift für korrekte €/Umlaut-Darstellung
- State: Riverpod (in-memory, kein Backend/Konto/Cloud)

Noch offen (Woche 5–6): RevenueCat/Paywall, Drift-Persistenz,
lokale Push-Erinnerungen für die Fristen.

## Entwicklung

```bash
flutter pub get
flutter analyze     # ohne Findings
flutter test        # Widget- und Flow-Tests
flutter run         # auf Gerät/Emulator
```
