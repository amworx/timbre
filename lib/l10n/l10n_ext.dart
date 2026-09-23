import 'package:flutter/widgets.dart';

import '../domain/models.dart';
import 'app_localizations.dart';

/// Shorthand for the current locale's strings. Every screen uses this.
AppLocalizations t(BuildContext context) => AppLocalizations.of(context);

/// Data-layer fallbacks are stored in English; translate them at the edge.
String displayArtist(Song song, AppLocalizations t) =>
    song.artist == kUnknownArtist ? t.unknownArtist : song.artist;

String displayAlbum(Song song, AppLocalizations t) =>
    song.album == kUnknownAlbum ? t.unknownAlbum : song.album;
