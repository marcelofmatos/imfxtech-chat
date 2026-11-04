// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/room_wallpaper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';

class RoomWallpaperListTile extends StatelessWidget {
  final Room room;
  final VoidCallback onSet;
  final VoidCallback onRemove;

  const RoomWallpaperListTile({
    required this.room,
    required this.onSet,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder(
      stream: room.onWallpaperUpdate,
      builder: (context, _) => ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainer,
          foregroundColor: theme.textTheme.bodyLarge!.color,
          child: const Icon(Icons.wallpaper_outlined),
        ),
        title: Text(L10n.of(context).setWallpaper),
        subtitle: Text(L10n.of(context).chatWallpaperDescription),
        onTap: onSet,
        trailing: room.roomWallpaper == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outlined),
                color: theme.colorScheme.error,
                tooltip: L10n.of(context).removeChatWallpaper,
                onPressed: onRemove,
              ),
      ),
    );
  }
}
