import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coach/coach_engine.dart';
import '../coach/coach_providers.dart';
import '../state/application_docs.dart';
import 'coach_screen.dart';

/// Upload a CV (PDF/image) and paste the job ad; the AI compares them and
/// gives concrete tips. The same documents can then be carried into the
/// interview simulation as context. Clearly framed as practice, not advice.
class UnterlagenScreen extends ConsumerStatefulWidget {
  const UnterlagenScreen({super.key});

  @override
  ConsumerState<UnterlagenScreen> createState() => _UnterlagenScreenState();
}

class _UnterlagenScreenState extends ConsumerState<UnterlagenScreen> {
  static const int _maxBytes = 8 * 1024 * 1024; // 8 MB
  static const _allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];

  late final TextEditingController _jobAd;
  bool _extracting = false;
  bool _analyzing = false;
  String _analysis = '';
  String? _error;

  CoachEngine get _engine => ref.read(coachEngineProvider);

  @override
  void initState() {
    super.initState();
    _jobAd = TextEditingController(
      text: ref.read(applicationDocsProvider).jobAdText,
    );
  }

  @override
  void dispose() {
    _jobAd.dispose();
    super.dispose();
  }

  Future<void> _pickCv() async {
    setState(() => _error = null);
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );
    } catch (_) {
      setState(() => _error = 'Datei konnte nicht geöffnet werden.');
      return;
    }
    if (result == null || result.files.isEmpty) return; // cancelled
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'Datei konnte nicht gelesen werden.');
      return;
    }
    if (bytes.length > _maxBytes) {
      setState(() => _error = 'Die Datei ist zu groß (max. 8 MB).');
      return;
    }
    final mime = _mimeFor(file.extension);
    if (mime == null) {
      setState(() => _error = 'Bitte ein PDF oder ein Bild (PNG/JPG) wählen.');
      return;
    }

    setState(() => _extracting = true);
    final text = await _engine.extractDocument(
      CoachAttachment(bytes: bytes, mimeType: mime, name: file.name),
    );
    if (!mounted) return;
    ref
        .read(applicationDocsProvider.notifier)
        .setCv(text: text, fileName: file.name);
    setState(() => _extracting = false);
  }

  static String? _mimeFor(String? ext) => switch (ext?.toLowerCase()) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        _ => null,
      };

  Future<void> _analyze() async {
    final docs = ref.read(applicationDocsProvider);
    if (!docs.isReady || _analyzing) return;
    setState(() {
      _analyzing = true;
      _analysis = '';
    });
    final reply = await _engine.reply(
      const [
        CoachMessage(CoachRole.user,
            'Bitte vergleiche meinen Lebenslauf mit der Stellenanzeige und gib '
            'mir konkrete Tipps.'),
      ],
      CoachMode.unterlagen,
      CoachPersona.neutral,
      contextNote: buildDocsContext(docs),
    );
    if (!mounted) return;
    setState(() {
      _analysis = reply;
      _analyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docs = ref.watch(applicationDocsProvider);
    final busy = _extracting || _analyzing;

    return Scaffold(
      appBar: AppBar(title: const Text('Unterlagen-Check')),
      body: Column(
        children: [
          _Banner(aiPowered: _engine.isAiPowered),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text('Stellenanzeige', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: _jobAd,
                  minLines: 4,
                  maxLines: 10,
                  onChanged: (v) =>
                      ref.read(applicationDocsProvider.notifier).setJobAd(v),
                  decoration: const InputDecoration(
                    hintText: 'Text der Stellenanzeige hier einfügen …',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Lebenslauf', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                _CvStatus(
                  docs: docs,
                  extracting: _extracting,
                  onPick: busy ? null : _pickCv,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: (docs.isReady && !busy) ? _analyze : null,
                  icon: _analyzing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_analyzing ? 'Analysiere …' : 'Analysieren'),
                ),
                if (!docs.isReady)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Füge die Stellenanzeige ein und lade deinen Lebenslauf '
                      'hoch, um die Analyse zu starten.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                if (_analysis.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: SelectableText(_analysis,
                          style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: docs.isReady
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const CoachScreen()),
                          )
                      : null,
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Im Bewerbungsgespräch nutzen'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Übung und allgemeine Orientierung, keine individuelle '
                  'Bewerbungs- oder Rechtsberatung.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CvStatus extends StatelessWidget {
  const _CvStatus({
    required this.docs,
    required this.extracting,
    required this.onPick,
  });
  final ApplicationDocs docs;
  final bool extracting;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onPick,
          icon: extracting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_file),
          label: Text(docs.hasCv ? 'Anderen Lebenslauf' : 'PDF / Bild hochladen'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            extracting
                ? 'Lese Lebenslauf …'
                : docs.hasCv
                    ? '✓ ${docs.cvFileName.isEmpty ? 'gelesen' : docs.cvFileName}'
                    : 'PDF oder Foto deines Lebenslaufs',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.aiPowered});
  final bool aiPowered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = aiPowered
        ? 'Übung, keine Beratung. Lebenslauf und Stellenanzeige werden zur '
            'Analyse an einen KI-Dienst (Gemini) gesendet.'
        : 'Übung, keine Beratung. Vorschau ohne KI – die KI-Analyse (Gemini) '
            'folgt im Premium.';
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}
