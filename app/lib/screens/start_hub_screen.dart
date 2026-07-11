import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../coach/coach_engine.dart';
import '../pdf/dossier.dart';
import '../state/intake.dart';
import '../state/navigation.dart';
import '../state/wizard.dart';
import '../timeline/timeline.dart';
import '../util/format.dart';
import 'bewerbung_screen.dart';
import 'coach_screen.dart';
import 'intake_screen.dart';
import 'quick_estimate_screen.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';
import 'unterlagen_screen.dart';

/// The app's landing screen: every feature at a glance, grouped by intent,
/// with the KI-Coach as the flagship. Tiles either switch the shell's tab
/// (via [rootTabProvider]) or push a feature screen.
class StartHubScreen extends ConsumerWidget {
  const StartHubScreen({super.key});

  void _goTab(WidgetRef ref, int tab) =>
      ref.read(rootTabProvider.notifier).state = tab;

  Future<void> _sharePdf(WidgetRef ref) async {
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
    final theme = Theme.of(context);
    final data = ref.watch(wizardProvider);

    final intake = ref.watch(intakeProvider);
    final intakeDone = intake.done;
    final goal = intake.goal;

    void push(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ExitKompass'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => push(const SettingsScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (intakeDone)
            _SituationStrip(
              data: data,
              goal: goal,
              onTap: () => _goTab(ref, RootTab.finanzen),
            )
          else
            _IntakeCta(onTap: () => push(const IntakeScreen())),
          const SizedBox(height: 16),
          _CoachHero(
            onOpen: () => _goTab(ref, RootTab.coach),
            onInterview: () => push(const CoachScreen()),
            onNegotiation: () =>
                push(const CoachScreen(initialMode: CoachMode.negotiation)),
          ),
          const _SectionHeader('Deine Zahlen', 'Netto, Abfindung, Fristen'),
          _FeatureTile(
            icon: Icons.bolt_outlined,
            title: 'Schnell-Check',
            subtitle: 'Abfindung in 30 Sekunden schätzen',
            onTap: () => push(const QuickEstimateScreen()),
          ),
          _FeatureTile(
            icon: Icons.insights_outlined,
            title: 'Szenario-Rechner',
            subtitle: 'Bleiben · Aufhebung · Kündigung im Netto-Vergleich',
            onTap: () => _goTab(ref, RootTab.finanzen),
          ),
          _FeatureTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Liquidität & Fristen',
            subtitle: 'Wie lange reicht das Geld? Wichtige Termine',
            onTap: () => _goTab(ref, RootTab.finanzen),
          ),
          _FeatureTile(
            icon: Icons.calculate_outlined,
            title: 'Weitere Rechner',
            subtitle: 'Resturlaub · Karenzentschädigung · Zeugnis-Decoder',
            onTap: () => push(const ToolsScreen()),
          ),
          const _SectionHeader('Bewerbung', 'Der Weg nach vorn'),
          _FeatureTile(
            icon: Icons.description_outlined,
            title: 'Unterlagen-Check',
            subtitle: 'Lebenslauf hochladen und mit der Stelle abgleichen',
            badge: 'KI',
            onTap: () => push(const UnterlagenScreen()),
          ),
          _FeatureTile(
            icon: Icons.school_outlined,
            title: 'Bewerbungstraining',
            subtitle: 'STAR-Methode, Fragenkatalog, Workbook',
            onTap: () => push(const BewerbungScreen()),
          ),
          const _SectionHeader('Wissen & Hilfe', 'Verstehen & exportieren'),
          _FeatureTile(
            icon: Icons.menu_book_outlined,
            title: 'Ratgeber & passende Hilfe',
            subtitle: 'Rechte, Verhandlung, Anlaufstellen',
            onTap: () => _goTab(ref, RootTab.ratgeber),
          ),
          _FeatureTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF-Dossier teilen',
            subtitle: 'Alle Zahlen und Fristen als PDF',
            onTap: () => _sharePdf(ref),
          ),
          const SizedBox(height: 8),
          Text(
            'Alle Ergebnisse sind Schätzwerte, keine Steuer- oder '
            'Rechtsberatung.',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SituationStrip extends StatelessWidget {
  const _SituationStrip({
    required this.data,
    required this.goal,
    required this.onTap,
  });
  final WizardData data;
  final StartGoal? goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasOffer = data.severanceGrossEuro > 0;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deine Situation',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(data.situation.label, style: theme.textTheme.titleSmall),
                    Text(
                      [
                        if (goal != null) goal!.short,
                        if (hasOffer)
                          'Angebot ${euroFromCents(data.severanceGrossEuro * 100, withDecimals: false)}',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntakeCta extends StatelessWidget {
  const _IntakeCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Icon(Icons.waving_hand_outlined,
                  size: 22, color: cs.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Erzähl uns kurz von deiner Situation',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: cs.onPrimaryContainer)),
                    Text('3 kurze Fragen – dann zeigen wir dir das Passende.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer.withValues(alpha: 0.9))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachHero extends StatelessWidget {
  const _CoachHero({
    required this.onOpen,
    required this.onInterview,
    required this.onNegotiation,
  });
  final VoidCallback onOpen;
  final VoidCallback onInterview;
  final VoidCallback onNegotiation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      color: cs.primary,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: cs.onPrimary),
                  const SizedBox(width: 8),
                  Text('KI-COACH · PREMIUM',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                ],
              ),
              const SizedBox(height: 10),
              Text('Gespräche üben mit KI',
                  style: theme.textTheme.titleLarge?.copyWith(color: cs.onPrimary)),
              const SizedBox(height: 4),
              Text(
                'Realistisch trainieren – die KI antwortet wie ein echter '
                'Gesprächspartner.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onPrimary.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onInterview,
                      icon: const Icon(Icons.record_voice_over_outlined, size: 18),
                      label: const Text('Bewerbung'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onNegotiation,
                      icon: const Icon(Icons.handshake_outlined, size: 18),
                      label: const Text('Verhandlung'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onTertiaryContainer,
                        fontWeight: FontWeight.w800)),
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
