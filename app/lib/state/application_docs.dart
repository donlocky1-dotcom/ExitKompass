import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The user's application documents for the coaching flow: the job ad (pasted
/// as text) and the CV (uploaded once and read into plain text). Held in
/// memory only – this is never written to disk, which keeps sensitive personal
/// data off the device by default (spec §13). Cleared on "Daten löschen".
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
}

class ApplicationDocsController extends StateNotifier<ApplicationDocs> {
  ApplicationDocsController() : super(const ApplicationDocs());

  void setJobAd(String text) => state = state.copyWith(jobAdText: text);

  void setCv({required String text, required String fileName}) =>
      state = state.copyWith(cvText: text, cvFileName: fileName);

  void clear() => state = const ApplicationDocs();
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
