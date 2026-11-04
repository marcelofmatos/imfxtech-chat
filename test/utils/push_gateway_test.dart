// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

// O rebrand esvaziou a URL do gateway de push e o app passou a tentar
// registrar um pusher com URL vazia, que o homeserver recusa. Ver issue #10.

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/utils/background_push.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gateway de push padrão é o Sygnal da IMFxTech', () {
    expect(
      AppSettings.pushNotificationsGatewayUrl.defaultValue,
      'https://push.imfxtech.com/_matrix/push/v1/notify',
    );
  });

  test('aceita gateway http(s) com host', () {
    expect(
      BackgroundPush.isValidGatewayUrl(
        'https://push.imfxtech.com/_matrix/push/v1/notify',
      ),
      isTrue,
    );
    expect(
      BackgroundPush.isValidGatewayUrl(
        'http://localhost:5000/_matrix/push/v1/notify',
      ),
      isTrue,
    );
  });

  test('recusa gateway vazio ou que não seja http(s)', () {
    for (final url in [
      '',
      '   ',
      'push.imfxtech.com/_matrix/push/v1/notify',
      'ftp://push.imfxtech.com/_matrix/push/v1/notify',
      'https://',
      'https:///_matrix/push/v1/notify',
    ]) {
      expect(BackgroundPush.isValidGatewayUrl(url), isFalse, reason: url);
    }
  });
}
