import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

enum MicState { ready, connecting, disabled }

class MicButton extends StatelessWidget {
  const MicButton({super.key, required this.state, required this.onPressed, this.size = 132});

  final MicState state;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.lt;
    final on = state != MicState.disabled;
    final ring = on ? c.brand : c.line;

    Widget halo(double inset, double alpha) => Positioned.fill(
          left: -inset,
          top: -inset,
          right: -inset,
          bottom: -inset,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: on ? ring.withValues(alpha: alpha) : ring, width: 1.5),
            ),
          ),
        );

    return Semantics(
      button: true,
      enabled: state == MicState.ready,
      label: switch (state) {
        MicState.ready => 'Start',
        MicState.connecting => 'Connecting',
        MicState.disabled => 'Start (add an API key first)',
      },
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            halo(30, 0.10),
            halo(14, 0.22),
            Material(
              color: on ? c.brand : c.surface2,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: state == MicState.ready ? onPressed : null,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: on
                        ? [BoxShadow(color: c.brand.withValues(alpha: 0.45), blurRadius: 30, spreadRadius: -8, offset: const Offset(0, 10))]
                        : null,
                  ),
                  child: SizedBox.square(
                    dimension: size,
                    child: Center(
                      child: state == MicState.connecting
                          ? SizedBox.square(
                              dimension: 34,
                              child: CircularProgressIndicator(strokeWidth: 3, color: c.onBrand),
                            )
                          : Icon(Icons.mic_rounded, size: size * 0.4, color: on ? c.onBrand : c.faint),
                    ),
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
