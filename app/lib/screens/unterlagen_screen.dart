import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coach/coach_engine.dart';
import '../coach/coach_providers.dart';
import '../state/application_docs.dart';
import '../util/file_pick.dart';
import '../widgets/ui_kit.dart';
import 'coach_screen.dart';

/// Upload a CV (PDF/image) once and compare it against several job ads. Each
/// position is saved as its own profile (job ad + AI analysis) and can later
/// be picked in the interview simulation. Clearly framed as practice, not
/// advice.
class UnterlagenScreen extends ConsumerStatefulWidget {
  const UnterlagenScreen({super.key});

  @override
  ConsumerState<UnterlagenScreen> createState() => _UnterlagenScreenState();
}

class _UnterlagenScreenState extends ConsumerState<UnterlagenScreen> {
  static const int _maxBytes = 8 * 1024 * 1024; // 8 MB
  static const _allowedMimes = {'application/pdf', 'image/png', 'image/jpeg'};

  late final TextEditingController _name;
  late final TextEditingController _jobAd;
  final _nameFocus = FocusNode();
  final _jobAdFocus = FocusNode();

  bool _extracting = false;
  bool _analyzing = false;
  String? _error;

  CoachEngine get _engine => ref.read(coachEngineProvider);

  @override
  void initState() {
    super.initState();
    final docs = ref.read(applicationDocsProvider);
    final sel = docs.selected;
    _name = TextEditingController(text: sel?.title ?? '');
    _jobAd = TextEditingController(text: sel?.jobAdText ?? '');
    // Always start with at least one position to fill in.
    if (docs.profiles.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(applicationDocsProvider.notifier).addProfile();
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _jobAd.dispose();
    _nameFocus.dispose();
    _jobAdFocus.dispose();
    super.dispose();
  }

  /// Reloads the text fields for a newly selected position. Skips fields the
  /// user is currently editing so it never clobbers in-progress typing – the
  /// iOS Safari IME breaks if the controller text is reassigned mid-edit.
  void _syncFieldsToSelection() {
    final sel = ref.read(applicationDocsProvider).selected;
    if (!_nameFocus.hasFocus) _name.text = sel?.title ?? '';
    if (!_jobAdFocus.hasFocus) _jobAd.text = sel?.jobAdText ?? '';
  }

  Future<void> _pickCv() async {
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
    final mime = file.mimeType.isNotEmpty
        ? file.mimeType
        : _mimeForName(file.name);
    if (mime == null || !_allowedMimes.contains(mime)) {
      setState(() => _error = 'Bitte ein PDF oder ein Bild (PNG/JPG) wählen.');
      return;
    }

    setState(() => _extracting = true);
    final text = await _engine.extractDocument(
      CoachAttachment(bytes: file.bytes, mimeType: mime, name: file.name),
    );
    if (!mounted) return;
    ref
        .read(applicationDocsProvider.notifier)
        .setCv(text: text, fileName: file.name);
    setState(() => _extracting = false);
  }

  static String? _mimeForName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => null,
    };
  }

  void _addProfile() {
    _nameFocus.unfocus();
    _jobAdFocus.unfocus();
    ref.read(applicationDocsProvider.notifier).addProfile();
  }

  Future<void> _deleteSelected(JobProfile profile) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stelle löschen?'),
        content: Text(
            '„${profile.title}“ und die dazu gespeicherte Analyse werden '
            'entfernt.'),
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
    if (ok != true) return;
    _nameFocus.unfocus();
    _jobAdFocus.unfocus();
    ref.read(applicationDocsProvider.notifier).deleteProfile(profile.id);
  }

  Future<void> _analyze(JobProfile profile) async {
    final docs = ref.read(applicationDocsProvider);
    if (!docs.hasCv || !profile.hasJobAd || _analyzing) return;
    setState(() => _analyzing = true);
    final reply = await _engine.reply(
      const [
        CoachMessage(CoachRole.user,
            'Bitte vergleiche meinen Lebenslauf mit der Stellenanzeige und gib '
            'mir konkrete Tipps.'),
      ],
      CoachMode.unterlagen,
      CoachPersona.neutral,
      contextNote: buildDocsContext(
        cvText: docs.cvText,
        jobAdText: profile.jobAdText,
      ),
    );
    if (!mounted) return;
    ref
        .read(applicationDocsProvider.notifier)
        .updateProfile(profile.id, analysis: reply);
    setState(() => _analyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reload the fields whenever the active position changes (add / delete /
    // pick a different one from the dropdown).
    ref.listen<String?>(
      applicationDocsProvider.select((d) => d.selected?.id),
      (_, _) => _syncFieldsToSelection(),
    );
    final docs = ref.watch(applicationDocsProvider);
    final profile = docs.selected;
    final busy = _extracting || _analyzing;
    final ready = docs.hasCv && (profile?.hasJobAd ?? false);

    final accent = bewerbenAccent(context);

    return Scaffold(
      backgroundColor: groupedBackground(context),
      appBar: AppBar(
        title: const Text('Unterlagen-Check'),
        backgroundColor: groupedBackground(context),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          _Banner(aiPowered: _engine.isAiPowered),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const SectionLabel('Deine Stellen', topPad: 8),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfilePicker(
                        docs: docs,
                        onSelect: busy
                            ? null
                            : (id) {
                                _nameFocus.unfocus();
                                _jobAdFocus.unfocus();
                                ref
                                    .read(applicationDocsProvider.notifier)
                                    .selectProfile(id);
                              },
                        onAdd: busy ? null : _addProfile,
                        onDelete:
                            (busy || docs.profiles.length <= 1 || profile == null)
                                ? null
                                : () => _deleteSelected(profile),
                      ),
                      if (profile != null) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _name,
                          focusNode: _nameFocus,
                          textInputAction: TextInputAction.done,
                          onChanged: (v) => ref
                              .read(applicationDocsProvider.notifier)
                              .updateProfile(profile.id, title: v),
                          decoration: const InputDecoration(
                            labelText: 'Bezeichnung',
                            hintText: 'z. B. Data Engineer bei Firma X',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (profile != null) ...[
                  const SectionLabel('Stellenanzeige'),
                  AppCard(
                    child: TextField(
                      controller: _jobAd,
                      focusNode: _jobAdFocus,
                      minLines: 4,
                      maxLines: 10,
                      onChanged: (v) => ref
                          .read(applicationDocsProvider.notifier)
                          .updateProfile(profile.id, jobAdText: v),
                      decoration: const InputDecoration(
                        hintText: 'Text der Stellenanzeige hier einfügen …',
                        alignLabelWithHint: true,
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ],
                const SectionLabel('Lebenslauf'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: (ready && !busy && profile != null)
                      ? () => _analyze(profile)
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _analyzing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_analyzing ? 'Analysiere …' : 'Analysieren'),
                ),
                if (!ready)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                    child: Text(
                      'Füge die Stellenanzeige ein und lade deinen Lebenslauf '
                      'hoch, um die Analyse zu starten.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                if ((profile?.analysis ?? '').isNotEmpty) ...[
                  const SectionLabel('Tipps der KI'),
                  AppCard(
                    child: SelectableText(profile!.analysis,
                        style: theme.textTheme.bodyMedium),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: ready
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const CoachScreen()),
                          )
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Im Bewerbungsgespräch nutzen'),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Übung und allgemeine Orientierung, keine individuelle '
                    'Bewerbungs- oder Rechtsberatung.',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown of saved positions plus add / delete controls.
class _ProfilePicker extends StatelessWidget {
  const _ProfilePicker({
    required this.docs,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
  });
  final ApplicationDocs docs;
  final ValueChanged<String>? onSelect;
  final VoidCallback? onAdd;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                isDense: true,
                value: docs.selected?.id,
                items: [
                  for (final p in docs.profiles)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        p.title.isEmpty ? 'Ohne Titel' : p.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: onSelect == null
                    ? null
                    : (id) => id == null ? null : onSelect!(id),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Neue Stelle',
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
        IconButton(
          tooltip: 'Stelle löschen',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
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
      decoration: BoxDecoration(
        color: groupedCard(context),
        border: Border(bottom: BorderSide(color: hairline(context))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}
