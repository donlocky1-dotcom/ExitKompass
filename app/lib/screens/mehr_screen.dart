import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../pdf/dossier.dart';
import '../state/intake.dart';
import '../state/navigation.dart';
import '../state/wizard.dart';
import '../timeline/timeline.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/ui_kit.dart';
import 'ratgeber_screen.dart';
import 'settings_screen.dart';

/// The catch-all pillar: the knowledge base and neutral help, the PDF export
/// and the app settings — the things that don't belong to a single goal.
class MehrScreen extends ConsumerWidget {
  const MehrScreen({super.key});

  Future<void> _sharePdf(BuildContext context, WidgetRef ref) async {
    // The dossier needs the figures – guide the user to enter them first.
    if (!ref.read(intakeProvider).done) {
      ref.read(rootTabProvider.notifier).state = RootTab.abfindung;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Bitte zuerst deine Angaben eingeben – dann gibt es das PDF-Dossier.'),
      ));
      return;
    }
    final data = ref.read(wizardProvider);
    final bytes = await buildDossierPdf(
      data: data,
      result: data.compute(),
      timeline: buildTimeline(data),
      regularTtf: await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
      boldTtf: await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );
    await Printing.sharePdf(bytes: bytes, filename: 'exitkompass-dossier.pdf');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = neutralAccent(context);

    void push(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    return HubScaffold(
      title: 'Mehr',
      slivers: [
        const SectionLabel('Wissen & Hilfe', topPad: 8),
        AppGroup(children: [
          AppRow(
            accent: accent,
            icon: Icons.menu_book_outlined,
            title: 'Ratgeber',
            subtitle: 'Abfindung, ALG, Verhandeln — verständlich erklärt',
            onTap: () => push(const RatgeberScreen()),
          ),
          AppRow(
            accent: accent,
            icon: Icons.support_outlined,
            title: 'Passende Hilfe',
            subtitle: 'Neutrale Anlaufstellen, ohne Tracking',
            onTap: () => push(const RatgeberScreen()),
          ),
        ]),
        const SectionLabel('Dokument'),
        AppGroup(children: [
          AppRow(
            accent: accent,
            icon: Icons.ios_share_outlined,
            title: 'PDF-Dossier teilen',
            subtitle: 'Zahlen, Fristen & Hilfe als PDF',
            onTap: () => _sharePdf(context, ref),
          ),
          AppRow(
            accent: accent,
            icon: Icons.settings_outlined,
            title: 'Einstellungen',
            subtitle: 'Parameterjahr 2026 · Daten löschen',
            onTap: () => push(const SettingsScreen()),
          ),
        ]),
        const DisclaimerNote(),
      ],
    );
  }
}
