import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/pricing.dart';
import '../../openai/text_client.dart';
import '../../openai/transcription_client.dart';
import '../../ui/basics.dart';
import '../../ui/tokens.dart';

Future<void> showCostBreakdown(BuildContext context, SessionCost cost) {
  final body = _CostBreakdown(cost: cost);
  if (context.isWide) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(padding: const EdgeInsets.only(top: 20), child: body),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => body,
  );
}

class _CostBreakdown extends StatelessWidget {
  const _CostBreakdown({required this.cost});

  final SessionCost cost;

  static String _minutes(double seconds) {
    if (seconds < 60) return '${seconds.toStringAsFixed(seconds < 10 ? 1 : 0)} s';
    final m = seconds ~/ 60;
    final s = (seconds % 60).round().toString().padLeft(2, '0');
    return '$m:$s min';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final n = NumberFormat.decimalPattern();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Estimated cost', style: LtText.label.copyWith(color: c.faint)),
          const SizedBox(height: 4),
          Text(
            formatUsd(cost.total),
            style: LtText.title.copyWith(color: c.ink, fontFeatures: LtText.tabular),
          ),
          const SizedBox(height: 16),
          LtCard(
            color: c.surface2,
            child: Column(
              children: [
                _Row(
                  title: 'Transcription',
                  model: TranscriptionClient.model,
                  detail: '${_minutes(cost.transcribeSeconds)} of audio',
                  amount: cost.transcribe,
                ),
                Divider(color: c.line, indent: 14, endIndent: 14),
                _Row(
                  title: 'Translation and title',
                  model: OpenAiTextClient.model,
                  detail: '${n.format(cost.inputTokens)} in'
                      '${cost.cachedTokens > 0 ? ' (${n.format(cost.cachedTokens)} cached)' : ''}'
                      ' · ${n.format(cost.outputTokens)} out tokens',
                  amount: cost.translate,
                ),
                if (cost.speechSeconds > 0) ...[
                  Divider(color: c.line, indent: 14, endIndent: 14),
                  _Row(
                    title: 'Spoken translation',
                    model: OpenAiTextClient.speechModel,
                    detail: '${_minutes(cost.speechSeconds)} of speech',
                    amount: cost.speech,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on OpenAI list prices as of ${Pricing.asOf}. '
            'Your OpenAI usage page shows the exact charge.',
            style: LtText.meta.copyWith(color: c.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.model, required this.detail, required this.amount});

  final String title;
  final String model;
  final String detail;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LtText.body.copyWith(color: c.ink)),
                const SizedBox(height: 2),
                Text(model, style: LtText.meta.copyWith(color: c.faint, fontSize: 12)),
                const SizedBox(height: 2),
                Text(detail, style: LtText.meta.copyWith(color: c.muted, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatUsd(amount),
            style: LtText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600, fontFeatures: LtText.tabular),
          ),
        ],
      ),
    );
  }
}
