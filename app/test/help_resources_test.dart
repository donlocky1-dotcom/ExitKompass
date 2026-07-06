import 'package:exitkompass_app/content/help_resources.dart';
import 'package:flutter_test/flutter_test.dart';

/// The risk-flag codes the M5 aggregator can emit. `highlightFlags` must only
/// reference these, otherwise a resource could never light up (typo guard).
const _knownFlagCodes = {
  'freistellung',
  'fuenftel_erstattung',
  'ruhen_158',
  'sperrzeit_eigenkuendigung',
  'sperrzeit_unwahrscheinlich',
  'sperrzeit_wahrscheinlich',
  'alg_gedeckelt',
  'kv_luecke',
};

void main() {
  group('help resources integrity', () {
    test('ids are unique', () {
      final ids = helpResources.map((r) => r.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every resource has title, when, body and where-to-turn', () {
      for (final r in helpResources) {
        expect(r.title, isNotEmpty, reason: r.id);
        expect(r.when, isNotEmpty, reason: r.id);
        expect(r.body, isNotEmpty, reason: r.id);
        expect(r.whereToTurn, isNotEmpty, reason: r.id);
      }
    });

    test('highlight flags reference only real risk-flag codes', () {
      for (final r in helpResources) {
        expect(_knownFlagCodes.containsAll(r.highlightFlags), isTrue,
            reason: '${r.id} has an unknown highlight flag: ${r.highlightFlags}');
      }
    });

    test('a review date is set', () {
      expect(helpResourcesReviewedOn, isNotEmpty);
    });

    test('nothing here looks commercial (no http/affiliate links)', () {
      for (final r in helpResources) {
        final blob = '${r.body} ${r.whereToTurn}';
        expect(blob.contains('http'), isFalse, reason: r.id);
      }
    });
  });

  group('rankedHelpResources', () {
    test('with no flags keeps the neutral order and drops nothing', () {
      final ranked = rankedHelpResources(const {});
      expect(ranked, hasLength(helpResources.length));
      expect(ranked.map((r) => r.id), helpResources.map((r) => r.id));
    });

    test('never adds or removes entries', () {
      final ranked = rankedHelpResources({'kv_luecke', 'ruhen_158'});
      expect(ranked.map((r) => r.id).toSet(),
          helpResources.map((r) => r.id).toSet());
      expect(ranked, hasLength(helpResources.length));
    });

    test('kv_luecke moves the health-insurance entry to the front', () {
      final ranked = rankedHelpResources({'kv_luecke'});
      expect(ranked.first.id, 'krankenversicherung');
    });

    test('sperrzeit flag surfaces the Agentur entry before non-matching ones',
        () {
      final ranked = rankedHelpResources({'sperrzeit_wahrscheinlich'});
      final agenturPos = ranked.indexWhere((r) => r.id == 'arbeitsagentur');
      final rechtsschutzPos = ranked.indexWhere((r) => r.id == 'rechtsschutz');
      expect(agenturPos, lessThan(rechtsschutzPos));
    });

    test('isHighlightedFor matches the resource highlight flags', () {
      final kv = helpResources.firstWhere((r) => r.id == 'krankenversicherung');
      expect(kv.isHighlightedFor({'kv_luecke'}), isTrue);
      expect(kv.isHighlightedFor({'alg_gedeckelt'}), isFalse);
      expect(kv.isHighlightedFor(const {}), isFalse);
    });
  });
}
