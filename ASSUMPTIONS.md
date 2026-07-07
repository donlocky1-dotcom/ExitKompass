# ASSUMPTIONS

Annahmen und Entscheidungen, die während der Entwicklung getroffen wurden,
weil die Spezifikation sie nicht (oder nicht eindeutig) vorgibt.

## A0 – Spezifikation lag zum Entwicklungsstart nicht vor (GELÖST am 2026-07-05)

Die Engine-Entwicklung startete versehentlich im Spiel-Repository
`Sozialbetrug` und wurde anschließend hierher (`exitkompass`) umgezogen.
`docs/ExitKompass_Spezifikation_v1.md` und `CLAUDE.md` lagen zum Start
in keinem der beiden Repositories vor; alle Parameter wurden deshalb
direkt aus den offiziellen Rechtsquellen 2026 übernommen (Quellen je
JSON-Block als `_quelle` dokumentiert) und per Web-Recherche verifiziert.

**Auflösung nach Nachreichen der Spec (2026-07-05):**

- `params_2026.json` wurde gegen die M2-Tabelle aus **Spec §5**
  abgeglichen: **100 % Übereinstimmung** (BBG RV/AV 101.400 €, BBG KV/PV
  69.750 €, KV 14,6 % + Ø-Zusatz 2,9 %, PV 3,6 % ±Kinderlogik, RV 18,6 %,
  AV 2,6 %, Bezugsgröße 3.955 €/Monat, AN-Anteile hälftig,
  PV-Kinderlosenzuschlag allein AN, Abfindungen SV-frei).
- Die Fünftelregelungs-Formel aus `CLAUDE.md` ist identisch mit der
  implementierten Formel des § 34 Abs. 1 EStG.
- Die §147-Tabelle der Spec ist eine Teilmenge der implementierten
  vollständigen Gesetzestabelle (inkl. Stufen 16→8 und 20→10 Monate).

**Noch offen aus Spec §5 (M1):** Validierung gegen die offiziellen
Testfälle des BMF-Programmablaufplans (PAP) 2026 als Golden-Master
(„ohne diese Validierung kein Release"). Die PAP-PDFs waren über den
Session-Proxy nicht abrufbar. **TODO vor Release.**

## A1 – Parameterdatei 2026

- **A1.1 GKV-Zusatzbeitrag:** Es wird der **durchschnittliche**
  Zusatzbeitragssatz 2026 (2,9 %, BMG-Bekanntmachung) als Default verwendet.
  Der tatsächliche Satz ist kassenindividuell; die API erlaubt einen
  abweichenden Satz als Parameter (`healthAdditionalRate`).
- **A1.2 § 39b Abs. 2 S. 7 EStG (StKl V/VI):** Die Grenzwerte 2026
  (14.071 € / 34.939 € / 222.260 €) stammen aus Sekundärquellen zum
  PAP 2026 (rechnercheck.de; BMF-PAP v. 12.11.2025 war über den
  Session-Proxy nicht direkt abrufbar). Plausibilität: 34.939 = 69.878/2,
  222.260 = 0,8 × 277.825. **TODO:** gegen den offiziellen PAP 2026 prüfen
  (zusammen mit der PAP-Golden-Master-Validierung aus A0).
- **A1.3 Entlastungsbetrag für Alleinerziehende (§ 24b EStG):** 4.260 €
  (Stand seit 2023) – für 2026 keine Änderung bekannt. Wird nur für
  Steuerklasse II verwendet. **TODO:** bestätigen.
- **A1.4 Kindergeld:** 259 €/Monat ab 01.01.2026 (§ 66 EStG i. d. F.
  Steuerfortentwicklungsgesetz). Wird von der Engine informativ mitgeführt,
  geht aber in keine M1–M4-Berechnung ein.
- **A1.5 Kirchensteuer:** Vereinfachung auf „8 % in BY/BW, 9 % sonst".
  Kappungsregelungen der Länder und besonderes Kirchgeld sind nicht
  abgebildet.
- **A1.6 Keine `null`-Platzhalter nötig:** Alle Parameterwerte konnten aus
  offiziellen bzw. verlässlichen Sekundärquellen belegt werden; ein Test
  (`params_sync_test.dart`) schlägt fehl, falls künftig `null`-TODOs in der
  Datei stehen, ohne dass sie hier gelistet sind.
- **A1.7 JSON-Schlüssel deutsch:** Die Schlüssel in `params_2026.json`
  bleiben deutsch (sie spiegeln die Begriffe der Rechtsquellen); das
  Dart-Modell (`params.dart`) übersetzt auf englische Bezeichner.

## A2 – M1 Einkommensteuer/Lohnsteuer

- **A2.1 Vorsorgepauschale (§ 39b Abs. 2 S. 5 Nr. 3 EStG):** Teilbeträge
  RV + KV + PV, dabei KV mit dem **ermäßigten** Beitragssatz
  (14,0 %/2 = 7,0 % + halber Zusatzbeitrag); die Summe wird **einmal**
  auf volle Euro aufgerundet; Mindestvorsorgepauschale 12 %,
  max. 1.900/3.000 € (StKl III). Diese Punkte wurden am 2026-07-05 gegen
  den BMF-Rechner kalibriert und treffen ihn seither **exakt**
  (G1/G2/G3/G5, siehe VERIFY.md). Weiterhin **nicht** abgebildet (für die
  Zielgruppe der Spec i. d. R. irrelevant): PKV-Basistarif-Bescheinigungen,
  Faktorverfahren, Frei-/Hinzurechnungsbeträge, sonstige
  Bezüge/Einmalzahlungen. Das offizielle PAP-Golden-Master aus Spec §5
  (M1) bleibt als zusätzliches Release-Gate offen (A0).
- **A2.2 Rundung:** zvE und Steuerbetrag werden auf volle Euro abgerundet
  (§ 32a Abs. 1 EStG); Soli/KiSt auf volle Cent abgerundet (Bruchteile
  eines Cents bleiben außer Ansatz). SV-Beiträge kaufmännisch auf Cent.
- **A2.3 Splitting:** Steuerklasse III wird über den Splittingtarif auf das
  eigene Brutto abgebildet (Alleinverdiener-Annahme); Einkommen des
  Ehepartners ist kein Eingabeparameter von M1.
- **A2.4 Kirchensteuer im LSt-Abzug:** Bemessungsgrundlage ist die fiktive
  LSt mit Kinderfreibeträgen (§ 51a Abs. 2a EStG); Kappung und besonderes
  Kirchgeld sind nicht abgebildet. In den **Steuerklassen V/VI** gibt es
  keine Kinderfreibetragszähler (§ 38b Abs. 2 EStG), daher wird die
  Kirchensteuer dort auf die volle Lohnsteuer berechnet (gegen den
  BMF-Rechner bestätigt, G5).

## A3 – M2 Sozialversicherung

- **A3.1 Personenkreis:** gesetzlich pflichtversicherter Arbeitnehmer.
  Keine PKV, kein Midijob-Übergangsbereich (§ 20 Abs. 2a SGB IV), keine
  Gleitzone, keine berufsständischen Versorgungswerke. (PKV-Behandlung
  in der ALG-Phase: laut Spec §13 bewusst vereinfacht mit Hinweis-Flag –
  betrifft die UI, nicht die Engine.)
- **A3.2 Jahresbetrachtung:** Beiträge werden auf das Jahresbrutto mit
  Jahres-BBGs gerechnet (keine Monatsabrechnung mit anteiligen BBGs bei
  unterjährigen Verläufen).
- **A3.3 PV-Kinderabschlag:** Eingaben sind `totalChildren` (jemals,
  für den Kinderlosenzuschlag) und `childrenUnder25` (für die
  Abschläge Kind 2–5). Die Altersprüfung der Kinder übernimmt der Aufrufer.

## A4 – M3 Abfindung

- **A4.1 Formel:** § 34 Abs. 1 EStG, identisch mit CLAUDE.md:
  `ESt_ermäßigt = ESt(zvE_rest) + 5 × (ESt(zvE_rest + A/5) − ESt(zvE_rest))`.
- **A4.2 Zusammenballung:** Die von Spec §5 (M3) geforderte **grobe**
  Prüfung ist implementiert (`incomeBunchingGiven`: Abfindung + Einkünfte
  im Jahr > entgangene Einnahmen) und optional in `severanceComparison`
  verdrahtet (`fifthRuleApplicable`). Sie ist eine Heuristik, keine
  rechtliche Würdigung; Grenzfälle muss die UI mit „prüfen
  lassen"-Hinweis versehen.
- **A4.3 Flag `refundOnlyViaTaxReturn`:** Seit VZ 2025 keine
  Fünftelregelung mehr im Lohnsteuerabzug (Wachstumschancengesetz); das
  Flag ist `true`, sobald eine Ersparnis > 0 existiert. Die von der Spec
  geforderte Cashflow-Darstellung (erst zahlen, später erstatten) ist
  Aufgabe des M5-Aggregators (Woche 3–4).
- **A4.4 Sozialversicherung:** Echte Abfindungen sind beitragsfrei in der
  SV; M3 rechnet daher nur die Steuer.

## A5 – M4 ALG 1

- **A5.1 Fiktive Lohnsteuer:** § 153 SGB III verlangt die Lohnsteuer nach
  dem BMF-Programmablaufplan „im Jahresdurchschnitt". M4 verwendet die
  vereinfachte M1-Jahreslohnsteuer auf das (gedeckelte) Bemessungsentgelt;
  kleine Abweichungen zum BA-Rechner sind möglich. Kirchensteuer wird –
  wie im geltenden Recht – **nicht** abgezogen, Soli mit
  Kinderfreibeträgen (§ 51a) schon.
- **A5.2 Rundung:** Tageswerte werden durch Ganzzahldivision (÷365)
  abgerundet, der Tagessatz ebenfalls; Monatsbetrag = 30 Tagessätze
  (§ 154 SGB III). Die BA rundet teils anders (2 Nachkommastellen je
  Rechenschritt); Abweichungen im Cent-Bereich sind möglich.
- **A5.3 Sperrzeit-Minderung:** § 148 Abs. 1 Nr. 4 SGB III – Minderung um
  die Sperrzeittage, bei 12 Wochen mindestens ein Viertel der
  Anspruchsdauer. Bei nicht durch 4 teilbaren Anspruchsdauern (450 Tage)
  wird abgerundet (450/4 → 112 Tage). Verkürzte Sperrzeiten (3/6 Wochen,
  § 159 Abs. 3 S. 2) sind nicht abgebildet.
- **A5.4 Sperrzeit-Ausnahme-Heuristik (Spec §5, M4):**
  `blockingPeriodUnlikely` bildet die BA-Geschäftsanweisung ab
  (Aufhebungsvertrag wegen drohender **betriebsbedingter** Kündigung,
  Abfindung ≤ 0,5 Bruttomonatsgehälter je Beschäftigungsjahr → i. d. R.
  keine Sperrzeit). Nur Flag-Charakter; die UI muss immer den „prüfen
  lassen"-Hinweis anzeigen. Die Untergrenze von 0,25 Monatsgehältern
  (unterhalb derer die BA den wichtigen Grund gesondert prüft) ist
  bewusst nicht abgebildet – die Spec nennt nur die 0,5-Obergrenze.
- **A5.5 § 158-Ruhen:** Eingabe ist `missedNoticeDays`
  (Differenz tatsächliches Ende ↔ fiktives Ende der ordentlichen
  Kündigungsfrist); die Bestimmung der maßgeblichen Kündigungsfrist
  (inkl. Sonderfälle unkündbarer Arbeitsverhältnisse, § 158 Abs. 1
  S. 3–4) übernimmt der Aufrufer. Während des Ruhens bleibt die
  Anspruchsdauer erhalten (kein § 148-Verbrauch); Ruhen und Sperrzeit
  laufen parallel, die Engine addiert sie nicht automatisch.
- **A5.6 Anspruchsdauer:** Die Tabelle setzt Versicherungsmonate in der
  auf 5 Jahre erweiterten Rahmenfrist voraus (Eingabe des Aufrufers);
  Vordienstzeiten-Anrechnung nach § 147 Abs. 3/4 ist nicht abgebildet.

## A7 – M5 Szenario-Aggregator (v1)

Erste Fassung des Aggregators (Spec §5 M5, §3). Bewusste Vereinfachungen,
damit die Engine ohne Kalender-/UI-Abhängigkeit testbar bleibt:

- **A7.1 Monatsraster statt Kalendertagen:** Der Aggregator rechnet auf
  **Monats-Offsets** (Monat 0 = `referenceDate`). Datumsangaben werden über
  ganze Monatsdifferenzen in Offsets umgerechnet; tagesgenaue Kalenderlogik
  (anteilige erste/letzte Monate) ist Sache der UI/Wizard-Schicht.
- **A7.2 Nettogehalt/Monat:** = Jahresnetto (M1+M2 auf `bruttoMonat×12 +
  Sonderzahlungen`) ÷ 12. Sonderzahlungen werden also gleichmäßig verteilt
  (kein separater Einmalzahlungs-Lohnsteuerabzug im Auszahlungsmonat).
- **A7.3 Abfindungs-Steuerbasis:** Als „zvE_rest im Auszahlungsjahr" wird
  das **volle** zu versteuernde Jahresgehalt angesetzt. Da der/die
  Beschäftigte unterjährig ausscheidet, überschätzt das das Rest-zvE und
  **unterschätzt** damit den Fünftelvorteil → konservativ (die App
  verspricht keine zu hohe Ersparnis). Tagesgenaue YTD-Berechnung ist eine
  spätere Verfeinerung.
- **A7.4 Liquiditätseffekt Fünftelregelung:** Im Austrittsmonat wird die
  Abfindung netto nach **Regelbesteuerung** angesetzt (so behält der
  Arbeitgeber ein); die Fünftel-Ersparnis fließt als separater
  Erstattungs-Zufluss rund **12 Monate später** (nächste Veranlagung) ein
  und wird zusätzlich als Flag ausgewiesen (Spec §5/§8).
- **A7.5 ALG-Start & Dauer:** ALG beginnt im Austrittsmonat, verzögert um
  Sperrzeit bzw. §158-Ruhen (in Monate gerundet: 12 Wochen ≈ 3 Monate).
  Die Anspruchsdauer (§147) wird aus der Betriebszugehörigkeit als
  Versicherungsmonate abgeleitet (gedeckelt auf 60) – die genaue
  Rahmenfrist-Prüfung bleibt der Eingabe vorbehalten. Bei Sperrzeit wird
  die Dauer um ein Viertel gekürzt (aufgerundet).
- **A7.6 Szenario-Zuordnung:** S1 (AG-Kündigung) ohne Sperrzeit, aber mit
  §158-Ruhen bei verkürzter Frist; S2 (Aufhebung) nutzt die
  Sperrzeit-Ausnahme-Heuristik (A5.4) zur Entscheidung wahrscheinlich/
  unwahrscheinlich; S3 (Eigenkündigung) immer 12 Wochen Sperrzeit + ¼;
  S4 (Bleiben) = Netto-Gehaltsfortschreibung als Baseline.
- **A7.9 Bezahlte Freistellung (S1/S2):** Ist `paidRelease` gesetzt, läuft
  das Arbeitsverhältnis bis zum regulären Ende (`regularEndDate`) weiter:
  volles Gehalt bis dahin, Abfindung/Restzahlung zu diesem Zeitpunkt, ALG
  erst danach – und kein §158-Ruhen (die ordentliche Kündigungsfrist ist
  gewahrt). Für S3 (Eigenkündigung) greift die Freistellung nicht. Eine
  Anrechnung anderweitigen Verdienstes während der Freistellung
  (§ 615 S. 2 BGB) ist nicht modelliert.
- **A7.7 Krankenversicherung in der Lücke:** Einkommenslose Monate nach dem
  Austritt werden als 0 geführt und mit einem KV-Flag markiert; ein
  konkreter KV-Beitrag in der Lücke wird (noch) nicht gerechnet (Spec §13:
  PKV/KV-Lücke vereinfacht mit Hinweis).
- **A7.8 Genauigkeitsziel:** Das Spec-§5-Ziel von ±2 % bezieht sich auf die
  Bausteine M1–M4 (gegen BMF/BA verifiziert, VERIFY.md); der Aggregator
  komponiert diese nur monatsweise.

## A9 – M6 Abfindungshöhe-Schätzer

Neues Engine-Modul (Marktrecherche: beide Wettbewerbs-Rechner führen mit
einer Höhen-Schätzung). Bewusst als **Orientierung, kein Rechtsanspruch**:

- **A9.1 Faktor-Bänder:** heuristische Bandbreiten je Verhandlungsposition
  (schwach 0,25–0,5 · standard 0,5–1,0 · stark 1,0–1,5), abgeleitet aus der
  arbeitsgerichtlichen Faustformel (0,5 Bruttomonatsgehälter je Jahr). Keine
  amtlichen Werte – die tatsächliche Höhe hängt vom Einzelfall ab.
- **A9.2 Kleinbetrieb (<10):** verschiebt das Band um 0,25 nach unten
  (KSchG greift i. d. R. nicht → schwächere Position). Vereinfachung.
- **A9.3 § 10 KSchG:** Kappung des oberen Bandendes auf 15 Monatsgehälter
  (ab 50/15 J.) bzw. 18 (ab 55/20 J.). Gilt genau genommen nur für die
  **gerichtliche Auflösung**, wird hier als Orientierungs-Obergrenze auch
  auf die freie Verhandlung angewandt und als solche gekennzeichnet.
- **A9.4 § 1a KSchG korrekt eingeordnet:** Der Faktor 0,5 ist die
  Regelabfindung nur bei betriebsbedingter Kündigung mit Abfindungsangebot
  und Klageverzicht – **nicht** ein allgemeines gesetzliches Minimum (anders
  als bei Wettbewerber 2 dargestellt).
- **A9.5 Verwendung:** Der Mittelwert der Bandbreite kann per Button die
  Abfindungs-Eingabe vorbefüllen. Die gewählte Verhandlungsstärke selbst
  bleibt transienter UI-Zustand des Schätzers; ihr **Startwert** wird aber
  aus dem persistierten Kündigungsgrund abgeleitet (A9.6).
- **A9.6 Kündigungsgrund (`KuendigungsArt`) als persistierte Eingabe:** Der
  Grund der Kündigung (unbekannt · betriebsbedingt · verhaltensbedingt ·
  personenbedingt) wird im Wizard erfasst und in der Drift/SQLite-Datenbank
  mitgespeichert. Er schlägt eine sinnvolle Start-Verhandlungsstärke vor
  (`suggestedStrength`: betriebs-/personenbedingt → standard, verhaltens­-
  bedingt → schwach). Die Zuordnung ist eine Heuristik, kein Rechtsurteil –
  bei verhaltensbedingter Kündigung *kann* die Position dennoch stark sein
  (z. B. bei formell fehlerhafter Abmahnung); der Nutzer kann die Stärke
  jederzeit übersteuern. Das neue Feld erforderte eine **Schema-Migration
  v1 → v2** (`app_database.dart`): `onUpgrade` fügt die Spalte
  `kuendigungs_art` mit Default 0 (= `unbekannt`) hinzu, sodass bereits
  gespeicherte Profile ohne Datenverlust weiterlaufen. Ein
  `persistence_test`-Fall spielt den Downgrade → Upgrade durch und sichert
  Datenerhalt und Default zu.
- **A9.7 Bandbreite auch im PDF-Dossier:** Die Verhandlungs-Bandbreite
  erscheint zusätzlich im „Entscheidungs-Dossier" (PDF) als eigener
  Abschnitt (Spanne · Orientierungswert · Regelabfindung · Grundlage). Da
  das Dossier aus den **persistierten** Angaben erzeugt wird und die
  Verhandlungsstärke selbst transient ist (A9.5), verwendet das PDF die aus
  dem gespeicherten Kündigungsgrund abgeleitete `suggestedStrength` und
  `smallBusiness = false`. Die Ableitung (Betriebszugehörigkeit, Alter,
  Bandbreite) liegt als gemeinsamer Helper `WizardData.estimateSeveranceRange`
  vor, den Bildschirm-Schätzer und PDF teilen – eine einzige Quelle der
  Wahrheit. Der Abschnitt ist ausdrücklich als „Orientierung, kein
  Rechtsanspruch" überschrieben.

## A8 – Ratgeber & Fristen (Content, RDG/StBerG-Leitlinie)

Die App enthält neben dem Rechner einen Ratgeber-Bereich und eine
Fristen-Timeline. Rechtssicherheits-Leitlinie (RDG/StBerG), damit dies
**allgemeine Rechtsinformation** bleibt und keine unerlaubte
Rechts-/Steuerberatung im Einzelfall wird:

- **A8.1 Allgemein statt fallbezogen:** Ratgeber-Artikel sind abstrakt
  formuliert und reagieren **nicht** mit einer rechtlichen
  Handlungsempfehlung auf die konkreten Nutzereingaben. Jeder Artikel
  trägt seine Rechtsgrundlagen (§) und ein Stand-Datum
  (`contentReviewedOn`) – auditierbar wie die Parameterdatei.
- **A8.2 Keine Empfehlungssprache:** durchgehend Info-/„du"-Form, nie
  „du solltest …". Engine-Flags und Timeline weisen auf Risiken/Fristen
  hin („lass prüfen"), fällen aber kein rechtliches Urteil.
- **A8.3 Timeline = Fakten:** Die Fristen-Timeline (§ 4 KSchG, § 38/§ 141
  SGB III, KV, § 109 GewO) rechnet nur gesetzliche Fristen aus den
  eingegebenen Daten aus; sie ist bewusst als Orientierung markiert und
  verweist auf Agentur für Arbeit/Anwalt. Eingabe `noticeDate` (Zugang
  der Kündigung) steuert die § 4-KSchG-Frist; die Bestimmung des exakten
  Zugangs bleibt dem Nutzer überlassen.
- **A8.4 Keine generierten Rechtsdokumente:** Ein Zahlen-Dossier (PDF,
  später) ist zulässig; das Erstellen individueller Schriftsätze
  (Klage, Gegenentwurf Aufhebungsvertrag) wird bewusst **nicht**
  angeboten (wäre grenzwertig zur Rechtsdienstleistung).
- **A8.5 Pflege:** Recht ändert sich – der Content ist versioniert
  (`contentReviewedOn`) und muss wie die Jahresparameter regelmäßig
  geprüft werden (Spec §9 Nr. 4). Ein Test (`content_test.dart`)
  erzwingt Quellenangaben und Stand-Datum je Artikel.

## A10 – „Passende Hilfe"-Panel (bewusst nicht-kommerziell)

Marktrecherche: die Wettbewerber monetarisieren genau diesen Moment über
Affiliate-Links, Werbeplätze oder Anwalts-Lead-Generierung. ExitKompass
setzt das **absichtlich anders** um (Privacy-USP, Einmalkauf-Modell, Spec §8):

- **A10.1 Kein Tracking, keine Vermittlung, keine Werbung:** Das Panel
  (`content/help_resources.dart`, `widgets/help_panel.dart`) nennt nur
  **neutrale/amtliche** Anlaufstellen (Rechtsanwaltskammer, Amtsgericht,
  Agentur für Arbeit, Krankenkasse, Betriebsrat/Gewerkschaft). Es enthält
  keine Partner-Links, keine `http`-URLs, kein Lead-Formular. Ein Test
  (`help_resources_test.dart`) schlägt fehl, sobald ein Eintrag „http"
  enthält.
- **A10.2 Allgemein statt fallbezogen (RDG/StBerG, wie A8):** Die Texte sind
  abstrakte Rechtsinformation. Die Kontext-Sensitivität beschränkt sich auf
  die **Reihenfolge/Hervorhebung**: Einträge, deren `highlightFlags` zu den
  aktuellen M5-`RiskFlag`-Codes passen (z. B. `kv_luecke` →
  Krankenversicherung, Sperrzeit-/ALG-Flags → Agentur für Arbeit), rücken
  nach oben und bekommen ein dezentes Pin-Symbol. `rankedHelpResources`
  entfernt oder ergänzt nie Einträge – Hilfe ist immer vollständig sichtbar.
- **A10.3 Auditierbar:** Wie der Ratgeber trägt das Panel ein Stand-Datum
  (`helpResourcesReviewedOn`) und je Eintrag optional Rechtsgrundlagen (§).
  Der Detail-Screen zeigt den Disclaimer-Footer und den ausdrücklichen
  Hinweis „ExitKompass verdient nichts an diesen Hinweisen".
- **A10.4 Auch im PDF-Dossier:** Der `_helpSection`-Block im
  `buildDossierPdf` listet dieselben Anlaufstellen kompakt (Titel + „Wo
  hinwenden") in derselben `rankedHelpResources`-Reihenfolge, sodass das
  teilbare Entscheidungs-Dossier ohne die App auskommt. Auch dort keine
  Links/Werbung, Stand-Datum und der „verdient nichts"-Hinweis inklusive.
- **A10.5 Auch im Info-only-Pfad:** Wer im Onboarding „Nur informieren – zum
  Ratgeber" wählt, durchläuft nie den Rechner und sähe das Panel sonst nicht.
  Deshalb blendet die standalone `RatgeberScreen` es ein
  (`RatgeberTab(showHelpPanel: true)`, ohne Flags → neutrale Reihenfolge). Im
  Post-Wizard-`HomeShell` bleibt der Ratgeber-Tab bewusst ohne Panel (es lebt
  dort im Vergleichs-Tab), um Doppelung zu vermeiden – ein Widget-Test sichert
  beide Fälle.

## A11 – M7 Liquiditäts-/Brückenplaner

Neues Engine-Modul + „Liquidität"-Tab: „Reicht mein Geld bis zum neuen Job?".

- **A11.1 Reine Cashflow-Projektion:** `computeRunway` addiert Monat für Monat
  den Netto-Cashflow des gewählten Szenarios (M5) und zieht die monatlichen
  Ausgaben ab, ausgehend von den Rücklagen. **Keine** Zinsen, keine Inflation,
  keine unregelmäßigen Einmalkosten – bewusste Vereinfachung, als solche in
  der UI gekennzeichnet („Schätzung, keine Finanzberatung").
- **A11.2 Monatsraster wie M5:** Der Planer erbt das Monats-Offset-Raster des
  Aggregators (A7.1); der „Deckungslücke ab"-Monat wird über
  `referenceDate + firstNegativeMonth` grob in einen Kalendermonat übersetzt.
- **A11.3 Zwei neue persistierte Eingaben:** `monthlyExpensesEuro` (Default
  2.500) und `savingsEuro` (Default 10.000) werden im Wizard-State gespeichert.
  Das erforderte eine **Schema-Migration v2 → v3** (`app_database.dart`):
  `onUpgrade` fügt die Spalten `monthly_expenses_euro` und `savings_euro` mit
  ihren Defaults hinzu; bestehende Profile laufen ohne Datenverlust weiter.
  `persistence_test` prüft Migration von v1 (alle Spalten neu) **und** v2 → v3.
- **A11.4 Szenario-Wahl:** Der Runway hängt am Einkommensstrom eines Szenarios;
  der Tab lässt es wählen (Default = bestes Szenario). Die Auswahl ist
  transienter UI-Zustand (nicht persistiert).

## A12 – M8 Abfindungs-Auszahlungs-Timing

Neues Engine-Modul + Wizard-Card „Auszahlung timen": vergleicht das Netto der
Abfindung bei Auszahlung dieses vs. nächstes Jahr.

- **A12.1 Effektive Steuer = günstigere Methode:** Je Jahr wird die auf die
  Abfindung entfallende Steuer als **Minimum** aus Regelbesteuerung und
  Fünftelregelung angesetzt (die Veranlagung wendet § 34 nur an, wenn er
  günstiger ist). Netto = Abfindung − effektive Steuer.
- **A12.2 Nur die zwei zvE als Eingabe:** Der Vergleich braucht das übrige zu
  versteuernde Einkommen **ohne** Abfindung je Jahr. Diese beiden Werte sind
  **transienter** UI-Zustand (nicht persistiert); die Card füllt „dieses Jahr"
  mit `Bruttomonat × 12` vor und „nächstes Jahr" mit 0 (Annahme:
  einkommensschwaches Jahr). Der Nutzer kann beide anpassen.
- **A12.3 Vereinfachung:** Kein voller Jahresabschluss beider Jahre (keine
  weiteren Einkünfte, Werbungskosten, Progressionsvorbehalt des ALG etc.).
  Reine Orientierung, ausdrücklich „keine Steuerberatung". Die tatsächliche
  Gestaltung (z. B. Auszahlung Januar statt Dezember) hängt vom Einzelfall ab.

## A13 – Zeugnis-Decoder (Content)

Werkzeug im Ratgeber: übersetzt die Code-Sprache von Arbeitszeugnissen in
Klartext/Schulnoten.

- **A13.1 Konventionen, kein Gesetz:** Die Noten-Skala („…zu unserer …
  Zufriedenheit") und die Geheimcodes sind **etablierte Rechtsprechungs-/
  Formulierungskonventionen**, kein Gesetzestext. § 109 GewO (Anspruch auf ein
  wahres und wohlwollendes qualifiziertes Zeugnis) wird als Rechtsgrundlage
  genannt. Wie bei A8 nur **allgemeine Information**, keine Bewertung des
  konkreten Zeugnisses; Grenzfälle → Fachanwalt.
- **A13.2 Auditierbar:** Stand-Datum `zeugnisReviewedOn`; ein Content-Test
  erzwingt Text/Bedeutung je Eintrag, Noten im Bereich 1–6 und die
  Vollständigkeit der sechs Leistungsstufen.

## A14 – Bewerbungstraining (Content, bewusst lokal)

Werkzeug im Ratgeber: strukturierte Interview-Vorbereitung (Klassiker,
Kündigung/Lücke erklären, Gehaltsverhandlung) mit STAR-Methode.

- **A14.1 On-device statt Cloud-KI:** Aus der Marktrecherche stünde ein
  KI-Mock-Interview zur Wahl; das bräuchte aber die **Cloud** und würde das
  „alles bleibt auf dem Gerät"-Versprechen (Spec §8) brechen. Deshalb bewusst
  die **lokale, statische** Variante: kuratierter Fragen-Katalog mit
  Antwort-Gerüsten und Tipps. Ein optionaler Opt-in-KI-Coach bleibt als
  spätere, ausdrücklich einzuwilligende Ausbaustufe offen (nicht Teil dieser
  Umsetzung).
- **A14.2 Allgemein, keine Einzelfallberatung:** Allgemeine Tipps, keine
  individuelle Bewerbungs-/Karriereberatung. Stand-Datum
  `bewerbungReviewedOn`; ein Content-Test sichert Frage + Antwort-Gerüst je
  Eintrag und dass jede Kategorie belegt ist.
- **A14.3 „Value Selling"-Erweiterung:** Der Kern eines eigenen Buch-Entwurfs
  („Job Interviews as a Sales Pitch") wurde als **deutscher, strukturierter**
  Inhalt eingearbeitet (nicht der Rohtext übernommen): eine
  „Grundhaltung"-Sektion mit Value-Selling-Prinzipien (`valueSellingPrinciples`)
  sowie zwei neue Fragen-Kategorien „Kritische & Fangfragen" und „Fragen, die
  DU stellst" (die Macht der richtigen Fragen). Kernidee: sich über den
  **Nutzen** verkaufen, Arbeits*markt* auf Augenhöhe, mit guten Rückfragen das
  Gespräch führen.
- **A14.4 Brainteaser & Case-Fragen:** Zusätzlich ein kurzer Leitfaden
  (`brainteaserIntro` + `brainteaserSteps`): Rückfragen stellen, laut denken,
  Schritt für Schritt erklären – der Weg zählt mehr als die Zahl.

## A15 – M9 Karenzentschädigung (§§ 74 ff. HGB)

Neues Engine-Modul + Ratgeber-Rechner für die Entschädigung eines
nachvertraglichen Wettbewerbsverbots.

- **A15.1 Gesetzliche Eckwerte:** Mindestens 50 % der zuletzt bezogenen
  vertragsmäßigen Leistungen je Verbotsjahr (§ 74 Abs. 2); Höchstdauer zwei
  Jahre (§ 74a Abs. 1); Anrechnung anderweitigen Erwerbs, soweit
  Entschädigung + Erwerb die letzten Bezüge um mehr als 1/10 (110 %) bzw.
  bei erzwungenem Umzug um mehr als 1/4 (125 %) übersteigen (§ 74c).
- **A15.2 „Bezüge" vereinfacht:** Als Bemessungsgröße dient eine einzige
  Monats-Eingabe „letzte Bezüge". Die genaue Zusammensetzung der
  „vertragsmäßigen Leistungen" (Grundgehalt + regelmäßige variable Anteile,
  Sachbezüge wie Dienstwagen, Durchschnittsbildung bei schwankenden Bezügen)
  bleibt dem Nutzer/der Beratung überlassen.
- **A15.3 Anrechnung als Monatsgröße:** Der § 74c-Vergleich rechnet je Monat
  (Entschädigung, Neuverdienst, Schwelle). „Böswillig unterlassener" Erwerb
  und die steuer-/sv-rechtliche Behandlung der Entschädigung sind nicht
  abgebildet. Orientierung, ausdrücklich „keine Rechtsberatung".

## A16 – M10 Resturlaubs-Abgeltung (§ 7 Abs. 4 BUrlG)

Neues Engine-Modul + Ratgeber-Rechner.

- **A16.1 Tageswert-Formel:** `Monatsbrutto × 3 / (13 × Arbeitstage/Woche)`.
  Das entspricht dem 13-Wochen-Durchschnitt des § 11 BUrlG **bei konstantem
  Monatsgehalt**; schwankende/variable Bezüge (Provisionen, Zuschläge) sind
  nicht gemittelt und müssten separat berücksichtigt werden.
- **A16.2 Anteiliger Anspruch (§ 5 BUrlG):** `Vollurlaub × Monate / 12`,
  Bruchteile ab einem halben Tag aufgerundet (§ 5 Abs. 2). Die Unterscheidung
  Voll-/Teilurlaub (Wartezeit § 4, erste Jahreshälfte etc.) ist bewusst nicht
  abgebildet – reine Anteilsrechnung als Orientierung.
- **A16.3 Nur brutto:** Die Abgeltung ist steuer- und sozialabgabenpflichtig;
  der Rechner weist den **Bruttowert** aus. Der gesetzliche Mindesturlaub
  (20 Tage bei 5-Tage-Woche, § 3 BUrlG) wird als Hinweis genannt.

## A6 – Sprach- und Historien-Migration (2026-07-05)

Die Engine wurde ursprünglich mit deutschen Bezeichnern, Kommentaren und
Commit-Messages gebaut (CLAUDE.md lag nicht vor). Nach Nachreichen der
CLAUDE.md wurde gemäß deren Regel („Code, Kommentare, Commit-Messages:
Englisch" + Conventional Commits) migriert:

- Alle Identifier und Kommentare auf Englisch; **deutsche Rechtsbegriffe
  ohne präzise Übersetzung bleiben als Fachbegriffe erhalten**
  (`vorsorgepauschale`, `Bundesland`, „Fünftelregelung" in Doku).
- Die Commit-Historie wurde als englische Conventional Commits neu
  aufgebaut (Force-Push auf den Draft-PR); die 93 Tests sichern die
  Verhaltensgleichheit (Golden-Pins unverändert).
- JSON-Parameterschlüssel bleiben deutsch (A1.7).

_(wird fortlaufend gepflegt)_
