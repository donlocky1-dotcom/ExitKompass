import 'package:flutter/material.dart';

import 'quick_estimate_screen.dart';
import 'ratgeber_screen.dart';
import 'wizard_screen.dart';

/// Onboarding with the mandatory disclaimer acceptance (spec §4 screen 0,
/// §9): the user must actively agree before entering the wizard.
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
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              const Spacer(),
              Icon(Icons.explore_outlined, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('ExitKompass', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Kündigung oder Aufhebungsvertrag auf dem Tisch? Rechne alle '
                'Szenarien netto durch – 100 % lokal auf deinem Gerät.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              const _Bullet(
                icon: Icons.lock_outline,
                text: 'Kein Konto, keine Cloud – deine Daten bleiben auf dem Gerät.',
              ),
              const _Bullet(
                icon: Icons.compare_arrows,
                text: 'Vier Handlungsoptionen im direkten Netto-Vergleich.',
              ),
              const _Bullet(
                icon: Icons.calculate_outlined,
                text: 'Fünftelregelung, Sperrzeit, Ruhen und ALG 1 in einem Rechner.',
              ),
              const Spacer(),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _accepted,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Ich verstehe: Alle Ergebnisse sind Schätzwerte und keine Steuer- '
                  'oder Rechtsberatung.',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _accepted
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const QuickEstimateScreen()),
                        )
                    : null,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text('Abfindung schätzen'),
              ),
              TextButton(
                onPressed: _accepted
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const WizardScreen()),
                        )
                    : null,
                child: const Text('Direkt zum Netto-Szenario-Vergleich'),
              ),
              TextButton(
                onPressed: _accepted
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const RatgeberScreen()),
                        )
                    : null,
                child: const Text('Nur informieren – zum Ratgeber'),
              ),
              const SizedBox(height: 8),
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

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
