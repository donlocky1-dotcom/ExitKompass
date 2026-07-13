import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../pdf/dossier.dart';
import '../state/wizard.dart';
import '../timeline/timeline.dart';
import '../widgets/ui_kit.dart';
import 'comparison_tab.dart';
import 'liquidity_tab.dart';
import 'timeline_screen.dart';
import 'wizard_screen.dart';

/// The financial area: the scenario comparison, the liquidity runway and the
/// deadlines, with quick access to edit the inputs (wizard) and to export the
/// PDF dossier. Reuses the existing body-only tab widgets.
class FinanzenScreen extends ConsumerStatefulWidget {
  const FinanzenScreen({super.key});

  @override
  ConsumerState<FinanzenScreen> createState() => _FinanzenScreenState();
}

class _FinanzenScreenState extends ConsumerState<FinanzenScreen> {
  int _sub = 0;

  static const _views = [ComparisonTab(), LiquidityTab(), TimelineTab()];

  Future<void> _sharePdf() async {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: groupedBackground(context),
      appBar: AppBar(
        title: const Text('Finanzen'),
        backgroundColor: groupedBackground(context),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Eingaben bearbeiten',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const WizardScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Als PDF-Dossier teilen',
            onPressed: _sharePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Vergleich')),
                  ButtonSegment(value: 1, label: Text('Liquidität')),
                  ButtonSegment(value: 2, label: Text('Fristen')),
                ],
                selected: {_sub},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _sub = s.first),
              ),
            ),
          ),
          Expanded(child: IndexedStack(index: _sub, children: _views)),
        ],
      ),
    );
  }
}
