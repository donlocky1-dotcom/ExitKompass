import 'dart:convert';
import 'dart:io';

import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

void main() {
  group('params_2026.json', () {
    test('embedded copy is identical to lib/params/params_2026.json', () {
      final fileContent = File('lib/params/params_2026.json').readAsStringSync();
      expect(params2026Json, fileContent,
          reason: 'lib/src/params_2026_data.dart is stale - '
              'run python3 tool/embed_params.py');
    });

    test('JSON is valid and fully parseable', () {
      final params = ExitParams.year2026();
      expect(params.year, 2026);
    });

    test('key 2026 values (spot checks against the legal sources)', () {
      final p = ExitParams.year2026();
      // § 32a EStG 2026
      expect(p.tariff.basicAllowanceEuro, 12348);
      expect(p.tariff.zone2EndEuro, 17799);
      expect(p.tariff.zone3EndEuro, 69878);
      expect(p.tariff.zone4EndEuro, 277825);
      // Social insurance ceilings 2026
      expect(p.socialInsurance.ceilingHealthCareYearCents, 6975000);
      expect(p.socialInsurance.ceilingPensionUnempYearCents, 10140000);
      // Solidarity surcharge 2026
      expect(p.soli.exemptionSingleCents, 2035000);
      // Church tax: 8 % only in BY and BW
      expect(p.churchTax.rateFor(Bundesland.bayern), 0.08);
      expect(p.churchTax.rateFor(Bundesland.badenWuerttemberg), 0.08);
      expect(p.churchTax.rateFor(Bundesland.nordrheinWestfalen), 0.09);
      // ALG entitlement: 7 tiers, maximum 720 days from age 58
      expect(p.alg1.durationTable, hasLength(7));
      expect(p.alg1.durationTable.last.entitlementDays, 720);
      expect(p.alg1.durationTable.last.minAge, 58);
    });

    test('all 16 federal states have a church tax rate', () {
      final p = ExitParams.year2026();
      expect(p.churchTax.ratesByState.keys.toSet(), Bundesland.values.toSet());
    });

    test('no null placeholders (open TODO values) in the parameter set', () {
      final decoded = (jsonDecode(params2026Json) as Map).cast<String, dynamic>();
      final nullPaths = <String>[];
      void walk(Object? node, String path) {
        if (node == null) {
          nullPaths.add(path);
        } else if (node is Map) {
          node.forEach((k, v) => walk(v, '$path.$k'));
        } else if (node is List) {
          for (var i = 0; i < node.length; i++) {
            walk(node[i], '$path[$i]');
          }
        }
      }

      walk(decoded, r'$');
      expect(nullPaths, isEmpty,
          reason: 'null values are open TODOs and must be listed in ASSUMPTIONS.md');
    });
  });
}
