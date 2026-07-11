import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'wizard.dart';
import 'workbook.dart';

const _kWizardKey = 'wizard_v1';
const _kWorkbookKey = 'workbook_v1';

/// Persists the wizard inputs to shared_preferences (localStorage on the web).
/// Used by the web preview, which has no Drift database.
class WizardPrefsStore implements WizardStore {
  @override
  Future<void> save(WizardData data) async {
    await SharedPreferencesAsync()
        .setString(_kWizardKey, jsonEncode(data.toJson()));
  }

  @override
  Future<void> clear() async {
    await SharedPreferencesAsync().remove(_kWizardKey);
  }

  static Future<WizardData?> load() async {
    try {
      final raw = await SharedPreferencesAsync().getString(_kWizardKey);
      if (raw == null) return null;
      return WizardData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// Persists the workbook answers to shared_preferences.
class WorkbookPrefsStore implements WorkbookStore {
  @override
  Future<void> save(String questionId, String answer) async {
    final prefs = SharedPreferencesAsync();
    final map = await _read(prefs);
    if (answer.isEmpty) {
      map.remove(questionId);
    } else {
      map[questionId] = answer;
    }
    if (map.isEmpty) {
      await prefs.remove(_kWorkbookKey);
    } else {
      await prefs.setString(_kWorkbookKey, jsonEncode(map));
    }
  }

  @override
  Future<void> clear() async {
    await SharedPreferencesAsync().remove(_kWorkbookKey);
  }

  static Future<Map<String, String>> load() async {
    try {
      return await _read(SharedPreferencesAsync());
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, String>> _read(SharedPreferencesAsync prefs) async {
    final raw = await prefs.getString(_kWorkbookKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in decoded.entries) e.key: e.value as String};
  }
}
