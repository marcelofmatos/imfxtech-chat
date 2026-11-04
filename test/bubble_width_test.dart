// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/themes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluffyThemes.bubbleMaxWidth', () {
    test('em tela larga usa 75% da área disponível', () {
      expect(FluffyThemes.bubbleMaxWidth(1200), 900);
    });

    test('em tela ultrawide respeita o teto absoluto', () {
      expect(FluffyThemes.bubbleMaxWidth(3000), 1000);
    });

    test('em áreas estreitas (celular) mantém o piso de 570', () {
      for (final width in [390.0, 600.0, 760.0]) {
        expect(FluffyThemes.bubbleMaxWidth(width), 570);
      }
    });
  });
}
