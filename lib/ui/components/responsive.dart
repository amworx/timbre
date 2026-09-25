import 'package:flutter/material.dart';

/// Single source of truth for overlay geometry so lists never hide behind
/// the mini player / navigation bar and floating bars never overlap them —
/// on any screen size, density, gesture inset, or text scale.
///
/// The shell stacks (bottom-up): system gesture inset, [navBarHeight]
/// navigation bar, and the mini player ([miniPlayerHeight]) when a song is
/// active. Everything floating or padded above derives from here.
class TimbreOverlay {
  static const double navBarHeight = 68;
  static const double miniPlayerHeight = 66; // 58 content + 2×4 padding
  static const double gap = 12;
  static const double listTailGap = 16;

  /// Total bottom overlay a list must clear.
  static double bottomInset(BuildContext context,
      {required bool miniVisible}) {
    return MediaQuery.paddingOf(context).bottom +
        navBarHeight +
        (miniVisible ? miniPlayerHeight : 0);
  }

  /// Bottom padding for scrollable lists (overlay + breathing room).
  static double listBottomPadding(BuildContext context,
      {required bool miniVisible}) {
    return bottomInset(context, miniVisible: miniVisible) + listTailGap;
  }

  /// Bottom offset for floating bars (bulk actions) above the overlay.
  static double barBottom(BuildContext context,
      {required bool miniVisible}) {
    return bottomInset(context, miniVisible: miniVisible) + gap;
  }
}
