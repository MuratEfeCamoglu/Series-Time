// PowerShell 5.1 `&&` desteklemediği için doğrulama adımları bu betikle zincirlenir.
// Kullanım: dart run tool/verify.dart
import 'dart:io';

const _steps = <List<String>>[
  ['flutter', 'analyze'],
  ['dart', 'format', '--output=none', '--set-exit-if-changed', '.'],
  ['flutter', 'test'],
];

Future<void> main() async {
  for (final step in _steps) {
    final command = step.join(' ');
    stdout.writeln('\n==> $command');
    // runInShell: Windows'ta flutter/dart .bat dosyalarıdır.
    final process = await Process.start(
      step.first,
      step.sublist(1),
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    final code = await process.exitCode;
    if (code != 0) {
      stderr.writeln('\nverify: "$command" başarısız (çıkış kodu $code).');
      exit(code);
    }
  }
  stdout.writeln('\nverify: tüm kontroller geçti.');
}
