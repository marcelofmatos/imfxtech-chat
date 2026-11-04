// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/account_config.dart';
import 'package:matrix/matrix.dart';

/// Plano de fundo de uma conversa, guardado no room account data do usuário
/// (só ele vê, e sincroniza entre os dispositivos dele).
class RoomWallpaper {
  static const String accountDataKey = 'com.imfxtech.chat.wallpaper';

  final Uri url;
  final double? opacity;
  final double? blur;

  const RoomWallpaper({required this.url, this.opacity, this.blur});

  /// Retorna null quando o conteúdo está ausente ou não tem uma url mxc
  /// válida — é assim que o fundo da conversa é removido (conteúdo vazio).
  static RoomWallpaper? fromJson(Map<String, dynamic>? json) {
    final rawUrl = json?['url'];
    if (rawUrl is! String) return null;
    final url = Uri.tryParse(rawUrl);
    if (url == null || url.scheme != 'mxc') return null;
    final opacity = json!.tryGet<double>('opacity');
    return RoomWallpaper(
      url: url,
      opacity: opacity != null && opacity >= 0 && opacity <= 1 ? opacity : null,
      blur: json.tryGet<double>('blur'),
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url.toString(),
    if (opacity != null) 'opacity': opacity,
    if (blur != null) 'blur': blur,
  };
}

/// Fundo da conversa → senão fundo global → senão nenhum. Opacidade e
/// desfoque não definidos na conversa herdam os valores globais.
RoomWallpaper? resolveChatWallpaper(
  RoomWallpaper? roomWallpaper,
  ApplicationAccountConfig global,
) {
  final url = roomWallpaper?.url ?? global.wallpaperUrl;
  if (url == null) return null;
  return RoomWallpaper(
    url: url,
    opacity: roomWallpaper?.opacity ?? global.wallpaperOpacity,
    blur: roomWallpaper?.blur ?? global.wallpaperBlur,
  );
}

/// Se o sync trouxe mudança no fundo desta conversa ou no fundo global.
bool isWallpaperUpdate(SyncUpdate update, String roomId) =>
    (update.rooms?.join?[roomId]?.accountData?.any(
          (event) => event.type == RoomWallpaper.accountDataKey,
        ) ??
        false) ||
    (update.accountData?.any(
          (event) =>
              event.type == ApplicationAccountConfigExtension.accountDataKey,
        ) ??
        false);

extension RoomWallpaperExtension on Room {
  RoomWallpaper? get roomWallpaper => RoomWallpaper.fromJson(
    roomAccountData[RoomWallpaper.accountDataKey]?.content,
  );

  RoomWallpaper? get chatWallpaper =>
      resolveChatWallpaper(roomWallpaper, client.applicationAccountConfig);

  Stream<SyncUpdate> get onWallpaperUpdate =>
      client.onSync.stream.where((update) => isWallpaperUpdate(update, id));

  Future<void> setRoomWallpaper(RoomWallpaper? wallpaper) =>
      client.setAccountDataPerRoom(
        client.userID!,
        id,
        RoomWallpaper.accountDataKey,
        wallpaper?.toJson() ?? {},
      );
}
