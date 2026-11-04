// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

// O target macOS veio do FluffyChat com nome, bundle id e copyright dele.
// Estes testes garantem o rebrand (mesmo bundle id do iOS) e que o workflow
// de release gera o .dmg do macOS. Ver docs/MACOS_RELEASE.md.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final appInfo = File(
    'macos/Runner/Configs/AppInfo.xcconfig',
  ).readAsStringSync();

  test('target macOS não tem mais resquícios do FluffyChat', () {
    for (final path in [
      'macos/Runner/Configs/AppInfo.xcconfig',
      'macos/Runner/Info.plist',
      'macos/Runner/Base.lproj/MainMenu.xib',
      'macos/Runner.xcodeproj/project.pbxproj',
      'macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
    ]) {
      final content = File(path).readAsStringSync();
      expect(content, isNot(contains('im.fluffychat')), reason: path);
      expect(content, isNot(contains('FluffyChat')), reason: path);
      expect(content, isNot(contains('APP_NAME')), reason: path);
    }
  });

  test('bundle id do macOS é o mesmo do app iOS', () {
    final iosBundleIds = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([\w.]+);')
        .allMatches(
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
        )
        .map((m) => m.group(1))
        .toSet();
    final macosBundleId = RegExp(
      r'PRODUCT_BUNDLE_IDENTIFIER = (\S+)',
    ).firstMatch(appInfo)?.group(1);

    expect(macosBundleId, 'com.imfxtech.chat');
    expect(iosBundleIds, contains(macosBundleId));
  });

  test('workflow de release gera e anexa o .dmg do macOS', () {
    final workflow = File(
      '.github/workflows/release-and-build.yml',
    ).readAsStringSync();

    expect(workflow, contains('build-macos:'));
    expect(workflow, contains('flutter build macos --release'));
    expect(workflow, contains('hdiutil create'));
    expect(workflow, contains(r'imfxtech-chat-$NEW_VERSION-macos.dmg'));
  });

  test(
    'build release do macOS exclui x86_64 (BoringSSL do webcrypto trava nessa arquitetura)',
    () {
      final releaseConfig = File(
        'macos/Runner/Configs/Release.xcconfig',
      ).readAsStringSync();
      expect(releaseConfig, contains('EXCLUDED_ARCHS[sdk=macosx*] = x86_64'));
    },
  );

  test('falha do macOS não bloqueia a GitHub Release', () {
    final workflow = File(
      '.github/workflows/release-and-build.yml',
    ).readAsStringSync();
    final createRelease = workflow.substring(
      workflow.indexOf('  create-release:'),
    );

    expect(createRelease, contains('always()'));
    expect(
      createRelease,
      isNot(contains("needs.build-macos.result == 'success' &&")),
    );
    expect(
      createRelease,
      contains("if: needs.build-macos.result == 'success'"),
    );
  });
}
