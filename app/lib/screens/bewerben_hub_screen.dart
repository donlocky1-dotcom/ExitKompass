import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/application_docs.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/ui_kit.dart';
import 'bewerbung_screen.dart';
import 'coach_screen.dart';
import 'unterlagen_screen.dart';
import 'zeugnis_decoder_screen.dart';

/// The applying/next-job pillar: convince — documents and the interview. Leads
/// with the Unterlagen-Check status, then the KI interview practice, the
/// training and the Zeugnis decoder.
class BewerbenScreen extends ConsumerWidget {
  const BewerbenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(applicationDocsProvider);
    final accent = bewerbenAccent(context);

    void push(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    final count = docs.profiles.length;
    final String caption;
    if (count == 0 && !docs.hasCv) {
      caption = 'Lebenslauf hochladen und mit einer Stelle abgleichen.';
    } else {
      final stellen = count == 1 ? '1 Stelle' : '$count Stellen';
      caption = docs.hasCv
          ? '$stellen · Lebenslauf geprüft'
          : '$stellen · Lebenslauf fehlt noch';
    }

    return HubScaffold(
      title: 'Bewerben',
      slivers: [
        AppHero(
          accent: accent,
          eyebrow: 'Unterlagen-Check',
          headline: 'Lebenslauf vs. Stelle',
          caption: caption,
          onTap: () => push(const UnterlagenScreen()),
        ),
        const SectionLabel('Vorbereiten'),
        AppGroup(children: [
          AppRow(
            accent: accent,
            icon: Icons.description_outlined,
            title: 'Unterlagen-Check',
            badge: 'KI',
            subtitle: 'Mehrere Stellen speichern & vergleichen',
            onTap: () => push(const UnterlagenScreen()),
          ),
          AppRow(
            accent: accent,
            icon: Icons.record_voice_over_outlined,
            title: 'Bewerbungsgespräch üben',
            badge: 'KI',
            subtitle: 'Fragen zur gewählten Stelle · Feedback am Ende',
            onTap: () => push(const CoachScreen()),
          ),
          AppRow(
            accent: accent,
            icon: Icons.school_outlined,
            title: 'Bewerbungstraining',
            subtitle: 'Klassiker, Brainteaser, dein Werteheft',
            onTap: () => push(const BewerbungScreen()),
          ),
          AppRow(
            accent: accent,
            icon: Icons.translate_outlined,
            title: 'Zeugnis-Decoder',
            badge: 'KI',
            subtitle: 'Foto hochladen – Note schätzen & prüfen, was fehlt',
            onTap: () => push(const ZeugnisDecoderScreen()),
          ),
        ]),
        const DisclaimerNote(),
      ],
    );
  }
}
