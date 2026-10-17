# ADR-001: Bottom Navigation Bar Library Selection for v0.5.0

## Status
**Accepted** (Targeted for Release v0.5.0)

## Context & Problem Statement
Selah is expanding from a single-screen focused Scripture loop player into a comprehensive contemplative sanctuary offering three distinct experiential modes:
1. **🕊️ Prayer Mode**: Long contemplative pauses (15s–60s) with ambient prayer pads.
2. **🌿 Meditation Mode**: Calibrated core loop (3s–7s) with gold word karaoke and tactile haptics.
3. **💡 Memorization Mode**: Prominent countdown arc, progressive word occlusion, and Gemini AI voice checking.
4. **🏛️ Sanctuary Tab**: Consolidated profile, spiritual streak, reflection journal, feature voting roadmap, and settings.

Currently, auxiliary features (topic tabs, settings bottom sheet, about dialog, feature voting, feedback) clutter the top `AppBar` with multiple action buttons and overflow menus. 

We need a modern, "cute", delightful, and lightweight bottom navigation bar to switch between these 4 spaces without adding visual noise or feeling corporate.

---

## Decision Drivers
1. **Cute, Friendly & Delightful Aesthetic**: Playful animated transitions (e.g. pill expansion, icon color morphing) that evoke peace and delight.
2. **Low Overhead & Memory Safety**: Minimal dependency footprint to respect low-memory target devices (preventing Antigravity IDE/device memory pressure).
3. **Accessibility & Safe Areas**: Native Flutter `Semantics` support and bottom-inset handling across notched and gesture-nav Android/iOS screens.
4. **Active Maintenance & Flutter 3 / Impeller Compatibility**: Proven compatibility with modern Flutter rendering engines.

---

## Considered Options

### Option 1: `salomon_bottom_bar` (Selected)
- **Pub.dev**: `https://pub.dev/packages/salomon_bottom_bar`
- **Description**: Designed by Salomon Diei, this library transforms bottom navigation into a series of playful, rounded pill bubbles. Unselected items show just an icon; the selected item expands smoothly into a rounded pill filled with an accent color and readable label.
- **Pros**:
  - Extremely "cute", joyful, and friendly feel; fits the warm, peaceful Selah design ethos.
  - Per-item custom accent colors:
    - 🕊️ Prayer: Warm Rose / Coral (`#FB7185`)
    - 🌿 Meditation: Emerald / Mint (`#34D399`)
    - 💡 Memorize: Golden Amber (`#FBBF24`)
    - 🏛️ Sanctuary: Soft Indigo (`#818CF8`)
  - Zero external native dependencies; pure Dart widget animation.
  - Very lightweight (< 15 KB).
- **Cons**:
  - Does not support arbitrary floating badge overlays out-of-the-box (can be added via custom wrapper).

### Option 2: `google_nav_bar` (GNav)
- **Pub.dev**: `https://pub.dev/packages/google_nav_bar`
- **Description**: A modern floating pill navigation bar popular in fitness and meditation apps (Nike, Calm style).
- **Pros**:
  - Highly customizable padding, border radius, and haptic response.
  - Built-in tab badge support for notification counts.
- **Cons**:
  - Slightly more rigid configuration syntax.
  - Less playful/cute than `salomon_bottom_bar` (feels more athletic/corporate than contemplative).

### Option 3: Flutter Native Material 3 `NavigationBar`
- **Pub.dev**: Built into Flutter SDK (`flutter/material.dart`).
- **Description**: Standard Material Design 3 navigation bar with pill indicator.
- **Pros**:
  - Zero third-party dependencies.
  - Automatic system theme and accessibility integration.
- **Cons**:
  - M3 pill styling can feel standard and conventional rather than distinctively "cute" and crafted.
  - Animating individual tab colors requires verbose custom theme overriding.

---

## Decision
We select **Option 1: `salomon_bottom_bar`** as the primary bottom navigation library for Selah v0.5.0, with Flutter Native `NavigationBar` as our architectural fallback.

### Implementation Blueprint
```dart
SalomonBottomBar(
  currentIndex: _selectedTabIndex,
  onTap: (i) => setState(() => _selectedTabIndex = i),
  backgroundColor: const Color(0xFF0F0E26),
  items: [
    SalomonBottomBarItem(
      icon: const Icon(Icons.favorite_border_rounded),
      title: const Text('Prayer'),
      selectedColor: const Color(0xFFFB7185), // Warm Rose
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.spa_rounded),
      title: const Text('Meditate'),
      selectedColor: const Color(0xFF34D399), // Emerald Mint
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.lightbulb_outline_rounded),
      title: const Text('Memorize'),
      selectedColor: const Color(0xFFFBBF24), // Golden Amber
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.account_balance_rounded),
      title: const Text('Sanctuary'),
      selectedColor: const Color(0xFF818CF8), // Soft Indigo
    ),
  ],
)
```

---

## Consequences & Mitigations
- **Dependency Ingestion**: Add `salomon_bottom_bar: ^3.3.2` to `pubspec.yaml` when beginning v0.5.0 milestone.
- **Top AppBar Decluttering**: Move About, Settings, and Feature Voting into the **Sanctuary** tab, leaving the top AppBar serenely minimal (only the current passage title and translation badge).
- **Testability**: Fast widget tests will verify tab switching and index persistence with mock viewports.
