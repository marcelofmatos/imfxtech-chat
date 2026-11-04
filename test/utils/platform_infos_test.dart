// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

// O app iOS rodando num Mac Apple Silicon via "Designed for iPad" continua
// reportando Platform.isIOS == true, então sendOnEnter ficava com o padrão
// de mobile (false) mesmo havendo teclado físico. O Runner expõe
// ProcessInfo.isiOSAppOnMac por este canal (ios/Runner/AppDelegate.swift);
// ver issue #22.

import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(PlatformInfos.iosAppOnMacChannel, null);
  });

  group('isIOSAppOnMac', () {
    test('fica true quando o Runner responde true', () async {
      messenger.setMockMethodCallHandler(
        PlatformInfos.iosAppOnMacChannel,
        (call) async => true,
      );
      await PlatformInfos.initIOSAppOnMac();
      expect(PlatformInfos.isIOSAppOnMac, isTrue);
    });

    test('fica false quando o Runner responde false', () async {
      messenger.setMockMethodCallHandler(
        PlatformInfos.iosAppOnMacChannel,
        (call) async => false,
      );
      await PlatformInfos.initIOSAppOnMac();
      expect(PlatformInfos.isIOSAppOnMac, isFalse);
    });

    test(
      'fica false sem crashar quando não há canal nativo (Android/desktop/web)',
      () async {
        await PlatformInfos.initIOSAppOnMac();
        expect(PlatformInfos.isIOSAppOnMac, isFalse);
      },
    );
  });

  group('sendOnEnterDefault', () {
    test(
      'vira true quando isIOSAppOnMac é true, mesmo com isMobile true',
      () async {
        messenger.setMockMethodCallHandler(
          PlatformInfos.iosAppOnMacChannel,
          (call) async => true,
        );
        await PlatformInfos.initIOSAppOnMac();
        expect(PlatformInfos.sendOnEnterDefault, isTrue);
      },
    );

    test('segue !isMobile quando isIOSAppOnMac é false', () async {
      messenger.setMockMethodCallHandler(
        PlatformInfos.iosAppOnMacChannel,
        (call) async => false,
      );
      await PlatformInfos.initIOSAppOnMac();
      expect(PlatformInfos.sendOnEnterDefault, !PlatformInfos.isMobile);
    });
  });
}
