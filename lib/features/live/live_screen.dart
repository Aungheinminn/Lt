import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../widgets/language_picker.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final hasKey = ref.watch(apiKeyProvider).value?.isNotEmpty ?? false;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Live')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!hasKey)
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.key),
                      title: const Text('Add your OpenAI API key'),
                      subtitle: const Text('Lt needs it to transcribe and translate.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/settings'),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LanguagePicker(
                        label: 'I speak',
                        value: settings.sourceLang,
                        onChanged: (v) => controller.setLanguages(source: v),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Swap languages',
                      icon: const Icon(Icons.swap_horiz),
                      onPressed: controller.swapLanguages,
                    ),
                    Expanded(
                      child: LanguagePicker(
                        label: 'Translate to',
                        value: settings.targetLang,
                        onChanged: (v) => controller.setLanguages(target: v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Center(
                  child: SizedBox.square(
                    dimension: 120,
                    child: FilledButton(
                      style: FilledButton.styleFrom(shape: const CircleBorder()),
                      onPressed: hasKey
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Live translation is the next feature to build.'),
                                ),
                              )
                          : null,
                      child: const Icon(Icons.mic, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to start',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  settings.saveAudio ? 'Audio will be saved' : 'Audio will not be saved',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
