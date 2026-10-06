// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

const _vpsDomain = 'vps.imfxtech.com';

List<String> homeserverSuggestions(String typed) {
  final text = typed.trim().toLowerCase();
  if (text.isEmpty || text.endsWith(_vpsDomain)) return const [];
  if (_vpsDomain.startsWith(text)) return const [_vpsDomain];
  final prefix = text.endsWith('.') ? text : '$text.';
  return ['$prefix$_vpsDomain'];
}

class HomeserverTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;
  final String? errorText;

  const HomeserverTextField({
    required this.controller,
    required this.readOnly,
    this.errorText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        TextField(
          readOnly: readOnly,
          controller: controller,
          autocorrect: false,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.dns_outlined),
            labelText: L10n.of(context).homeserverLabel,
            hintText: 'chat.exemplo.vps.imfxtech.com',
            errorText: errorText,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) => Column(
            mainAxisSize: .min,
            children: [
              for (final suggestion in homeserverSuggestions(value.text))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(suggestion),
                  onTap: () {
                    controller.value = TextEditingValue(
                      text: suggestion,
                      selection: TextSelection.collapsed(
                        offset: suggestion.length,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
