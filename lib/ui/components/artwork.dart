import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models.dart';
import '../../state/app_state.dart';

/// In-memory memo of artwork futures, keyed by albumId + library generation.
/// Cleared whenever the library is rescanned.
class ArtworkMemo {
  static final Map<String, Future<File?>> _futures = {};
  static int _generation = 0;

  static void invalidate() {
    _generation++;
    _futures.clear();
  }

  static Future<File?> resolve(AppState state, String albumId) {
    final key = '$_generation/$albumId';
    return _futures.putIfAbsent(key, () => state.artwork(albumId));
  }
}

/// Rounded album artwork for [song]'s album (or [albumId] directly).
///
/// States: soft placeholder while loading; tinted initial when the file has
/// no embedded art; decoded image otherwise. Never stretches; always square.
class Artwork extends StatelessWidget {
  final String? albumId;
  final String title;
  final double size;
  final double radius;

  const Artwork({
    super.key,
    required this.albumId,
    required this.title,
    required this.size,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedAlbumId = albumId;

    Widget placeholder() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(radius),
          ),
          alignment: Alignment.center,
          child: Text(
            title.isNotEmpty ? title.characters.first.toUpperCase() : '♪',
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        );

    Widget imageWidget(File file) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, _, _) => placeholder(),
        ),
      );
    }

    if (resolvedAlbumId == null || resolvedAlbumId.isEmpty) {
      return placeholder();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: size, maxHeight: size),
      child: FutureBuilder<File?>(
        future: ArtworkMemo.resolve(context.read<AppState>(), resolvedAlbumId),
        builder: (context, snapshot) {
          final file = snapshot.data;
          if (snapshot.connectionState != ConnectionState.done || file == null) {
            return placeholder();
          }
          return imageWidget(file);
        },
      ),
    );
  }
}

/// Artwork for a specific song row (resolves by its album).
class SongArtwork extends StatelessWidget {
  final Song song;
  final double size;
  final double radius;

  const SongArtwork({super.key, required this.song, required this.size, this.radius = 10});

  @override
  Widget build(BuildContext context) {
    return Artwork(albumId: song.albumId, title: song.album, size: size, radius: radius);
  }
}
