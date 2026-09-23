import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../l10n/l10n_ext.dart';
import '../components/artwork.dart';
import '../icons/broadcast_icons.dart';
import '../navigation/app_navigator.dart';
import '../theme/timbre_theme.dart';

/// Persistent tuner bar above the navigation bar — the compact receiver.
/// Appears only when a song is active; taps open the full receiver.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final song = state.currentSong;
    final cs = Theme.of(context).colorScheme;

    if (song == null) return const SizedBox.shrink();

    final strings = t(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          TimbreSpacing.sm, TimbreSpacing.xs, TimbreSpacing.sm, TimbreSpacing.xs),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => AppNavigator.openNowPlaying(context),
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Artwork(
                      albumId: song.albumId, title: song.album, size: 46, radius: 6),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: TimbreText.family,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 1.2,
                              color: cs.primary)),
                      const SizedBox(height: 2),
                      Text(displayArtist(song, t(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: TimbreText.family,
                              fontSize: 10.5,
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip:
                      state.isPlaying ? strings.tipPause : strings.tipPlay,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: BIcon(
                      state.isPlaying ? BIcons.pause : BIcons.play,
                      key: ValueKey(state.isPlaying),
                      size: 22,
                      color: cs.primary,
                      filled: true,
                    ),
                  ),
                  onPressed: state.togglePlayPause,
                ),
                IconButton(
                  tooltip: strings.tipNext,
                  icon: BIcon(BIcons.next, size: 22, color: cs.onSurface),
                  onPressed: state.hasNext ? state.next : null,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
