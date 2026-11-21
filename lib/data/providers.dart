import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/app_database.dart';
import 'settings/api_key_store.dart';
import 'settings/app_settings.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => ApiKeyStore());

class ApiKeyController extends AsyncNotifier<String?> {
  ApiKeyStore get _store => ref.read(apiKeyStoreProvider);

  @override
  Future<String?> build() => _store.readOpenAiKey();

  Future<void> save(String key) async {
    await _store.writeOpenAiKey(key);
    state = AsyncData(key.trim());
  }

  Future<void> clear() async {
    await _store.deleteOpenAiKey();
    state = const AsyncData(null);
  }
}

final apiKeyProvider =
    AsyncNotifierProvider<ApiKeyController, String?>(ApiKeyController.new);

class SettingsController extends Notifier<AppSettings> {
  static const _theme = 'theme_mode';
  static const _source = 'source_lang';
  static const _target = 'target_lang';
  static const _saveAudio = 'save_audio';
  static const _speak = 'speak_translation';
  static const _retention = 'audio_retention_days';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    const d = AppSettings();
    return AppSettings(
      themeMode: ThemeMode.values.asNameMap()[_prefs.getString(_theme)] ??
          d.themeMode,
      sourceLang: _prefs.getString(_source) ?? d.sourceLang,
      targetLang: _prefs.getString(_target) ?? d.targetLang,
      saveAudio: _prefs.getBool(_saveAudio) ?? d.saveAudio,
      speakTranslation: _prefs.getBool(_speak) ?? d.speakTranslation,
      audioRetentionDays: _prefs.getInt(_retention) ?? d.audioRetentionDays,
    );
  }

  void setThemeMode(ThemeMode v) {
    _prefs.setString(_theme, v.name);
    state = state.copyWith(themeMode: v);
  }

  void setLanguages({String? source, String? target}) {
    if (source != null) _prefs.setString(_source, source);
    if (target != null) _prefs.setString(_target, target);
    state = state.copyWith(sourceLang: source, targetLang: target);
  }

  void swapLanguages() =>
      setLanguages(source: state.targetLang, target: state.sourceLang);

  void setSaveAudio(bool v) {
    _prefs.setBool(_saveAudio, v);
    state = state.copyWith(saveAudio: v);
  }

  void setSpeakTranslation(bool v) {
    _prefs.setBool(_speak, v);
    state = state.copyWith(speakTranslation: v);
  }

  void setAudioRetentionDays(int v) {
    _prefs.setInt(_retention, v);
    state = state.copyWith(audioRetentionDays: v);
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

final sessionsProvider = StreamProvider<List<Session>>(
  (ref) => ref.watch(databaseProvider).watchSessions(),
);

final sessionProvider = StreamProvider.family<Session?, String>(
  (ref, id) => ref.watch(databaseProvider).watchSession(id),
);

final linesProvider = StreamProvider.family<List<Line>, String>(
  (ref, sessionId) => ref.watch(databaseProvider).watchLines(sessionId),
);
