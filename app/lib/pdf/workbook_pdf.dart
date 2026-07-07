import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../content/bewerbung.dart';

/// Builds the Bewerbungstraining workbook as a PDF.
///
/// When [empty] is true it produces a blank workbook (writing lines under each
/// question) for offline / printed preparation; otherwise it fills in the
/// user's saved [answers] (questionId → answer).
///
/// Pure function returning the PDF bytes – independent of the `printing`
/// plugin, so it is fully unit-testable. Uses an embedded full-coverage font
/// (the built-in Helvetica lacks €, „, –).
Future<Uint8List> buildWorkbookPdf({
  required Map<String, String> answers,
  required bool empty,
  required ByteData regularTtf,
  required ByteData boldTtf,
}) async {
  final base = pw.Font.ttf(regularTtf);
  final bold = pw.Font.ttf(boldTtf);
  final doc = pw.Document(
    title: 'ExitKompass – Bewerbungs-Workbook',
    theme: pw.ThemeData.withFont(base: base, bold: bold),
  );
  final dateFmt = DateFormat('dd.MM.yyyy');
  final teal = PdfColor.fromInt(0xFF00696E);

  pw.Widget writingLines(int n) => pw.Column(
        children: [
          for (var i = 0; i < n; i++)
            pw.Container(
              height: 18,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                ),
              ),
            ),
        ],
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (context) => pw.Column(children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          'Bewerbungstraining – Workbook. Allgemeine Tipps, keine individuelle '
          'Bewerbungsberatung.',
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
            pw.Text('Bewerbungs-Workbook',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold, color: teal)),
            pw.Text(empty ? 'zum Ausfüllen' : 'Erstellt am ${dateFmt.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Text(starMethodExplainer,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
        for (final category in InterviewCategory.values) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
            child: pw.Text(category.label,
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold, color: teal)),
          ),
          for (final q in interviewQuestions.where((q) => q.category == category))
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('„${q.question}"',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text('So gehst du ran: ${q.approach}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                for (final tip in q.tips)
                  pw.Bullet(text: tip, style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.Text('Deine Antwort:',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                if (empty)
                  writingLines(3)
                else
                  pw.Text(
                    (answers[q.id]?.trim().isNotEmpty ?? false)
                        ? answers[q.id]!
                        : '—',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
              ]),
            ),
        ],
      ],
    ),
  );

  return doc.save();
}
