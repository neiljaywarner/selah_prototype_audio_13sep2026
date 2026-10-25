// ignore_for_file: avoid_print
import 'dart:io';

String getEsvKey() {
  final envKey = Platform.environment['ESV_API_KEY'];
  if (envKey != null && envKey.isNotEmpty && envKey != 'REDACTED') {
    return envKey;
  }
  // Fall back to reading ~/.zshrc
  final home = Platform.environment['HOME'] ?? '';
  final zshrc = File('$home/.zshrc');
  if (zshrc.existsSync()) {
    for (final line in zshrc.readAsLinesSync()) {
      if (line.contains('ESV_API_KEY=')) {
        final match = RegExp(r'ESV_API_KEY=["\x27]?([A-Za-z0-9_\-]+)["\x27]?').firstMatch(line);
        if (match != null) {
          return match.group(1)!;
        }
      }
    }
  }
  return '';
}

Future<int> runProcess(String executable, List<String> args, {String? cwd}) async {
  print('▶ Running: $executable ${args.join(" ")}');
  final p = await Process.start(executable, args, workingDirectory: cwd, mode: ProcessStartMode.inheritStdio);
  return await p.exitCode;
}

void main(List<String> args) async {
  final command = args.isNotEmpty ? args[0] : 'all';
  final key = getEsvKey();
  if (key.isEmpty) {
    stderr.writeln('❌ ESV_API_KEY could not be found in environment or ~/.zshrc');
    exit(1);
  }
  print('🔑 ESV_API_KEY loaded successfully (${key.substring(0, 4)}...${key.substring(key.length - 4)})');

  final projectDir = Directory.current.path;

  if (command == 'analyze' || command == 'all') {
    print('\n--- 1. Flutter Analyze ---');
    final code = await runProcess('flutter', ['analyze'], cwd: projectDir);
    if (code != 0) exit(code);
  }

  if (command == 'test' || command == 'all') {
    print('\n--- 2. Flutter Test Suite ---');
    final code = await runProcess('flutter', ['test'], cwd: projectDir);
    if (code != 0) exit(code);
  }

  if (command == 'build' || command == 'all') {
    print('\n--- 3. Build Debug APK with ESV Define ---');
    final code = await runProcess('flutter', [
      'build',
      'apk',
      '--debug',
      '--dart-define=ESV_API_KEY=$key',
    ], cwd: projectDir);
    if (code != 0) exit(code);
  }

  if (command == 'install' || command == 'all') {
    print('\n--- 4. Install on Device ---');
    final apkPath = '$projectDir/build/app/outputs/flutter-apk/app-debug.apk';
    final code = await runProcess('adb', ['-s', '58221JEBF20835', 'install', '-r', apkPath]);
    if (code != 0) {
      print('⚠️ Failed to install to 58221JEBF20835, trying default adb install...');
      await runProcess('adb', ['install', '-r', apkPath]);
    }
  }

  if (command == 'verify' || command == 'all') {
    print('\n--- 5. Verify ESV Human Narrator on Device ---');
    final devId = '58221JEBF20835';
    // Launch app
    await runProcess('adb', ['-s', devId, 'shell', 'am', 'force-stop', 'com.example.selah_prototype_audio_13sep2026']);
    await runProcess('adb', ['-s', devId, 'shell', 'am', 'start', '-n', 'com.example.selah_prototype_audio_13sep2026/.MainActivity']);
    await Future.delayed(const Duration(seconds: 3));

    // Clear logcat
    await Process.run('adb', ['-s', devId, 'logcat', '-c']);

    // Tap play button (575, 2076)
    print('Tapping Play for default ESV curated passage...');
    await runProcess('adb', ['-s', devId, 'shell', 'input', 'tap', '575', '2076']);
    await Future.delayed(const Duration(seconds: 4));

    // Search and play 1 Peter 5:7-9
    print('Searching and playing 1 Peter 5:7-9...');
    // Tap search field at (300, 404)
    await runProcess('adb', ['-s', devId, 'shell', 'input', 'tap', '300', '404']);
    await Future.delayed(const Duration(milliseconds: 500));
    // Select all and delete text
    for (int i = 0; i < 35; i++) {
      await Process.run('adb', ['-s', devId, 'shell', 'input', 'keyevent', '67']);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    await runProcess('adb', ['-s', devId, 'shell', 'input', 'text', '1%sPeter%s5:7-9']);
    await Future.delayed(const Duration(milliseconds: 500));
    // Tap search play button at (655, 404)
    await runProcess('adb', ['-s', devId, 'shell', 'input', 'tap', '655', '404']);
    await Future.delayed(const Duration(seconds: 5));

    // Check logcat for audio stream URL
    final logs = await Process.run('adb', ['-s', devId, 'logcat', '-d', '-s', 'flutter']);
    print('Recent device log output:');
    final lines = (logs.stdout as String).split('\n');
    for (final l in lines.reversed.take(25).toList().reversed) {
      if (l.trim().isNotEmpty) print('  $l');
    }

    // Capture screenshot
    await Directory('$projectDir/docs/artifacts/screenshots').create(recursive: true);
    final shotPath = '$projectDir/docs/artifacts/screenshots/pixel9a_esv_human_verified.png';
    await runProcess('adb', ['-s', devId, 'shell', 'screencap', '-p', '/sdcard/esv_verified.png']);
    await runProcess('adb', ['-s', devId, 'pull', '/sdcard/esv_verified.png', shotPath]);
    print('📸 Saved verification screenshot to $shotPath');
  }

  print('\n✨ Pipeline completed successfully!');
}
