// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/intro/intro_page.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.init(loadWebConfigFile: false);
  });

  Future<TextEditingController> pumpIntroPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    // Os textos do L10n são carregados de forma assíncrona (deferred loading).
    await tester.runAsync(() => L10n.delegate.load(const Locale('pt', 'BR')));

    await tester.pumpWidget(
      Matrix(
        clients: const [],
        store: AppSettings.store,
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: [
            ...L10n.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
            ...GlobalCupertinoLocalizations.delegates,
          ],
          supportedLocales: L10n.supportedLocales,
          home: IntroPage(
            isLoading: false,
            loggingInToHomeserver: null,
            hasPresetHomeserver: false,
            welcomeText: null,
            login: () {},
            homeserverController: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('mostra o campo Servidor: com exemplo de endereço', (
    tester,
  ) async {
    await pumpIntroPage(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.labelText, 'Servidor:');
    expect(field.decoration?.hintText, 'chat.exemplo.vps.imfxtech.com');
  });

  testWidgets('mostra sugestão do VPS enquanto digita', (tester) async {
    await pumpIntroPage(tester);

    expect(find.byType(ListTile), findsNothing);

    await tester.enterText(find.byType(TextField), 'chat');
    await tester.pump();

    expect(find.text('chat.vps.imfxtech.com'), findsOneWidget);
  });

  testWidgets('tocar na sugestão preenche o campo com o endereço completo', (
    tester,
  ) async {
    final controller = await pumpIntroPage(tester);

    await tester.enterText(find.byType(TextField), 'chat');
    await tester.pump();
    await tester.tap(find.text('chat.vps.imfxtech.com'));
    await tester.pump();

    expect(controller.text, 'chat.vps.imfxtech.com');
    expect(find.byType(ListTile), findsNothing);
  });
}
