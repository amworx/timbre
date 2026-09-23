import 'package:flutter/material.dart';

import '../nowplaying/now_playing_sheet.dart';

/// Central place for navigation calls so screens stay decoupled from routes.
class AppNavigator {
  static const albumRoute = '/album';
  static const artistRoute = '/artist';
  static const genreRoute = '/genre';
  static const folderRoute = '/folder';
  static const playlistRoute = '/playlist';
  static const settingsRoute = '/settings';
  static const queueRoute = '/queue';

  static void openAlbum(BuildContext context, String albumId, String name) =>
      Navigator.pushNamed(context, albumRoute,
          arguments: {'albumId': albumId, 'name': name});

  static void openArtist(BuildContext context, String artistId, String name) =>
      Navigator.pushNamed(context, artistRoute,
          arguments: {'artistId': artistId, 'name': name});

  static void openGenre(BuildContext context, String name) =>
      Navigator.pushNamed(context, genreRoute, arguments: {'name': name});

  static void openFolder(BuildContext context, String path) =>
      Navigator.pushNamed(context, folderRoute, arguments: {'path': path});

  static void openPlaylist(BuildContext context, int id, String name) =>
      Navigator.pushNamed(context, playlistRoute,
          arguments: {'id': id, 'name': name});

  static void openSettings(BuildContext context) =>
      Navigator.pushNamed(context, settingsRoute);

  static void openQueue(BuildContext context) =>
      Navigator.pushNamed(context, queueRoute);

  static void openNowPlaying(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const NowPlayingSheet(),
    );
  }

  /// Shell tab switching: Home listens to this to move between
  /// Guide / Archive / Memory Bank / Scanner.
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);

  static void openLibraryTab(BuildContext context) => tab.value = 1;
  static void openSearchTab(BuildContext context) => tab.value = 3;
}
