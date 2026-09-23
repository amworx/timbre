import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/library_repository.dart';
import 'playback/timbre_audio_handler.dart';
import 'state/app_state.dart';
import 'ui/detail/detail_screen.dart';
import 'ui/navigation/app_navigator.dart';
import 'ui/queue/queue_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme/theme_controller.dart';
import 'ui/theme/timbre_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final themeController = ThemeController(
    switch (prefs.getString('settings.themeMode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    },
  );

  final db = await LibraryRepository.openDatabase();
  final query = OnAudioQuery();
  final library = LibraryRepository(query, db);

  final handler = await AudioService.init(
    builder: () => TimbreAudioHandler(library, query),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'app.timbre.timbre.playback',
      androidNotificationChannelName: 'Timbre playback',
      androidNotificationChannelDescription:
          'Controls for Timbre music playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(TimbreApp(
    library: library,
    query: query,
    handler: handler,
    themeController: themeController,
  ));
}

class TimbreApp extends StatelessWidget {
  final LibraryRepository library;
  final OnAudioQuery query;
  final TimbreAudioHandler handler;
  final ThemeController themeController;

  const TimbreApp({
    super.key,
    required this.library,
    required this.query,
    required this.handler,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LibraryRepository>.value(value: library),
        Provider<OnAudioQuery>.value(value: query),
        Provider<TimbreAudioHandler>.value(value: handler),
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(library: library, player: handler),
        ),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
      ],
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) => MaterialApp(
          title: 'Timbre',
          theme: TimbreTheme.light(),
          darkTheme: TimbreTheme.dark(),
          themeMode: themeController.mode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ar')],
          home: const AppShell(),
          routes: {
            AppNavigator.albumRoute: (context) => _DetailRoute(
                  kind: DetailKind.album,
                  args: ModalRoute.of(context)!.settings.arguments as Map?,
                ),
            AppNavigator.artistRoute: (context) => _DetailRoute(
                  kind: DetailKind.artist,
                  args: ModalRoute.of(context)!.settings.arguments as Map?,
                ),
            AppNavigator.genreRoute: (context) => _DetailRoute(
                  kind: DetailKind.genre,
                  args: ModalRoute.of(context)!.settings.arguments as Map?,
                ),
            AppNavigator.folderRoute: (context) => _DetailRoute(
                  kind: DetailKind.folder,
                  args: ModalRoute.of(context)!.settings.arguments as Map?,
                ),
            AppNavigator.playlistRoute: (context) => _DetailRoute(
                  kind: DetailKind.playlist,
                  args: ModalRoute.of(context)!.settings.arguments as Map?,
                ),
            AppNavigator.settingsRoute: (context) => const SettingsScreen(),
            AppNavigator.queueRoute: (context) => const QueueScreen(),
          },
        ),
      ),
    );
  }
}

class _DetailRoute extends StatelessWidget {
  final DetailKind kind;
  final Map? args;

  const _DetailRoute({required this.kind, required this.args});

  @override
  Widget build(BuildContext context) {
    return DetailScreen(
      kind: kind,
      id: args?['albumId'] as String? ??
          args?['artistId'] as String? ??
          args?['path'] as String? ??
          args?['id']?.toString(),
      title: (args?['name'] as String?) ?? '',
    );
  }
}
