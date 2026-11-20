import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/passage_share.dart';

/// Hands the share payload to the platform.
///
/// Widget tests override this provider. The real iOS, Android, and web share
/// sheets cannot be opened under `flutter test`; [PlatformPassageShareLauncher]
/// is the thin device boundary, and the scenarios assert the payload it would
/// show.
abstract class PassageShareLauncher {
  Future<void> share(PassageSharePayload payload);
}

/// Copies the link, then opens the native share sheet with [PassageSharePayload.message].
/// The message includes the verse text when the payload has it. The clipboard
/// stays the play link, so a paste still opens the passage.
class PlatformPassageShareLauncher implements PassageShareLauncher {
  PlatformPassageShareLauncher({SharePlus? sharePlus})
    : _sharePlus = sharePlus ?? SharePlus.instance;

  final SharePlus _sharePlus;

  @override
  Future<void> share(PassageSharePayload payload) async {
    try {
      await Clipboard.setData(ClipboardData(text: payload.url));
    } catch (error) {
      AppLogger.warning('Could not copy the passage link: $error');
    }
    await _sharePlus.share(
      ShareParams(
        text: payload.message,
        subject: 'Selah · ${payload.reference}',
      ),
    );
  }
}

final passageShareLauncherProvider = Provider<PassageShareLauncher>(
  (ref) => PlatformPassageShareLauncher(),
);
