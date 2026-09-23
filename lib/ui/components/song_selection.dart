import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../state/app_state.dart';

/// Per-list multi-select state (bulk actions). Owned by the list screen,
/// never global: leaving the list drops the instance and the selection.
class SongSelection extends ChangeNotifier {
  final Set<int> _ids = {};

  Set<int> get ids => Set.unmodifiable(_ids);

  bool get isSelecting => _ids.isNotEmpty;

  int get count => _ids.length;

  bool isSelected(int id) => _ids.contains(id);

  void toggle(int id) {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
  }

  void selectAll(Iterable<int> ids) {
    _ids.addAll(ids);
    notifyListeners();
  }

  void clear() {
    if (_ids.isEmpty) return;
    _ids.clear();
    notifyListeners();
  }
}

/// Bottom offset for the bulk-action bar so it always floats clear of the
/// navigation bar (68), the mini player when one is showing (58 + padding),
/// and the system gesture inset — with a 12px breathing gap.
/// Pure so it stays unit-testable; callers feed real insets in.
double selectionBarBottom({
  required double systemBottom,
  required bool miniVisible,
}) =>
    systemBottom + 68 + (miniVisible ? 70 : 0) + 12;

/// Floating bulk-action bar (Gmail-style contextual actions). Slides and
/// fades in above the mini player while [visible]; hidden otherwise.
class SelectionActionBar extends StatelessWidget {
  final bool visible;
  final int selectedCount;
  final int totalCount;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onShare;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onDelete;

  const SelectionActionBar({
    super.key,
    required this.visible,
    required this.selectedCount,
    required this.totalCount,
    required this.busy,
    required this.onClose,
    required this.onSelectAll,
    required this.onShare,
    required this.onAddToPlaylist,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final strings = t(context);
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1.6),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(20),
            color: cs.inverseSurface,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: strings.tipClearSelection,
                    onPressed: busy ? null : onClose,
                    icon: Icon(Icons.close_rounded,
                        color: cs.onInverseSurface),
                  ),
                  GestureDetector(
                    onTap: busy ? null : onSelectAll,
                    child: Text(
                      selectedCount == totalCount && totalCount > 0
                          ? strings.selAllTotal(totalCount)
                          : strings.selCountAll(selectedCount),
                      style: TextStyle(
                        color: cs.onInverseSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: strings.tipShare,
                    onPressed: busy ? null : onShare,
                    icon: Icon(Icons.ios_share_rounded,
                        color: cs.onInverseSurface),
                  ),
                  IconButton(
                    tooltip: strings.tipAddToPlaylist,
                    onPressed: busy ? null : onAddToPlaylist,
                    icon: Icon(Icons.playlist_add_rounded,
                        color: cs.onInverseSurface),
                  ),
                  IconButton(
                    tooltip: strings.tipDelete,
                    onPressed: busy ? null : onDelete,
                    icon: Icon(Icons.delete_outline_rounded,
                        color: cs.error),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirms a device-file delete. Returns true when the user accepts.
/// [count] == 1 names the song; otherwise the count is shown.
Future<bool> confirmDeviceDelete(
  BuildContext context,
  AppLocalizations t, {
  required int count,
  String? songTitle,
}) async {
  final title = count == 1 && songTitle != null
      ? t.deleteOneTitle(songTitle)
      : t.deleteManyTitle(count);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.confirmDeleteTitle),
      content: Text(
        '$title\n\n${t.deleteBody}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(t.delete),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// One-line snackbar text for a bulk/single delete result.
String deleteResultText(
    AppLocalizations t, DeleteSummary summary, int total) {
  if (summary.deleted == total) return t.deletedAll(summary.deleted);
  if (summary.deleted > 0) return t.deletedPartial(summary.deleted, total);
  return summary.message ?? t.couldNotDeleteSong;
}
