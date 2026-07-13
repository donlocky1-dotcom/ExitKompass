import 'package:flutter/material.dart';

import '../widgets/ui_kit.dart';
import 'non_compete_screen.dart';
import 'vacation_screen.dart';
import 'zeugnis_decoder_screen.dart';

/// A small hub for the additional calculators that don't need a top-level tab.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = abfindungAccent(context);
    void push(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    return GroupedPage(
      title: 'Weitere Rechner',
      children: [
        const SectionLabel('Was oft übersehen wird', topPad: 8),
        AppGroup(children: [
          AppRow(
            accent: accent,
            icon: Icons.beach_access_outlined,
            title: 'Resturlaub-Abgeltung',
            subtitle: 'Offene Urlaubstage in Euro (§ 7 IV BUrlG)',
            onTap: () => push(const VacationScreen()),
          ),
          AppRow(
            accent: accent,
            icon: Icons.gavel_outlined,
            title: 'Karenzentschädigung',
            subtitle: 'Wettbewerbsverbot nach dem Job (§§ 74 ff. HGB)',
            onTap: () => push(const NonCompeteScreen()),
          ),
          AppRow(
            accent: accent,
            icon: Icons.translate_outlined,
            title: 'Zeugnis-Decoder',
            subtitle: 'Zeugnissprache in Schulnoten übersetzen',
            onTap: () => push(const ZeugnisDecoderScreen()),
          ),
        ]),
      ],
    );
  }
}
