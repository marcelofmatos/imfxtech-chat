// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

// O light_compressor_v2 declara FOREGROUND_SERVICE_DATA_SYNC e um serviço
// dataSync que o app nunca inicia (não passamos `background:` ao comprimir
// vídeo). A Google Play exige um vídeo de demonstração para essa permissão,
// então ela é removida no manifest do app. Ver docs/GOOGLE_PLAY_PUBLISHING.md.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('manifest remove a permissão FOREGROUND_SERVICE_DATA_SYNC', () {
    expect(
      manifest,
      matches(
        RegExp(
          r'android\.permission\.FOREGROUND_SERVICE_DATA_SYNC"\s+tools:node="remove"',
        ),
      ),
    );
  });

  test('manifest remove o serviço de compressão em primeiro plano', () {
    expect(
      manifest,
      matches(
        RegExp(
          r'CompressionForegroundService"\s+tools:node="remove"',
        ),
      ),
    );
  });

  test('nenhuma compressão de vídeo pede execução em segundo plano', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) {
          final src = f.readAsStringSync();
          return src.contains('compressVideo') && src.contains('background:');
        })
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });
}
