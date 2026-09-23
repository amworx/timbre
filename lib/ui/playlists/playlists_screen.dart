import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../navigation/app_navigator.dart';
import '../theme/timbre_theme.dart';

/// Playlists: user playlists plus prominent access to Favorites.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  TimbreSpacing.md, TimbreSpacing.sm, TimbreSpacing.sm, 0),
              child: Row(
                children: [
                  Text('Playlists',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'New playlist',
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _createPlaylist(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.playlists.isEmpty && state.favoriteSongs.isEmpty
                  ? EmptyState(
                      icon: Icons.queue_music_rounded,
                      title: 'No playlists yet',
                      body: 'Make a playlist for your next listening session.',
                      actionLabel: 'New playlist',
                      onAction: () => _createPlaylist(context),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(
                          top: TimbreSpacing.sm, bottom: 140),
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: TimbreSpacing.md),
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.favorite_rounded,
                                color:
                                    Theme.of(context).colorScheme.primary),
                          ),
                          title: const Text('Favorites',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              songsLabel(state.favoriteSongs.length)),
                          onTap: () => _openFavorites(context),
                        ),
                        const SizedBox(height: TimbreSpacing.xs),
                        for (final pl in state.playlists)
                          Dismissible(
                            key: ValueKey('playlist-${pl.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: AlignmentDirectional.centerEnd,
                              padding:
                                  const EdgeInsetsDirectional.only(end: 24),
                              color: Theme.of(context).colorScheme.error,
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Delete "${pl.name}"?'),
                                  content: const Text(
                                      'Songs stay in your library. This only removes the playlist.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel')),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete')),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) {
                              context.read<AppState>().deletePlaylist(pl.id);
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: TimbreSpacing.md),
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.queue_music_rounded,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                              title: Text(pl.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(songsLabel(pl.songCount)),
                              trailing: IconButton(
                                tooltip: 'Rename',
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _renamePlaylist(context, pl.id, pl.name),
                              ),
                              onTap: () => AppNavigator.openPlaylist(
                                  context, pl.id, pl.name),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFavorites(BuildContext context) {
    final state = context.read<AppState>();
    final favorites = state.favoriteSongs;
    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Favorite some songs to fill this list.')));
      return;
    }
    AppNavigator.openPlaylist(
        context, -1, 'Favorites'); // -1 signals the favorites view
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final name = await _askName(context, title: 'New playlist', hint: 'Playlist name');
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      await context.read<AppState>().createPlaylist(name.trim());
    }
  }

  Future<void> _renamePlaylist(BuildContext context, int id, String current) async {
    final name = await _askName(context,
        title: 'Rename playlist', hint: current, initial: current);
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      await context.read<AppState>().renamePlaylist(id, name.trim());
    }
  }
}

Future<String?> _askName(BuildContext context,
    {required String title, required String hint, String? initial}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
