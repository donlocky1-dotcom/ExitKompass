import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coach/coach_engine.dart';
import '../coach/coach_providers.dart';
import '../content/zeugnis.dart';
import '../util/file_pick.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/ui_kit.dart';

/// Decodes the coded language of an Arbeitszeugnis. Two ways in: upload a
/// photo/PDF and let the AI estimate the overall grade and flag what is
/// missing, or look up the common phrases by hand. General information
/// (§ 109 GewO), not a legal assessment.
class ZeugnisDecoderScreen extends ConsumerStatefulWidget {
  const ZeugnisDecoderScreen({super.key});

  @override
  ConsumerState<ZeugnisDecoderScreen> createState() =>
      _ZeugnisDecoderScreenState();
}

class _ZeugnisDecoderScreenState extends ConsumerState<ZeugnisDecoderScreen> {
  static const int _maxBytes = 8 * 1024 * 1024; // 8 MB
  static const _allowedMimes = {'application/pdf', 'image/png', 'image/jpeg'};

  bool _busy = false;
  String _result = '';
  String? _error;

  CoachEngine get _engine => ref.read(coachEngineProvider);

  static String? _mimeForName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => null,
    };
  }

  Future<void> _pickAndAnalyze() async {
    setState(() => _error = null);
    final PickedFile? file;
    try {
      file = await pickCvFile();
    } catch (_) {
      setState(() => _error = 'Datei konnte nicht geöffnet werden.');
      return;
    }
    if (file == null) return; // cancelled
    if (file.bytes.isEmpty) {
      setState(() => _error = 'Datei konnte nicht gelesen werden.');
      return;
    }
    if (file.bytes.length > _maxBytes) {
      setState(() => _error = 'Die Datei ist zu groß (max. 8 MB).');
      return;
    }
    final mime =
        file.mimeType.isNotEmpty ? file.mimeType : _mimeForName(file.name);
    if (mime == null || !_allowedMimes.contains(mime)) {
      setState(() => _error = 'Bitte ein PDF oder ein Bild (PNG/JPG) wählen.');
      return;
    }

    setState(() {
      _busy = true;
      _result = '';
    });
    final reply = await _engine.analyzeZeugnis(
      CoachAttachment(bytes: file.bytes, mimeType: mime, name: file.name),
    );
    if (!mounted) return;
    setState(() {
      _result = reply;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = bewerbenAccent(context);
    return GroupedPage(
      title: 'Zeugnis-Decoder',
      footer: const DisclaimerFooter(),
      children: [
        const SectionLabel('Von der KI prüfen lassen', topPad: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 17, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Zeugnis prüfen lassen',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Lade ein Foto oder PDF deines Arbeitszeugnisses hoch – '
                'die KI schätzt die Gesamtnote aus den Formulierungen '
                'und sagt dir, ob etwas fehlt oder versteckt negativ ist.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _pickAndAnalyze,
                  icon: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: Text(_busy
                      ? 'Analysiere …'
                      : (_result.isEmpty
                          ? 'Foto / PDF hochladen'
                          : 'Anderes Zeugnis')),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: cs.error)),
              ],
              const SizedBox(height: 8),
              Text(
                _engine.isAiPowered
                    ? 'Übung, keine Rechtsberatung. Dein Zeugnis wird zur '
                        'Analyse an einen KI-Dienst (Gemini) gesendet.'
                    : 'Vorschau ohne KI – die Auswertung (Gemini) folgt im '
                        'Premium.',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (_result.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: groupedBackground(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(_result,
                      style: theme.textTheme.bodyMedium),
                ),
              ],
            ],
          ),
        ),
        for (final category in ZeugnisCategory.values) ...[
          SectionLabel(category.label),
          AppGroup(children: [
            for (final p in zeugnisPhrases.where((p) => p.category == category))
              _PhraseRow(phrase: p),
          ]),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Arbeitszeugnisse müssen wohlwollend sein (§ 109 GewO), deshalb '
            'steckt die eigentliche Bewertung oft in festen Formulierungen. '
            'Stand: $zeugnisReviewedOn. Konventionen der Arbeitsgerichtsbarkeit, '
            'kein Gesetzestext – im Zweifel ein Fachanwalt prüfen lassen.',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _PhraseRow extends StatelessWidget {
  const _PhraseRow({required this.phrase});

  final ZeugnisPhrase phrase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (phrase.grade != null) ...[
            _GradeBadge(grade: phrase.grade!),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('„${phrase.phrase}"',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text(phrase.meaning,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});

  final int grade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 1–2 good (green), 3–4 mid (amber), 5–6 poor (red).
    final Color color = grade <= 2
        ? Colors.green.shade700
        : (grade <= 4 ? Colors.amber.shade800 : theme.colorScheme.error);
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
      child: Text('$grade',
          style: theme.textTheme.titleMedium?.copyWith(
              color: color, fontWeight: FontWeight.bold)),
    );
  }
}
