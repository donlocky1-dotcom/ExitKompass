import 'package:exit_engine/exit_engine.dart';

/// German UI label for a scenario.
String scenarioLabel(ScenarioType type) {
  switch (type) {
    case ScenarioType.kuendigungAg:
      return 'Kündigung durch Arbeitgeber';
    case ScenarioType.aufhebungsvertrag:
      return 'Aufhebungsvertrag';
    case ScenarioType.eigenkuendigung:
      return 'Eigenkündigung';
    case ScenarioType.bleiben:
      return 'Bleiben';
  }
}

/// Short German label (for tight chart axes).
String scenarioShortLabel(ScenarioType type) {
  switch (type) {
    case ScenarioType.kuendigungAg:
      return 'AG-Kündigung';
    case ScenarioType.aufhebungsvertrag:
      return 'Aufhebung';
    case ScenarioType.eigenkuendigung:
      return 'Eigenkündig.';
    case ScenarioType.bleiben:
      return 'Bleiben';
  }
}

/// German label for a tax class.
String taxClassLabel(TaxClass c) => switch (c) {
      TaxClass.i => 'I',
      TaxClass.ii => 'II',
      TaxClass.iii => 'III',
      TaxClass.iv => 'IV',
      TaxClass.v => 'V',
      TaxClass.vi => 'VI',
    };

/// German name for a federal state.
String bundeslandLabel(Bundesland b) => switch (b) {
      Bundesland.badenWuerttemberg => 'Baden-Württemberg',
      Bundesland.bayern => 'Bayern',
      Bundesland.berlin => 'Berlin',
      Bundesland.brandenburg => 'Brandenburg',
      Bundesland.bremen => 'Bremen',
      Bundesland.hamburg => 'Hamburg',
      Bundesland.hessen => 'Hessen',
      Bundesland.mecklenburgVorpommern => 'Mecklenburg-Vorpommern',
      Bundesland.niedersachsen => 'Niedersachsen',
      Bundesland.nordrheinWestfalen => 'Nordrhein-Westfalen',
      Bundesland.rheinlandPfalz => 'Rheinland-Pfalz',
      Bundesland.saarland => 'Saarland',
      Bundesland.sachsen => 'Sachsen',
      Bundesland.sachsenAnhalt => 'Sachsen-Anhalt',
      Bundesland.schleswigHolstein => 'Schleswig-Holstein',
      Bundesland.thueringen => 'Thüringen',
    };

/// German label for a cashflow source.
String cashflowSourceLabel(CashflowSource s) => switch (s) {
      CashflowSource.salary => 'Gehalt',
      CashflowSource.severance => 'Abfindung',
      CashflowSource.severanceRefund => 'Steuererstattung',
      CashflowSource.alg => 'ALG 1',
      CashflowSource.gap => 'ohne Einkommen',
    };
