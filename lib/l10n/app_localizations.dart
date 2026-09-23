import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Timbre'**
  String get appTitle;

  /// No description provided for @tabGuide.
  ///
  /// In en, this message translates to:
  /// **'GUIDE'**
  String get tabGuide;

  /// No description provided for @tabArchive.
  ///
  /// In en, this message translates to:
  /// **'ARCHIVE'**
  String get tabArchive;

  /// No description provided for @tabBank.
  ///
  /// In en, this message translates to:
  /// **'BANK'**
  String get tabBank;

  /// No description provided for @tabScan.
  ///
  /// In en, this message translates to:
  /// **'SCAN'**
  String get tabScan;

  /// No description provided for @gateNoSignal.
  ///
  /// In en, this message translates to:
  /// **'NO SIGNAL'**
  String get gateNoSignal;

  /// No description provided for @gateBody.
  ///
  /// In en, this message translates to:
  /// **'Your music stays on your device.\nGrant audio access so the receiver can scan your library.'**
  String get gateBody;

  /// No description provided for @gateScanCta.
  ///
  /// In en, this message translates to:
  /// **'SCAN FOR STATIONS'**
  String get gateScanCta;

  /// No description provided for @gateDeniedNote.
  ///
  /// In en, this message translates to:
  /// **'Timbre cannot browse or play music without this permission.'**
  String get gateDeniedNote;

  /// No description provided for @gateAccessOff.
  ///
  /// In en, this message translates to:
  /// **'Access is off'**
  String get gateAccessOff;

  /// No description provided for @gateAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Timbre needs permission to read audio files. Enable it in system settings, then come back.'**
  String get gateAccessBody;

  /// No description provided for @gateOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get gateOpenSettings;

  /// No description provided for @tipArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get tipArchive;

  /// No description provided for @tipScanner.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get tipScanner;

  /// No description provided for @tipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tipSettings;

  /// No description provided for @tuned.
  ///
  /// In en, this message translates to:
  /// **'TUNED'**
  String get tuned;

  /// No description provided for @stationArchive.
  ///
  /// In en, this message translates to:
  /// **'ARCHIVE'**
  String get stationArchive;

  /// No description provided for @stationFlow.
  ///
  /// In en, this message translates to:
  /// **'FLOW'**
  String get stationFlow;

  /// No description provided for @stationFavorites.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get stationFavorites;

  /// No description provided for @memoryBankPlaylists.
  ///
  /// In en, this message translates to:
  /// **'MEMORY BANK · PLAYLISTS'**
  String get memoryBankPlaylists;

  /// No description provided for @programGuide.
  ///
  /// In en, this message translates to:
  /// **'PROGRAM GUIDE'**
  String get programGuide;

  /// No description provided for @noTransmissions.
  ///
  /// In en, this message translates to:
  /// **'No transmissions found.\nAdd music to your device and pull to scan.'**
  String get noTransmissions;

  /// No description provided for @signalLost.
  ///
  /// In en, this message translates to:
  /// **'SIGNAL LOST'**
  String get signalLost;

  /// No description provided for @couldNotReadLibrary.
  ///
  /// In en, this message translates to:
  /// **'Could not read your library.'**
  String get couldNotReadLibrary;

  /// No description provided for @retryScan.
  ///
  /// In en, this message translates to:
  /// **'RETRY SCAN'**
  String get retryScan;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get now;

  /// No description provided for @flow.
  ///
  /// In en, this message translates to:
  /// **'FLOW'**
  String get flow;

  /// No description provided for @flowQueue.
  ///
  /// In en, this message translates to:
  /// **'Flow Queue'**
  String get flowQueue;

  /// No description provided for @flowMix.
  ///
  /// In en, this message translates to:
  /// **'A fresh mix from your library'**
  String get flowMix;

  /// No description provided for @onAir.
  ///
  /// In en, this message translates to:
  /// **'on air'**
  String get onAir;

  /// No description provided for @noFavoritesSnack.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet — tap the heart on any track'**
  String get noFavoritesSnack;

  /// No description provided for @tracks.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 track} other{{n} tracks}}'**
  String tracks(int n);

  /// No description provided for @queueArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get queueArchiveTitle;

  /// No description provided for @queueFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get queueFavoritesTitle;

  /// No description provided for @flowQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Flow · {title}'**
  String flowQueueTitle(String title);

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @tipRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh library'**
  String get tipRefresh;

  /// No description provided for @tabSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get tabSongs;

  /// No description provided for @tabAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get tabAlbums;

  /// No description provided for @tabArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get tabArtists;

  /// No description provided for @tabGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get tabGenres;

  /// No description provided for @tabFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get tabFolders;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load your music'**
  String get couldNotLoad;

  /// No description provided for @loadUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get loadUnknownError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your music will appear here'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'Timbre reads your device\'s audio library. Once music is found, it shows up instantly.'**
  String get emptyLibraryBody;

  /// No description provided for @scanLibrary.
  ///
  /// In en, this message translates to:
  /// **'Scan library'**
  String get scanLibrary;

  /// No description provided for @rescanDevice.
  ///
  /// In en, this message translates to:
  /// **'Rescan device music'**
  String get rescanDevice;

  /// No description provided for @songsFound.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No music found yet} =1{1 song found on this device} other{{n} songs found on this device}}'**
  String songsFound(int n);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @noSongsHere.
  ///
  /// In en, this message translates to:
  /// **'No songs here yet'**
  String get noSongsHere;

  /// No description provided for @songsWillShow.
  ///
  /// In en, this message translates to:
  /// **'Songs you add will show up in this list.'**
  String get songsWillShow;

  /// No description provided for @playlistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlistsTitle;

  /// No description provided for @tipNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get tipNewPlaylist;

  /// No description provided for @emptyPlaylistsTitle.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get emptyPlaylistsTitle;

  /// No description provided for @emptyPlaylistsBody.
  ///
  /// In en, this message translates to:
  /// **'Make a playlist for your next listening session.'**
  String get emptyPlaylistsBody;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @tipRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get tipRename;

  /// No description provided for @deletePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deletePlaylistTitle(String name);

  /// No description provided for @deletePlaylistBody.
  ///
  /// In en, this message translates to:
  /// **'Songs stay in your library. This only removes the playlist.'**
  String get deletePlaylistBody;

  /// No description provided for @newPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylistTitle;

  /// No description provided for @renamePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get renamePlaylistTitle;

  /// No description provided for @playlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameHint;

  /// No description provided for @favoriteSomeSnack.
  ///
  /// In en, this message translates to:
  /// **'Favorite some songs to fill this list.'**
  String get favoriteSomeSnack;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists, albums…'**
  String get searchHint;

  /// No description provided for @tipClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get tipClear;

  /// No description provided for @nothingToSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to search yet'**
  String get nothingToSearchTitle;

  /// No description provided for @nothingToSearchBody.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty. Scan your music first.'**
  String get nothingToSearchBody;

  /// No description provided for @browseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Browse your library'**
  String get browseLibrary;

  /// No description provided for @nothingFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFoundTitle;

  /// No description provided for @nothingFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Try another song, artist, or album.'**
  String get nothingFoundBody;

  /// No description provided for @secArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get secArtists;

  /// No description provided for @secAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get secAlbums;

  /// No description provided for @secGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get secGenres;

  /// No description provided for @secSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get secSongs;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// No description provided for @tipClearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue'**
  String get tipClearQueue;

  /// No description provided for @clearQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear queue?'**
  String get clearQueueTitle;

  /// No description provided for @clearQueueBody.
  ///
  /// In en, this message translates to:
  /// **'This stops playback and empties the queue.'**
  String get clearQueueBody;

  /// No description provided for @queueEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get queueEmptyTitle;

  /// No description provided for @queueEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Play a song to build a queue.'**
  String get queueEmptyBody;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get nowPlaying;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT'**
  String get upNext;

  /// No description provided for @tipAddFav.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get tipAddFav;

  /// No description provided for @tipRemoveFav.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get tipRemoveFav;

  /// No description provided for @tipMore.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get tipMore;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addToQueue;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist…'**
  String get addToPlaylist;

  /// No description provided for @addToPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylistTitle;

  /// No description provided for @addCountToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add {n} songs to playlist'**
  String addCountToPlaylist(int n);

  /// No description provided for @goToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Go to album'**
  String get goToAlbum;

  /// No description provided for @goToArtist.
  ///
  /// In en, this message translates to:
  /// **'Go to artist'**
  String get goToArtist;

  /// No description provided for @shareAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Share audio file'**
  String get shareAudioFile;

  /// No description provided for @deleteFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete from device'**
  String get deleteFromDevice;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete from device?'**
  String get confirmDeleteTitle;

  /// No description provided for @deleteOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" from this device?'**
  String deleteOneTitle(String title);

  /// No description provided for @deleteManyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {n} songs from this device?'**
  String deleteManyTitle(int n);

  /// No description provided for @deleteBody.
  ///
  /// In en, this message translates to:
  /// **'The audio files will be permanently removed.'**
  String get deleteBody;

  /// No description provided for @tipClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get tipClearSelection;

  /// No description provided for @selAllTotal.
  ///
  /// In en, this message translates to:
  /// **'All {n}'**
  String selAllTotal(int n);

  /// No description provided for @selCountAll.
  ///
  /// In en, this message translates to:
  /// **'{n} · All'**
  String selCountAll(int n);

  /// No description provided for @tipShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get tipShare;

  /// No description provided for @tipAddToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get tipAddToPlaylist;

  /// No description provided for @tipDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete from device'**
  String get tipDelete;

  /// No description provided for @audioNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Audio file not available for sharing.'**
  String get audioNotAvailable;

  /// No description provided for @nothingToShare.
  ///
  /// In en, this message translates to:
  /// **'Nothing to share.'**
  String get nothingToShare;

  /// No description provided for @couldNotDeleteSong.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this song.'**
  String get couldNotDeleteSong;

  /// No description provided for @deletedAll.
  ///
  /// In en, this message translates to:
  /// **'Deleted {n}.'**
  String deletedAll(int n);

  /// No description provided for @deletedPartial.
  ///
  /// In en, this message translates to:
  /// **'Deleted {done} of {total}.'**
  String deletedPartial(int done, int total);

  /// No description provided for @deleteNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Delete was not allowed.'**
  String get deleteNotAllowed;

  /// No description provided for @cannotDeleteHere.
  ///
  /// In en, this message translates to:
  /// **'This song cannot be deleted from here.'**
  String get cannotDeleteHere;

  /// No description provided for @shareOneText.
  ///
  /// In en, this message translates to:
  /// **'{title} — {artist}'**
  String shareOneText(String title, String artist);

  /// No description provided for @shareManyText.
  ///
  /// In en, this message translates to:
  /// **'{n} songs from Timbre'**
  String shareManyText(int n);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @listeningMemory.
  ///
  /// In en, this message translates to:
  /// **'Listening memory'**
  String get listeningMemory;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear listening history'**
  String get clearHistory;

  /// No description provided for @clearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Removes play counts, resume positions and Continue Listening.'**
  String get clearHistoryBody;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear listening history?'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryContent.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Favorites and playlists are kept.'**
  String get clearHistoryContent;

  /// No description provided for @librarySection.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get librarySection;

  /// No description provided for @updatesSection.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesSection;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @musicStaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Your music stays on your device'**
  String get musicStaysTitle;

  /// No description provided for @musicStaysBody.
  ///
  /// In en, this message translates to:
  /// **'Timbre reads audio files only to play them. No account, no tracking. Updates check GitHub only when you ask.'**
  String get musicStaysBody;

  /// No description provided for @aboutTimbre.
  ///
  /// In en, this message translates to:
  /// **'Timbre'**
  String get aboutTimbre;

  /// No description provided for @versionLine.
  ///
  /// In en, this message translates to:
  /// **'Version {v} · A calm offline music player'**
  String versionLine(String v);

  /// No description provided for @timbreVersion.
  ///
  /// In en, this message translates to:
  /// **'Timbre version'**
  String get timbreVersion;

  /// No description provided for @installedVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed: {v}'**
  String installedVersion(String v);

  /// No description provided for @checkUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkUpdates;

  /// No description provided for @checkUpdatesSub.
  ///
  /// In en, this message translates to:
  /// **'Compares with the latest GitHub release.'**
  String get checkUpdatesSub;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You’re up to date.'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update {v} available'**
  String updateAvailable(String v);

  /// No description provided for @installedTo.
  ///
  /// In en, this message translates to:
  /// **'Installed {cur} → {v}.'**
  String installedTo(String cur, String v);

  /// No description provided for @downloadInstall.
  ///
  /// In en, this message translates to:
  /// **'Download & Install'**
  String get downloadInstall;

  /// No description provided for @startingDownload.
  ///
  /// In en, this message translates to:
  /// **'Starting download…'**
  String get startingDownload;

  /// No description provided for @downloadDoneInstaller.
  ///
  /// In en, this message translates to:
  /// **'Download complete — opening installer… Tap Install to finish.'**
  String get downloadDoneInstaller;

  /// No description provided for @installedRestart.
  ///
  /// In en, this message translates to:
  /// **'Installed. Restart the app if it is still open.'**
  String get installedRestart;

  /// No description provided for @downloadCanceled.
  ///
  /// In en, this message translates to:
  /// **'Download canceled.'**
  String get downloadCanceled;

  /// No description provided for @allowInstalls.
  ///
  /// In en, this message translates to:
  /// **'Allow installs'**
  String get allowInstalls;

  /// No description provided for @installBlocked.
  ///
  /// In en, this message translates to:
  /// **'Android blocked the install. Allow “Install unknown apps” for Timbre, then retry.'**
  String get installBlocked;

  /// No description provided for @notifOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Background controls on'**
  String get notifOnTitle;

  /// No description provided for @notifOnBody.
  ///
  /// In en, this message translates to:
  /// **'Playback controls show on the lock screen and in notifications.'**
  String get notifOnBody;

  /// No description provided for @notifOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Background controls off'**
  String get notifOffTitle;

  /// No description provided for @notifOffBody.
  ///
  /// In en, this message translates to:
  /// **'Music still plays. Turn on notifications for lock-screen controls.'**
  String get notifOffBody;

  /// No description provided for @notifOffBodyDenied.
  ///
  /// In en, this message translates to:
  /// **'Music still plays. Enable notifications in system settings for lock-screen controls.'**
  String get notifOffBodyDenied;

  /// No description provided for @errNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection. Connect to the internet and retry.'**
  String get errNoConnection;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'Update check timed out. Check your connection and retry.'**
  String get errTimeout;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and retry.'**
  String get errNetwork;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates. Please retry.'**
  String get errGeneric;

  /// No description provided for @errNoReleases.
  ///
  /// In en, this message translates to:
  /// **'No releases published yet.'**
  String get errNoReleases;

  /// No description provided for @errRateLimit.
  ///
  /// In en, this message translates to:
  /// **'GitHub rate limit reached. Try again later.'**
  String get errRateLimit;

  /// No description provided for @errHttp.
  ///
  /// In en, this message translates to:
  /// **'Update check failed (HTTP {code}). Please retry.'**
  String errHttp(int code);

  /// No description provided for @errUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected update response. Please retry.'**
  String get errUnexpected;

  /// No description provided for @errNoApk.
  ///
  /// In en, this message translates to:
  /// **'Latest release has no installable APK.'**
  String get errNoApk;

  /// No description provided for @evtDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading update… {p}%'**
  String evtDownloading(String p);

  /// No description provided for @evtDownloadingPlain.
  ///
  /// In en, this message translates to:
  /// **'Downloading update…'**
  String get evtDownloadingPlain;

  /// No description provided for @evtInstalling.
  ///
  /// In en, this message translates to:
  /// **'Download complete — opening installer…'**
  String get evtInstalling;

  /// No description provided for @evtRunning.
  ///
  /// In en, this message translates to:
  /// **'An update is already running.'**
  String get evtRunning;

  /// No description provided for @evtPermDenied.
  ///
  /// In en, this message translates to:
  /// **'Install permission was denied.'**
  String get evtPermDenied;

  /// No description provided for @evtDownloadError.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Check your connection and retry.'**
  String get evtDownloadError;

  /// No description provided for @evtChecksumError.
  ///
  /// In en, this message translates to:
  /// **'Downloaded file failed integrity check. Retry.'**
  String get evtChecksumError;

  /// No description provided for @evtCanceled.
  ///
  /// In en, this message translates to:
  /// **'Download canceled.'**
  String get evtCanceled;

  /// No description provided for @evtInstallError.
  ///
  /// In en, this message translates to:
  /// **'Installation reported an error.'**
  String get evtInstallError;

  /// No description provided for @evtInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed.'**
  String get evtInstalled;

  /// No description provided for @evtInternal.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please retry.'**
  String get evtInternal;

  /// No description provided for @evtInternalDetail.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {d}'**
  String evtInternalDetail(String d);

  /// No description provided for @tipMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get tipMinimize;

  /// No description provided for @tipQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get tipQueue;

  /// No description provided for @tipSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get tipSleep;

  /// No description provided for @tipSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get tipSpeed;

  /// No description provided for @tipShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get tipShuffle;

  /// No description provided for @tipPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get tipPrevious;

  /// No description provided for @tipPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get tipPlay;

  /// No description provided for @tipPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get tipPause;

  /// No description provided for @tipNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tipNext;

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get repeatOne;

  /// No description provided for @sleepTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTitle;

  /// No description provided for @sleepEndOfTrack.
  ///
  /// In en, this message translates to:
  /// **'End of current track'**
  String get sleepEndOfTrack;

  /// No description provided for @sleepWillPauseEnd.
  ///
  /// In en, this message translates to:
  /// **'Will pause at the end of this track'**
  String get sleepWillPauseEnd;

  /// No description provided for @sleepPausingIn.
  ///
  /// In en, this message translates to:
  /// **'Pausing in {r}'**
  String sleepPausingIn(String r);

  /// No description provided for @minutesCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 minute} other{{n} minutes}}'**
  String minutesCount(int n);

  /// No description provided for @remainingShort.
  ///
  /// In en, this message translates to:
  /// **'{m} min {s} s'**
  String remainingShort(int m, String s);

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{s} s'**
  String secondsShort(int s);

  /// No description provided for @remainingWord.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remainingWord;

  /// No description provided for @speedTitle.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get speedTitle;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown album'**
  String get unknownAlbum;

  /// No description provided for @flowPlain.
  ///
  /// In en, this message translates to:
  /// **'Built from your library'**
  String get flowPlain;

  /// No description provided for @flowSocial.
  ///
  /// In en, this message translates to:
  /// **'Similar artist + your favorites'**
  String get flowSocial;

  /// No description provided for @flowRecent.
  ///
  /// In en, this message translates to:
  /// **'Similar artist + recent favorites'**
  String get flowRecent;

  /// No description provided for @flowArtist.
  ///
  /// In en, this message translates to:
  /// **'Built from this artist and your listening'**
  String get flowArtist;

  /// No description provided for @songsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No songs} =1{1 song} other{{n} songs}}'**
  String songsCount(int n);

  /// No description provided for @totalDuration.
  ///
  /// In en, this message translates to:
  /// **'{h, plural, =0{{m} min} other{{h} h {m} min}}'**
  String totalDuration(int h, int m);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
