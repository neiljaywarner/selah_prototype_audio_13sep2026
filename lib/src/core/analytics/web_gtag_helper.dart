/// Cross-platform conditional export bridge for Google Tag (`gtag.js`) analytics dispatch.
///
/// Dispatches to:
/// - `web_gtag_helper_web.dart` on Web targets where `dart.library.js_interop` is available.
/// - `web_gtag_helper_stub.dart` on native mobile/desktop platforms as a safe no-op.
library;

export 'web_gtag_helper_stub.dart'
    if (dart.library.js_interop) 'web_gtag_helper_web.dart';

