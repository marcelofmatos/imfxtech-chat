// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/pages/chat/enter_key_newline.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

KeyEvent _event(Type type) {
  const physical = PhysicalKeyboardKey.enter;
  const logical = LogicalKeyboardKey.enter;
  const stamp = Duration.zero;
  return switch (type) {
    const (KeyDownEvent) => KeyDownEvent(
      physicalKey: physical,
      logicalKey: logical,
      timeStamp: stamp,
    ),
    const (KeyRepeatEvent) => KeyRepeatEvent(
      physicalKey: physical,
      logicalKey: logical,
      timeStamp: stamp,
    ),
    _ => KeyUpEvent(
      physicalKey: physical,
      logicalKey: logical,
      timeStamp: stamp,
    ),
  };
}

void main() {
  group('enterKeyAction', () {
    // (evento, shift, mobile, sendOnEnter) -> ação esperada
    final cases = <(Type, bool, bool, bool, EnterKeyAction)>[
      (KeyDownEvent, false, true, true, EnterKeyAction.send),
      (KeyRepeatEvent, false, true, true, EnterKeyAction.swallow),
      (KeyUpEvent, false, true, true, EnterKeyAction.swallow),
      (KeyDownEvent, true, true, true, EnterKeyAction.newline),
      (KeyRepeatEvent, true, true, true, EnterKeyAction.newline),
      (KeyUpEvent, true, true, true, EnterKeyAction.passThrough),
      (KeyDownEvent, false, true, false, EnterKeyAction.passThrough),
      (KeyDownEvent, true, true, false, EnterKeyAction.passThrough),
      (KeyDownEvent, false, false, true, EnterKeyAction.send),
      (KeyDownEvent, true, false, true, EnterKeyAction.passThrough),
      (KeyRepeatEvent, true, false, true, EnterKeyAction.passThrough),
    ];
    for (final (type, shift, mobile, sendOnEnter, expected) in cases) {
      test('$type shift=$shift mobile=$mobile sendOnEnter=$sendOnEnter', () {
        expect(
          enterKeyAction(
            _event(type),
            shift: shift,
            isMobile: mobile,
            sendOnEnter: sendOnEnter,
          ),
          expected,
        );
      });
    }
  });

  group('insertNewlineAtSelection', () {
    TextEditingController controller(String text, TextSelection selection) =>
        TextEditingController(text: text)..selection = selection;

    test('insere no cursor e avança o cursor', () {
      final c = controller('abcd', const TextSelection.collapsed(offset: 2));
      insertNewlineAtSelection(c);
      expect(c.text, 'ab\ncd');
      expect(c.selection, const TextSelection.collapsed(offset: 3));
    });
    test('substitui a seleção', () {
      final c = controller(
        'abcd',
        const TextSelection(baseOffset: 1, extentOffset: 3),
      );
      insertNewlineAtSelection(c);
      expect(c.text, 'a\nd');
      expect(c.selection, const TextSelection.collapsed(offset: 2));
    });
    test('substitui seleção invertida', () {
      final c = controller(
        'abcd',
        const TextSelection(baseOffset: 3, extentOffset: 1),
      );
      insertNewlineAtSelection(c);
      expect(c.text, 'a\nd');
    });
    test('seleção além do fim é limitada ao texto', () {
      final c = TextEditingController();
      c.value = const TextEditingValue(
        text: 'abc',
        selection: TextSelection(baseOffset: 2, extentOffset: 10),
      );
      insertNewlineAtSelection(c);
      expect(c.text, 'ab\n');
    });
    test('sem seleção válida, acrescenta no fim', () {
      final c = TextEditingController(text: 'abc');
      insertNewlineAtSelection(c);
      expect(c.text, 'abc\n');
    });
  });
}
