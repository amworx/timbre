// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Timbre';

  @override
  String get tabGuide => 'GUIDE';

  @override
  String get tabArchive => 'ARCHIVE';

  @override
  String get tabBank => 'BANK';

  @override
  String get tabScan => 'SCAN';

  @override
  String get gateNoSignal => 'NO SIGNAL';

  @override
  String get gateBody =>
      'Your music stays on your device.\nGrant audio access so the receiver can scan your library.';

  @override
  String get gateScanCta => 'SCAN FOR STATIONS';

  @override
  String get gateDeniedNote =>
      'Timbre cannot browse or play music without this permission.';

  @override
  String get gateAccessOff => 'Access is off';

  @override
  String get gateAccessBody =>
      'Timbre needs permission to read audio files. Enable it in system settings, then come back.';

  @override
  String get gateOpenSettings => 'Open settings';

  @override
  String get tipArchive => 'Archive';

  @override
  String get tipScanner => 'Scanner';

  @override
  String get tipSettings => 'Settings';

  @override
  String get tuned => 'TUNED';

  @override
  String get stationArchive => 'ARCHIVE';

  @override
  String get stationFlow => 'FLOW';

  @override
  String get stationFavorites => 'FAVORITES';

  @override
  String get memoryBankPlaylists => 'MEMORY BANK · PLAYLISTS';

  @override
  String get programGuide => 'PROGRAM GUIDE';

  @override
  String get noTransmissions =>
      'No transmissions found.\nAdd music to your device and pull to scan.';

  @override
  String get signalLost => 'SIGNAL LOST';

  @override
  String get couldNotReadLibrary => 'Could not read your library.';

  @override
  String get retryScan => 'RETRY SCAN';

  @override
  String get now => 'NOW';

  @override
  String get flow => 'FLOW';

  @override
  String get flowQueue => 'Flow Queue';

  @override
  String get flowMix => 'A fresh mix from your library';

  @override
  String get onAir => 'on air';

  @override
  String get noFavoritesSnack =>
      'No favorites yet — tap the heart on any track';

  @override
  String tracks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get queueArchiveTitle => 'Archive';

  @override
  String get queueFavoritesTitle => 'Favorites';

  @override
  String flowQueueTitle(String title) {
    return 'Flow · $title';
  }

  @override
  String get libraryTitle => 'Library';

  @override
  String get tipRefresh => 'Refresh library';

  @override
  String get tabSongs => 'Songs';

  @override
  String get tabAlbums => 'Albums';

  @override
  String get tabArtists => 'Artists';

  @override
  String get tabGenres => 'Genres';

  @override
  String get tabFolders => 'Folders';

  @override
  String get couldNotLoad => 'Could not load your music';

  @override
  String get loadUnknownError => 'Unknown error';

  @override
  String get tryAgain => 'Try again';

  @override
  String get emptyLibraryTitle => 'Your music will appear here';

  @override
  String get emptyLibraryBody =>
      'Timbre reads your device\'s audio library. Once music is found, it shows up instantly.';

  @override
  String get scanLibrary => 'Scan library';

  @override
  String get rescanDevice => 'Rescan device music';

  @override
  String songsFound(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n songs found on this device',
      one: '1 song found on this device',
      zero: 'No music found yet',
    );
    return '$_temp0';
  }

  @override
  String get play => 'Play';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get noSongsHere => 'No songs here yet';

  @override
  String get songsWillShow => 'Songs you add will show up in this list.';

  @override
  String get playlistsTitle => 'Playlists';

  @override
  String get tipNewPlaylist => 'New playlist';

  @override
  String get emptyPlaylistsTitle => 'No playlists yet';

  @override
  String get emptyPlaylistsBody =>
      'Make a playlist for your next listening session.';

  @override
  String get favorites => 'Favorites';

  @override
  String get tipRename => 'Rename';

  @override
  String deletePlaylistTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deletePlaylistBody =>
      'Songs stay in your library. This only removes the playlist.';

  @override
  String get newPlaylistTitle => 'New playlist';

  @override
  String get renamePlaylistTitle => 'Rename playlist';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String get favoriteSomeSnack => 'Favorite some songs to fill this list.';

  @override
  String get searchHint => 'Search songs, artists, albums…';

  @override
  String get tipClear => 'Clear';

  @override
  String get nothingToSearchTitle => 'Nothing to search yet';

  @override
  String get nothingToSearchBody =>
      'Your library is empty. Scan your music first.';

  @override
  String get browseLibrary => 'Browse your library';

  @override
  String get nothingFoundTitle => 'Nothing found';

  @override
  String get nothingFoundBody => 'Try another song, artist, or album.';

  @override
  String get secArtists => 'Artists';

  @override
  String get secAlbums => 'Albums';

  @override
  String get secGenres => 'Genres';

  @override
  String get secSongs => 'Songs';

  @override
  String get queueTitle => 'Queue';

  @override
  String get tipClearQueue => 'Clear queue';

  @override
  String get clearQueueTitle => 'Clear queue?';

  @override
  String get clearQueueBody => 'This stops playback and empties the queue.';

  @override
  String get queueEmptyTitle => 'Queue is empty';

  @override
  String get queueEmptyBody => 'Play a song to build a queue.';

  @override
  String get nowPlaying => 'NOW PLAYING';

  @override
  String get upNext => 'UP NEXT';

  @override
  String get tipAddFav => 'Add to favorites';

  @override
  String get tipRemoveFav => 'Remove from favorites';

  @override
  String get tipMore => 'More actions';

  @override
  String get playNext => 'Play next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get addToPlaylist => 'Add to playlist…';

  @override
  String get addToPlaylistTitle => 'Add to playlist';

  @override
  String addCountToPlaylist(int n) {
    return 'Add $n songs to playlist';
  }

  @override
  String get goToAlbum => 'Go to album';

  @override
  String get goToArtist => 'Go to artist';

  @override
  String get shareAudioFile => 'Share audio file';

  @override
  String get deleteFromDevice => 'Delete from device';

  @override
  String get confirmDeleteTitle => 'Delete from device?';

  @override
  String deleteOneTitle(String title) {
    return 'Delete \"$title\" from this device?';
  }

  @override
  String deleteManyTitle(int n) {
    return 'Delete $n songs from this device?';
  }

  @override
  String get deleteBody => 'The audio files will be permanently removed.';

  @override
  String get tipClearSelection => 'Clear selection';

  @override
  String selAllTotal(int n) {
    return 'All $n';
  }

  @override
  String selCountAll(int n) {
    return '$n · All';
  }

  @override
  String get tipShare => 'Share';

  @override
  String get tipAddToPlaylist => 'Add to playlist';

  @override
  String get tipDelete => 'Delete from device';

  @override
  String get audioNotAvailable => 'Audio file not available for sharing.';

  @override
  String get nothingToShare => 'Nothing to share.';

  @override
  String get couldNotDeleteSong => 'Could not delete this song.';

  @override
  String deletedAll(int n) {
    return 'Deleted $n.';
  }

  @override
  String deletedPartial(int done, int total) {
    return 'Deleted $done of $total.';
  }

  @override
  String get deleteNotAllowed => 'Delete was not allowed.';

  @override
  String get cannotDeleteHere => 'This song cannot be deleted from here.';

  @override
  String shareOneText(String title, String artist) {
    return '$title — $artist';
  }

  @override
  String shareManyText(int n) {
    return '$n songs from Timbre';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get languageSection => 'Language';

  @override
  String get langSystem => 'System default';

  @override
  String get langEnglish => 'English';

  @override
  String get langArabic => 'Arabic';

  @override
  String get followSystem => 'Follow system';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get listeningMemory => 'Listening memory';

  @override
  String get clearHistory => 'Clear listening history';

  @override
  String get clearHistoryBody =>
      'Removes play counts, resume positions and Continue Listening.';

  @override
  String get clearHistoryTitle => 'Clear listening history?';

  @override
  String get clearHistoryContent =>
      'This cannot be undone. Favorites and playlists are kept.';

  @override
  String get librarySection => 'Library';

  @override
  String get updatesSection => 'Updates';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get aboutSection => 'About';

  @override
  String get musicStaysTitle => 'Your music stays on your device';

  @override
  String get musicStaysBody =>
      'Timbre reads audio files only to play them. No account, no tracking. Updates check GitHub only when you ask.';

  @override
  String get aboutTimbre => 'Timbre';

  @override
  String versionLine(String v) {
    return 'Version $v · A calm offline music player';
  }

  @override
  String get timbreVersion => 'Timbre version';

  @override
  String installedVersion(String v) {
    return 'Installed: $v';
  }

  @override
  String get checkUpdates => 'Check for updates';

  @override
  String get checkUpdatesSub => 'Compares with the latest GitHub release.';

  @override
  String get checking => 'Checking…';

  @override
  String get upToDate => 'You’re up to date.';

  @override
  String updateAvailable(String v) {
    return 'Update $v available';
  }

  @override
  String installedTo(String cur, String v) {
    return 'Installed $cur → $v.';
  }

  @override
  String get downloadInstall => 'Download & Install';

  @override
  String get startingDownload => 'Starting download…';

  @override
  String get downloadDoneInstaller =>
      'Download complete — opening installer… Tap Install to finish.';

  @override
  String get installedRestart =>
      'Installed. Restart the app if it is still open.';

  @override
  String get downloadCanceled => 'Download canceled.';

  @override
  String get allowInstalls => 'Allow installs';

  @override
  String get installBlocked =>
      'Android blocked the install. Allow “Install unknown apps” for Timbre, then retry.';

  @override
  String get notifOnTitle => 'Background controls on';

  @override
  String get notifOnBody =>
      'Playback controls show on the lock screen and in notifications.';

  @override
  String get notifOffTitle => 'Background controls off';

  @override
  String get notifOffBody =>
      'Music still plays. Turn on notifications for lock-screen controls.';

  @override
  String get notifOffBodyDenied =>
      'Music still plays. Enable notifications in system settings for lock-screen controls.';

  @override
  String get errNoConnection =>
      'No connection. Connect to the internet and retry.';

  @override
  String get errTimeout =>
      'Update check timed out. Check your connection and retry.';

  @override
  String get errNetwork => 'Network error. Check your connection and retry.';

  @override
  String get errGeneric => 'Could not check for updates. Please retry.';

  @override
  String get errNoReleases => 'No releases published yet.';

  @override
  String get errRateLimit => 'GitHub rate limit reached. Try again later.';

  @override
  String errHttp(int code) {
    return 'Update check failed (HTTP $code). Please retry.';
  }

  @override
  String get errUnexpected => 'Unexpected update response. Please retry.';

  @override
  String get errNoApk => 'Latest release has no installable APK.';

  @override
  String evtDownloading(String p) {
    return 'Downloading update… $p%';
  }

  @override
  String get evtDownloadingPlain => 'Downloading update…';

  @override
  String get evtInstalling => 'Download complete — opening installer…';

  @override
  String get evtRunning => 'An update is already running.';

  @override
  String get evtPermDenied => 'Install permission was denied.';

  @override
  String get evtDownloadError =>
      'Download failed. Check your connection and retry.';

  @override
  String get evtChecksumError =>
      'Downloaded file failed integrity check. Retry.';

  @override
  String get evtCanceled => 'Download canceled.';

  @override
  String get evtInstallError => 'Installation reported an error.';

  @override
  String get evtInstalled => 'Installed.';

  @override
  String get evtInternal => 'Something went wrong. Please retry.';

  @override
  String evtInternalDetail(String d) {
    return 'Something went wrong: $d';
  }

  @override
  String get tipMinimize => 'Minimize';

  @override
  String get tipQueue => 'Queue';

  @override
  String get tipSleep => 'Sleep timer';

  @override
  String get tipSpeed => 'Playback speed';

  @override
  String get tipShuffle => 'Shuffle';

  @override
  String get tipPrevious => 'Previous';

  @override
  String get tipPlay => 'Play';

  @override
  String get tipPause => 'Pause';

  @override
  String get tipNext => 'Next';

  @override
  String get repeatOff => 'Repeat off';

  @override
  String get repeatAll => 'Repeat all';

  @override
  String get repeatOne => 'Repeat one';

  @override
  String get sleepTitle => 'Sleep timer';

  @override
  String get sleepEndOfTrack => 'End of current track';

  @override
  String get sleepWillPauseEnd => 'Will pause at the end of this track';

  @override
  String sleepPausingIn(String r) {
    return 'Pausing in $r';
  }

  @override
  String minutesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String remainingShort(int m, String s) {
    return '$m min $s s';
  }

  @override
  String secondsShort(int s) {
    return '$s s';
  }

  @override
  String get remainingWord => 'remaining';

  @override
  String get speedTitle => 'Playback speed';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String get flowPlain => 'Built from your library';

  @override
  String get flowSocial => 'Similar artist + your favorites';

  @override
  String get flowRecent => 'Similar artist + recent favorites';

  @override
  String get flowArtist => 'Built from this artist and your listening';

  @override
  String songsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n songs',
      one: '1 song',
      zero: 'No songs',
    );
    return '$_temp0';
  }

  @override
  String totalDuration(int h, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      h,
      locale: localeName,
      other: '$h h $m min',
      zero: '$m min',
    );
    return '$_temp0';
  }

  @override
  String get filtersSection => 'Library filters';

  @override
  String get minDuration => 'Minimum duration';

  @override
  String get durAny => 'Any';

  @override
  String get dur15s => '15 sec';

  @override
  String get dur30s => '30 sec';

  @override
  String get dur1min => '1 min';

  @override
  String get dur2min => '2 min';

  @override
  String get hiddenFolders => 'Hidden folders';

  @override
  String get filtersOff => 'Everything is listed';

  @override
  String hiddenFoldersCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hidden folders',
      one: '1 hidden folder',
    );
    return '$_temp0';
  }

  @override
  String minActive(String label) {
    return '≥ $label';
  }

  @override
  String get folderTitle => 'Hidden folders';

  @override
  String get folderBody =>
      'Untick a folder to hide its audio from the library. Nothing is deleted.';

  @override
  String get hideMessaging => 'Hide WhatsApp & Telegram audio';

  @override
  String messagingHidden(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n messaging folders hidden',
      one: '1 messaging folder hidden',
    );
    return '$_temp0';
  }

  @override
  String get noMessagingFound => 'No messaging audio folders found.';

  @override
  String get showAll => 'Show all';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get clear => 'Clear';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';
}
