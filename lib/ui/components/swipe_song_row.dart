import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../state/app_state.dart';
import 'song_row.dart';
import 'song_selection.dart';

/// Gmail-style swipe row: swipe right to share, swipe left to delete
/// (with confirmation). Delete animates the row out; share keeps it.
///
/// When [selection] is provided and active, swipes are disabled and taps
/// toggle selection instead of playing — long-press enters selection mode.
class SwipeSongRow extends StatelessWidget {
  final Song song;
  final List<Song> queueContext;
  final SongSelection? selection;
  final String keySuffix;
  final int? queueIndex;
  final bool showArtwork;

  /// Called after a successful delete so snapshot-based lists (detail
  /// screens) can refresh. Live lists (library) can pass null.
  final VoidCallback? onAfterDelete;

  const SwipeSongRow({
    super.key,
    required this.song,
    required this.queueContext,
    this.selection,
    this.keySuffix = '',
    this.queueIndex,
    this.showArtwork = true,
    this.onAfterDelete,
  });

  @override
  Widget build(BuildContext context) {
    final selection = this.selection;
    if (selection == null) {
      return _swipeable(context);
    }
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        if (selection.isSelecting) {
          final isSelected = selection.isSelected(song.id);
          return SongRow(
            song: song,
            queueContext: queueContext,
            queueIndex: queueIndex,
            showArtwork: showArtwork,
            selected: isSelected,
            onTapOverride: () => selection.toggle(song.id),
            onLongPressOverride: () => selection.toggle(song.id),
          );
        }
        return _swipeable(context);
      },
    );
  }

  Widget _swipeable(BuildContext context) {
    final selection = this.selection;
    return Dismissible(
      key: ValueKey('swipe-$keySuffix-${song.id}'),
      direction: DismissDirection.horizontal,
      background: _SwipeBackground(
        alignment: AlignmentDirectional.centerStart,
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.ios_share_rounded,
        label: 'Share',
      ),
      secondaryBackground: const _SwipeBackground(
        alignment: AlignmentDirectional.centerEnd,
        color: Colors.red,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _share(context);
          return false; // share keeps the row
        }
        return _delete(context);
      },
      child: SongRow(
        song: song,
        queueContext: queueContext,
        queueIndex: queueIndex,
        showArtwork: showArtwork,
        // Idle: default tap (play) + long-press enters selection mode.
        onLongPressOverride:
            selection == null ? null : () => selection.toggle(song.id),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await app.shareSongs([song]);
    if (outcome.attached == 0 && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(outcome.message ?? 'Nothing to share.')),
      );
    }
  }

  /// Returns true when the row should animate out (file actually deleted).
  Future<bool> _delete(BuildContext context) async {
    final confirmed = await confirmDeviceDelete(
      context,
      count: 1,
      songTitle: song.title,
    );
    if (!confirmed || !context.mounted) return false;
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final summary = await app.deleteSongs([song]);
    if (!context.mounted) return summary.deleted == 1;
    if (summary.deleted == 1) {
      onAfterDelete?.call();
      return true;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(summary.message ?? 'Could not delete this song.'),
      ),
    );
    return false;
  }
}

class _SwipeBackground extends StatelessWidget {
  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final start = alignment == AlignmentDirectional.centerStart;
    return Container(
      alignment: alignment,
      padding: EdgeInsetsDirectional.only(
        start: start ? 24 : 0,
        end: start ? 0 : 24,
      ),
      color: color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (start) ...[
            const Icon(Icons.ios_share_rounded, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          if (!start) ...[
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ],
      ),
    );
  }
}
