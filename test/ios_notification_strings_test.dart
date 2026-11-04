// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

// A Notification Service Extension do iOS monta o título e o corpo das
// notificações com String(localized:). Sem tradução para português, o iPhone
// e o iPad em pt-BR mostravam "Unread message" / "New message - open app to
// read". Estes testes garantem que toda string da extensão tenha pt-BR e pt.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _catalogPath = 'ios/Localizable.xcstrings';
const _extensionPath =
    'ios/Notification Service Extension/NotificationService.swift';
const _portuguese = ['pt-BR', 'pt'];

Map<String, dynamic> _strings() =>
    (jsonDecode(File(_catalogPath).readAsStringSync())
            as Map<String, dynamic>)['strings']
        as Map<String, dynamic>;

/// Chaves que a extensão pede ao catálogo. Interpolações viram o formato do
/// catálogo: "\(unread ?? 1) unread messages" -> "%lld unread messages".
List<String> _extensionKeys() {
  final source = File(_extensionPath).readAsStringSync();
  return RegExp(r'localized:\s*"((?:[^"\\]|\\.)*)"')
      .allMatches(source)
      .map((m) => m.group(1)!.replaceAll(RegExp(r'\\\([^)]*\)'), '%lld'))
      .toList();
}

void main() {
  test('a extensão de notificação usa strings localizadas', () {
    expect(_extensionKeys(), isNotEmpty);
  });

  test('toda string da extensão existe no catálogo', () {
    final strings = _strings();
    for (final key in _extensionKeys()) {
      expect(strings.containsKey(key), isTrue, reason: 'falta "$key"');
    }
  });

  test('toda string da extensão tem tradução pt-BR e pt', () {
    final strings = _strings();
    for (final key in _extensionKeys()) {
      final localizations =
          (strings[key] as Map<String, dynamic>?)?['localizations']
              as Map<String, dynamic>? ??
          const {};
      for (final lang in _portuguese) {
        expect(
          localizations.containsKey(lang),
          isTrue,
          reason: 'falta $lang para "$key"',
        );
      }
    }
  });

  test('o projeto iOS declara pt-BR e pt nos knownRegions', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final regions = RegExp(
      r'knownRegions = \(([^)]*)\)',
    ).firstMatch(project)!.group(1)!;
    expect(regions, contains('"pt-BR"'));
    expect(regions, contains(RegExp(r'\bpt,')));
  });
}
