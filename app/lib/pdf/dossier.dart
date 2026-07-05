import 'dart:typed_data';

import 'package:exit_engine/exit_engine.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../state/wizard.dart';
import '../timeline/timeline.dart';
import '../util/format.dart';
import '../util/labels.dart';

/// Builds the "Entscheidungs-Dossier" PDF (spec §4 screen 12): inputs,
/// scenario comparison, per-scenario flags, the deadline timeline and the
/// disclaimer.
///
/// Pure function returning the PDF bytes – independent of the `printing`
/// plugin, so it is fully unit-testable.
Future<Uint8List> buildDossierPdf({
  required WizardData data,
  required AggregateResult result,
  required List<TimelineItem> timeline,
  required ByteData regularTtf,
  required ByteData boldTtf,
}) async {
  // Embed a full-coverage font (the built-in Helvetica lacks €, „, −, Δ).
  final base = pw.Font.ttf(regularTtf);
  final bold = pw.Font.ttf(boldTtf);
  final doc = pw.Document(
    title: 'ExitKompass – Entscheidungs-Dossier',
    theme: pw.ThemeData.withFont(base: base, bold: bold),
  );
  final dateFmt = DateFormat('dd.MM.yyyy');
  final teal = PdfColor.fromInt(0xFF00696E);

  const order = [
    ScenarioType.kuendigungAg,
    ScenarioType.aufhebungsvertrag,
    ScenarioType.eigenkuendigung,
    ScenarioType.bleiben,
  ];
  final best = result.bestScenario;

  pw.Widget h(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 4),
        child: pw.Text(t, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: teal)),
      );
  pw.Widget kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(children: [
          pw.SizedBox(width: 220, child: pw.Text(k, style: const pw.TextStyle(fontSize: 10))),
          pw.Expanded(child: pw.Text(v, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
        ]),
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (context) => pw.Column(children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          'Alle Werte sind Schätzungen für das Jahr 2026 und keine Steuer- oder '
          'Rechtsberatung. Im Zweifel Fachanwalt oder Steuerberater fragen.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.Text('Seite ${context.pageNumber} von ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ]),
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('ExitKompass', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: teal)),
            pw.Text('Erstellt am ${dateFmt.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Text('Entscheidungs-Dossier', style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),

        h('Deine Angaben'),
        kv('Geburtsjahr / Steuerklasse',
            '${data.birthYear} / Klasse ${taxClassLabel(data.taxClass)}'),
        kv('Kinder unter 25 / Kirche',
            '${data.childrenUnder25} / ${data.churchMember ? "ja (${bundeslandLabel(data.state)})" : "nein"}'),
        kv('Bruttomonatsgehalt', euroFromCents(data.grossMonthEuro * 100)),
        kv('Sonderzahlungen p. a.', euroFromCents(data.annualExtrasEuro * 100)),
        kv('Abfindung brutto', euroFromCents(data.severanceGrossEuro * 100)),
        kv('Austrittsdatum', dateFmt.format(data.exitDate)),
        kv('Betrachtungszeitraum', '${data.horizonMonths} Monate'),

        h('Szenario-Vergleich (kumuliertes Netto über ${result.horizonMonths} Monate)'),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell('Szenario', bold: true),
                _cell('Netto gesamt', bold: true),
                _cell('Δ zu „Bleiben"', bold: true),
              ],
            ),
            for (final t in order)
              pw.TableRow(
                decoration: t == best
                    ? const pw.BoxDecoration(color: PdfColors.teal50)
                    : null,
                children: [
                  _cell('${scenarioLabel(t)}${t == best ? "  ★" : ""}'),
                  _cell(euroFromCents(result.scenarios[t]!.cumulativeNetCents)),
                  _cell(t == ScenarioType.bleiben
                      ? '–'
                      : signedEuroFromCents(result.deltaToBaselineCents(t))),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text('★ günstigstes Szenario im Betrachtungszeitraum',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),

        h('Hinweise je Szenario'),
        for (final t in order)
          if (result.scenarios[t]!.flags.isNotEmpty)
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(scenarioLabel(t),
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              for (final f in result.scenarios[t]!.flags)
                pw.Bullet(text: f.message, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 6),
            ]),

        h('Deine Fristen'),
        for (final item in timeline)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.SizedBox(
                width: 70,
                child: pw.Text(item.date != null ? dateFmt.format(item.date!) : '—',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: item.urgency == TimelineUrgency.critical
                            ? PdfColors.red700
                            : teal)),
              ),
              pw.Expanded(
                child: pw.Text('${item.title} (${item.source})',
                    style: const pw.TextStyle(fontSize: 9)),
              ),
            ]),
          ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
