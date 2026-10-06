// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/widgets/layouts/login_scaffold.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('campo focado fica inteiro acima do teclado no iPad', (
    tester,
  ) async {
    const screen = Size(1024, 768);
    const keyboardHeight = 400.0;
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
    addTearDown(tester.view.reset);

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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: LoginScaffold(
          body: ListView(
            children: [
              for (var i = 0; i < 6; i++)
                const Padding(padding: EdgeInsets.all(8), child: TextField()),
              const TextField(key: Key('senha')),
              const FilledButton(onPressed: null, child: Text('Conectar')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final keyboardTop = screen.height - keyboardHeight;
    final listHeight = tester.getSize(find.byType(ListView)).height;
    expect(listHeight, greaterThan(150));

    await tester.scrollUntilVisible(
      find.byKey(const Key('senha')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('senha')));
    await tester.pumpAndSettle();

    final passwordRect = tester.getRect(find.byKey(const Key('senha')));
    expect(passwordRect.top, greaterThanOrEqualTo(0));
    expect(passwordRect.bottom, lessThanOrEqualTo(keyboardTop));
  });
}
