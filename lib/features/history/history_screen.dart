import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/languages.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import 'sample_session.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: () => insertSampleSession(ref.read(databaseProvider)),
              icon: const Icon(Icons.add),
              label: const Text('Sample session'),
            )
          : null,
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load history: $e')),
        data: (items) => items.isEmpty
            ? const _Empty()
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => _SessionTile(items[i]),
              ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile(this.session);

  final Session session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final langs =
        '${languageFor(s.sourceLang).code.toUpperCase()} → ${languageFor(s.targetLang).code.toUpperCase()}';
    final minutes = (s.durationMs / 60000).ceil();
    final when = DateFormat.yMMMd().add_jm().format(s.createdAt);

    return ListTile(
      leading: Icon(s.starred ? Icons.star : Icons.graphic_eq),
      title: Text(s.title),
      subtitle: Text('$langs · $minutes min · $when'),
      trailing: s.status == SessionStatus.interrupted
          ? const Tooltip(message: 'Interrupted', child: Icon(Icons.warning_amber))
          : null,
      onTap: () => context.go('/history/${s.id}'),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No sessions yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Sessions you record on the Live tab show up here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
