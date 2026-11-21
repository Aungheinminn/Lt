import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider(sessionId)).value;
    final lines = ref.watch(linesProvider(sessionId));
    final db = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.title ?? ''),
        actions: [
          if (session != null)
            IconButton(
              tooltip: session.starred ? 'Unstar' : 'Star',
              icon: Icon(session.starred ? Icons.star : Icons.star_border),
              onPressed: () => db.updateSession(
                sessionId,
                SessionsCompanion(starred: Value(!session.starred)),
              ),
            ),
          IconButton(
            tooltip: 'Delete session',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete this session?'),
                  content: const Text('The transcript and audio will be removed from this device.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await db.deleteSession(sessionId);
                if (context.mounted) context.go('/history');
              }
            },
          ),
        ],
      ),
      body: lines.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load transcript: $e')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _LineTile(items[i]),
        ),
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile(this.line);

  final Line line;

  String _clock(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            _clock(line.startMs),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.originalText ?? '…', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 2),
              Text(
                line.translatedText ?? '…',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
