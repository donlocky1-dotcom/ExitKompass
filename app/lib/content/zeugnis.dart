/// Decoder for the coded language of German employment references
/// (Arbeitszeugnis) into plain meaning / school grades.
///
/// General information, **not** a legal assessment of an individual Zeugnis:
/// § 109 GewO grants a right to a *truthful* and *benevolent* qualified
/// reference; the grade conventions below are established case-law usage, not
/// a statute. Borderline wordings should be checked by a specialist lawyer.
library;

/// Last editorial review (mirrors the Ratgeber's `contentReviewedOn`).
const String zeugnisReviewedOn = 'Juli 2026';

/// Which part of the reference a phrase belongs to.
enum ZeugnisCategory { leistung, verhalten, schlussformel, code }

extension ZeugnisCategoryLabel on ZeugnisCategory {
  String get label => switch (this) {
        ZeugnisCategory.leistung => 'Leistungsbeurteilung',
        ZeugnisCategory.verhalten => 'Verhaltensbeurteilung',
        ZeugnisCategory.schlussformel => 'Schlussformel',
        ZeugnisCategory.code => 'Versteckte Botschaften',
      };
}

/// A single coded phrase and what it usually means.
class ZeugnisPhrase {
  const ZeugnisPhrase({
    required this.category,
    required this.phrase,
    required this.meaning,
    this.grade,
  });

  final ZeugnisCategory category;
  final String phrase;
  final String meaning;

  /// School grade (1 = sehr gut … 6 = ungenügend) where the phrase encodes
  /// one; `null` for final clauses and hidden-message codes.
  final int? grade;
}

/// Curated decoder entries. Grade wording follows the established
/// "Zufriedenheits-Skala" of the German labour courts.
const List<ZeugnisPhrase> zeugnisPhrases = [
  // --- Leistung: the "…zu unserer … Zufriedenheit" scale ---
  ZeugnisPhrase(
    category: ZeugnisCategory.leistung,
    grade: 1,
    phrase: 'stets zu unserer vollsten Zufriedenheit',
    meaning: 'Sehr gut (Note 1). „vollsten" ist die höchste Steigerung.',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.leistung,
    grade: 2,
    phrase: 'stets zu unserer vollen Zufriedenheit',
    meaning: 'Gut (Note 2). „stets" + „vollen", aber nicht „vollsten".',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.leistung,
    grade: 3,
    phrase: 'zu unserer vollen Zufriedenheit',
    meaning: 'Befriedigend (Note 3). Ohne „stets" – nur „voll".',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.leistung,
    grade: 4,
    phrase: 'stets zu unserer Zufriedenheit',
    meaning: 'Ausreichend (Note 4). „stets", aber ohne „voll".',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.leistung,
    grade: 5,
    phrase: 'zu unserer Zufriedenheit',
    meaning: 'Mangelhaft (Note 5). Weder „stets" noch „voll".',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.leistung,
    grade: 6,
    phrase: 'hat sich bemüht, den Anforderungen gerecht zu werden',
    meaning: 'Ungenügend (Note 6). „bemüht" = die Anforderungen nicht erfüllt.',
  ),
  // --- Verhalten ---
  ZeugnisPhrase(
    category: ZeugnisCategory.verhalten,
    grade: 1,
    phrase: 'Verhalten gegenüber Vorgesetzten und Kollegen war stets vorbildlich',
    meaning: 'Sehr gut. Reihenfolge Vorgesetzte → Kollegen und „stets vorbildlich".',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.verhalten,
    grade: 2,
    phrase: 'Verhalten war stets einwandfrei / vorbildlich',
    meaning: 'Gut. „stets einwandfrei" liegt unter „stets vorbildlich".',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.verhalten,
    grade: 4,
    phrase: 'Verhalten gab zu keiner Klage Anlass',
    meaning: 'Nur ausreichend – eine schwache Formulierung.',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.verhalten,
    phrase: 'Verhalten gegenüber Kollegen und Vorgesetzten (Kollegen zuerst)',
    meaning: 'Werden die Kollegen vor den Vorgesetzten genannt, deutet das auf '
        'ein gestörtes Verhältnis zu den Vorgesetzten hin.',
  ),
  // --- Schlussformel ---
  ZeugnisPhrase(
    category: ZeugnisCategory.schlussformel,
    phrase: 'Wir bedauern sein Ausscheiden, danken für die stets gute '
        'Zusammenarbeit und wünschen für die Zukunft alles Gute',
    meaning: 'Positive, vollständige Schlussformel – ein gutes Zeichen.',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.schlussformel,
    phrase: 'Fehlende Schlussformel (kein Dank, kein Bedauern, keine guten Wünsche)',
    meaning: 'Das Fehlen der Schlussformel gilt als Distanzierung und wertet '
        'ein sonst gutes Zeugnis ab.',
  ),
  // --- Versteckte Botschaften / Geheimcodes ---
  ZeugnisPhrase(
    category: ZeugnisCategory.code,
    phrase: 'trug durch seine Geselligkeit zur Verbesserung des Betriebsklimas bei',
    meaning: 'Kann auf übermäßigen Alkoholkonsum anspielen.',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.code,
    phrase: 'war stets bemüht',
    meaning: '„bemüht" ohne Erfolg = die Leistung war nicht ausreichend.',
  ),
  ZeugnisPhrase(
    category: ZeugnisCategory.code,
    phrase: 'zeigte für die Belange der Belegschaft (großes) Verständnis',
    meaning: 'Kann andeuten, dass die Person mehr mit Betriebsrats-/'
        'Kollegen-Themen als mit der Arbeit beschäftigt war.',
  ),
];
