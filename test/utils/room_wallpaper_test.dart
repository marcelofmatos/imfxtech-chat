// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/utils/account_config.dart';
import 'package:fluffychat/utils/room_wallpaper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

void main() {
  group('RoomWallpaper.fromJson', () {
    test('lê url, opacidade e desfoque', () {
      final wallpaper = RoomWallpaper.fromJson({
        'url': 'mxc://example.org/abc',
        'opacity': 0.3,
        'blur': 4.0,
      });
      expect(wallpaper?.url, Uri.parse('mxc://example.org/abc'));
      expect(wallpaper?.opacity, 0.3);
      expect(wallpaper?.blur, 4.0);
    });

    test('opacidade e desfoque são opcionais', () {
      final wallpaper = RoomWallpaper.fromJson({
        'url': 'mxc://example.org/abc',
      });
      expect(wallpaper?.url, Uri.parse('mxc://example.org/abc'));
      expect(wallpaper?.opacity, isNull);
      expect(wallpaper?.blur, isNull);
    });

    test('conteúdo ausente ou vazio é ignorado', () {
      expect(RoomWallpaper.fromJson(null), isNull);
      expect(RoomWallpaper.fromJson({}), isNull);
    });

    test('url inválida é ignorada', () {
      expect(RoomWallpaper.fromJson({'url': 42}), isNull);
      expect(RoomWallpaper.fromJson({'url': ''}), isNull);
      expect(
        RoomWallpaper.fromJson({'url': 'https://example.org/a.png'}),
        isNull,
      );
    });

    test('opacidade fora de 0..1 e valores de tipo errado são ignorados', () {
      final wallpaper = RoomWallpaper.fromJson({
        'url': 'mxc://example.org/abc',
        'opacity': 3.0,
        'blur': 'muito',
      });
      expect(wallpaper?.url, Uri.parse('mxc://example.org/abc'));
      expect(wallpaper?.opacity, isNull);
      expect(wallpaper?.blur, isNull);
    });

    test('toJson faz o caminho de volta', () {
      const json = {
        'url': 'mxc://example.org/abc',
        'opacity': 0.3,
        'blur': 2.0,
      };
      expect(RoomWallpaper.fromJson(json)?.toJson(), json);
      expect(RoomWallpaper(url: Uri.parse('mxc://example.org/abc')).toJson(), {
        'url': 'mxc://example.org/abc',
      });
    });
  });

  group('resolveChatWallpaper', () {
    final roomUrl = Uri.parse('mxc://example.org/room');
    final globalUrl = Uri.parse('mxc://example.org/global');

    test('fundo da conversa tem precedência sobre o global', () {
      final resolved = resolveChatWallpaper(
        RoomWallpaper(url: roomUrl, opacity: 0.2, blur: 3),
        ApplicationAccountConfig(
          wallpaperUrl: globalUrl,
          wallpaperOpacity: 0.9,
          wallpaperBlur: 8,
        ),
      );
      expect(resolved?.url, roomUrl);
      expect(resolved?.opacity, 0.2);
      expect(resolved?.blur, 3);
    });

    test('conversa sem opacidade/desfoque herda os valores globais', () {
      final resolved = resolveChatWallpaper(
        RoomWallpaper(url: roomUrl),
        const ApplicationAccountConfig(wallpaperOpacity: 0.7, wallpaperBlur: 5),
      );
      expect(resolved?.url, roomUrl);
      expect(resolved?.opacity, 0.7);
      expect(resolved?.blur, 5);
    });

    test('sem fundo da conversa usa o global', () {
      final resolved = resolveChatWallpaper(
        null,
        ApplicationAccountConfig(
          wallpaperUrl: globalUrl,
          wallpaperOpacity: 0.9,
          wallpaperBlur: 8,
        ),
      );
      expect(resolved?.url, globalUrl);
      expect(resolved?.opacity, 0.9);
      expect(resolved?.blur, 8);
    });

    test('sem nenhum fundo não há plano de fundo', () {
      expect(
        resolveChatWallpaper(null, const ApplicationAccountConfig()),
        isNull,
      );
    });
  });

  group('isWallpaperUpdate', () {
    const roomId = '!room:example.org';

    SyncUpdate syncWith({
      List<BasicEvent>? accountData,
      Map<String, JoinedRoomUpdate>? join,
    }) => SyncUpdate(
      nextBatch: 'n',
      accountData: accountData,
      rooms: join == null ? null : RoomsUpdate(join: join),
    );

    test('reage ao fundo da conversa e ao global', () {
      expect(
        isWallpaperUpdate(
          syncWith(
            join: {
              roomId: JoinedRoomUpdate(
                accountData: [
                  BasicEvent(type: RoomWallpaper.accountDataKey, content: {}),
                ],
              ),
            },
          ),
          roomId,
        ),
        isTrue,
      );
      expect(
        isWallpaperUpdate(
          syncWith(
            accountData: [
              BasicEvent(
                type: ApplicationAccountConfigExtension.accountDataKey,
                content: {},
              ),
            ],
          ),
          roomId,
        ),
        isTrue,
      );
    });

    test('ignora outras conversas e outros tipos', () {
      expect(
        isWallpaperUpdate(
          syncWith(
            join: {
              '!other:example.org': JoinedRoomUpdate(
                accountData: [
                  BasicEvent(type: RoomWallpaper.accountDataKey, content: {}),
                ],
              ),
              roomId: JoinedRoomUpdate(
                accountData: [BasicEvent(type: 'm.tag', content: {})],
              ),
            },
          ),
          roomId,
        ),
        isFalse,
      );
      expect(isWallpaperUpdate(syncWith(), roomId), isFalse);
    });
  });
}
