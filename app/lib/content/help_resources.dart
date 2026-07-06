/// Curated, **non-commercial** pointers to real-world help ("Passende Hilfe").
///
/// Market-research note: competitor calculators monetise this moment with
/// affiliate links, ad placements or lawyer lead-generation. ExitKompass
/// deliberately does **not** – there is no tracking, no referral, no partner
/// broking here (privacy USP, one-time-purchase model, spec §8). Every entry
/// only names neutral or official bodies (Rechtsanwaltskammer, Amtsgericht,
/// Agentur für Arbeit, Krankenkasse) and stays general information, not
/// individual advice (RDG/StBerG line, see ASSUMPTIONS A8/A10).
library;

/// Content version / last editorial review of the help resources. Bump when
/// entries change so the "Stand" shown in the UI stays honest (mirrors the
/// Ratgeber's `contentReviewedOn`).
const String helpResourcesReviewedOn = 'Juli 2026';

/// One neutral place to turn to for help.
class HelpResource {
  const HelpResource({
    required this.id,
    required this.title,
    required this.when,
    required this.body,
    required this.whereToTurn,
    this.sources = const [],
    this.highlightFlags = const {},
  });

  final String id;
  final String title;

  /// One line on when this help is relevant (shown in the list).
  final String when;

  /// The main explanation – neutral, non-promotional.
  final String body;

  /// Where to actually find this help (only neutral/official bodies).
  final String whereToTurn;

  /// Legal sources (e.g. `§ 4 KSchG`), may be empty.
  final List<String> sources;

  /// [RiskFlag] codes (from the M5 aggregator) that make this resource
  /// especially relevant for the current user. Used only to order/badge the
  /// list – never to give an individual legal recommendation.
  final Set<String> highlightFlags;

  /// Whether any of the user's current [flagCodes] make this entry stand out.
  bool isHighlightedFor(Set<String> flagCodes) =>
      highlightFlags.intersection(flagCodes).isNotEmpty;
}

/// All help resources. Order here is the neutral default (shown when no
/// flags apply); [rankedHelpResources] moves the relevant ones to the top.
const List<HelpResource> helpResources = [
  HelpResource(
    id: 'fachanwalt',
    title: 'Fachanwalt für Arbeitsrecht',
    when: 'Kündigung oder Aufhebungsvertrag prüfen und die Abfindung verhandeln.',
    body: 'Ein Fachanwalt für Arbeitsrecht kann deine Kündigung oder den '
        'Aufhebungsvertrag prüfen, die Erfolgsaussichten einer '
        'Kündigungsschutzklage einschätzen und die Abfindung verhandeln. '
        'Wichtig ist die Drei-Wochen-Frist des § 4 KSchG: Nach Zugang einer '
        'schriftlichen Kündigung bleibt nur diese Zeit, um Klage zu erheben.',
    whereToTurn: 'Qualifizierte Kanzleien findest du über das amtliche '
        'Anwaltsverzeichnis der Bundesrechtsanwaltskammer oder die '
        'Rechtsanwaltskammer deines Bezirks. ExitKompass vermittelt keine '
        'Kanzleien und verdient nichts an diesem Hinweis.',
    sources: ['§ 4 KSchG', '§ 43c BRAO'],
    highlightFlags: {'sperrzeit_wahrscheinlich', 'ruhen_158'},
  ),
  HelpResource(
    id: 'rechtsschutz',
    title: 'Rechtsschutzversicherung prüfen',
    when: 'Bevor Beratungs- oder Prozesskosten entstehen.',
    body: 'Hast du eine Rechtsschutzversicherung mit Arbeitsrechtsschutz, '
        'übernimmt sie oft Anwalts- und Gerichtskosten. Prüfe die Wartezeit '
        '(meist drei Monate) und ob der Streitfall schon vor Vertragsbeginn '
        'angelegt war. Vor dem ersten Anwaltstermin lohnt sich eine '
        'Deckungsanfrage.',
    whereToTurn: 'Steht in deiner Police oder erfährst du direkt bei deiner '
        'Versicherung. ExitKompass empfiehlt keinen bestimmten Anbieter.',
  ),
  HelpResource(
    id: 'beratungshilfe',
    title: 'Beratungs- und Prozesskostenhilfe',
    when: 'Wenn anwaltliche Hilfe finanziell schwerfällt.',
    body: 'Mit geringem Einkommen kannst du beim örtlichen Amtsgericht einen '
        'Beratungshilfeschein für eine Erstberatung beantragen (Eigenanteil '
        'rund 15 €). Für ein Gerichtsverfahren gibt es Prozesskostenhilfe. '
        'Beides beantragst du beim Amtsgericht deines Wohnorts.',
    whereToTurn: 'Rechtsantragstelle des Amtsgerichts am Wohnort.',
    sources: ['BerHG', '§§ 114 ff. ZPO'],
  ),
  HelpResource(
    id: 'arbeitsagentur',
    title: 'Agentur für Arbeit: früh melden',
    when: 'Sobald du von der Beendigung erfährst.',
    body: 'Melde dich spätestens drei Tage nach Kenntnis vom Ende '
        'arbeitsuchend – bei mehr als drei Monaten Vorlauf spätestens drei '
        'Monate vorher (§ 38 SGB III), sonst droht eine Minderung. Zum ersten '
        'Tag der Beschäftigungslosigkeit meldest du dich arbeitslos '
        '(§ 141 SGB III). Beides geht online oder persönlich; die Agentur '
        'berät auch zu ALG und Weiterbildung.',
    whereToTurn: 'Agentur für Arbeit – online oder in der örtlichen '
        'Dienststelle.',
    sources: ['§ 38 SGB III', '§ 141 SGB III'],
    highlightFlags: {
      'sperrzeit_eigenkuendigung',
      'sperrzeit_wahrscheinlich',
      'ruhen_158',
      'alg_gedeckelt',
    },
  ),
  HelpResource(
    id: 'krankenversicherung',
    title: 'Krankenversicherung klären',
    when: 'Für Monate ohne Gehalt und ohne ALG.',
    body: 'Während des ALG-Bezugs bist du in der Regel über die Agentur '
        'versichert. In Lückenmonaten ohne Gehalt und ohne ALG musst du '
        'deinen Versicherungsschutz selbst sichern – etwa über die '
        'freiwillige Weiterversicherung oder die Familienversicherung. Melde '
        'dich früh bei deiner Krankenkasse; rückwirkende Lücken werden teuer. '
        'Privatversicherte haben eigene Regeln.',
    whereToTurn: 'Deine gesetzliche Krankenkasse bzw. dein privater '
        'Versicherer.',
    sources: ['§ 188 SGB V', '§ 5 SGB V'],
    highlightFlags: {'kv_luecke'},
  ),
  HelpResource(
    id: 'betriebsrat',
    title: 'Betriebsrat und Gewerkschaft',
    when: 'Wenn es einen Betriebsrat oder eine Gewerkschaft gibt.',
    body: 'Der Betriebsrat muss vor jeder Kündigung angehört werden '
        '(§ 102 BetrVG) – eine unterbliebene Anhörung macht die Kündigung '
        'unwirksam. Bist du Gewerkschaftsmitglied, gehören arbeitsrechtliche '
        'Beratung und Rechtsschutz meist zum Mitgliedsbeitrag.',
    whereToTurn: 'Betriebsrat im Unternehmen; deine Gewerkschaft.',
    sources: ['§ 102 BetrVG'],
  ),
];

/// Returns [helpResources] with the entries that match the user's current
/// [flagCodes] moved to the front (stable otherwise). Never drops or adds
/// entries – help is always fully available, just ordered by relevance.
List<HelpResource> rankedHelpResources(Set<String> flagCodes) {
  final highlighted = <HelpResource>[];
  final rest = <HelpResource>[];
  for (final r in helpResources) {
    (r.isHighlightedFor(flagCodes) ? highlighted : rest).add(r);
  }
  return [...highlighted, ...rest];
}
