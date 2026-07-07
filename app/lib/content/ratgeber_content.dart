import 'models.dart';

/// Content version / last editorial review. Bump when articles change so
/// the "Stand" shown in the UI stays honest.
const String contentReviewedOn = 'Juli 2026';

/// All Ratgeber articles. General legal information with sources; no
/// individual advice (see content/models.dart).
const List<Article> ratgeberArticles = [
  // ------------------------------------------------------------------
  // Verhandlung
  // ------------------------------------------------------------------
  Article(
    id: 'abfindung-anspruch',
    category: ArticleCategory.verhandlung,
    title: 'Habe ich Anspruch auf eine Abfindung?',
    teaser: 'Meistens nein – aber es gibt wichtige Ausnahmen und viel Verhandlungsspielraum.',
    sections: [
      ArticleSection(
        'Grundsatz',
        'Einen allgemeinen gesetzlichen Anspruch auf eine Abfindung gibt es in '
            'Deutschland nicht. Eine Abfindung ist meist das Ergebnis einer Einigung – '
            'etwa in einem Vergleich vor dem Arbeitsgericht oder in einem '
            'Aufhebungsvertrag.',
      ),
      ArticleSection(
        'Die wichtigsten Ausnahmen',
        'Ein Anspruch kann sich ergeben aus einem Abfindungsangebot bei '
            'betriebsbedingter Kündigung (§ 1a KSchG), aus einem Sozialplan '
            '(§§ 112, 112a BetrVG), aus einem Nachteilsausgleich (§ 113 BetrVG) oder '
            'aus einem gerichtlichen Auflösungsurteil (§§ 9, 10 KSchG).',
      ),
      ArticleSection(
        'Warum trotzdem oft gezahlt wird',
        'Auch ohne Anspruch bieten viele Arbeitgeber eine Abfindung an, um das '
            'Kosten- und Prozessrisiko einer Kündigungsschutzklage zu vermeiden. Genau '
            'darin liegt der Verhandlungsspielraum.',
      ),
    ],
    sources: ['§ 1a KSchG', '§§ 9, 10 KSchG', '§§ 112, 112a, 113 BetrVG'],
  ),
  Article(
    id: 'abfindung-hoehe',
    category: ArticleCategory.verhandlung,
    title: 'Wie hoch fällt eine Abfindung üblicherweise aus?',
    teaser: 'Die Faustformel als Orientierung – und warum sie nur ein Startpunkt ist.',
    sections: [
      ArticleSection(
        'Die Faustformel',
        'Als grobe Orientierung gilt: ein halbes Bruttomonatsgehalt je Jahr der '
            'Betriebszugehörigkeit. Diese Größe nennt auch § 1a KSchG als Regelabfindung. '
            'Sie ist ein Anhaltspunkt, keine Obergrenze und kein Anspruch.',
      ),
      ArticleSection(
        'Was die Höhe beeinflusst',
        'Wie gut die Erfolgsaussichten einer Kündigungsschutzklage sind, wie dringend '
            'der Arbeitgeber die Trennung braucht, die Dauer der Betriebszugehörigkeit '
            'und die Lage am Arbeitsmarkt wirken sich auf die tatsächliche Höhe aus.',
      ),
      ArticleSection(
        'Mehr als nur Geld',
        'Verhandelbar sind neben dem Betrag oft auch die Zeugnisnote, eine bezahlte '
            'Freistellung, der Verzicht auf Rückzahlungsklauseln, der Auszahlungszeitpunkt '
            '(steuerlich relevant) und Leistungen wie Outplacement.',
      ),
    ],
    sources: ['§ 1a KSchG'],
  ),
  Article(
    id: 'verhandlung-hebel',
    category: ArticleCategory.verhandlung,
    title: 'Verhandlungshebel bei Abfindung und Aufhebung',
    teaser: 'Prozessrisiko, Fristen und Timing sind deine stärksten Argumente.',
    sections: [
      ArticleSection(
        'Prozessrisiko als Druckmittel',
        'Eine fristgerechte Kündigungsschutzklage hält den Rechtsweg offen. Für den '
            'Arbeitgeber bedeutet ein laufendes Verfahren Unsicherheit, Zeit und Kosten – '
            'das erhöht die Bereitschaft, sich per Vergleich zu einigen.',
      ),
      ArticleSection(
        'Auszahlung ins Folgejahr',
        'Der Zeitpunkt der Auszahlung kann die Steuerlast verändern (Progression, '
            'Fünftelregelung). Ob sich eine Verschiebung lohnt, lässt sich im Rechner '
            'dieser App durchspielen.',
      ),
      ArticleSection(
        'Nicht unter Druck unterschreiben',
        'Für einen Aufhebungsvertrag gibt es keine gesetzliche Bedenkzeit und kein '
            'Widerrufsrecht. Einmal unterschrieben, gilt er – deshalb ist Ruhe vor der '
            'Unterschrift wichtiger als Tempo.',
      ),
    ],
    sources: ['§ 34 EStG', '§ 4 KSchG'],
  ),
  Article(
    id: 'win-win-mythen',
    category: ArticleCategory.verhandlung,
    title: 'Sieben Mythen der Win-win-Verhandlung',
    teaser: 'Nett, fair und vertrauensvoll allein macht dich in der Verhandlung '
        'nicht stark – hier die wirksameren Strategien.',
    sections: [
      ArticleSection(
        'Vertrauen → Interdependenz',
        'Vertrauen ist subjektiv und braucht Zeit; es garantiert keine '
            'Gegenleistung. Wirksamer ist es, die Anreize zu koppeln: Wenn beide '
            'Seiten erkennen, dass Zusammenarbeit im eigenen Interesse liegt, '
            'trägt die Einigung von selbst.',
      ),
      ArticleSection(
        'Zuhören → proaktiv fragen',
        'Bloßes (auch aktives) Zuhören ist reaktiv. Wer die Verhandlung führen '
            'will, stellt zuerst Fragen und lenkt so das Gespräch dorthin, wo am '
            'meisten zu lernen ist.',
      ),
      ArticleSection(
        'Transparent → durchscheinend auf der Sache',
        'Bei Beziehung und Kommunikation darfst du offen sein. Auf der '
            'Sachebene gilt: nur so viel preisgeben, wie nötig ist, damit die '
            'Gegenseite eine Einigung anstrebt – nicht mehr.',
      ),
      ArticleSection(
        'Nett & fair → positiv und vernünftig',
        'Nettigkeit kann als Schwäche gelesen werden. Sei stattdessen positiv, '
            'aber nicht naiv, und statt „subjektiv fair" lieber „vernünftig": '
            'ein Vorschlag, der im Wertesystem beider Seiten nachvollziehbar ist.',
      ),
      ArticleSection(
        'Treu zur Person → treu zum Prozess',
        'Bleib dem fairen Verhandlungsprozess verpflichtet, nicht bedingungslos '
            'der Gegenseite. Und verpflichte dich dem guten Prozess – nicht einem '
            'bestimmten Ergebnis, das du ohnehin nicht garantieren kannst.',
      ),
      ArticleSection(
        'Das eigentliche Werkzeug: bewusster Machtverzicht',
        'Auf Machtspiele zu verzichten ist keine Schwäche, sondern eine '
            'strategische Entscheidung, die oft zu besseren Ergebnissen führt. '
            '(Nach „Getting to Yes" von Fisher/Ury.)',
      ),
    ],
    sources: ['Getting to Yes (Fisher/Ury)'],
  ),

  // ------------------------------------------------------------------
  // Rechtsgrundlagen
  // ------------------------------------------------------------------
  Article(
    id: 'kuendigungsschutz',
    category: ArticleCategory.rechtsgrundlagen,
    title: 'Gilt der Kündigungsschutz für mich?',
    teaser: 'Das Kündigungsschutzgesetz greift erst ab bestimmten Voraussetzungen.',
    sections: [
      ArticleSection(
        'Zwei Voraussetzungen',
        'Das Kündigungsschutzgesetz (KSchG) gilt, wenn das Arbeitsverhältnis länger als '
            'sechs Monate bestanden hat und im Betrieb in der Regel mehr als zehn '
            'Arbeitnehmer beschäftigt sind (Kleinbetriebsklausel).',
      ),
      ArticleSection(
        'Wenn es greift',
        'Dann braucht eine ordentliche Kündigung einen anerkannten Grund – '
            'betriebsbedingt, verhaltensbedingt oder personenbedingt – und muss sozial '
            'gerechtfertigt sein.',
      ),
      ArticleSection(
        'Auch im Kleinbetrieb',
        'Selbst ohne KSchG darf eine Kündigung nicht sitten- oder treuwidrig sein, und '
            'es gelten Formvorschriften, Fristen und der Sonderkündigungsschutz.',
      ),
    ],
    sources: ['§ 1 KSchG', '§ 23 KSchG'],
  ),
  Article(
    id: 'form-und-frist',
    category: ArticleCategory.rechtsgrundlagen,
    title: 'Formfehler und Fristen: Wann eine Kündigung unwirksam ist',
    teaser: 'Schriftform, Unterschrift, Betriebsratsanhörung – Formfehler zählen.',
    sections: [
      ArticleSection(
        'Nur schriftlich',
        'Eine Kündigung muss schriftlich mit eigenhändiger Unterschrift erfolgen '
            '(§ 623 BGB). Eine Kündigung per E-Mail, SMS oder Messenger ist unwirksam.',
      ),
      ArticleSection(
        'Betriebsrat anhören',
        'Gibt es einen Betriebsrat, muss er vor jeder Kündigung angehört werden '
            '(§ 102 BetrVG). Ohne ordnungsgemäße Anhörung ist die Kündigung unwirksam.',
      ),
      ArticleSection(
        'Kündigungsfristen',
        'Die gesetzlichen Fristen richten sich nach § 622 BGB und verlängern sich für '
            'Arbeitgeberkündigungen mit der Dauer der Betriebszugehörigkeit. Im Vertrag '
            'oder Tarifvertrag können abweichende Fristen stehen.',
      ),
    ],
    sources: ['§ 623 BGB', '§ 622 BGB', '§ 102 BetrVG'],
  ),
  Article(
    id: 'klagefrist',
    category: ArticleCategory.rechtsgrundlagen,
    title: 'Die 3-Wochen-Frist für die Kündigungsschutzklage',
    teaser: 'Der wichtigste Termin überhaupt – nach Ablauf gilt die Kündigung als wirksam.',
    sections: [
      ArticleSection(
        'Drei Wochen ab Zugang',
        'Wer sich gegen eine Kündigung wehren will, muss innerhalb von drei Wochen ab '
            'Zugang der schriftlichen Kündigung Kündigungsschutzklage beim Arbeitsgericht '
            'erheben (§ 4 KSchG).',
      ),
      ArticleSection(
        'Was nach Fristablauf passiert',
        'Wird die Frist versäumt, gilt die Kündigung grundsätzlich als von Anfang an '
            'wirksam (§ 7 KSchG) – unabhängig davon, ob sie eigentlich angreifbar gewesen '
            'wäre.',
      ),
      ArticleSection(
        'Auch als Verhandlungsweg',
        'Die Klage dient nicht nur der Weiterbeschäftigung. Viele Verfahren enden mit '
            'einem Vergleich, in dem eine Abfindung vereinbart wird.',
      ),
    ],
    sources: ['§ 4 KSchG', '§ 7 KSchG'],
  ),

  // ------------------------------------------------------------------
  // Arbeitsagentur & Leistungen
  // ------------------------------------------------------------------
  Article(
    id: 'arbeitsuchend-melden',
    category: ArticleCategory.arbeitsagentur,
    title: 'Arbeitsuchend melden – so früh wie möglich',
    teaser: 'Versäumnis kann eine Sperrzeit auslösen. Die Meldung geht auch online.',
    sections: [
      ArticleSection(
        'Wann melden?',
        'Wer weiß, dass sein Arbeitsverhältnis endet, muss sich spätestens drei Monate '
            'vor dem Ende arbeitsuchend melden. Liegen zwischen Kenntnis und Ende weniger '
            'als drei Monate, muss die Meldung innerhalb von drei Tagen nach Kenntnis '
            'erfolgen (§ 38 SGB III).',
      ),
      ArticleSection(
        'Wie melden?',
        'Die Arbeitsuchendmeldung ist telefonisch, persönlich oder online über die '
            'Website der Bundesagentur für Arbeit möglich. Sie ist etwas anderes als die '
            'spätere Arbeitslosmeldung.',
      ),
      ArticleSection(
        'Warum das wichtig ist',
        'Eine verspätete Meldung kann als Meldeversäumnis eine Sperrzeit nach sich '
            'ziehen (§ 159 SGB III) und damit den ALG-Bezug verkürzen.',
      ),
    ],
    sources: ['§ 38 SGB III', '§ 159 SGB III'],
  ),
  Article(
    id: 'alg1-vs-buergergeld',
    category: ArticleCategory.arbeitsagentur,
    title: 'ALG 1 oder Bürgergeld (ALG 2)?',
    teaser: 'Versicherungsleistung gegen Grundsicherung – die wichtigsten Unterschiede.',
    sections: [
      ArticleSection(
        'ALG 1: Versicherungsleistung',
        'Arbeitslosengeld 1 ist eine Leistung der Arbeitslosenversicherung (SGB III). '
            'Voraussetzung ist eine Anwartschaftszeit von in der Regel zwölf '
            'Versicherungsmonaten. Die Höhe beträgt 60 % (mit Kind 67 %) des '
            'pauschalierten Nettoentgelts, die Dauer richtet sich nach Alter und '
            'Versicherungszeit.',
      ),
      ArticleSection(
        'Bürgergeld: Grundsicherung',
        'Das Bürgergeld (SGB II, früher „ALG 2"/Hartz IV) sichert den Lebensunterhalt '
            'unabhängig von früherer Beschäftigung. Es ist bedürftigkeitsabhängig – '
            'Einkommen und Vermögen der Bedarfsgemeinschaft werden geprüft.',
      ),
      ArticleSection(
        'Der Übergang',
        'Wer keinen oder keinen ausreichenden ALG-1-Anspruch hat oder dessen Anspruch '
            'ausläuft, kann ergänzend oder anschließend Bürgergeld beziehen.',
      ),
    ],
    sources: ['§ 149 SGB III', '§ 147 SGB III', 'SGB II'],
  ),
  Article(
    id: 'arbeitslos-melden',
    category: ArticleCategory.arbeitsagentur,
    title: 'Arbeitslos melden und ALG 1 beantragen',
    teaser: 'Ab dem ersten Tag ohne Beschäftigung – und welche Unterlagen du brauchst.',
    sections: [
      ArticleSection(
        'Ab dem ersten Tag',
        'Die Arbeitslosmeldung erfolgt persönlich oder online mit Wirkung ab dem ersten '
            'Tag der Beschäftigungslosigkeit. Der Antrag auf Arbeitslosengeld kann online '
            'gestellt werden.',
      ),
      ArticleSection(
        'Wichtige Unterlagen',
        'Der Arbeitgeber übermittelt der Agentur eine Arbeitsbescheinigung (§ 312 '
            'SGB III). Hilfreich sind außerdem der Kündigungs- bzw. Aufhebungsvertrag und '
            'Nachweise über Vorbeschäftigungen.',
      ),
      ArticleSection(
        'Krankenversicherung nicht vergessen',
        'Mit dem ALG-Bezug besteht in der Regel Versicherungsschutz. In einer Lücke '
            'zwischen Job und Leistung sollte der Krankenversicherungsschutz aktiv '
            'geklärt werden.',
      ),
    ],
    sources: ['§ 312 SGB III', '§ 141 SGB III'],
  ),
];
