// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

// O desktop_drop 0.8.4 usado aqui não tem iOS, então arrastar arquivos para
// a conversa no iPhone/iPad (e no app iOS rodando no Mac) não fazia nada. O Runner iOS trata o drop/paste nativamente e entrega
// os arquivos por este canal.

import 'package:cross_file/cross_file.dart';
import 'package:fluffychat/utils/ios_file_drop.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  const payload = [
    {'path': '/tmp/a/0/print.png', 'mimeType': 'image/png'},
    {'path': '/tmp/a/1/relatorio.pdf', 'mimeType': 'application/pdf'},
    {'path': '/tmp/a/2/sem-tipo'},
  ];

  test('converte o payload nativo em um XFile por arquivo', () {
    final files = IosFileDrop.xFilesFromPayload(payload);
    expect(files, hasLength(3));
    expect(files.map((f) => f.path), [
      '/tmp/a/0/print.png',
      '/tmp/a/1/relatorio.pdf',
      '/tmp/a/2/sem-tipo',
    ]);
    expect(files.map((f) => f.name), [
      'print.png',
      'relatorio.pdf',
      'sem-tipo',
    ]);
    expect(files.map((f) => f.mimeType), [
      'image/png',
      'application/pdf',
      null,
    ]);
  });

  test('payload nulo vira lista vazia', () {
    expect(IosFileDrop.xFilesFromPayload(null), isEmpty);
  });

  group('canal nativo', () {
    final calls = <MethodCall>[];
    void Function(List<XFile> files)? lastOnDrop;

    void listen({
      VoidCallback? onEnter,
      VoidCallback? onExit,
      required void Function(List<XFile> files) onDrop,
    }) {
      lastOnDrop = onDrop;
      IosFileDrop.listen(
        onEnter: onEnter ?? () {},
        onExit: onExit ?? () {},
        onDrop: onDrop,
      );
    }

    setUp(() {
      calls.clear();
      lastOnDrop = null;
      messenger.setMockMethodCallHandler(IosFileDrop.channel, (call) async {
        calls.add(call);
        return call.method == 'pasteboardFiles' ? payload : true;
      });
    });

    tearDown(() {
      final onDrop = lastOnDrop;
      if (onDrop != null) IosFileDrop.stop(onDrop);
      messenger.setMockMethodCallHandler(IosFileDrop.channel, null);
    });

    Future<void> fromNative(String method, [Object? arguments]) =>
        messenger.handlePlatformMessage(
          IosFileDrop.channel.name,
          IosFileDrop.channel.codec.encodeMethodCall(
            MethodCall(method, arguments),
          ),
          (_) {},
        );

    test('listen pede ao Runner para anexar a área de drop', () async {
      listen(onDrop: (_) {});
      await pumpEventQueue();
      expect(calls.map((c) => c.method), ['attach']);
    });

    test('drop de N arquivos entrega N XFile', () async {
      final dropped = <List<String>>[];
      var entered = 0;
      var exited = 0;
      listen(
        onEnter: () => entered++,
        onExit: () => exited++,
        onDrop: (files) => dropped.add(files.map((f) => f.path).toList()),
      );

      await fromNative('enter');
      await fromNative('exit');
      await fromNative('drop', payload);

      expect(entered, 1);
      expect(exited, 1);
      expect(dropped, [
        ['/tmp/a/0/print.png', '/tmp/a/1/relatorio.pdf', '/tmp/a/2/sem-tipo'],
      ]);
    });

    test('drop sem arquivos não chama onDrop', () async {
      var drops = 0;
      listen(onDrop: (_) => drops++);
      await fromNative('drop', const []);
      expect(drops, 0);
    });

    test('stop do listener atual remove a área de drop do Runner', () async {
      void chat(List<XFile> files) {}
      listen(onDrop: chat);
      IosFileDrop.stop(chat);
      await pumpEventQueue();
      expect(calls.map((c) => c.method), ['attach', 'detach']);
    });

    test('stop de uma conversa antiga não remove o listener da nova', () async {
      void oldChat(List<XFile> files) {}
      final dropped = <int>[];
      void newChat(List<XFile> files) => dropped.add(files.length);
      listen(onDrop: oldChat);
      listen(onDrop: newChat);
      IosFileDrop.stop(oldChat);
      await fromNative('drop', payload);
      expect(dropped, [3]);
      expect(calls.map((c) => c.method), ['attach', 'attach']);

      IosFileDrop.stop(newChat);
      await pumpEventQueue();
      expect(calls.map((c) => c.method), ['attach', 'attach', 'detach']);
    });

    test(
      'pasteboardFiles devolve os arquivos da área de transferência',
      () async {
        final files = await IosFileDrop.pasteboardFiles();
        expect(calls.single.method, 'pasteboardFiles');
        expect(files, hasLength(3));
      },
    );
  });
}
