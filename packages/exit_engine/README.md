# exit_engine

Rechen-Engine des **ExitKompass** für das Steuer-/Beitragsjahr **2026**:
Einkommensteuer (M1), Sozialversicherung (M2), Abfindung (M3) und
ALG 1 (M4). Reine Dart-Bibliothek ohne Flutter-Abhängigkeit.

**Konventionen**

- Alle Geldbeträge sind `int` in **Cent** (Eingabe und Ausgabe).
- Alle Parameter (Tarifformel § 32a EStG, Beitragssätze, BBGs,
  ALG-Tabellen) kommen aus
  [`lib/params/params_2026.json`](lib/params/params_2026.json)
  mit Quellenkommentar je Block; `ExitParams.year2026()` lädt die
  eingebettete Kopie. Andere Jahre: eigene JSON über
  `ExitParams.fromJsonString(...)` laden und als `params:` übergeben.
- Code und Kommentare sind Englisch; deutsche Rechtsbegriffe ohne
  präzise Übersetzung (Vorsorgepauschale, Fünftelregelung, Bundesland)
  bleiben als Fachbegriffe erhalten.
- Vereinfachungen und offene Punkte: siehe [`ASSUMPTIONS.md`](../../ASSUMPTIONS.md);
  manuelle Verifikation der Golden-Cases: [`VERIFY.md`](../../VERIFY.md).

```bash
dart pub get
dart analyze            # ohne Findings
dart test               # 93 Tests
dart test --exclude-tags unverified   # ohne die noch nicht extern
                                      # verifizierten Golden-Cases
```

## M1 – Einkommensteuer / Lohnsteuer

zvE → tarifliche Einkommensteuer (§ 32a EStG, Grund-/Splittingtarif),
darauf Soli und Kirchensteuer; Jahres-Lohnsteuer je Steuerklasse I–VI mit
vereinfachter Vorsorgepauschale als Netto-Schätzung.

```dart
import 'package:exit_engine/exit_engine.dart';

// 50.000 € zvE → 10.548,00 € ESt (Grundtarif 2026)
final tax = incomeTax(taxableIncomeCents: 5000000);        // 1054800

// Soli auf eine ESt von 40.000 € (oberhalb der Milderungszone)
final soli = solidaritySurcharge(assessmentBasisCents: 4000000); // 220000

// Kirchensteuer 8 % (Bayern) auf 10.000 € ESt
final church = churchTax(
  assessmentBasisCents: 1000000,
  state: Bundesland.bayern,
);                                                          // 80000

// Jahres-Lohnsteuer: 60.000 € Brutto, StKl I, kinderlos, 30 Jahre
final wage = annualWageTax(
  grossYearCents: 6000000,
  taxClass: TaxClass.i,
  age: 30,
);
print(wage.wageTaxCents); // 932800  (9.328,00 €)
print(wage.soliCents);    // 0       (unter der Freigrenze)
```

## M2 – Sozialversicherung

Arbeitnehmer-Abzüge KV/PV/RV/AV mit Deckelung an beiden
Beitragsbemessungsgrenzen; PV mit Kinderlosenzuschlag, Kinderabschlägen
und Sachsen-Sonderfall.

```dart
// 130.000 € Brutto liegt über beiden BBGs
final sv = employeeSocialContributions(
  grossYearCents: 13000000,
  age: 40,
  totalChildren: 2,
  childrenUnder25: 2,
);
print(sv.healthCents);       // 610313  (KV auf 69.750 € gedeckelt)
print(sv.pensionCents);      // 943020  (RV auf 101.400 € gedeckelt)
print(sv.careRateEmployee);  // 0.0155  (1,8 % − 0,25 %-Pkt. für das 2. Kind)
print(sv.totalCents);        // Summe aller AN-Beiträge

// Netto-Schätzung (M1 + M2) in einem Aufruf:
final net = annualNetIncome(
  grossYearCents: 6000000,
  taxClass: TaxClass.i,
  age: 30,
);
print(net.netMonthCents); // 313517  (3.135,17 €/Monat)
```

## M3 – Abfindung (Fünftelregelung)

Regelbesteuerung vs. Fünftelregelung (§ 34 Abs. 1 EStG) auf das zvE des
Abfindungsjahres; seit 2025 gibt es die Ermäßigung nur noch über die
Veranlagung – das Flag macht das explizit. Optional: grobe
Zusammenballungsprüfung nach Spec §5.

```dart
final sev = severanceComparison(
  taxableIncomeWithoutSeveranceCents: 5500000,  // 55.000 € Rest-zvE
  severanceCents: 6000000,                      // 60.000 € Abfindung
  // optional für die Zusammenballungsprüfung:
  otherIncomeYearCents: 5500000,
  foregoneIncomeCents: 8000000,
);
print(sev.taxRegularCents);        // 3716400  (37.164,00 €)
print(sev.taxFifthRuleCents);      // 3570200  (35.702,00 €)
print(sev.savingsCents);           // 146200   ( 1.462,00 €)
print(sev.refundOnlyViaTaxReturn); // true → Erstattung erst mit der Veranlagung
print(sev.fifthRuleApplicable);    // true → Zusammenballung gegeben
```

## M4 – ALG 1

Bemessungsentgelt (BBG-gedeckelt) → pauschaliertes Leistungsentgelt
(20 % SV-Pauschale, fiktive Lohnsteuer, Soli) → Leistungssatz 60/67 % →
Tagessatz und Monatsbetrag; dazu Anspruchsdauer (§ 147), Sperrzeit-
Simulation (§ 159/§ 148) inkl. Ausnahme-Heuristik und Ruhen bei
Abfindung (§ 158).

```dart
final alg = alg1Benefit(
  grossYearCents: 6000000,       // 60.000 € letztes Jahresbrutto
  taxClass: TaxClass.i,
  age: 30,
);
print(alg.benefitDayCents);   // 6357    (63,57 €/Tag)
print(alg.benefitMonthCents); // 190710  (1.907,10 €/Monat)

final days = alg1EntitlementDays(insuredMonths: 24, age: 30); // 360

// Eigenkündigung ohne wichtigen Grund: 12 Wochen Sperrzeit,
// Anspruchsdauer −25 %
final block = blockingPeriodSimulation(
    entitlementDays: days, benefitDayCents: alg.benefitDayCents);
print(block.reductionDays);    // 90
print(block.lostBenefitCents); // 572130  (5.721,30 € endgültig verloren)

// Spec-§5-Heuristik: Aufhebung wegen drohender betriebsbedingter
// Kündigung, Abfindung ≤ 0,5 Monatsgehälter je Beschäftigungsjahr
final unlikely = blockingPeriodUnlikely(
  dismissalWasThreatened: true,
  severanceCents: 2500000,
  grossMonthCents: 500000,
  tenureYears: 10,
); // true → Sperrzeit unwahrscheinlich („prüfen lassen"-Hinweis Pflicht)

// Abfindung + verkürzte Kündigungsfrist: Ruhen nach § 158
final susp = suspension158(
  severanceCents: 5000000,
  age: 40,
  tenureYears: 10,
  dailyWageCents: 6000000 ~/ 365,
  missedNoticeDays: 60,
);
print(susp.applicableShare); // 0.45
print(susp.suspensionDays);  // 60 (gedeckelt auf die fehlende Frist)
```

## Parameter aktualisieren

`lib/params/params_2026.json` ist die Quelle der Wahrheit. Nach
Änderungen die eingebettete Kopie neu erzeugen:

```bash
python3 tool/embed_params.py
```

Der Test `params_sync_test.dart` schlägt fehl, wenn beide Fassungen
auseinanderlaufen.
