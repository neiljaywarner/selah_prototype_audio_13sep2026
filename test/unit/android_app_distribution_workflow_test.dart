import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contract for the main-branch Android App Distribution workflow.
///
/// These checks stay in `flutter test` so a release job cannot upload a build
/// that skipped signing, certificate, or secret handling.
void main() {
  const workflowPath = '.github/workflows/android_app_distribution.yml';
  const previewPath = '.github/workflows/pr_preview_channel.yml';
  const gradlePath = 'android/app/build.gradle.kts';

  test('main pushes build an APK and upload only after signing checks', () {
    final workflowFile = File(workflowPath);
    expect(workflowFile.existsSync(), isTrue, reason: workflowPath);
    final workflow = workflowFile.readAsStringSync();
    final preview = File(previewPath).readAsStringSync();

    final workflowFlutter = RegExp(
      r"flutter-version:\s*'([^']+)'",
    ).firstMatch(workflow)?.group(1);
    final previewFlutter = RegExp(
      r"flutter-version:\s*'([^']+)'",
    ).firstMatch(preview)?.group(1);
    expect(workflowFlutter, previewFlutter);
    expect(workflowFlutter, '3.47.x');

    expect(workflow, contains('workflow_dispatch:'));
    expect(workflow, contains('release_notes:'));
    expect(workflow, contains('- main'));
    expect(workflow, contains('contents: read'));
    expect(workflow, contains('pull-requests: read'));
    expect(workflow, contains("java-version: '17'"));
    expect(workflow, contains('flutter build apk --release'));
    expect(workflow, contains('app.selahword.audio'));
    expect(
      workflow,
      contains('1:228765786696:android:b477acdfcb898d30382e7d'),
    );
    expect(workflow, contains('core-testers'));
    expect(workflow, contains('selahwordapp'));
    expect(workflow, contains('scripts/android_distribution_preflight.sh'));
    expect(workflow, contains('scripts/compose_android_release_notes.sh'));
    expect(workflow, contains('scripts/verify_apk_cert_fingerprint.py'));
    expect(workflow, contains('scripts/write_android_signing_files.py'));
    expect(workflow, contains('scripts/write_dart_defines.py'));
    expect(workflow, contains('scripts/write_secret_file.py'));
    expect(workflow, contains('--apk'));
    expect(workflow, contains('web/.well-known/assetlinks.json'));
    expect(workflow, contains('gh pr view'));
    expect(workflow, contains('set -euo pipefail'));
    expect(workflow, contains('GOOGLE_APPLICATION_CREDENTIALS'));
    expect(workflow, contains('appdistribution:distribute'));
    expect(workflow, contains('GITHUB_STEP_SUMMARY'));
    expect(workflow, contains('androiddebugkey'));
    expect(workflow, contains('~/.android/debug.keystore'));

    final buildAt = workflow.indexOf('flutter build apk --release');
    final verifyAt = workflow.indexOf('verify_apk_cert_fingerprint.py');
    final uploadAt = workflow.indexOf('appdistribution:distribute');
    expect(buildAt, greaterThan(0));
    expect(verifyAt, greaterThan(buildAt));
    expect(uploadAt, greaterThan(verifyAt));

    expect(workflow, isNot(contains('continue-on-error: true')));
    expect(workflow, isNot(contains('set -x')));
    expect(workflow, isNot(contains('action-hosting-deploy')));
    expect(workflow, isNot(contains('firebase deploy')));
    expect(workflow, isNot(contains('selahword.web.app')));
    expect(workflow, isNot(contains('BEGIN PRIVATE KEY')));
    expect(workflow, isNot(contains('private_key')));
    expect(workflow, isNot(contains('86:13:09:5F')));

    const secretNames = [
      'ANDROID_KEYSTORE_BASE64',
      'ANDROID_KEYSTORE_PASSWORD',
      'ANDROID_KEY_PASSWORD',
      'ANDROID_KEY_ALIAS',
      'FIREBASE_SERVICE_ACCOUNT_SELAHWORDAPP',
      'API_BIBLE_KEY',
      'APTABASE_KEY',
      'POSTHOG_KEY',
      'ESV_API_KEY',
    ];
    for (final name in secretNames) {
      expect(workflow, contains('secrets.$name'));
      expect(workflow, isNot(contains('echo "\$$name"')));
      expect(workflow, isNot(contains("echo '\$$name'")));
    }
  });

  test('release builds sign with key.properties and otherwise stay on debug', () {
    final gradle = File(gradlePath).readAsStringSync();
    expect(gradle, contains('applicationId = "app.selahword.audio"'));
    expect(gradle, contains('rootProject.file("key.properties")'));
    expect(
      gradle,
      contains(
        'keystorePropertiesFile.reader(Charsets.UTF_8).use { keystoreProperties.load(it) }',
      ),
    );
    expect(
      RegExp(
        r'signingConfig\s*=\s*if\s*\(\s*keystorePropertiesFile\.exists\(\)\s*\)',
      ).hasMatch(gradle),
      isTrue,
      reason: gradle,
    );
    expect(gradle, contains('signingConfigs.getByName("release")'));
    expect(gradle, contains('signingConfigs.getByName("debug")'));
  });

  test('preflight lists missing secret names and hides values that are set', () {
    const canary = 'CANARY-KEYSTORE-VALUE-9f3a';
    final result = _run('bash', ['scripts/android_distribution_preflight.sh'], {
      'ANDROID_KEYSTORE_BASE64': canary,
    });
    expect(result.exitCode, isNot(0));
    final output = '${result.stdout}${result.stderr}';
    expect(output, contains('- ANDROID_KEYSTORE_PASSWORD:'));
    expect(output, contains('- ANDROID_KEY_PASSWORD:'));
    expect(output, contains('- ANDROID_KEY_ALIAS:'));
    expect(output, contains('- FIREBASE_SERVICE_ACCOUNT_SELAHWORDAPP:'));
    expect(output, isNot(contains('- ANDROID_KEYSTORE_BASE64:')));
    expect(output, isNot(contains('- API_BIBLE_KEY:')));
    expect(output, isNot(contains(canary)));
  });

  test('preflight passes when required secrets are set and prints no values', () {
    const canary = 'CANARY-DO-NOT-LEAK-9f3a';
    final result = _run('bash', ['scripts/android_distribution_preflight.sh'], {
      'ANDROID_KEYSTORE_BASE64': canary,
      'ANDROID_KEYSTORE_PASSWORD': canary,
      'ANDROID_KEY_PASSWORD': canary,
      'ANDROID_KEY_ALIAS': 'androiddebugkey',
      'FIREBASE_SERVICE_ACCOUNT_SELAHWORDAPP': '{"client_email":"$canary"}',
    });
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    final output = '${result.stdout}${result.stderr}';
    expect(output, isNot(contains(canary)));
    expect(output, isNot(contains('androiddebugkey')));
  });

  test('release notes use the commit subject without executing it', () {
    final result = _run('bash', ['scripts/compose_android_release_notes.sh'], {
      'APP_VERSION': '0.4.1+53',
      'COMMIT_SUBJECT': r'Keep ranges (#267) $(echo LEAKED) %s',
      'COMMIT_BODY': '',
      'COMMIT_SHA': 'abc123def',
    });
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    expect(result.stdout, contains('Selah Scripture Audio Meditation v0.4.1+53'));
    expect(
      result.stdout,
      contains(r'Keep ranges (#267) $(echo LEAKED) %s'),
    );
    expect(result.stdout, contains('Commit: abc123def'));
    expect(result.stdout, isNot(contains('LEAKED\n')));
  });

  test('merge commits prefer the pull request title in the commit body', () {
    final result = _run('bash', ['scripts/compose_android_release_notes.sh'], {
      'APP_VERSION': '0.4.1+53',
      'COMMIT_SUBJECT':
          'Merge pull request #267 from neiljaywarner/cursor/ranges',
      'COMMIT_BODY':
          'Keep exact verse ranges in My passages (#267)\n\nMore detail.',
      'COMMIT_SHA': 'abc123def',
    });
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    expect(
      result.stdout,
      contains('Keep exact verse ranges in My passages (#267)'),
    );
    expect(result.stdout, isNot(contains('Merge pull request #267')));
  });

  test('manual release notes replace the commit title', () {
    final result = _run('bash', ['scripts/compose_android_release_notes.sh'], {
      'APP_VERSION': '0.4.1+53',
      'COMMIT_SUBJECT': 'chore: unrelated',
      'COMMIT_BODY': '',
      'COMMIT_SHA': 'abc123def',
      'NOTES_OVERRIDE': 'Manual smoke for core testers',
    });
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    expect(result.stdout, contains('Manual smoke for core testers'));
    expect(result.stdout, isNot(contains('chore: unrelated')));
  });

  test('assetlinks certificate text matches colon and hex spellings', () {
    final matched = _certResult('''
Signer #1 certificate SHA-256 digest: 8613095f66790e0cea7edac3ca62d347ebf510a6553d66a12e6fd95ae1649ef2
''');
    expect(matched.exitCode, 0, reason: '${matched.stdout}${matched.stderr}');

    final colonForm = _certResult('''
Certificate fingerprints:
	 SHA256: 86:13:09:5F:66:79:0E:0C:EA:7E:DA:C3:CA:62:D3:47:EB:F5:10:A6:55:3D:66:A1:2E:6F:D9:5A:E1:64:9E:F2
''');
    expect(
      colonForm.exitCode,
      0,
      reason: '${colonForm.stdout}${colonForm.stderr}',
    );
  });

  test('a certificate that misses assetlinks fails closed', () {
    final result = _certResult('''
Signer #1 certificate SHA-256 digest: 00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff
''');
    expect(result.exitCode, isNot(0));
    final output = '${result.stdout}${result.stderr}';
    expect(output, contains('assetlinks.json'));
    expect(output, contains('00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff'));
    expect(
      output,
      contains(
        '86:13:09:5F:66:79:0E:0C:EA:7E:DA:C3:CA:62:D3:47:EB:F5:10:A6:55:3D:66:A1:2E:6F:D9:5A:E1:64:9E:F2',
      ),
    );
  });

  test('signing files round-trip the keystore and stay out of stdout', () {
    final dir = Directory.systemTemp.createTempSync('selah-sign');
    addTearDown(() => dir.deleteSync(recursive: true));
    final keystoreBytes = utf8.encode('keystore-bytes-v1');
    const password = 'p#ass word=!';
    final encoded = base64Encode(keystoreBytes);
    final result = _run('python3', [
      'scripts/write_android_signing_files.py',
      '--properties-file',
      '${dir.path}/key.properties',
      '--keystore-file',
      '${dir.path}/ci-release.keystore',
      '--store-file-property',
      'ci-release.keystore',
    ], {
      'ANDROID_KEYSTORE_BASE64': encoded,
      'ANDROID_KEYSTORE_PASSWORD': password,
      'ANDROID_KEY_PASSWORD': password,
      'ANDROID_KEY_ALIAS': 'androiddebugkey',
    });
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    final output = '${result.stdout}${result.stderr}';
    expect(output, isNot(contains(password)));
    expect(output, isNot(contains(encoded)));
    expect(
      File('${dir.path}/ci-release.keystore').readAsBytesSync(),
      keystoreBytes,
    );
    final properties = File('${dir.path}/key.properties').readAsStringSync();
    expect(properties, contains('storeFile=ci-release.keystore'));
    expect(properties, contains('keyAlias=androiddebugkey'));
    expect(properties, contains('storePassword=$password'));
    expect(_mode(File('${dir.path}/ci-release.keystore')) & 0x077, 0);
    expect(_mode(File('${dir.path}/key.properties')) & 0x077, 0);
  });

  test('signing properties round-trip through Java Properties.load', () {
    final dir = Directory.systemTemp.createTempSync('selah-props');
    addTearDown(() => dir.deleteSync(recursive: true));
    const storePassword = ' secret\twith\\slash\fand\nline';
    const keyPassword = ' leading';
    const alias = 'méditation';
    final encoded = base64Encode(utf8.encode('keystore-bytes-v2'));
    final propertiesPath = '${dir.path}/key.properties';
    final result = _run('python3', [
      'scripts/write_android_signing_files.py',
      '--properties-file',
      propertiesPath,
      '--keystore-file',
      '${dir.path}/ci-release.keystore',
      '--store-file-property',
      'ci-release.keystore',
    ], {
      'ANDROID_KEYSTORE_BASE64': encoded,
      'ANDROID_KEYSTORE_PASSWORD': storePassword,
      'ANDROID_KEY_PASSWORD': keyPassword,
      'ANDROID_KEY_ALIAS': alias,
    });
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    final output = '${result.stdout}${result.stderr}';
    expect(output, isNot(contains('secret')));
    expect(output, isNot(contains(alias)));
    expect(output, isNot(contains(encoded)));

    final javaFile = File('${dir.path}/LoadProps.java')
      ..writeAsStringSync('''
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

public class LoadProps {
  public static void main(String[] args) throws Exception {
    Properties props = new Properties();
    try (var reader = Files.newBufferedReader(Path.of(args[0]), StandardCharsets.UTF_8)) {
      props.load(reader);
    }
    Files.writeString(Path.of(args[1]), props.getProperty("storePassword"), StandardCharsets.UTF_8);
    Files.writeString(Path.of(args[2]), props.getProperty("keyPassword"), StandardCharsets.UTF_8);
    Files.writeString(Path.of(args[3]), props.getProperty("keyAlias"), StandardCharsets.UTF_8);
  }
}
''');
    final compile = Process.runSync('javac', [javaFile.path]);
    expect(compile.exitCode, 0, reason: '${compile.stdout}${compile.stderr}');
    final storeOut = '${dir.path}/store.txt';
    final keyOut = '${dir.path}/key.txt';
    final aliasOut = '${dir.path}/alias.txt';
    final loaded = Process.runSync('java', [
      '-cp',
      dir.path,
      'LoadProps',
      propertiesPath,
      storeOut,
      keyOut,
      aliasOut,
    ]);
    expect(loaded.exitCode, 0, reason: '${loaded.stdout}${loaded.stderr}');
    expect(File(storeOut).readAsStringSync(), storePassword);
    expect(File(keyOut).readAsStringSync(), keyPassword);
    expect(File(aliasOut).readAsStringSync(), alias);
  });

  test('invalid keystore base64 fails without echoing the secret', () {
    final dir = Directory.systemTemp.createTempSync('selah-sign-bad');
    addTearDown(() => dir.deleteSync(recursive: true));
    const garbage = '!!!not-base64-CANARY!!!';
    final result = _run('python3', [
      'scripts/write_android_signing_files.py',
      '--properties-file',
      '${dir.path}/key.properties',
      '--keystore-file',
      '${dir.path}/ci-release.keystore',
      '--store-file-property',
      'ci-release.keystore',
    ], {
      'ANDROID_KEYSTORE_BASE64': garbage,
      'ANDROID_KEYSTORE_PASSWORD': 'store-secret',
      'ANDROID_KEY_PASSWORD': 'key-secret',
      'ANDROID_KEY_ALIAS': 'androiddebugkey',
    });
    expect(result.exitCode, isNot(0));
    final output = '${result.stdout}${result.stderr}';
    expect(output, contains('ANDROID_KEYSTORE_BASE64'));
    expect(output, isNot(contains(garbage)));
    expect(output, isNot(contains('store-secret')));
    expect(File('${dir.path}/ci-release.keystore').existsSync(), isFalse);
  });

  test('dart defines include only non-empty allowlisted keys', () {
    final dir = Directory.systemTemp.createTempSync('selah-defines');
    addTearDown(() => dir.deleteSync(recursive: true));
    final outputPath = '${dir.path}/defines.json';
    const bible = 'BIBLE-CANARY';
    const other = 'OTHER-CANARY';
    final result = _run('python3', [
      'scripts/write_dart_defines.py',
      '--output',
      outputPath,
    ], {
      'API_BIBLE_KEY': bible,
      'APTABASE_KEY': '',
      'POSTHOG_KEY': '',
      'ESV_API_KEY': '',
      'OTHER_SECRET': other,
    });
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    final output = '${result.stdout}${result.stderr}';
    expect(output, contains('API_BIBLE_KEY'));
    expect(output, contains('value hidden'));
    expect(output, isNot(contains(bible)));
    expect(output, isNot(contains(other)));
    final defines =
        jsonDecode(File(outputPath).readAsStringSync()) as Map<String, dynamic>;
    expect(defines, {'API_BIBLE_KEY': bible});
    expect(_mode(File(outputPath)) & 0x077, 0);
  });

  test('firebase credential file is written unprinted and mode 0600', () {
    final dir = Directory.systemTemp.createTempSync('selah-sa');
    addTearDown(() => dir.deleteSync(recursive: true));
    final outputPath = '${dir.path}/sa.json';
    const canary = 'CANARY-PRIVATE-KEY-VALUE';
    final json = '{"private_key":"$canary","client_email":"sa@example.iam.gserviceaccount.com"}';
    final result = _run('python3', [
      'scripts/write_secret_file.py',
      '--env',
      'FIREBASE_SERVICE_ACCOUNT_SELAHWORDAPP',
      '--output',
      outputPath,
    ], {'FIREBASE_SERVICE_ACCOUNT_SELAHWORDAPP': json});
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    expect('${result.stdout}${result.stderr}', isNot(contains(canary)));
    expect(File(outputPath).readAsStringSync(), json);
    expect(_mode(File(outputPath)) & 0x077, 0);
  });
}

ProcessResult _certResult(String text) {
  final dir = Directory.systemTemp.createTempSync('selah-cert');
  addTearDown(() => dir.deleteSync(recursive: true));
  final sample = File('${dir.path}/cert.txt')..writeAsStringSync(text);
  return _run('python3', [
    'scripts/verify_apk_cert_fingerprint.py',
    '--cert-text',
    sample.path,
    '--assetlinks',
    'web/.well-known/assetlinks.json',
  ], {});
}

ProcessResult _run(
  String executable,
  List<String> arguments,
  Map<String, String> extra,
) {
  return Process.runSync(executable, arguments, environment: {
    'PATH': Platform.environment['PATH'] ?? '',
    'HOME': Platform.environment['HOME'] ?? '',
    'LANG': Platform.environment['LANG'] ?? 'C.UTF-8',
    ...extra,
  });
}

int _mode(File file) => file.statSync().mode;
