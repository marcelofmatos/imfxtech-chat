// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_details/room_wallpaper_list_tile.dart';
import 'package:fluffychat/utils/room_wallpaper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';

import '../../utils/test_client.dart';

void main() {
  late Client client;

  setUpAll(() async {
    client = await prepareTestClient();
  });

  Future<void> pumpTile(
    WidgetTester tester,
    Room room, {
    VoidCallback? onSet,
    VoidCallback? onRemove,
  }) async {
    await tester.runAsync(() => L10n.delegate.load(const Locale('pt', 'BR')));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: [
          ...L10n.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: RoomWallpaperListTile(
            room: room,
            onSet: onSet ?? () {},
            onRemove: onRemove ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sem fundo da conversa: só a ação de escolher', (tester) async {
    var tapped = false;
    final room = Room(id: '!a:example.org', client: client);
    await pumpTile(tester, room, onSet: () => tapped = true);

    expect(find.text('Configurar plano de fundo'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outlined), findsNothing);

    await tester.tap(find.text('Configurar plano de fundo'));
    expect(tapped, isTrue);
  });

  testWidgets('com fundo da conversa: botão de remover', (tester) async {
    var removed = false;
    final room = Room(
      id: '!b:example.org',
      client: client,
      roomAccountData: {
        RoomWallpaper.accountDataKey: BasicEvent(
          type: RoomWallpaper.accountDataKey,
          content: {'url': 'mxc://example.org/abc'},
        ),
      },
    );
    await pumpTile(tester, room, onRemove: () => removed = true);

    await tester.tap(find.byIcon(Icons.delete_outlined));
    expect(removed, isTrue);
  });

  testWidgets('atualiza quando o fundo chega pelo sync', (tester) async {
    final room = Room(id: '!c:example.org', client: client);
    await pumpTile(tester, room);
    expect(find.byIcon(Icons.delete_outlined), findsNothing);

    final event = BasicEvent(
      type: RoomWallpaper.accountDataKey,
      content: {'url': 'mxc://example.org/abc'},
    );
    room.roomAccountData[RoomWallpaper.accountDataKey] = event;
    client.onSync.add(
      SyncUpdate(
        nextBatch: 'n',
        rooms: RoomsUpdate(
          join: {
            room.id: JoinedRoomUpdate(accountData: [event]),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outlined), findsOneWidget);
  });
}
