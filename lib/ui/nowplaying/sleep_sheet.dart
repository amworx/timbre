import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

/// Sleep timer sheet: 15/30/45/60 min, end of track, cancel.
Future<void> showSleepSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => const _SleepSheet(),
  );
}

class _SleepSheet extends StatelessWidget {
  const _SleepSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final remaining = state.sleepRemainingMs;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('Sleep timer',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          if (remaining != null)
            ListTile(
              leading: const Icon(Icons.bedtime_rounded),
              title: Text(remaining == -1
                  ? 'Will pause at the end of this track'
                  : 'Pausing in ${remainingLabel(remaining)}'),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  state.cancelSleepTimer();
                },
                child: const Text('Cancel'),
              ),
            ),
          const Divider(height: 1),
          for (final minutes in const [15, 30, 45, 60])
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text('$minutes minutes'),
              onTap: () {
                Navigator.pop(context);
                state.startSleepTimer(minutes);
              },
            ),
          ListTile(
            leading: const Icon(Icons.skip_next_rounded),
            title: const Text('End of current track'),
            onTap: () {
              Navigator.pop(context);
              state.sleepAtEndOfTrack();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

String remainingLabel(int remainingMs) =>
    '${_fmt(remainingMs)} remaining';

String _fmt(int ms) {
  final totalSeconds = (ms / 1000).round();
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  if (m > 0) return '$m min ${s.toString().padLeft(2, '0')} s';
  return '$s s';
}
