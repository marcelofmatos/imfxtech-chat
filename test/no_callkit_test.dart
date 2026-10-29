// SPDX-License-Identifier: AGPL-3.0-or-later

// A Apple rejeitou o app por usar CallKit (vídeo obrigatório na revisão e
// proibição na China). Estes testes impedem que um merge do FluffyChat
// upstream traga o CallKit de volta. Ver APPLE_CALLKIT.md.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec não depende de flutter_callkit_incoming', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('flutter_callkit_incoming')));
  });

  test('Info.plist não declara o background mode voip', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, isNot(contains('<string>voip</string>')));
  });

  test('nenhum arquivo em lib/ usa flutter_callkit_incoming', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('flutter_callkit_incoming'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });
}
