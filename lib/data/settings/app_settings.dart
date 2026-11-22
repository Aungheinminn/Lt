import 'package:material_ui/material_ui.dart';

import '../db/tables.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.sourceLang = 'en',
    this.targetLang = 'my',
    this.saveAudio = true,
    this.speakTranslation = false,
    this.audioRetentionDays = 0,
    this.mode = SessionMode.captions,
  });

  final ThemeMode themeMode;
  final String sourceLang;
  final String targetLang;
  final bool saveAudio;
  final bool speakTranslation;

  /// 0 keeps audio forever.
  final int audioRetentionDays;
  final SessionMode mode;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? sourceLang,
    String? targetLang,
    bool? saveAudio,
    bool? speakTranslation,
    int? audioRetentionDays,
    SessionMode? mode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      saveAudio: saveAudio ?? this.saveAudio,
      speakTranslation: speakTranslation ?? this.speakTranslation,
      audioRetentionDays: audioRetentionDays ?? this.audioRetentionDays,
      mode: mode ?? this.mode,
    );
  }
}
