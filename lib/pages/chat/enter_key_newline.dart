// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum EnterKeyAction {
  send,

  /// Consome o evento sem fazer nada (repeat/up do Enter que já enviou).
  swallow,

  newline,

  /// Deixa o TextField tratar.
  passThrough,
}

/// Decide o que fazer com um evento de Enter. No mobile com "Enviar com
/// Enter" o input usa `TextInputAction.send`, então um Enter ignorado chega à
/// plataforma como "enviar": Shift+Enter (down ou repeat) precisa inserir a
/// quebra de linha manualmente. O KeyUp é inofensivo.
EnterKeyAction enterKeyAction(
  KeyEvent event, {
  required bool shift,
  required bool isMobile,
  required bool sendOnEnter,
}) {
  if (!sendOnEnter) return EnterKeyAction.passThrough;
  if (!shift) {
    return event is KeyDownEvent ? EnterKeyAction.send : EnterKeyAction.swallow;
  }
  if (isMobile && event is! KeyUpEvent) return EnterKeyAction.newline;
  return EnterKeyAction.passThrough;
}

/// Insere `\n` na posição do cursor, substituindo a seleção se houver.
void insertNewlineAtSelection(TextEditingController controller) {
  final text = controller.text;
  final selection = controller.selection;
  final start = selection.isValid
      ? min(selection.start, selection.end).clamp(0, text.length)
      : text.length;
  final end = selection.isValid
      ? max(selection.start, selection.end).clamp(0, text.length)
      : text.length;
  controller.value = TextEditingValue(
    text: text.replaceRange(start, end, '\n'),
    selection: TextSelection.collapsed(offset: start + 1),
  );
}
