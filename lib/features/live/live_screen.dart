import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/settings/app_settings.dart';
import '../../session/live_session.dart';
import '../../ui/basics.dart';
import '../../ui/language_card.dart';
import '../../ui/mic_button.dart';
import '../../ui/record_dock.dart';
import '../../ui/tokens.dart';
import '../../ui/transcript_line.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveSessionProvider);

    ref.listen(liveSessionProvider, (prev, next) {
      final messenger = ScaffoldMessenger.of(context);
      final saved = next.savedSessionId;
      if (saved != null && saved != prev?.savedSessionId) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.error ??
              (next.savedWithAudio ? 'Audio saved to History' : 'Transcript saved to History')),
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => context.go('/history/$saved'),
          ),
        ));
        ref.read(liveSessionProvider.notifier).clearMessage();
      } else if (next.error != null && next.error != prev?.error) {
        messenger.showSnackBar(SnackBar(content: Text(next.error!)));
        ref.read(liveSessionProvider.notifier).clearMessage();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: live.active && live.sessionId != null
            ? _LiveView(state: live)
            : _IdleView(connecting: live.phase == LivePhase.connecting),
      ),
    );
  }
}

class _IdleView extends ConsumerWidget {
  const _IdleView({required this.connecting});

  final bool connecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final hasKey = ref.watch(apiKeyProvider).value?.isNotEmpty ?? false;
    final c = context.lt;
    final wide = context.isWide;

    final micState = !hasKey
        ? MicState.disabled
        : connecting
            ? MicState.connecting
            : MicState.ready;

    return ReadingColumn(
      maxWidth: 560,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, wide ? 24 : 8, 16, 0),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Live', style: LtText.title.copyWith(color: c.ink))),
                    LtChip(
                      icon: settings.saveAudio ? Icons.save_rounded : Icons.save_outlined,
                      label: settings.saveAudio ? 'Audio on' : 'Audio off',
                      tone: settings.saveAudio ? ChipTone.neutral : ChipTone.warn,
                      onTap: () => controller.setSaveAudio(!settings.saveAudio),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!hasKey) ...[
                  LtBanner(
                    icon: Icons.key_rounded,
                    title: 'Connect OpenAI to start',
                    body: 'Your key stays on this device.',
                    actionLabel: 'Add key',
                    onAction: () => context.go('/settings'),
                  ),
                  const SizedBox(height: 12),
                ],
                LanguageCard(
                  source: settings.sourceLang,
                  target: settings.targetLang,
                  onSource: (v) => controller.setLanguages(source: v),
                  onTarget: (v) => controller.setLanguages(target: v),
                  onSwap: controller.swapLanguages,
                ),
                if (interpreterModeEnabled) ...[
                  const SizedBox(height: 12),
                  LtSegmented<SessionMode>(
                    segments: const [
                      (SessionMode.captions, 'Captions', Icons.subtitles_rounded),
                      (SessionMode.interpreter, 'Interpreter', Icons.record_voice_over_rounded),
                    ],
                    selected: settings.mode,
                    onChanged: connecting ? null : controller.setMode,
                  ),
                ],
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MicButton(
                    state: micState,
                    onPressed: () => ref.read(liveSessionProvider.notifier).start(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    switch (micState) {
                      MicState.disabled => 'Add a key to start',
                      MicState.connecting => 'Connecting…',
                      MicState.ready => wide ? 'Click to start' : 'Tap to start',
                    },
                    style: LtText.rowTitle.copyWith(fontSize: 17, color: c.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settings.mode == SessionMode.captions
                        ? 'Captions · sentence by sentence'
                        : 'Interpreter · lowest delay, approximate text',
                    style: LtText.original.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveView extends ConsumerStatefulWidget {
  const _LiveView({required this.state});

  final LiveState state;

  @override
  ConsumerState<_LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends ConsumerState<_LiveView> {
  final _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _followBottom(int count) {
    if (count == _lastCount) return;
    _lastCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final settings = ref.watch(settingsProvider);
    final lines = ref.watch(linesProvider(s.sessionId!)).value ?? const <Line>[];
    final stopping = s.phase == LivePhase.stopping;
    _followBottom(lines.length + s.partials.length);

    final status = stopping
        ? const LtChip(label: 'Finishing…')
        : s.speaking
            ? const LtChip(label: 'Hearing speech', tone: ChipTone.rec, pulse: true)
            : const LtChip(label: 'Listening', tone: ChipTone.brand, pulse: true);

    return ReadingColumn(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                status,
                const Spacer(),
                if (settings.mode == SessionMode.interpreter) ...[
                  const LtChip(label: 'Interpreter', icon: Icons.record_voice_over_rounded),
                  const SizedBox(width: 6),
                ],
                LtChip(
                  label: '${settings.sourceLang.toUpperCase()} → ${settings.targetLang.toUpperCase()}',
                ),
              ],
            ),
          ),
          if (s.reconnecting)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InlineNote(
                icon: Icons.wifi_off_rounded,
                busy: true,
                text: 'Reconnecting. Still recording, translations will catch up.',
              ),
            ),
          Expanded(
            child: lines.isEmpty
                ? EmptyState(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Start speaking',
                    body: 'Each sentence appears here with its translation.',
                  )
                : ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0, 0.06],
                    ).createShader(r),
                    blendMode: BlendMode.dstIn,
                    child: ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: lines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final l = lines[i];
                        return LiveLine(
                          original: l.originalText,
                          translation: l.translatedText,
                          partial: s.partials[l.itemId],
                          ended: l.endMs != null,
                        );
                      },
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: RecordDock(
                elapsedMs: s.elapsedMs,
                level: s.level,
                stopping: stopping,
                onStop: () => ref.read(liveSessionProvider.notifier).stop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
