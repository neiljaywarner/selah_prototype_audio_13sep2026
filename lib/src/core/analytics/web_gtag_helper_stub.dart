/// Stub implementation for non-web platforms (Android, iOS, macOS, Windows, Linux).
///
/// On native platforms, telemetry is dispatched through native analytics pipelines
/// (e.g., Android Firebase SDK / Aptabase / PostHog) rather than `window.gtag`.
library;


bool isMarionetteDriving = false;

void setMarionetteDriving(bool active) {
  isMarionetteDriving = active;
}

void setGtagUserProperty(String name, String value) {
  // No-op on native platforms.
}

void sendGtagEvent(String eventName, Map<String, dynamic>? parameters) {
  // No-op on native platforms.
}
