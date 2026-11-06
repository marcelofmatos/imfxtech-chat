// SPDX-FileCopyrightText: 2026 IMFX TECH LTDA
// SPDX-License-Identifier: AGPL-3.0-or-later

// scripts/notarize-dmg.sh envia o .dmg para a notarização da Apple e espera o
// resultado. Na v1.1.5 o `notarytool submit --wait` caiu com timeout de rede
// enquanto a Apple ainda processava, e o job inteiro falhou. Estes testes rodam
// o script com um `xcrun` falso e garantem que queda de rede vira nova
// tentativa, e que só "Invalid"/"Rejected" ou o tempo limite derrubam o job.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _script = 'scripts/notarize-dmg.sh';

// xcrun falso: `submit` lê respostas de submit_responses, `info` lê de
// info_responses (uma por chamada; FAIL = erro de rede), `log` e `stapler`
// só registram a chamada.
const _fakeXcrun = r'''#!/usr/bin/env bash
dir="$(dirname "$0")"
pop() {
  local file="$dir/$1" line
  line=$(head -n 1 "$file")
  tail -n +2 "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  echo "$line"
}
echo "$*" >> "$dir/calls"
case "$1 $2" in
  "notarytool submit")
    r=$(pop submit_responses)
    [ "$r" = FAIL ] && { echo "The request timed out." >&2; exit 1; }
    echo "{\"id\": \"$r\", \"message\": \"ok\"}" ;;
  "notarytool info")
    r=$(pop info_responses)
    [ "$r" = FAIL ] && { echo "The request timed out." >&2; exit 1; }
    echo "{\"id\": \"$3\", \"status\": \"$r\"}" ;;
  "notarytool log") echo "log da Apple" ;;
  "stapler staple") touch "$dir/stapled" ;;
esac
''';

class _Run {
  _Run(this.result, this.dir);
  final ProcessResult result;
  final Directory dir;
  List<String> get calls {
    final file = File('${dir.path}/calls');
    return file.existsSync() ? file.readAsLinesSync() : const [];
  }

  bool get stapled => File('${dir.path}/stapled').existsSync();
}

Future<_Run> _runScript({
  required List<String> submit,
  required List<String> info,
  String timeoutSeconds = '60',
}) async {
  final dir = Directory.systemTemp.createTempSync('notarize_test_');
  addTearDown(() => dir.deleteSync(recursive: true));
  final xcrun = File('${dir.path}/xcrun')..writeAsStringSync(_fakeXcrun);
  await Process.run('chmod', ['+x', xcrun.path]);
  File(
    '${dir.path}/submit_responses',
  ).writeAsStringSync('${submit.join('\n')}\n');
  File('${dir.path}/info_responses').writeAsStringSync('${info.join('\n')}\n');
  final dmg = File('${dir.path}/app.dmg')..writeAsStringSync('dmg');

  final result = await Process.run(
    'bash',
    [_script, dmg.path],
    environment: {
      'PATH': '${dir.path}:${Platform.environment['PATH']}',
      'ASC_KEY_PATH': '${dir.path}/key.p8',
      'ASC_KEY_ID': 'KEYID',
      'ASC_ISSUER_ID': 'ISSUER',
      'NOTARY_POLL_SECONDS': '0',
      'NOTARY_TIMEOUT_SECONDS': timeoutSeconds,
    },
  );
  return _Run(result, dir);
}

void main() {
  test('queda de rede na espera vira nova tentativa até Accepted', () async {
    final run = await _runScript(
      submit: ['abc-123'],
      info: ['FAIL', 'In Progress', 'FAIL', 'Accepted'],
    );
    expect(
      run.result.exitCode,
      0,
      reason: '${run.result.stdout}${run.result.stderr}',
    );
    expect(run.stapled, isTrue);
    expect(
      run.calls.where((c) => c.startsWith('notarytool info abc-123')),
      hasLength(4),
    );
  });

  test('queda de rede no envio tenta de novo', () async {
    final run = await _runScript(
      submit: ['FAIL', 'abc-123'],
      info: ['Accepted'],
    );
    expect(
      run.result.exitCode,
      0,
      reason: '${run.result.stdout}${run.result.stderr}',
    );
    expect(run.stapled, isTrue);
  });

  test('Invalid falha o job e mostra o log da Apple', () async {
    final run = await _runScript(
      submit: ['abc-123'],
      info: ['In Progress', 'Invalid'],
    );
    expect(run.result.exitCode, isNot(0));
    expect(run.stapled, isFalse);
    expect(run.calls, contains(startsWith('notarytool log abc-123')));
    expect(run.result.stdout, contains('log da Apple'));
  });

  test('sem resultado dentro do tempo limite falha sem grampear', () async {
    final run = await _runScript(
      submit: ['abc-123'],
      info: ['In Progress'],
      timeoutSeconds: '0',
    );
    expect(run.result.exitCode, isNot(0));
    expect(run.stapled, isFalse);
    expect(run.result.stdout, contains('abc-123'));
  });

  test('envio que falha sempre derruba o job', () async {
    final run = await _runScript(submit: ['FAIL', 'FAIL', 'FAIL'], info: []);
    expect(run.result.exitCode, isNot(0));
    expect(run.calls.where((c) => c.startsWith('notarytool info')), isEmpty);
  });
}
