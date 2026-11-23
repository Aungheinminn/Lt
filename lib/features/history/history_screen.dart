import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../ui/basics.dart';
import '../../ui/session_row.dart';
import '../../ui/tokens.dart';
import 'sample_session.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _starredOnly = false;
  bool _searching = false;
  String _query = '';

  List<Session> _filter(List<Session> all) {
    final q = _query.trim().toLowerCase();
    return [
      for (final s in all)
        if ((!_starredOnly || s.starred) && (q.isEmpty || s.title.toLowerCase().contains(q))) s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final c = context.lt;
    final wide = context.isWide;
    final showSearch = wide || _searching;

    return Scaffold(
      body: SafeArea(
        child: ReadingColumn(
          child: sessions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load history',
              body: '$e',
            ),
            data: (all) {
              final items = _filter(all);
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, wide ? 24 : 8, 16, 0),
                    sliver: SliverList.list(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('History', style: LtText.title.copyWith(color: c.ink))),
                            if (kDebugMode)
                              TextButton.icon(
                                onPressed: () => insertSampleSession(ref.read(databaseProvider)),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Sample'),
                              ),
                            if (!wide)
                              RoundIconButton(
                                icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                                tooltip: _searching ? 'Close search' : 'Search',
                                filled: true,
                                onPressed: () => setState(() {
                                  _searching = !_searching;
                                  if (!_searching) _query = '';
                                }),
                              ),
                          ],
                        ),
                        if (showSearch) ...[
                          const SizedBox(height: 12),
                          TextField(
                            autofocus: _searching,
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Search sessions',
                              isDense: true,
                              prefixIcon: Icon(Icons.search_rounded, size: 20, color: c.faint),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            LtChip(
                              label: 'All',
                              height: 32,
                              tone: _starredOnly ? ChipTone.neutral : ChipTone.selected,
                              onTap: () => setState(() => _starredOnly = false),
                            ),
                            const SizedBox(width: 8),
                            LtChip(
                              label: 'Starred',
                              icon: Icons.star_rounded,
                              height: 32,
                              tone: _starredOnly ? ChipTone.selected : ChipTone.neutral,
                              onTap: () => setState(() => _starredOnly = true),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: all.isEmpty
                          ? const EmptyState(
                              icon: Icons.schedule_rounded,
                              title: 'No sessions yet',
                              body: 'Sessions you record on the Live tab show up here.',
                            )
                          : EmptyState(
                              icon: _starredOnly ? Icons.star_outline_rounded : Icons.search_off_rounded,
                              title: _starredOnly && _query.isEmpty ? 'No starred sessions' : 'Nothing matches',
                              body: _starredOnly && _query.isEmpty
                                  ? 'Star a session to keep it here.'
                                  : 'Try a different search.',
                            ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverList.list(
                        children: [
                          for (final (label, group) in _groupByDay(items))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SectionLabel(label),
                                LtCard(
                                  child: Column(
                                    children: [
                                      for (var i = 0; i < group.length; i++) ...[
                                        if (i > 0) const Divider(indent: 68),
                                        SessionRow(
                                          session: group[i],
                                          onTap: () => context.go('/history/${group[i].id}'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sessions arrive newest first; this keeps that order within each day.
List<(String, List<Session>)> _groupByDay(List<Session> sessions) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  String label(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return d.year == now.year ? DateFormat.MMMd().format(d) : DateFormat.yMMMd().format(d);
  }

  final groups = <(String, List<Session>)>[];
  for (final s in sessions) {
    final l = label(s.createdAt.toLocal());
    if (groups.isEmpty || groups.last.$1 != l) {
      groups.add((l, [s]));
    } else {
      groups.last.$2.add(s);
    }
  }
  return groups;
}
