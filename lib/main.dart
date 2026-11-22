import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'data/providers.dart';
import 'session/background_recording.dart';
import 'session/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // just_audio has no native Windows backend; media_kit provides one.
  JustAudioMediaKit.ensureInitialized(windows: true, linux: false);
  BackgroundRecording.initCommunicationPort();
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();
  await recoverUnfinishedSessions(db);
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
    ],
    child: const LtApp(),
  ));
}
