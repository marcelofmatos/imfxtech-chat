// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/login/homeserver_text_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<TextEditingController> pumpField(
    WidgetTester tester, {
    required bool readOnly,
  }) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    // Os textos do L10n são carregados de forma assíncrona (deferred loading).
    await tester.runAsync(() => L10n.delegate.load(const Locale('pt', 'BR')));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: [
          ...L10n.localizationsDelegates,
          ...GlobalMaterialLocalizations.delegates,
          ...GlobalCupertinoLocalizations.delegates,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: HomeserverTextField(controller: controller, readOnly: readOnly),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('mostra o campo Servidor: com exemplo de endereço', (
    tester,
  ) async {
    await pumpField(tester, readOnly: false);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.labelText, 'Servidor:');
    expect(field.decoration?.hintText, 'chat.exemplo.vps.imfxtech.com');
  });

  testWidgets('sugere o domínio do VPS enquanto digita', (tester) async {
    await pumpField(tester, readOnly: false);

    expect(find.byType(ListTile), findsNothing);

    await tester.enterText(find.byType(TextField), 'chat.exemplo');
    await tester.pump();

    expect(
      find.widgetWithText(ListTile, 'chat.exemplo.vps.imfxtech.com'),
      findsOneWidget,
    );
  });

  testWidgets('tocar na sugestão preenche o campo com o endereço completo', (
    tester,
  ) async {
    final controller = await pumpField(tester, readOnly: false);

    await tester.enterText(find.byType(TextField), 'chat');
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'chat.vps.imfxtech.com'));
    await tester.pump();

    expect(controller.text, 'chat.vps.imfxtech.com');
    expect(find.byType(ListTile), findsNothing);
  });
}
