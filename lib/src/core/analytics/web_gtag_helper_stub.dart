/// Stub implementation for non-web platforms (Android, iOS, macOS, Windows, Linux).
library;

bool isMarionetteDriving = false;
bool isMaestroDriving = false;
bool isPatrolDriving = false;
bool isPwaRunning = false;
bool isWebApkRunning = false;

void setMarionetteDriving(bool active) {
  isMarionetteDriving = active;
}

void setMaestroDriving(bool active) {
  isMaestroDriving = active;
}

void setPatrolDriving(bool active) {
  isPatrolDriving = active;
}

void setPwaRunning(bool active) {
  isPwaRunning = active;
}

void setWebApkRunning(bool active) {
  isWebApkRunning = active;
}

void setGtagUserProperty(String name, String value) {
  // No-op on native platforms.
}

void sendGtagEvent(String eventName, Map<String, dynamic>? parameters) {
  // No-op on native platforms.
}
