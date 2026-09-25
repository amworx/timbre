import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timbre/l10n/app_localizations.dart';
import 'package:timbre/ui/components/responsive.dart';
import 'package:timbre/ui/components/song_selection.dart';

/// Test app shell with real localization delegates (widgets under test
/// read translated strings via `t(context)`).
Widget testApp(Widget child) => MaterialApp(
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

Widget overlayProbe({
  required double systemBottom,
  required bool miniVisible,
  required void Function(double inset, double list, double bar) onMetrics,
}) {
  return MediaQuery(
    data: MediaQueryData(
      padding: EdgeInsets.only(bottom: systemBottom),
      size: const Size(360, 640),
    ),
    child: Builder(builder: (context) {
      onMetrics(
        TimbreOverlay.bottomInset(context, miniVisible: miniVisible),
        TimbreOverlay.listBottomPadding(context, miniVisible: miniVisible),
        TimbreOverlay.barBottom(context, miniVisible: miniVisible),
      );
      return const SizedBox.shrink();
    }),
  );
}

void main() {
  group('TimbreOverlay', () {
    testWidgets('no mini player: clears nav + inset with room to spare',
        (tester) async {
      double? inset;
      double? list;
      double? bar;
      await tester.pumpWidget(overlayProbe(
        systemBottom: 24,
        miniVisible: false,
        onMetrics: (i, l, b) {
          inset = i;
          list = l;
          bar = b;
        },
      ));
      expect(inset, 24 + 68);
      expect(list, greaterThan(inset!));
      expect(bar, greaterThan(inset!));
      expect(bar, lessThanOrEqualTo(list!));
    });

    testWidgets('mini player adds its height on top', (tester) async {
      double? withMini;
      double? withoutMini;
      await tester.pumpWidget(overlayProbe(
        systemBottom: 0,
        miniVisible: true,
        onMetrics: (i, _, _) => withMini = i,
      ));
      await tester.pumpWidget(overlayProbe(
        systemBottom: 0,
        miniVisible: false,
        onMetrics: (i, _, _) => withoutMini = i,
      ));
      expect(withMini! - withoutMini!,
          TimbreOverlay.miniPlayerHeight);
    });
  });

  group('SelectionActionBar small screens', () {
    Future<void> pumpBar(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testApp(
          Stack(
            children: [
              Positioned(
                left: 16,
                right: 16,
                bottom: 150,
                child: SelectionActionBar(
                  visible: true,
                  selectedCount: 12,
                  totalCount: 120,
                  busy: false,
                  onClose: () {},
                  onSelectAll: () {},
                  onShare: () {},
                  onAddToPlaylist: () {},
                  onDelete: () {},
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('320pt wide renders without overflow', (tester) async {
      await pumpBar(tester, 320);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders mirrored in RTL without overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 150,
                    child: SelectionActionBar(
                      visible: true,
                      selectedCount: 3,
                      totalCount: 18,
                      busy: false,
                      onClose: () {},
                      onSelectAll: () {},
                      onShare: () {},
                      onAddToPlaylist: () {},
                      onDelete: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
