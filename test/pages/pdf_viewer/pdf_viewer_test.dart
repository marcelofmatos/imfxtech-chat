// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:typed_data';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/pdf_viewer/pdf_viewer.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';

import '../../utils/test_client.dart';

/// Gera um PDF de 1 página válido, com a tabela xref nos offsets corretos.
Uint8List minimalPdf() {
  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>',
  ];
  final buffer = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(buffer.length);
    buffer.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xref = buffer.length;
  buffer.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final offset in offsets) {
    buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  buffer.write(
    'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
    'startxref\n$xref\n%%EOF\n',
  );
  return Uint8List.fromList(ascii.encode(buffer.toString()));
}

void main() {
  group('isPdfFile', () {
    test('mimetype application/pdf é PDF', () {
      expect(isPdfFile(mimetype: 'application/pdf', filename: 'x'), isTrue);
      expect(isPdfFile(mimetype: 'Application/PDF', filename: 'x'), isTrue);
    });

    test('sem mimetype, decide pela extensão .pdf', () {
      expect(isPdfFile(mimetype: '', filename: 'Relatório.PDF'), isTrue);
      expect(isPdfFile(mimetype: '', filename: 'notas.txt'), isFalse);
      expect(isPdfFile(mimetype: '', filename: 'pdf'), isFalse);
    });

    test('application/octet-stream decide pela extensão .pdf', () {
      const octet = 'application/octet-stream';
      expect(isPdfFile(mimetype: octet, filename: 'boleto.pdf'), isTrue);
      expect(isPdfFile(mimetype: octet, filename: 'pacote.zip'), isFalse);
    });

    test('outro mimetype não é PDF, mesmo com nome .pdf', () {
      expect(isPdfFile(mimetype: 'image/png', filename: 'a.pdf'), isFalse);
      expect(isPdfFile(mimetype: 'text/plain', filename: 'a.txt'), isFalse);
    });
  });

  test('Event.isPdf lê mimetype e nome do conteúdo do evento', () async {
    final room = Room(
      id: '!sala:example.invalid',
      client: await prepareTestClient(),
    );
    Event fileEvent(Map<String, Object?> content) => Event.fromJson({
      'type': EventTypes.Message,
      'event_id': '\$ev',
      'sender': '@alice:example.invalid',
      'origin_server_ts': 0,
      'content': {'msgtype': MessageTypes.File, 'url': 'mxc://x/y', ...content},
    }, room);

    expect(
      fileEvent({
        'body': 'a',
        'info': {'mimetype': 'application/pdf'},
      }).isPdf,
      isTrue,
    );
    expect(fileEvent({'body': 'legenda', 'filename': 'a.pdf'}).isPdf, isTrue);
    expect(
      fileEvent({
        'body': 'a.pdf',
        'info': {'mimetype': 'image/png'},
      }).isPdf,
      isFalse,
    );
    expect(fileEvent({'body': 'a.zip'}).isPdf, isFalse);
  });

  // O PDFium não carrega no `flutter test` (o native asset não é empacotado no
  // ambiente de teste), então aqui só a casca do visualizador é verificada.
  testWidgets('visualizador mostra título e ações', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: PdfViewerPage(
          file: MatrixFile(
            bytes: minimalPdf(),
            name: 'documento.pdf',
            mimeType: 'application/pdf',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('documento.pdf'), findsOneWidget);
    expect(find.byTooltip('Save'), findsOneWidget);
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
