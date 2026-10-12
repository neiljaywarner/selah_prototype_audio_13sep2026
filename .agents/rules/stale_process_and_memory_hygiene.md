# Rule: Stale Process and Memory Hygiene

To ensure predictable performance, prevent port collision, and avoid unnecessary RAM consumption on developer and agent workstations, the following hygiene practices are mandatory:

## 1. Ephemeral Process Lifecycle Management
- **Immediate Termination**: Any background daemon or helper started for transient verification (e.g., `python3 -m http.server`, local test proxies, ADB port forwarders, or headless browser instances) MUST be explicitly terminated immediately after verification completes using `manage_task(Action='kill')`.
- **No Orphan Daemons**: Never leave local web servers or mock services running across session milestones.

## 2. Robust Teardown in Test and Automation Scripts
- **Mandatory `try...finally`**: All Node/Puppeteer/Playwright and Python automation scripts must wrap browser instances and network servers in `try...finally` blocks to guarantee `.close()` or `.terminate()` is invoked even on unhandled exceptions or test failures.
- **Explicit Signal Handlers**: Scripts with persistent listeners should trap `SIGINT` and `SIGTERM` to clean up child processes cleanly.

## 3. Routine Stale Process Audits
- Before executing memory-intensive builds (`flutter build web`, `flutter build apk`, Xcode compilation), inspect running processes for stale instances of:
  - Lingering headless Chrome / Chromium instances
  - Stray `http.server` or `live-server` listeners on test ports (e.g., 8080, 8089)
  - Orphaned `dart` or `flutter_tester` background processes
- Terminate any identified stale processes before beginning compilation.

## 4. Simulator and Virtual Device Conservation
- Only keep target devices booted when actively testing. Shut down secondary emulators or simulators when moving to web-only or unit-testing phases.
