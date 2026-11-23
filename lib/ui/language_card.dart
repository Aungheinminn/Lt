import 'package:material_ui/material_ui.dart';

import '../core/languages.dart';
import 'basics.dart';
import 'tokens.dart';

class LanguageCard extends StatelessWidget {
  const LanguageCard({
    super.key,
    required this.source,
    required this.target,
    required this.onSource,
    required this.onTarget,
    required this.onSwap,
  });

  final String source;
  final String target;
  final ValueChanged<String> onSource;
  final ValueChanged<String> onTarget;
  final VoidCallback onSwap;

  Future<void> _pick(BuildContext context, String current, String title, ValueChanged<String> done) async {
    final code = await pickLanguage(context, selected: current, title: title);
    if (code != null) done(code);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    return LtCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _Side(
              caption: 'From',
              language: languageFor(source),
              onTap: () => _pick(context, source, 'Translate from', onSource),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: IconButton(
              tooltip: 'Swap languages',
              onPressed: onSwap,
              style: IconButton.styleFrom(
                backgroundColor: c.surface2,
                fixedSize: const Size.square(40),
              ),
              icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            ),
          ),
          Expanded(
            child: _Side(
              caption: 'To',
              language: languageFor(target),
              end: true,
              onTap: () => _pick(context, target, 'Translate to', onTarget),
            ),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.caption, required this.language, required this.onTap, this.end = false});

  final String caption;
  final Language language;
  final VoidCallback onTap;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final align = end ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return InkWell(
      borderRadius: BorderRadius.circular(LtRadius.md),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: align,
          children: [
            Text(caption.toUpperCase(), style: LtText.label.copyWith(color: c.faint)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    language.nativeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.35),
                  ),
                ),
                Icon(Icons.expand_more_rounded, size: 20, color: c.faint),
              ],
            ),
            Text(
              language.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LtText.meta.copyWith(color: c.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet on phones, dialog on wide windows.
Future<String?> pickLanguage(BuildContext context, {required String selected, required String title}) {
  final sheet = _LanguageSheet(selected: selected, title: title);
  if (context.isWide) {
    return showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: Padding(padding: const EdgeInsets.only(top: 16), child: sheet),
        ),
      ),
    );
  }
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(heightFactor: 0.8, child: sheet),
  );
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({required this.selected, required this.title});

  final String selected;
  final String title;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  String _query = '';

  bool _matches(Language l) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        l.name.toLowerCase().contains(q) ||
        l.nativeName.toLowerCase().contains(q) ||
        l.code == q;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final pinned = languages.where((l) => pinnedLanguageCodes.contains(l.code) && _matches(l)).toList();
    final rest = languages.where((l) => !pinnedLanguageCodes.contains(l.code) && _matches(l)).toList();

    Widget tile(Language l) {
      final sel = l.code == widget.selected;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Text(l.nativeName, style: LtText.body.copyWith(fontSize: 15.5, color: c.ink)),
        subtitle: l.name == l.nativeName ? null : Text(l.name, style: LtText.meta.copyWith(color: c.muted)),
        trailing: sel ? Icon(Icons.check_rounded, color: c.brand) : null,
        selected: sel,
        selectedTileColor: c.brandSoft,
        onTap: () => Navigator.pop(context, l.code),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(widget.title, style: LtText.heading.copyWith(fontSize: 19)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: context.isWide,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search languages',
              prefixIcon: Icon(Icons.search_rounded, color: c.faint, size: 20),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              if (pinned.isNotEmpty) ...[
                const SectionLabel('Pinned', padding: EdgeInsets.fromLTRB(20, 10, 20, 4)),
                ...pinned.map(tile),
              ],
              if (rest.isNotEmpty) ...[
                const SectionLabel('All languages', padding: EdgeInsets.fromLTRB(20, 14, 20, 4)),
                ...rest.map(tile),
              ],
              if (pinned.isEmpty && rest.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No language matches “$_query”.',
                      textAlign: TextAlign.center, style: LtText.original.copyWith(color: c.muted)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
