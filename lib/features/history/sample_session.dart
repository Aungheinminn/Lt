import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';

/// Debug-only data so the history and session screens can be tried without
/// recording anything.
Future<void> insertSampleSession(AppDatabase db) async {
  final id = const Uuid().v4();
  await db.createSession(id: id, sourceLang: 'en', targetLang: 'my');

  const lines = [
    (0, 2600, 'Good morning, thanks for coming in today.', 'မင်္ဂလာနံနက်ခင်းပါ၊ ဒီနေ့ လာတဲ့အတွက် ကျေးဇူးတင်ပါတယ်။'),
    (4800, 7000, "Let's finalize the contract.", 'စာချုပ်ကို အပြီးသတ်ကြရအောင်။'),
    (10600, 12200, 'Can you send it by Friday?', 'သောကြာနေ့မတိုင်ခင် ပို့ပေးနိုင်မလား။'),
  ];
  var i = 0;
  for (final (start, end, original, translated) in lines) {
    await db.upsertLine(
      id,
      'item_${i++}',
      LinesCompanion(
        startMs: Value(start),
        endMs: Value(end),
        originalText: Value(original),
        translatedText: Value(translated),
      ),
    );
  }
  await db.updateSession(
    id,
    const SessionsCompanion(
      title: Value('Meeting with client'),
      durationMs: Value(12500),
      status: Value(SessionStatus.complete),
    ),
  );
}
