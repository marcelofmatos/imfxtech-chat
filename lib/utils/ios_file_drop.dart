// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';

/// Drop e paste de arquivos no iOS/iPadOS, tratados pelo Runner
/// (ios/Runner/AppDelegate.swift): o desktop_drop 0.8.4 usado aqui não tem
/// iOS (só a 0.9.x, que exige Flutter 3.47.7 e cross_file 0.4) e o
/// pasteboard não lê arquivos no iOS.
///
/// O Runner copia cada arquivo para um diretório temporário e envia uma lista
/// de mapas `{path, mimeType}`.
abstract class IosFileDrop {
  static const MethodChannel channel = MethodChannel(
    'com.imfxtech.chat/file_drop',
  );

  static List<XFile> xFilesFromPayload(Object? payload) => [
    for (final item in (payload as List?) ?? const [])
      XFile(
        (item as Map)['path'] as String,
        mimeType: item['mimeType'] as String?,
      ),
  ];

  static void Function(List<XFile> files)? _onDrop;

  static void listen({
    required VoidCallback onEnter,
    required VoidCallback onExit,
    required void Function(List<XFile> files) onDrop,
  }) {
    _onDrop = onDrop;
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'enter':
          onEnter();
        case 'exit':
          onExit();
        case 'drop':
          final files = xFilesFromPayload(call.arguments);
          if (files.isNotEmpty) onDrop(files);
      }
    });
    channel.invokeMethod('attach');
  }

  /// Só remove o listener (e a área de drop no Runner) se ele ainda for o
  /// registrado por [onDrop]: ao trocar de conversa o initState da nova roda
  /// antes do dispose da antiga.
  static void stop(void Function(List<XFile> files) onDrop) {
    if (_onDrop != onDrop) return;
    _onDrop = null;
    channel.setMethodCallHandler(null);
    channel.invokeMethod('detach');
  }

  static Future<List<XFile>> pasteboardFiles() async =>
      xFilesFromPayload(await channel.invokeMethod('pasteboardFiles'));
}
