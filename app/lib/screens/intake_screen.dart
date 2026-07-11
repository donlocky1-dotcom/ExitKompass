import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/intake.dart';
import '../state/wizard.dart';
import 'root_shell.dart';

/// A short guided intake shown once after the disclaimer: why the person is
/// here, what they want, and a few key figures. This replaces landing on the
/// hub with example defaults – the situation is now the user's own. Everything
/// can be refined later in Finanzen → "Eingaben bearbeiten".
class IntakeScreen extends ConsumerStatefulWidget {
  const IntakeScreen({super.key});

  @override
  ConsumerState<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends ConsumerState<IntakeScreen> {
  int _step = 0;
  Situation? _situation;
  StartGoal? _goal;
  bool _hasOffer = false;

  late final TextEditingController _gross;
  late final TextEditingController _tenure;
  final TextEditingController _offer = TextEditingController();

  @override
  void initState() {
    super.initState();
    final data = ref.read(wizardProvider);
    _gross = TextEditingController(text: data.grossMonthEuro.toString());
    _tenure = TextEditingController(text: data.tenureYears.toString());
  }

  @override
  void dispose() {
    _gross.dispose();
    _tenure.dispose();
    _offer.dispose();
    super.dispose();
  }

  void _next() => setState(() => _step++);

  void _finish() {
    final now = DateTime.now();
    final gross = int.tryParse(_gross.text.trim());
    final tenure = int.tryParse(_tenure.text.trim());
    final offer = int.tryParse(_offer.text.trim()) ?? 0;

    ref.read(wizardProvider.notifier).update((d) => d.copyWith(
          situation: _situation ?? d.situation,
          grossMonthEuro: gross ?? d.grossMonthEuro,
          entryDate: tenure != null
              ? DateTime(now.year - tenure, now.month, 1)
              : d.entryDate,
          severanceGrossEuro: _hasOffer ? offer : 0,
        ));
    ref.read(intakeProvider.notifier).complete(goal: _goal);
    _toShell();
  }

  void _skip() => _toShell();

  void _toShell() => Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const RootShell()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
        title: Text('Schritt ${_step + 1} von 3'),
        actions: [
          TextButton(onPressed: _skip, child: const Text('Überspringen')),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / 3),
        ),
      ),
      body: switch (_step) {
        0 => _StepWhy(
            selected: _situation,
            onSelect: (s) {
              setState(() => _situation = s);
              _next();
            },
          ),
        1 => _StepGoal(
            selected: _goal,
            onSelect: (g) {
              setState(() => _goal = g);
              _next();
            },
          ),
        _ => _StepData(
            gross: _gross,
            tenure: _tenure,
            offer: _offer,
            hasOffer: _hasOffer,
            onOfferChanged: (v) => setState(() => _hasOffer = v),
            onFinish: _finish,
          ),
      },
    );
  }
}

class _StepWhy extends StatelessWidget {
  const _StepWhy({required this.selected, required this.onSelect});
  final Situation? selected;
  final ValueChanged<Situation> onSelect;

  static const _icons = {
    Situation.kuendigungErhalten: Icons.mail_outline,
    Situation.aufhebungAngeboten: Icons.description_outlined,
    Situation.ueberlegeZuKuendigen: Icons.logout,
    Situation.nurInfo: Icons.lightbulb_outline,
  };

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Warum bist du hier?',
      subtitle: 'Damit wir dir das Passende zeigen.',
      children: [
        for (final s in Situation.values)
          _ChoiceCard(
            icon: _icons[s]!,
            label: s.label,
            selected: s == selected,
            onTap: () => onSelect(s),
          ),
      ],
    );
  }
}

class _StepGoal extends StatelessWidget {
  const _StepGoal({required this.selected, required this.onSelect});
  final StartGoal? selected;
  final ValueChanged<StartGoal> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Was möchtest du erreichen?',
      subtitle: 'Du kannst später alles nutzen – das hilft nur beim Einstieg.',
      children: [
        for (final g in StartGoal.values)
          _ChoiceCard(
            icon: g.icon,
            label: g.label,
            selected: g == selected,
            onTap: () => onSelect(g),
          ),
      ],
    );
  }
}

class _StepData extends StatelessWidget {
  const _StepData({
    required this.gross,
    required this.tenure,
    required this.offer,
    required this.hasOffer,
    required this.onOfferChanged,
    required this.onFinish,
  });
  final TextEditingController gross;
  final TextEditingController tenure;
  final TextEditingController offer;
  final bool hasOffer;
  final ValueChanged<bool> onOfferChanged;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StepScaffold(
      title: 'Deine Eckdaten',
      subtitle: 'Nur das Wichtigste – Details kannst du später ergänzen.',
      children: [
        TextField(
          controller: gross,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Bruttomonatsgehalt (€)',
            prefixIcon: Icon(Icons.euro),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: tenure,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Betriebszugehörigkeit (Jahre)',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: hasOffer,
          onChanged: onOfferChanged,
          title: const Text('Es liegt ein Abfindungsangebot vor'),
        ),
        if (hasOffer)
          TextField(
            controller: offer,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Angebotene Abfindung brutto (€)',
              prefixIcon: Icon(Icons.euro),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onFinish,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Fertig – zur Übersicht'),
        ),
        const SizedBox(height: 8),
        Text(
          'Alle Ergebnisse sind Schätzwerte, keine Steuer- oder Rechtsberatung.',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      color: selected ? cs.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(label),
        trailing: Icon(selected ? Icons.check_circle : Icons.chevron_right,
            color: selected ? cs.primary : cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
