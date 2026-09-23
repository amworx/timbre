import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../components/empty_state.dart';
import '../components/song_row.dart';
import '../theme/timbre_theme.dart';

/// Queue: Now Playing + Up Next. Drag to reorder, tap to jump, swipe or menu
/// to remove.
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final queue = state.queue;
    final currentSong = state.currentSong;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          if (queue.isNotEmpty)
            IconButton(
              tooltip: 'Clear queue',
              icon: const Icon(Icons.playlist_remove_rounded),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear queue?'),
                    content: const Text('This stops playback and empties the queue.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear')),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AppState>().clearQueue();
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: queue.isEmpty
          ? const EmptyState(
              icon: Icons.queue_music_outlined,
              title: 'Queue is empty',
              body: 'Play a song to build a queue.',
            )
          : SafeArea(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: TimbreSpacing.lg),
                itemCount: queue.length,
                onReorderItem: (oldIndex, newIndex) async {
                  await state.moveInQueue(oldIndex, newIndex);
                },
                proxyDecorator: (child, index, animation) => AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) => Material(
                    elevation: 4 * animation.value,
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  ),
                ),
                header: currentSong != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                            child: Text('NOW PLAYING',
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary)),
                          ),
                          SongRow(
                            key: const ValueKey('current'),
                            song: currentSong,
                            queueContext: queue,
                            queueIndex: state.queueIndex,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                            child: Text('UP NEXT',
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ),
                        ],
                      )
                    : null,
                itemBuilder: (context, i) {
                  final song = queue[i];
                  final isCurrent = currentSong?.id == song.id;
                  if (isCurrent) {
                    return SongRow(
                      key: ValueKey('current-${song.id}'),
                      song: song,
                      queueContext: queue,
                      queueIndex: i,
                    );
                  }
                  return Dismissible(
                    key: ValueKey('q-${song.id}-$i'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsetsDirectional.only(end: 24),
                      color: Theme.of(context).colorScheme.error,
                      child: const Icon(Icons.remove_circle_outline_rounded,
                          color: Colors.white),
                    ),
                    onDismissed: (_) => state.removeFromQueue(i),
                    child: SongRow(
                      key: ValueKey('q-$i-${song.id}'),
                      song: song,
                      queueContext: queue,
                      queueIndex: i,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
