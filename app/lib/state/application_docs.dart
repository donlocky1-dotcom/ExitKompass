import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's application documents for the coaching flow: the job ad (pasted
/// as text) and the CV (uploaded once and read into plain text). Persisted
/// locally (shared_preferences → localStorage on the web) so they survive a
/// reload; cleared on "Daten löschen".
class ApplicationDocs {
  const ApplicationDocs({
    this.jobAdText = '',
    this.cvText = '',
    this.cvFileName = '',
  });

  /// The job posting the user is applying for (plain text).
  final String jobAdText;

  /// The CV as structured plain text (extracted from the uploaded file).
  final String cvText;

  /// The uploaded file's name, shown as a small status label.
  final String cvFileName;

  bool get hasCv => cvText.trim().isNotEmpty;
  bool get hasJobAd => jobAdText.trim().isNotEmpty;

  /// True once there is enough material to run a useful comparison.
  bool get isReady => hasCv && hasJobAd;

  ApplicationDocs copyWith({
    String? jobAdText,
    String? cvText,
    String? cvFileName,
  }) =>
      ApplicationDocs(
        jobAdText: jobAdText ?? this.jobAdText,
        cvText: cvText ?? this.cvText,
        cvFileName: cvFileName ?? this.cvFileName,
      );

  Map<String, dynamic> toJson() =>
      {'jobAd': jobAdText, 'cv': cvText, 'cvFile': cvFileName};

  static ApplicationDocs fromJson(Map<String, dynamic> j) => ApplicationDocs(
        jobAdText: j['jobAd'] as String? ?? '',
        cvText: j['cv'] as String? ?? '',
        cvFileName: j['cvFile'] as String? ?? '',
      );
}

const _kDocsKey = 'application_docs_v1';

/// Loads the persisted documents. Call once at startup (see main).
Future<ApplicationDocs> loadApplicationDocs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDocsKey);
    if (raw == null) return const ApplicationDocs();
    return ApplicationDocs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return const ApplicationDocs();
  }
}

class ApplicationDocsController extends StateNotifier<ApplicationDocs> {
  ApplicationDocsController({ApplicationDocs? initial})
      : super(initial ?? const ApplicationDocs());

  void setJobAd(String text) {
    state = state.copyWith(jobAdText: text);
    _persist();
  }

  void setCv({required String text, required String fileName}) {
    state = state.copyWith(cvText: text, cvFileName: fileName);
    _persist();
  }

  void clear() {
    state = const ApplicationDocs();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Read the latest state after the await so concurrent writes converge.
      final snapshot = state;
      if (!snapshot.hasCv && !snapshot.hasJobAd) {
        await prefs.remove(_kDocsKey);
        return;
      }
      await prefs.setString(_kDocsKey, jsonEncode(snapshot.toJson()));
    } catch (_) {
      // Best effort – persistence must never break the flow.
    }
  }
}

final applicationDocsProvider =
    StateNotifierProvider<ApplicationDocsController, ApplicationDocs>(
        (ref) => ApplicationDocsController());

/// Builds the context block that carries the CV + job ad into a coaching
/// session (interview questions tailored to the role, or the document review).
/// Kept text-only so the uploaded file is never re-sent per turn.
String buildDocsContext(ApplicationDocs docs) {
  final b = StringBuffer();
  if (docs.hasJobAd) {
    b.writeln('Stellenanzeige:');
    b.writeln(docs.jobAdText.trim());
  }
  if (docs.hasCv) {
    if (b.isNotEmpty) b.writeln();
    b.writeln('Lebenslauf (aus dem Dokument der Person):');
    b.writeln(docs.cvText.trim());
  }
  return b.toString().trimRight();
}
