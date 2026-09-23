import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
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
    final strings = t(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(strings.sleepTitle,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          if (remaining != null)
            ListTile(
              leading: const Icon(Icons.bedtime_rounded),
              title: Text(remaining == -1
                  ? strings.sleepWillPauseEnd
                  : strings.sleepPausingIn(_remainingText(strings, remaining))),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  state.cancelSleepTimer();
                },
                child: Text(strings.cancel),
              ),
            ),
          const Divider(height: 1),
          for (final minutes in const [15, 30, 45, 60])
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(strings.minutesCount(minutes)),
              onTap: () {
                Navigator.pop(context);
                state.startSleepTimer(minutes);
              },
            ),
          ListTile(
            leading: const Icon(Icons.skip_next_rounded),
            title: Text(strings.sleepEndOfTrack),
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

String _remainingText(AppLocalizations strings, int ms) {
  final totalSeconds = (ms / 1000).round();
  final m = totalSeconds ~/ 60;
  if (m > 0) {
    return strings.remainingShort(m, (totalSeconds % 60).toString().padLeft(2, '0'));
  }
  return strings.secondsShort(totalSeconds);
}
