import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coach/coach_engine.dart';
import '../coach/coach_providers.dart';
import '../state/application_docs.dart';
import '../state/coach_session.dart';
import '../state/wizard.dart';
import '../util/format.dart';

/// Chat-style interview simulation. Uses the pluggable [CoachEngine]; the
/// local preview scripts an interview offline. Clearly framed as practice,
/// not advice.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key, this.initialMode = CoachMode.interview});

  /// Which conversation to open in (e.g. negotiation when entered from the
  /// KI-Coach hub's "Abfindung verhandeln").
  final CoachMode initialMode;

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final List<CoachMessage> _messages = [];
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;
  late CoachMode _mode;
  late CoachPersona _persona;

  CoachEngine get _engine => ref.read(coachEngineProvider);

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _persona = CoachPersona.neutral;
    _loadMode(_mode);
  }

  /// Restores the saved conversation for [m] (resume) or starts a fresh one.
  /// Assumes the caller updated [_mode]; does not call setState and does not
  /// write the provider (safe to call from initState).
  void _loadMode(CoachMode m) {
    final saved = ref.read(coachSessionProvider)[m];
    _messages.clear();
    if (saved != null && saved.hasUserTurns) {
      _persona = saved.persona;
      _messages.addAll(saved.messages);
    } else {
      _messages.add(CoachMessage(CoachRole.coach, _engine.opening(m, _persona)));
    }
    _typing = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Persists the current conversation so it survives leaving the screen.
  void _save() {
    ref.read(coachSessionProvider.notifier).save(CoachSession(
          messages: List.of(_messages),
          mode: _mode,
          persona: _persona,
        ));
  }

  void _reset() {
    setState(() {
      _messages
        ..clear()
        ..add(CoachMessage(CoachRole.coach, _engine.opening(_mode, _persona)));
      _typing = false;
    });
    _controller.clear();
    _save();
  }

  bool get _hasUserTurns => _messages.any((m) => m.role == CoachRole.user);

  /// Confirms before throwing away an ongoing conversation. Returns true when
  /// there is nothing to lose or the user agreed.
  Future<bool> _confirmDiscard(String action) async {
    if (!_hasUserTurns) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gespräch verwerfen?'),
        content: Text('$action Das aktuelle Gespräch geht dabei verloren.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _changeMode(CoachMode m) {
    if (m == _mode) return;
    _save(); // keep the current mode's conversation
    setState(() {
      _mode = m;
      _loadMode(m); // resume the other mode's conversation (or start fresh)
    });
    _controller.clear();
  }

  /// Switching the conversation partner only changes the tone – keep the
  /// conversation and apply the new character to the next replies.
  void _changePersona(CoachPersona p) {
    if (p == _persona) return;
    setState(() => _persona = p);
    _save();
  }

  Future<void> _restart() async {
    if (await _confirmDiscard('Neu starten setzt das Gespräch zurück.')) {
      _reset();
    }
  }

  /// Real figures handed to the negotiation partner as the only money values
  /// it may use – this keeps the AI from inventing severance amounts. Read
  /// from the wizard the user already filled in.
  String _negotiationContext() {
    final data = ref.read(wizardProvider);
    final est = data.estimateSeveranceRange();
    final b = StringBuffer()
      ..writeln('- Bruttomonatsgehalt: '
          '${euroFromCents(data.grossMonthEuro * 100, withDecimals: false)}')
      ..writeln('- Betriebszugehörigkeit: ca. ${data.tenureYears} Jahre')
      ..writeln('- Verhandelbare Abfindungs-Bandbreite: '
          '${euroFromCents(est.lowCents, withDecimals: false)} bis '
          '${euroFromCents(est.highCents, withDecimals: false)}')
      ..writeln('- Orientierungswert (Mitte der Bandbreite): '
          '${euroFromCents(est.pointCents, withDecimals: false)}')
      ..writeln('- Regelabfindung (§ 1a KSchG, 0,5 Gehälter je Jahr): '
          '${euroFromCents(est.regelabfindungCents, withDecimals: false)}');
    if (data.severanceGrossEuro > 0) {
      b.writeln('- Aktuell im Raum stehendes Angebot: '
          '${euroFromCents(data.severanceGrossEuro * 100, withDecimals: false)}');
    }
    return b.toString().trimRight();
  }

  /// The context passed to the engine for the active [mode]: the severance
  /// figures for the negotiation, or the uploaded CV + job ad for the
  /// interview (so the interviewer asks role-specific questions).
  String _contextFor(CoachMode mode) => switch (mode) {
        CoachMode.negotiation => _negotiationContext(),
        CoachMode.interview => buildDocsContext(ref.read(applicationDocsProvider)),
        CoachMode.unterlagen => '',
      };

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _typing) return;
    setState(() {
      _messages.add(CoachMessage(CoachRole.user, text));
      _typing = true;
    });
    _controller.clear();
    _save(); // keep the user's turn even if they leave before the reply
    _scrollToEnd();

    final reply = await _engine.reply(
      List.unmodifiable(_messages),
      _mode,
      _persona,
      contextNote: _contextFor(_mode),
    );
    if (!mounted) return;
    setState(() {
      _messages.add(CoachMessage(CoachRole.coach, reply));
      _typing = false;
    });
    _save();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _mode == CoachMode.negotiation
        ? 'Abfindungsverhandlung'
        : 'Bewerbungsgespräch';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gesprächssimulation'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('$subtitle · ${_engine.label}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Neu starten',
            onPressed: _restart,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _DisclaimerBanner(aiPowered: _engine.isAiPowered),
          _ModeSelector(selected: _mode, onChanged: _changeMode),
          _PersonaSelector(selected: _persona, onChanged: _changePersona),
          if (_mode == CoachMode.interview &&
              ref.watch(applicationDocsProvider).isReady)
            const _DocsActiveHint(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= _messages.length) return const _TypingBubble();
                return _Bubble(message: _messages[i]);
              },
            ),
          ),
          _Composer(controller: _controller, onSend: _send, enabled: !_typing),
        ],
      ),
    );
  }
}

class _DocsActiveHint extends StatelessWidget {
  const _DocsActiveHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Icon(Icons.description_outlined,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Lebenslauf & Stellenanzeige aktiv – die Fragen richten sich '
              'nach deinen Unterlagen.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.aiPowered});
  final bool aiPowered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = aiPowered
        ? 'Übung, keine Rechts- oder Steuerberatung. Deine Eingaben gehen zur '
            'Antwortgenerierung an einen KI-Dienst (Gemini); gib keine sensiblen '
            'Daten ein.'
        : 'Übung, keine Rechts- oder Steuerberatung. Vorschau ohne KI – die '
            'KI-Anbindung (Gemini) folgt im Premium.';
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

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onChanged});
  final CoachMode selected;
  final ValueChanged<CoachMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<CoachMode>(
          segments: const [
            ButtonSegment(
              value: CoachMode.interview,
              label: Text('Bewerbung'),
              icon: Icon(Icons.record_voice_over_outlined),
            ),
            ButtonSegment(
              value: CoachMode.negotiation,
              label: Text('Verhandlung'),
              icon: Icon(Icons.handshake_outlined),
            ),
          ],
          selected: {selected},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ),
    );
  }
}

class _PersonaSelector extends StatelessWidget {
  const _PersonaSelector({required this.selected, required this.onChanged});
  final CoachPersona selected;
  final ValueChanged<CoachPersona> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('Gesprächspartner:',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in CoachPersona.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.label),
                        tooltip: p.description,
                        selected: p == selected,
                        onSelected: (_) => onChanged(p),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == CoachRole.user;
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(message.text, style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: CircleAvatar(
                radius: 3,
                backgroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer(
      {required this.controller, required this.onSend, required this.enabled});
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Deine Antwort …',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
              tooltip: 'Senden',
              color: theme.colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
