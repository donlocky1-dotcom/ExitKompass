import 'package:flutter/material.dart';

import '../widgets/ui_kit.dart';
import 'intake_screen.dart';

/// Onboarding with the mandatory disclaimer acceptance (spec §4 screen 0, §9):
/// the user must actively agree before entering. Styled to match the app's
/// calm, iOS-flavoured look.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = abfindungAccent(context);
    return Scaffold(
      backgroundColor: groupedBackground(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(flex: 2),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.explore_outlined,
                            size: 34, color: theme.colorScheme.onPrimary),
                      ),
                      const SizedBox(height: 18),
                      Text('ExitKompass',
                          style: theme.textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1)),
                      const SizedBox(height: 8),
                      Text(
                        'Kündigung oder Aufhebungsvertrag auf dem Tisch? Rechne '
                        'alle Szenarien netto durch – 100 % lokal auf deinem Gerät.',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 26),
                      AppGroup(children: [
                        _InfoRow(
                          accent: accent,
                          icon: Icons.lock_outline,
                          text: 'Kein Konto, keine Cloud – deine Daten bleiben '
                              'auf dem Gerät.',
                        ),
                        _InfoRow(
                          accent: accent,
                          icon: Icons.compare_arrows,
                          text: 'Vier Handlungsoptionen im direkten '
                              'Netto-Vergleich.',
                        ),
                        _InfoRow(
                          accent: accent,
                          icon: Icons.calculate_outlined,
                          text: 'Fünftelregelung, Sperrzeit, Ruhen und ALG 1 in '
                              'einem Rechner.',
                        ),
                      ]),
                      const Spacer(flex: 3),
                      Material(
                        color: groupedCard(context),
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => setState(() => _accepted = !_accepted),
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(8, 6, 14, 6),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _accepted,
                                  onChanged: (v) =>
                                      setState(() => _accepted = v ?? false),
                                ),
                                Expanded(
                                  child: Text(
                                    'Ich verstehe: Alle Ergebnisse sind '
                                    'Schätzwerte und keine Steuer- oder '
                                    'Rechtsberatung.',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _accepted
                            ? () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                      builder: (_) => const IntakeScreen()),
                                )
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Loslegen'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.accent, required this.icon, required this.text});
  final Color accent;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 13),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
