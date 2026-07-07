/// Structured, **on-device** interview preparation ("Bewerbungstraining").
///
/// Deliberately not an AI mock-interview (that would need the cloud and break
/// the privacy promise): a curated question bank with answer frameworks and
/// tips. General guidance, not individual application coaching.
library;

/// Last editorial review (mirrors the other content review dates).
const String bewerbungReviewedOn = 'Juli 2026';

/// Thematic group of an interview question.
enum InterviewCategory { klassiker, kritischeFragen, eigeneFragen, kuendigungErklaeren, gehalt }

extension InterviewCategoryLabel on InterviewCategory {
  String get label => switch (this) {
        InterviewCategory.klassiker => 'Klassische Fragen',
        InterviewCategory.kritischeFragen => 'Kritische & Fangfragen',
        InterviewCategory.eigeneFragen => 'Fragen, die DU stellst',
        InterviewCategory.kuendigungErklaeren => 'Kündigung & Lücke erklären',
        InterviewCategory.gehalt => 'Gehaltsverhandlung',
      };
}

/// A short mindset principle (the "Value Selling" grounding of the training).
class PrepPrinciple {
  const PrepPrinciple(this.title, this.body);
  final String title;
  final String body;
}

/// Grounding attitude: sell yourself over your value. Adapted from the
/// author's own draft "Job Interviews as a Sales Pitch".
const List<PrepPrinciple> valueSellingPrinciples = [
  PrepPrinciple(
    'Es ist ein Arbeits*markt* – du bringst Wert',
    'Nicht nur du bewirbst dich; auch das Unternehmen muss dich überzeugen. '
        'Du investierst deine Arbeitskraft und erwartest eine Gegenleistung – '
        'trittst also auf Augenhöhe auf, nicht als Bittsteller.',
  ),
  PrepPrinciple(
    'Verkauf Nutzen, nicht nur Fähigkeiten (Value Selling)',
    'Nicht „ich kann X", sondern „damit bringe ich euch Y": Umsatz, '
        'Einsparungen, zufriedene Kunden, ein Netzwerk, Methoden, die Zeit und '
        'Geld sparen. Belege den Nutzen mit einer Zahl, wo es geht.',
  ),
  PrepPrinciple(
    'Sprich ihre Sprache',
    'Begriffe wie „Wert", „Nutzen" oder „Kundenzufriedenheit" versetzen dein '
        'Gegenüber in den Modus einer Geschäftsbesprechung – dein Pitch kommt '
        'besser an.',
  ),
  PrepPrinciple(
    'Sei Partner und Berater',
    'Ruhig und gelassen, auf Augenhöhe. Stell dir vor, du arbeitest schon '
        'dort, und überlege mit, wie du die Probleme der Stelle löst.',
  ),
  PrepPrinciple(
    'Bereite dich vor wie auf eine Verhandlung',
    'Win-win, aber nicht naiv: erst fragen (proaktiv zuhören), nur so viel '
        'offenlegen wie nötig, sachlich statt bloß „nett". Kenne deine '
        'Alternativen.',
  ),
  PrepPrinciple(
    'Lies die Anzeige richtig: Analyse + Synthese',
    'Zerlege die Anforderungen in einzelne Punkte (Analyse) und finde deine '
        'Überschneidungen (Synthese). Zu jedem wichtigen Punkt ein Beispiel '
        'aus deiner Erfahrung parat haben.',
  ),
];

/// A single interview question with a way to approach it.
class InterviewQuestion {
  const InterviewQuestion({
    required this.category,
    required this.question,
    required this.approach,
    this.tips = const [],
  });

  final InterviewCategory category;
  final String question;

  /// How to structure a good answer.
  final String approach;

  /// Short, concrete do's.
  final List<String> tips;
}

/// Intro for the brainteaser / case-question section.
const String brainteaserIntro =
    'Bei Brainteasern und Case-Fragen gibt es meist keine einzig richtige '
    'Lösung. Die Interviewer wollen sehen, wie du unter Druck denkst, ein '
    'Problem strukturiert angehst und deinen Gedankengang klar erklärst.';

/// How to tackle a brainteaser / case question (reuses the principle model).
const List<PrepPrinciple> brainteaserSteps = [
  PrepPrinciple(
    '1. Erst Rückfragen stellen',
    'Kläre das Problem, bevor du losrechnest: Welche Mittel habe ich? Muss das '
        'Ergebnis exakt sein? So zeigst du von Anfang an, dass du strukturiert '
        'vorgehst.',
  ),
  PrepPrinciple(
    '2. Laut denken',
    'Sprich deine Annahmen aus und begründe sie. Bei Brainteasern musst du oft '
        'selbst sinnvolle Annahmen treffen – mach sie transparent.',
  ),
  PrepPrinciple(
    '3. Schritt für Schritt erklären',
    'Nicht zur Lösung hetzen. Führe die Interviewer durch deinen Weg und '
        'begründe jede Entscheidung. Der Weg zählt mehr als die Zahl.',
  ),
];

/// The STAR method, shown as an intro on the training screen.
const String starMethodExplainer =
    'Beantworte Beispiel-Fragen mit der STAR-Methode: '
    'Situation (Ausgangslage) · Task (deine Aufgabe) · Action (was du getan '
    'hast) · Result (das Ergebnis, gern mit Zahl). So werden Stärken konkret '
    'statt behauptet.';

/// Curated question bank.
const List<InterviewQuestion> interviewQuestions = [
  // --- Klassiker ---
  InterviewQuestion(
    category: InterviewCategory.klassiker,
    question: 'Erzählen Sie etwas über sich.',
    approach: 'Ein 2–3-Minuten-Pitch in der Struktur Gegenwart → Vergangenheit '
        '→ Zukunft: Wo stehst du, was hat dich dorthin gebracht, warum diese '
        'Stelle. Nur Berufsrelevantes, kein Lebenslauf zum Vorlesen.',
    tips: [
      'Vorher laut üben und auf die Zeit achten.',
      'Mit einem Satz enden, der zur ausgeschriebenen Stelle überleitet.',
    ],
  ),
  InterviewQuestion(
    category: InterviewCategory.klassiker,
    question: 'Was sind Ihre größten Stärken und Schwächen?',
    approach: 'Stärken mit einem konkreten Beispiel (STAR) belegen, das zur '
        'Stelle passt. Bei der Schwäche eine echte nennen – plus, wie du '
        'aktiv daran arbeitest.',
    tips: [
      'Keine getarnte Stärke („ich bin zu perfektionistisch").',
      'Höchstens zwei Stärken, dafür mit Beleg.',
    ],
  ),
  InterviewQuestion(
    category: InterviewCategory.klassiker,
    question: 'Warum sollten wir gerade Sie einstellen?',
    approach: 'Die zwei, drei wichtigsten Anforderungen der Stelle aufgreifen '
        'und jeweils mit deiner Erfahrung matchen. Nutzen für das Unternehmen '
        'in den Vordergrund stellen, nicht deine Wünsche.',
  ),
  // --- Kündigung & Lücke erklären ---
  InterviewQuestion(
    category: InterviewCategory.kuendigungErklaeren,
    question: 'Warum haben Sie Ihre letzte Stelle verlassen?',
    approach: 'Sachlich und knapp bleiben, nach vorn richten. Betriebsbedingte '
        'Gründe (Umstrukturierung, Stellenabbau) neutral benennen. Nie über '
        'den alten Arbeitgeber schimpfen – das fällt auf dich zurück.',
    tips: [
      'Einen kurzen, ehrlichen Satz vorbereiten und einüben.',
      'Schnell zum Ausblick wechseln: was du jetzt suchst.',
    ],
  ),
  InterviewQuestion(
    category: InterviewCategory.kuendigungErklaeren,
    question: 'Sie haben eine Lücke im Lebenslauf – wie kam es dazu?',
    approach: 'Ehrlich und selbstbewusst: Was hast du in der Zeit getan '
        '(Weiterbildung, Bewerbungsphase, Pflege, Neuorientierung)? Zeig, dass '
        'die Zeit nicht verloren war.',
    tips: ['Kein Rechtfertigen – kurz erklären und weiter.'],
  ),
  InterviewQuestion(
    category: InterviewCategory.kuendigungErklaeren,
    question: 'Dürfen wir Ihren früheren Arbeitgeber kontaktieren?',
    approach: 'Ruhig bleiben. Du kannst auf ein qualifiziertes Zeugnis '
        'verweisen und um Rücksprache bitten, bevor Referenzen kontaktiert '
        'werden – das ist üblich und legitim.',
  ),
  // --- Gehaltsverhandlung ---
  InterviewQuestion(
    category: InterviewCategory.gehalt,
    question: 'Was sind Ihre Gehaltsvorstellungen?',
    approach: 'Vorher den Marktwert recherchieren (Branche, Region, Größe). '
        'Eine Spanne oder einen konkreten Anker nennen, begründet mit deiner '
        'Erfahrung und dem Verantwortungsumfang der Stelle.',
    tips: [
      'Nenne die Zahl selbstbewusst, ohne dich sofort zu rechtfertigen.',
      'Denk an das Gesamtpaket (Urlaub, Homeoffice, Weiterbildung, Bonus).',
    ],
  ),
  InterviewQuestion(
    category: InterviewCategory.gehalt,
    question: 'Ihre Forderung liegt über unserem Rahmen – warum so viel?',
    approach: 'Auf Marktwert und den konkreten Nutzen verweisen, den du '
        'bringst. Gesprächsbereit bleiben, aber nicht sofort einknicken. '
        'Wenn kein Spielraum beim Gehalt ist: über andere Bausteine verhandeln.',
    tips: ['Gehalt verhandelt sich am besten, wenn sie dich schon wollen.'],
  ),
  // --- Kritische & Fangfragen (Einwände souverän auflösen) ---
  InterviewQuestion(
    category: InterviewCategory.kritischeFragen,
    question: 'Sie passen bei Anforderung X nicht ganz.',
    approach: 'Den Punkt ruhig anerkennen, nicht wegreden. Dann die nächste '
        'Erfahrung dagegenstellen und zeigen, wie schnell du dich einarbeitest '
        '– mit einem Beispiel, wo du dir Neues zügig angeeignet hast.',
    tips: ['Nicht defensiv werden – eine fehlende Anforderung ist selten ein K.-o.'],
  ),
  InterviewQuestion(
    category: InterviewCategory.kritischeFragen,
    question: 'Sie hatten noch nie disziplinarische Führungsverantwortung.',
    approach: 'Fachliche Führung, Projekt- oder Teamleitung, Einarbeitung von '
        'Kollegen anführen. Lernbereitschaft zeigen und benennen, wie du in die '
        'Rolle hineinwachsen würdest.',
  ),
  InterviewQuestion(
    category: InterviewCategory.kritischeFragen,
    question: 'Ehrlich – Ihnen fehlt Erfahrung für diese Rolle.',
    approach: 'Motivation und schnelle Einarbeitung betonen, Transfer aus '
        'anderen Bereichen zeigen und konkrete erste Erfolge („Quick Wins") '
        'skizzieren, die du früh liefern kannst. Value statt Lücke.',
  ),
  // --- Fragen, die DU stellst (die Macht der richtigen Fragen) ---
  InterviewQuestion(
    category: InterviewCategory.eigeneFragen,
    question: 'Was hält Sie im Moment davon ab, mich einzustellen – wo sehen Sie blinde Flecken?',
    approach: 'Die vielleicht stärkste Frage: Du erfährst die echten Bedenken '
        'und kannst sie direkt ausräumen, statt dass sie unausgesprochen gegen '
        'dich wirken. Mutig, aber wirkungsvoll.',
  ),
  InterviewQuestion(
    category: InterviewCategory.eigeneFragen,
    question: 'Was sind aktuell die größten Herausforderungen dieser Rolle?',
    approach: 'Du positionierst dich sofort als Löser – und kannst deine '
        'Erfahrung genau auf ihren Schmerzpunkt zuschneiden.',
  ),
  InterviewQuestion(
    category: InterviewCategory.eigeneFragen,
    question: 'Wer hatte die Stelle zuvor, was macht die Person heute, warum ist sie gegangen?',
    approach: 'Deckt Fluktuation, Erwartungen und mögliche Probleme der Stelle '
        'auf – wichtige Infos für deine Entscheidung und deine Verhandlung.',
  ),
  InterviewQuestion(
    category: InterviewCategory.eigeneFragen,
    question: 'Wie sähen meine ersten Monate konkret aus?',
    approach: 'Zeigt, dass du dich in die Rolle hineindenkst, und gibt dir ein '
        'realistisches Bild von Einarbeitung und Erwartungen.',
  ),
  InterviewQuestion(
    category: InterviewCategory.eigeneFragen,
    question: 'Wie würde für Sie der perfekte Kandidat aussehen?',
    approach: 'Lass sie das Wunschprofil beschreiben – dann hakst du im Gespräch '
        'gezielt ab, was davon auf dich zutrifft.',
  ),
  InterviewQuestion(
    category: InterviewCategory.eigeneFragen,
    question: 'Wie geht es dem Unternehmen bzw. dem Team gerade?',
    approach: 'Signalisiert unternehmerisches Mitdenken. Frag ruhig konkret '
        'nach Wachstum, Umstrukturierungen oder der Auftragslage.',
    tips: [
      'Frag lieber nach den Umständen, statt etwas anzunehmen – z. B. warum ein '
          'bestimmtes Startdatum wichtig ist. Oft ist mehr Spielraum als gedacht.',
    ],
  ),
];
