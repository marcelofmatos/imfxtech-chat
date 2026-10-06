// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/login/login.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('loginUserFor', () {
    test('ID Matrix completo é usado como está', () {
      expect(
        loginUserFor('@marcelo:chat.adm.vps.imfxtech.com'),
        '@marcelo:chat.adm.vps.imfxtech.com',
      );
    });

    test('@ sem domínio vira o nome de usuário local', () {
      expect(loginUserFor('@marcelo'), 'marcelo');
    });

    test('nome sem @ é o nome de usuário local', () {
      expect(loginUserFor('marcelo'), 'marcelo');
      expect(loginUserFor('12345'), '12345');
    });

    test('ignora espaços nas bordas', () {
      expect(loginUserFor('  marcelo  '), 'marcelo');
    });
  });

  group('requiresHomeserver', () {
    test('nome sem domínio precisa do servidor', () {
      expect(requiresHomeserver('marcelo', ''), isTrue);
      expect(requiresHomeserver('@marcelo', ''), isTrue);
    });

    test('ID completo não precisa do servidor digitado', () {
      expect(
        requiresHomeserver('@marcelo:chat.adm.vps.imfxtech.com', ''),
        isFalse,
      );
    });

    test('servidor digitado dispensa a exigência', () {
      expect(
        requiresHomeserver('marcelo', 'chat.adm.vps.imfxtech.com'),
        isFalse,
      );
    });
  });
}
