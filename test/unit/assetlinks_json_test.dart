import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const packageName = 'app.selahword.audio';
  const debugSha256 =
      '86:13:09:5F:66:79:0E:0C:EA:7E:DA:C3:CA:62:D3:47:EB:F5:10:A6:55:3D:66:A1:2E:6F:D9:5A:E1:64:9E:F2';

  test('assetlinks.json names this app and the debug signing certificate', () {
    final file = File('web/.well-known/assetlinks.json');
    expect(file.existsSync(), isTrue, reason: file.path);
    final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    expect(decoded, hasLength(1));
    final statement = decoded.single as Map<String, dynamic>;
    expect(statement['relation'], ['delegate_permission/common.handle_all_urls']);
    final target = statement['target'] as Map<String, dynamic>;
    expect(target['namespace'], 'android_app');
    expect(target['package_name'], packageName);
    expect(target['sha256_cert_fingerprints'], [debugSha256]);
  });

  test('firebase hosting uploads .well-known instead of ignoring dot paths', () {
    final firebase =
        jsonDecode(File('firebase.json').readAsStringSync()) as Map<String, dynamic>;
    final hosting = firebase['hosting'] as Map<String, dynamic>;
    expect(hosting['public'], 'build/web');
    final ignore = (hosting['ignore'] as List<dynamic>).cast<String>();

    // `**/.*` matches the hidden `.well-known` directory, so Hosting never
    // uploads assetlinks.json and the SPA rewrite serves index.html instead.
    expect(ignore, isNot(contains('**/.*')));
    expect(
      ignore.where((pattern) => !pattern.startsWith('!')),
      isNot(anyElement(contains('.well-known'))),
    );
    for (final pattern in ignore) {
      expect(_ignoreWouldSkipWellKnown(pattern), isFalse, reason: pattern);
    }

    final headers = hosting['headers'] as List<dynamic>;
    final assetLinks = headers.cast<Map<String, dynamic>>().singleWhere(
      (entry) => entry['source'] == '/.well-known/assetlinks.json',
    );
    final headerMap = {
      for (final header in assetLinks['headers'] as List<dynamic>)
        (header as Map<String, dynamic>)['key']: header['value'],
    };
    expect(headerMap['Content-Type'], 'application/json');
  });
}

bool _ignoreWouldSkipWellKnown(String pattern) {
  if (pattern.startsWith('!')) return false;
  const probes = <String>[
    '.well-known/assetlinks.json',
    'build/web/.well-known/assetlinks.json',
  ];
  return probes.any((path) => _gitignoreMatch(pattern, path));
}

/// Enough of gitignore-style matching to catch the patterns that hide
/// `.well-known`. Not a full ignore implementation.
bool _gitignoreMatch(String pattern, String path) {
  var expression = pattern;
  if (expression.startsWith('/')) {
    expression = expression.substring(1);
  }
  final body = expression
      .replaceAll('.', r'\.')
      .replaceAll('**/', '(?:.*/)?')
      .replaceAll('**', '.*')
      .replaceAll('*', '[^/]*');
  return RegExp('(?:^|/)$body(?:\$|/)').hasMatch(path) || RegExp('^$body\$').hasMatch(path);
}
