import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n_ext.dart';
import '../../state/app_state.dart';

/// Playback speed sheet: 0.5x–2.0x.
Future<void> showSpeedSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => const _SpeedSheet(),
  );
}

class _SpeedSheet extends StatelessWidget {
  const _SpeedSheet();

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(t(context).speedTitle,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          RadioGroup<double>(
            groupValue: state.speed,
            onChanged: (v) {
              if (v != null) state.setSpeed(v);
              Navigator.pop(context);
            },
            child: Column(
              children: [
                for (final speed in _speeds)
                  RadioListTile<double>(
                    value: speed,
                    title: Text('${speed}x'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
