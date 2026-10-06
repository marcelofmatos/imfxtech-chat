// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/login/homeserver_text_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('homeserverSuggestions', () {
    test('sem sugestão quando o campo está vazio', () {
      expect(homeserverSuggestions(''), isEmpty);
      expect(homeserverSuggestions('   '), isEmpty);
    });

    test('completa um prefixo sem ponto com o domínio do VPS', () {
      expect(homeserverSuggestions('chat'), ['chat.vps.imfxtech.com']);
    });

    test('completa um endereço com ponto com o domínio do VPS', () {
      expect(homeserverSuggestions('chat.exemplo'), [
        'chat.exemplo.vps.imfxtech.com',
      ]);
      expect(homeserverSuggestions('chat.adm'), ['chat.adm.vps.imfxtech.com']);
    });

    test('completa quando o texto termina com ponto', () {
      expect(homeserverSuggestions('chat.'), ['chat.vps.imfxtech.com']);
    });

    test('sugere o domínio do VPS quando o texto é prefixo dele', () {
      expect(homeserverSuggestions('vps'), ['vps.imfxtech.com']);
      expect(homeserverSuggestions('vps.imf'), ['vps.imfxtech.com']);
    });

    test('ignora maiúsculas e espaços nas bordas', () {
      expect(homeserverSuggestions('  CHAT  '), ['chat.vps.imfxtech.com']);
    });

    test('não sugere nada quando o endereço já está completo', () {
      expect(homeserverSuggestions('chat.vps.imfxtech.com'), isEmpty);
    });
  });
}
