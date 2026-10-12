import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// JS interop binding to the global `window.gtag` function initialized in `web/index.html`.
@JS('gtag')
external void _gtag(JSString command, JSString action, [JSAny? params]);

bool isMarionetteDriving = false;

void setMarionetteDriving(bool active) {
  isMarionetteDriving = active;
  setGtagUserProperty('marionette_driving', active.toString());
}

/// Sets a persistent user property in Google Analytics 4 (GA4).
void setGtagUserProperty(String name, String value) {
  try {
    final payload = <String, dynamic>{
      'user_properties': {name: value},
    };
    _gtag('set'.toJS, 'user_properties'.toJS, payload.jsify());
  } catch (_) {}
}

/// Forwards an analytics event and associated metadata from Flutter Dart to `window.gtag`.
void sendGtagEvent(String eventName, Map<String, dynamic>? parameters) {
  try {
    final payload = <String, dynamic>{
      'k_debug_mode': kDebugMode,
      'marionette_driving': isMarionetteDriving,
      ...?parameters,
      // In debug mode, tag event for instant routing to GA4/Firebase DebugView
      if (kDebugMode) 'debug_mode': true,
    };

    if (payload.isNotEmpty) {
      _gtag('event'.toJS, eventName.toJS, payload.jsify());
    } else {
      _gtag('event'.toJS, eventName.toJS);
    }
  } catch (_) {
    // Graceful fallback if gtag is not yet mounted on the DOM.
  }
}
