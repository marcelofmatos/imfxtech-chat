// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:material_ui/material_ui.dart';
import 'package:matrix/matrix.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewerPage extends StatelessWidget {
  final MatrixFile file;

  const PdfViewerPage({required this.file, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: Navigator.of(context).pop,
          tooltip: L10n.of(context).close,
        ),
        title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => file.save(context),
            tooltip: L10n.of(context).save,
          ),
          // Use builder context to correctly position the share dialog on iPad
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.adaptive.share_outlined),
              onPressed: () => file.share(context),
              tooltip: L10n.of(context).share,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PdfViewer.data(file.bytes, sourceName: file.name),
    );
  }
}
