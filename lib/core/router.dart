import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/providers.dart';
import '../features/history/history_screen.dart';
import '../features/live/live_screen.dart';
import '../features/session/session_screen.dart';
import '../features/settings/settings_screen.dart';
import '../ui/tokens.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => const LiveScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/history',
              builder: (_, _) => const HistoryScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      SessionScreen(sessionId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});

  final StatefulNavigationShell shell;

  static const _destinations = [
    (icon: Icons.graphic_eq_rounded, label: 'Live'),
    (icon: Icons.schedule_rounded, label: 'History'),
    (icon: Icons.tune_rounded, label: 'Settings'),
  ];

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    if (context.isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(current: shell.currentIndex, onSelect: _go),
            VerticalDivider(width: 1, color: c.line),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _destinations[i].icon,
                      label: _destinations[i].label,
                      selected: i == shell.currentIndex,
                      onTap: () => _go(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final color = selected ? c.brandText : c.faint;
    return Semantics(
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: selected ? c.brandSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 3),
                  Text(label, style: LtText.label.copyWith(letterSpacing: 0, color: color)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.lt;
    final hasKey = ref.watch(apiKeyProvider).value?.isNotEmpty ?? false;
    return Container(
      width: 212,
      color: c.surface2,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 18),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(7)),
                    child: Text('Lt', style: TextStyle(color: c.onBrand, fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 9),
                  Text('Lt', style: LtText.rowTitle.copyWith(fontWeight: FontWeight.w700, color: c.ink)),
                ],
              ),
            ),
            for (var i = 0; i < _Shell._destinations.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _SideItem(
                  icon: _Shell._destinations[i].icon,
                  label: _Shell._destinations[i].label,
                  selected: i == current,
                  onTap: () => onSelect(i),
                ),
              ),
            const Spacer(),
            Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(LtRadius.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(LtRadius.sm),
                onTap: () => onSelect(2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: hasKey ? c.ok : c.warn, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasKey ? 'OpenAI key connected' : 'No OpenAI key',
                          style: LtText.meta.copyWith(fontSize: 12, color: c.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return Semantics(
      selected: selected,
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? c.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(LtRadius.sm),
          boxShadow: selected ? c.shadow : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(LtRadius.sm),
            onTap: onTap,
            child: SizedBox(
              height: 38,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(icon, size: 20, color: selected ? c.brand : c.muted),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: LtText.body.copyWith(fontSize: 13.5, color: selected ? c.ink : c.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
