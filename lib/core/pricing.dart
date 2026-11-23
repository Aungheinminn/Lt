import '../data/db/app_database.dart';

/// OpenAI list prices in USD, from https://developers.openai.com/api/docs/pricing.
/// Update these when OpenAI changes prices; costs are estimates either way.
abstract final class Pricing {
  static const asOf = 'November 2026';

  /// gpt-live-transcribe, billed by audio duration.
  static const transcribePerMinute = 0.017;

  /// gpt-5.4-mini, per 1M tokens.
  static const textInputPerM = 0.75;
  static const textCachedPerM = 0.075;
  static const textOutputPerM = 4.50;

  /// gpt-4o-mini-tts audio output is $12 per 1M tokens, about $0.015 per
  /// minute of speech. The API returns no usage for it, so it's estimated
  /// from the length of each clip.
  static const speechPerMinute = 0.015;
}

class SessionCost {
  SessionCost._(Session s)
      : transcribeSeconds = s.transcribeSeconds ?? 0,
        inputTokens = s.textInputTokens,
        cachedTokens = s.textCachedTokens,
        outputTokens = s.textOutputTokens,
        speechSeconds = s.speechSeconds;

  final double transcribeSeconds;
  final int inputTokens;
  final int cachedTokens;
  final int outputTokens;
  final double speechSeconds;

  /// Null for sessions recorded before usage tracking.
  static SessionCost? of(Session s) => s.transcribeSeconds == null ? null : SessionCost._(s);

  double get transcribe => transcribeSeconds / 60 * Pricing.transcribePerMinute;

  double get translate {
    final uncached = (inputTokens - cachedTokens).clamp(0, inputTokens);
    return (uncached * Pricing.textInputPerM +
            cachedTokens * Pricing.textCachedPerM +
            outputTokens * Pricing.textOutputPerM) /
        1e6;
  }

  double get speech => speechSeconds / 60 * Pricing.speechPerMinute;

  double get total => transcribe + translate + speech;
}

String formatUsd(double v) {
  if (v == 0) return r'$0.00';
  if (v < 0.001) return r'<$0.001';
  if (v < 0.01) return '\$${v.toStringAsFixed(3)}';
  return '\$${v.toStringAsFixed(2)}';
}
