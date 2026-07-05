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
- State: Riverpod (in-memory, kein Backend/Konto/Cloud)

Noch offen (Woche 5–6): RevenueCat/Paywall, PDF-Export, Drift-Persistenz,
Timeline & lokale Notifications.

## Entwicklung

```bash
flutter pub get
flutter analyze     # ohne Findings
flutter test        # Widget- und Flow-Tests
flutter run         # auf Gerät/Emulator
```
