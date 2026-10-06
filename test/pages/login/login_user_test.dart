// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/login/login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

void main() {
  group('loginIdentifierFor', () {
    test('ID completo e nome sem @ viram usuário', () {
      final full = loginIdentifierFor('@marcelo:chat.adm.vps.imfxtech.com');
      expect(full, isA<AuthenticationUserIdentifier>());
      expect(
        (full as AuthenticationUserIdentifier).user,
        '@marcelo:chat.adm.vps.imfxtech.com',
      );

      final plain = loginIdentifierFor('marcelo');
      expect(plain, isA<AuthenticationUserIdentifier>());
      expect((plain as AuthenticationUserIdentifier).user, 'marcelo');
    });

    test('@ sem domínio vira o nome de usuário local', () {
      final identifier = loginIdentifierFor('@marcelo');
      expect((identifier as AuthenticationUserIdentifier).user, 'marcelo');
    });

    test('e-mail vira identificador de e-mail', () {
      final identifier = loginIdentifierFor('marcelo@exemplo.com');
      expect(identifier, isA<AuthenticationThirdPartyIdentifier>());
      final third = identifier as AuthenticationThirdPartyIdentifier;
      expect(third.medium, 'email');
      expect(third.address, 'marcelo@exemplo.com');
    });

    test('telefone vira identificador de msisdn', () {
      final identifier = loginIdentifierFor('+55 11 99999-8888');
      expect(identifier, isA<AuthenticationThirdPartyIdentifier>());
      final third = identifier as AuthenticationThirdPartyIdentifier;
      expect(third.medium, 'msisdn');
      expect(third.address, '+55 11 99999-8888');
    });
  });

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
