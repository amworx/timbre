import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n_ext.dart';
import '../../state/app_state.dart';

/// Which folders the library lists. Unchecked folders (e.g. WhatsApp voice
/// notes) vanish from songs, albums, artists and search — nothing is
/// deleted and everything can be re-enabled here.
class FolderFilterScreen extends StatelessWidget {
  const FolderFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final strings = t(context);
    final folders = state.allFolders;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.folderTitle),
        actions: [
          if (state.excludedFolders.isNotEmpty)
            TextButton(
              onPressed: () => state.showAllFolders(),
              child: Text(strings.showAll),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text(
              strings.folderBody,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonalIcon(
              onPressed: () async {
                final hidden = await state.hideMessagingAudio();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(hidden > 0
                        ? strings.messagingHidden(hidden)
                        : strings.noMessagingFound),
                  ),
                );
              },
              icon: const Icon(Icons.mark_chat_unread_outlined),
              label: Text(strings.hideMessaging),
            ),
          ),
          const SizedBox(height: 8),
          for (final folder in folders)
            CheckboxListTile(
              value: !state.excludedFolders.contains(folder.path),
              title: Text(folder.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${folder.path}\n${strings.songsCount(folder.songCount)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              secondary: const Icon(Icons.folder_outlined),
              onChanged: (checked) {
                if (checked == null) return;
                context
                    .read<AppState>()
                    .setFolderExcluded(folder.path, !checked);
              },
            ),
        ],
      ),
    );
  }
}
