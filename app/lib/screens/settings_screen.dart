import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/application_docs.dart';
import '../state/coach_session.dart';
import '../state/intake.dart';
import '../state/wizard.dart';
import '../state/workbook.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/ui_kit.dart';

/// Settings screen (spec §4 screen 13, §9): parameter year, legal notes,
/// privacy, and local data control. Impressum and Datenschutzerklärung are
/// legally required before release; they are shown as clearly marked
/// placeholders here rather than inventing contact/entity data.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _analyticsOptIn = false;

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten löschen?'),
        content: const Text(
          'Deine gespeicherten Eingaben werden vollständig vom Gerät gelöscht. '
          'Das lässt sich nicht rückgängig machen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(wizardProvider.notifier).clearSaved();
    await ref.read(workbookProvider.notifier).clearSaved();
    ref.read(applicationDocsProvider.notifier).clear();
    ref.read(coachSessionProvider.notifier).clear();
    ref.read(intakeProvider.notifier).clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gespeicherte Daten wurden gelöscht.')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GroupedPage(
      title: 'Einstellungen',
      footer: const DisclaimerFooter(),
      children: [
        const SectionLabel('Berechnung', topPad: 8),
        const AppGroup(children: [
          ListTile(
            leading: Icon(Icons.calendar_month),
            title: Text('Parameterjahr'),
            subtitle: Text('2026 (Steuer- und Beitragswerte)'),
          ),
        ]),
        const SectionLabel('Datenschutz'),
        AppGroup(children: [
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Lokale Verarbeitung'),
            subtitle: Text(
              'Alle Eingaben bleiben auf deinem Gerät. Kein Konto, keine Cloud.',
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.insights_outlined),
            title: const Text('Anonyme Nutzungsstatistik'),
            subtitle:
                const Text('Standardmäßig aus. Hilft, die App zu verbessern.'),
            value: _analyticsOptIn,
            onChanged: (v) => setState(() => _analyticsOptIn = v),
          ),
        ]),
        const SectionLabel('Rechtliches'),
        AppGroup(children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Disclaimer'),
            subtitle: const Text(
              'Alle Ergebnisse sind Schätzungen und keine Steuer- oder '
              'Rechtsberatung.',
            ),
            onTap: () => _showTextSheet(
              context,
              'Disclaimer',
              'ExitKompass liefert überschlägige Schätzwerte auf Basis der '
                  'Steuer- und Sozialversicherungswerte 2026. Die Ergebnisse '
                  'ersetzen keine Steuerberatung (StBerG) und keine '
                  'Rechtsberatung (RDG). Für verbindliche Auskünfte wende dich '
                  'an einen Fachanwalt für Arbeitsrecht, einen Steuerberater '
                  'oder die Agentur für Arbeit.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Impressum'),
            subtitle: const Text('Vor Veröffentlichung auszufüllen'),
            onTap: () => _showTextSheet(
              context,
              'Impressum',
              'Platzhalter: Hier ist vor der Veröffentlichung das Impressum '
                  'nach § 5 DDG (Anbieterkennzeichnung) einzutragen – Name, '
                  'Anschrift, Kontakt und ggf. USt-IdNr. des Anbieters.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Datenschutzerklärung'),
            subtitle: const Text('Vor Veröffentlichung auszufüllen'),
            onTap: () => _showTextSheet(
              context,
              'Datenschutzerklärung',
              'Platzhalter: Auch bei rein lokaler Verarbeitung ist eine '
                  'Datenschutzerklärung erforderlich (u. a. für optionale '
                  'Analytics und Crash-Reports). Diese ist vor der '
                  'Veröffentlichung zu ergänzen.',
            ),
          ),
        ]),
        const SectionLabel('Daten'),
        AppGroup(children: [
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text('Gespeicherte Daten löschen',
                style: TextStyle(color: theme.colorScheme.error)),
            subtitle: const Text('Setzt die App auf die Ausgangswerte zurück.'),
            onTap: _clearData,
          ),
        ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(6, 20, 6, 0),
          child: Text('ExitKompass · Version 0.1.0',
              style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  void _showTextSheet(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
