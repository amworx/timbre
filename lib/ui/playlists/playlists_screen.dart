import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../l10n/l10n_ext.dart';
import '../components/empty_state.dart';
import '../components/formatters.dart';
import '../components/responsive.dart';
import '../navigation/app_navigator.dart';
import '../theme/timbre_theme.dart';

/// Playlists: user playlists plus prominent access to Favorites.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = t(context);

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
                  Text(strings.playlistsTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  const Spacer(),
                  IconButton(
                    tooltip: strings.tipNewPlaylist,
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
                      title: strings.emptyPlaylistsTitle,
                      body: strings.emptyPlaylistsBody,
                      actionLabel: strings.tipNewPlaylist,
                      onAction: () => _createPlaylist(context),
                    )
                  : ListView(
                      padding: EdgeInsets.only(
                          top: TimbreSpacing.sm,
                          bottom: TimbreOverlay.listBottomPadding(context,
                              miniVisible: state.currentSong != null)),
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
                          title: Text(strings.favorites,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(songsLabel(
                              strings, state.favoriteSongs.length)),
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
                                builder: (context) {
                              final strings = t(context);
                              return AlertDialog(
                                title:
                                    Text(strings.deletePlaylistTitle(pl.name)),
                                content: Text(strings.deletePlaylistBody),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(strings.cancel)),
                                  FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(strings.delete)),
                                ],
                              );
                            },
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
                              subtitle: Text(
                                  songsLabel(strings, pl.songCount)),
                              trailing: IconButton(
                                tooltip: strings.tipRename,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t(context).favoriteSomeSnack)));
      return;
    }
    AppNavigator.openPlaylist(
        context, -1, t(context).favorites); // -1 signals the favorites view
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final strings = t(context);
    final name = await _askName(context,
        title: strings.newPlaylistTitle, hint: strings.playlistNameHint);
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      await context.read<AppState>().createPlaylist(name.trim());
    }
  }

  Future<void> _renamePlaylist(BuildContext context, int id, String current) async {
    final strings = t(context);
    final name = await _askName(context,
        title: strings.renamePlaylistTitle, hint: current, initial: current);
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
    builder: (context) {
      final strings = t(context);
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(strings.save),
          ),
        ],
      );
    },
  );
}
