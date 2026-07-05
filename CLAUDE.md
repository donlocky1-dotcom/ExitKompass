# ExitKompass – Projektanweisungen

## Projekt
Flutter-App (iOS + Android): Szenariorechner für Kündigung, Aufhebungsvertrag, Abfindung und ALG 1 in Deutschland.
Die vollständige Produktspezifikation liegt in `docs/ExitKompass_Spezifikation_v1.md` – bei jeder Architektur- oder Fachfrage zuerst dort nachschlagen. Bei Widerspruch gilt die Spec.

## Architektur (nicht verhandelbar)
- Monorepo: `app/` (Flutter-App) + `packages/exit_engine/` (reines Dart-Package, KEINE Flutter-Abhängigkeit)
- `exit_engine`: ausschließlich pure, deterministische Funktionen; alle Jahreswerte kommen aus `packages/exit_engine/lib/params/params_2026.json`
- State-Management: Riverpod · Persistenz: Drift (SQLite) · Käufe: RevenueCat (`purchases_flutter`) · Charts: `fl_chart` · PDF: `pdf`-Package
- Kein Backend, kein Konto, keine Cloud. Alle Nutzerdaten bleiben on-device. Keine Abhängigkeit einführen, die Daten nach außen sendet (Ausnahme: RevenueCat für Kaufabwicklung, TelemetryDeck nur nach Opt-in).

## Rechenlogik – Qualitätsregeln
- Geldbeträge intern immer als `int` in Cent. Niemals `double` für Geld. Rundung erst an der UI-Grenze.
- Jedes Engine-Modul hat eine eigene Datei + eigene Testdatei:
  M1 Lohn-/Einkommensteuer · M2 Sozialversicherung · M3 Abfindung/Fünftelregelung · M4 ALG 1 · M5 Szenario-Aggregator
- Golden-Master-Tests in `packages/exit_engine/test/golden/` mit Referenzfällen, die gegen den BMF-Lohn- und Einkommensteuerrechner und den ALG-Rechner der Bundesagentur für Arbeit verifiziert werden. Toleranz ±2 %, je Testfall dokumentiert.
- Golden-Werte, die noch nicht manuell gegen die offiziellen Rechner geprüft wurden, tragen den Test-Tag `unverified`. Kein Release-Build, solange `unverified`-Tags existieren.
- Steuer- und SV-Parameter NIEMALS im Code hardcoden – immer aus `params_<jahr>.json`. Jeder Parameterblock trägt einen Quellenkommentar.

## Domänenregeln (Kurzreferenz – Details in Spec §5)
- Echte Abfindungen sind sozialversicherungsfrei, aber voll einkommensteuerpflichtig.
- Fünftelregelung (§ 34 EStG): `Steuer = 5 × [ESt(zvE_rest + Abfindung/5) − ESt(zvE_rest)]`. Seit 2025 nur noch über die Veranlagung, nicht im Lohnsteuerabzug → im Cashflow als spätere Erstattung modellieren, nicht als sofortigen Abzug.
- ALG 1: Bemessungsentgelt = Ø beitragspflichtiges Brutto der letzten 12 Monate, gedeckelt auf die BBG der Arbeitslosenversicherung (2026: 8.450 €/Monat). Leistungssatz 60 %, mit Kind 67 %.
- Anspruchsdauer nach § 147 SGB III (Tabelle in params-Datei). Sperrzeit (§ 159): 12 Wochen UND Minderung der Gesamtanspruchsdauer um mindestens ¼. Ruhen (§ 158) bei Abfindung + Nichteinhaltung der ordentlichen Kündigungsfrist.

## Sprache & Compliance
- UI-Texte: Deutsch, „du"-Form, klar und ohne Juristendeutsch. Code, Kommentare, Commit-Messages: Englisch.
- In UI-Texten niemals Empfehlungssprache („Du solltest kündigen") – ausschließlich Szenario-Sprache („In diesem Szenario ergäbe sich …").
- Jeder Ergebnis-Screen trägt den Disclaimer-Footer: Schätzwerte, keine Steuer- oder Rechtsberatung.
- Fachliche Unsicherheit niemals durch Raten lösen: Annahme treffen, als `// TODO(assumption)` markieren und in `ASSUMPTIONS.md` mit Begründung dokumentieren.

## Workflow
- TDD für die Engine: erst Testfall schreiben, dann implementieren.
- Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`). Kleine, modulweise Commits.
- Vor jedem Commit müssen grün sein: `dart analyze` + `dart test` (Engine) bzw. `flutter analyze` + `flutter test` (App).
- Keine neuen Dependencies ohne kurze Begründung im Commit-Body.

## Befehle
- Engine-Tests: `cd packages/exit_engine && dart test`
- Nur verifizierte Golden-Tests: `dart test --exclude-tags unverified`
- App starten: `cd app && flutter run`
- Statische Analyse: `dart analyze` / `flutter analyze`
