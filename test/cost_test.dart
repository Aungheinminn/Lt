import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lt/core/pricing.dart';
import 'package:lt/data/db/app_database.dart';
import 'package:lt/openai/text_client.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Session> session(String id) =>
      (db.select(db.sessions)..where((s) => s.id.equals(id))).getSingle();

  test('usage from concurrent callbacks adds up', () async {
    await db.createSession(id: 's1', sourceLang: 'en', targetLang: 'my');
    await Future.wait([
      db.addUsage('s1', transcribeSeconds: 2.5),
      db.addUsage('s1', transcribeSeconds: 3.5),
      db.addUsage('s1', textInput: 300, textCached: 100, textOutput: 40),
      db.addUsage('s1', textInput: 200, textOutput: 10),
      db.addUsage('s1', speechSeconds: 4),
    ]);

    final s = await session('s1');
    expect(s.transcribeSeconds, 6);
    expect(s.textInputTokens, 500);
    expect(s.textCachedTokens, 100);
    expect(s.textOutputTokens, 50);
    expect(s.speechSeconds, 4);
  });

  test('cost uses the price of each model', () async {
    await db.createSession(id: 's1', sourceLang: 'en', targetLang: 'my');
    await db.addUsage(
      's1',
      transcribeSeconds: 120,
      textInput: 1000000,
      textCached: 200000,
      textOutput: 100000,
      speechSeconds: 60,
    );

    final cost = SessionCost.of(await session('s1'))!;
    expect(cost.transcribe, closeTo(0.034, 1e-9));
    expect(cost.translate, closeTo(0.8 * 0.75 + 0.2 * 0.075 + 0.1 * 4.5, 1e-9));
    expect(cost.speech, closeTo(0.015, 1e-9));
    expect(cost.total, closeTo(cost.transcribe + cost.translate + cost.speech, 1e-12));
  });

  test('sessions without tracked usage have no cost', () async {
    await db.createSession(id: 'old', sourceLang: 'en', targetLang: 'my');
    await db.updateSession('old', const SessionsCompanion(transcribeSeconds: Value(null)));
    await db.createSession(id: 'interp', sourceLang: 'en', targetLang: 'my', mode: SessionMode.interpreter);

    expect(SessionCost.of(await session('old')), isNull);
    expect(SessionCost.of(await session('interp')), isNull);
  });

  test('reads token usage from a Responses API body', () {
    final u = TextUsage.fromResponse({
      'usage': {
        'input_tokens': 320,
        'input_tokens_details': {'cached_tokens': 128},
        'output_tokens': 24,
      },
    })!;
    expect((u.input, u.cached, u.output), (320, 128, 24));
    expect(TextUsage.fromResponse({}), isNull);
  });

  test('formats small amounts readably', () {
    expect(formatUsd(0), r'$0.00');
    expect(formatUsd(0.0004), r'<$0.001');
    expect(formatUsd(0.0042), r'$0.004');
    expect(formatUsd(0.184), r'$0.18');
  });
}
