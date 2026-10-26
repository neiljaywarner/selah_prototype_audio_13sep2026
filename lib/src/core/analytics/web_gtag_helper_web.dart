import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// JS interop binding to the global `window.gtag` function initialized in `web/index.html`.
@JS('gtag')
external void _gtag(JSString command, JSString action, [JSAny? params]);

bool isMarionetteDriving = false;
bool isMaestroDriving = false;
bool isPatrolDriving = false;
bool isPwaRunning = false;
bool isWebApkRunning = false;

void setMarionetteDriving(bool active) {
  isMarionetteDriving = active;
  setGtagUserProperty('marionette_driving', active.toString());
}

void setMaestroDriving(bool active) {
  isMaestroDriving = active;
  setGtagUserProperty('maestro_driving', active.toString());
}

void setPatrolDriving(bool active) {
  isPatrolDriving = active;
  setGtagUserProperty('patrol_driving', active.toString());
}

void setPwaRunning(bool active) {
  isPwaRunning = active;
  setGtagUserProperty('is_pwa', active.toString());
}

void setWebApkRunning(bool active) {
  isWebApkRunning = active;
  setGtagUserProperty('is_webapk', active.toString());
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
      'maestro_driving': isMaestroDriving,
      'patrol_driving': isPatrolDriving,
      'is_pwa': isPwaRunning,
      'is_webapk': isWebApkRunning,
      ...?parameters,
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
