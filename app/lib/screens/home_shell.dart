import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../pdf/dossier.dart';
import '../state/wizard.dart';
import '../timeline/timeline.dart';
import '../widgets/disclaimer_footer.dart';
import 'comparison_tab.dart';
import 'liquidity_tab.dart';
import 'ratgeber_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';

/// Post-wizard hub with three tabs: scenario comparison, personalised
/// deadlines and the Ratgeber knowledge base.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _titles = ['Szenario-Vergleich', 'Liquidität', 'Fristen', 'Ratgeber'];

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
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Als PDF-Dossier teilen',
            onPressed: _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                ComparisonTab(),
                LiquidityTab(),
                TimelineTab(),
                RatgeberTab(),
              ],
            ),
          ),
          const DisclaimerFooter(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Vergleich'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined), label: 'Liquidität'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Fristen'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Ratgeber'),
        ],
      ),
    );
  }
}
