# ☕️ Doppio — Keep-Awake Menu Bar Utility for macOS

<p align="center">
  <b>English</b> •
  <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square&logo=apple&logoColor=white" alt="macOS 14.0+" />
  <img src="https://img.shields.io/badge/Swift-6.4-orange?style=flat-square&logo=swift&logoColor=white" alt="Swift 6.4" />
  <img src="https://img.shields.io/badge/Architecture-Universal-brightgreen?style=flat-square" alt="Universal" />
  <img src="https://img.shields.io/badge/Version-1.5.0-purple?style=flat-square" alt="Version 1.5.0" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License MIT" />
</p>

> **Doppio** is a modern, lightweight, and battery-efficient menu bar utility for macOS designed to prevent your Mac from sleeping during long-running tasks, presentations, file transfers, compilations, or media renders.

Crafted specifically for macOS Sonoma and Sequoia with modern Swift 6 strict concurrency, native Liquid Glass styling, and zero-idle CPU overhead.

---

## ✨ Features at a Glance

### 🪟 Native macOS Menu & SF Symbols
- **System-Native Menu (`NSMenu`)**: Clean dropdown interface adhering to Apple Human Interface Guidelines with native 6pt corner radii and subtle Liquid Glass materials.
- **Monochrome Apple SF Symbols**: High-contrast, automatically tinted vector icons that look crisp in both light and dark macOS appearance.
- **Instant Preset Activation**: 1-click timer engagement marked with system checkmarks (`✓`), interactive session extension submenus, and quick custom timer inputs.

### ⚙️ Liquid Glass Settings Window (`⌘,`)
- **Fixed Calibrated Geometry**: Precisely sized at `360 × 355 pt` to accommodate all sections seamlessly without jarring window resizes, scrollbars, or layout shifts.
- **Native Titlebar Integration**: Seamless macOS traffic-light buttons and spring-animated tab transitions.
- **3 Logical Preference Panels**:
  - **General**: Interface language, launch at login, menu bar display format, low battery thresholds, and notifications.
  - **Automation**: Smart app triggers, AC power plug-in rules, external display detection, and battery safety cutoffs.
  - **About**: Version information, release details, GitHub update checker, and repository links.

### 🔄 In-App GitHub Releases Updater
- **Direct GitHub Releases API Integration**: Seamlessly checks updates against `banzaez/doppio`.
- **Interactive Update Dialogs**: View release notes and launch direct updates with a single click.
- **Automated Daily Checks**: Optional background update verification once every 24 hours.

### ⚡️ Quick Toggle & Headless Mode
- **Dual Mouse Click Support**: Left or right click on the menu bar icon toggles the full menu extra.
- **Option-Click (`⌥-Click`) Headless Toggle**: Instantly activate or deactivate keep-awake without expanding the menu extra or disturbing your workflow.

### 📱 Notch-Aware Menu Bar Modes
- **Standard Mode**: Displays the coffee cup icon with live countdown timer (`☕️ 45m`).
- **Minimalist Mode**: Displays icon only (`☕️`) to preserve precious menu bar real estate on notched MacBook displays.

### 🤖 Smart Automation Triggers
- **Application Triggers**: Automatically keeps your Mac awake while resource-intensive programs (e.g., Xcode, Final Cut Pro, Blender, Zoom) are running, and automatically releases sleep assertions upon termination.
- **1-Click Process Picker**: Instantly select from running user processes with cached app icons, or browse any `.app` bundle via the native open dialog.
- **AC Power Detection**: Automatically start keep-awake when connected to a charger, and revert when running on battery.
- **External Display Detection**: Keep the system awake whenever an external monitor or projector is connected.
- **Instant Wake Synchronization**: Listens for system wake notifications (`NSWorkspace.didWakeNotification`) to immediately resynchronize sleep timers and assertion states.

### ⏱ Presets & Custom Duration Stepper
- **Quick Presets**: `∞ Indefinite`, `15m`, `30m`, `1h`, `2h`, `4h`.
- **Custom Timer Stepper**: Tactile glass stepper with `−` / `+` controls in 5-minute increments (from 1 to 720 minutes), avoiding keyboard focus traps.

### 🖥 Two Sleep Prevention Modes
- **Display & System**: Keeps both the display and system awake. The screen will not dim or lock (ideal for reading, webinars, and live presentations).
- **System Only**: Allows the display to sleep normally to conserve power and protect the screen, while keeping the CPU, background render pipelines, network transfers, and servers active.

### 🛡 Intelligent Battery Protection
- **Low-Battery Auto-Stop**: Automatically releases sleep locks if battery charge drops below a configurable threshold (10% to 30%), preventing your Mac from dying unexpectedly while untethered.
- **Live Battery Status**: Real-time power monitoring with power source indicators (AC Power / Battery / Charging).

### 🔔 Interactive User Notifications
- Sends a native macOS notification 1 minute before the keep-awake session expires.
- Banner actions allow you to extend the session by **"+15 min"** or switch to **"∞ Indefinite"** directly from the notification prompt.

### 🌐 Multilingual & Auto-Detection
- Fully localized in **English**, **Ukrainian**, **Russian**, **German**, **French**, and **Spanish**.
- Automatic language detection based on system preferences (`Locale.preferredLanguages`) on first launch, with the ability to override manually in Settings.

---

## 🏛 Architecture & Engineering Standards

Doppio is built following modern macOS & Swift engineering standards:

```
┌────────────────────────────────────────────────────────┐
│                      DoppioApp                         │
│       (@main, MenuBarExtra, LSUIElement = true)        │
└──────────────────────────┬─────────────────────────────┘
                           │
             ┌─────────────▼─────────────┐
             │       DoppioState         │
             │   (@Observable MainActor) │
             └──────┬─────────────┬──────┘
                    │             │
        ┌───────────▼──┐       ┌──▼────────────────┐
        │ SleepActor   │       │ Background Svcs   │
        │ Swift Actor  │       │ - SmartTriggers   │
        │ IOKit Assert │       │ - BatteryMonitor  │
        └──────────────┘       │ - AppUpdate       │
                               │ - SessionTimer    │
                               └───────────────────┘
```

1. **Swift 6 & Strict Concurrency**:
   - `SleepAssertionService` is an isolated **Swift Actor**, ensuring thread-safe manipulation of `IOPMAssertionID` descriptors without race conditions.
   - Session timing is handled via `ContinuousClock` and structured `Task` loops, making countdowns impervious to system clock / NTP adjustments.
   - Strict `@Sendable` boundaries and actor isolation across background services.
2. **SwiftUI & Observation**:
   - Central application state (`DoppioState`) utilizes Apple's `@Observable` macro on `@MainActor`.
   - Runs with `LSUIElement = true` and `NSApplication.ActivationPolicy.accessory`, living strictly in the menu bar without cluttering the macOS Dock.
   - Zero-Idle CPU footprint: adaptive tick interval (1 second when UI is active, down to 60 seconds in background).
3. **IOKit Subsystems**:
   - `IOKit.pwr_mgt`: Low-level creation and reliable release of `kIOPMAssertionTypePreventUserIdleDisplaySleep` and `kIOPMAssertionTypePreventUserIdleSystemSleep`.
   - `IOKit.ps`: Native hardware power state polling via `IOPSCopyPowerSourcesInfo`.
4. **ServiceManagement Framework**:
   - Uses `SMAppService.mainApp` — modern macOS launch-at-login API without legacy helper daemons or background scripting bridges.
5. **Swift Testing**:
   - 100% core test suite implemented with Apple's modern `Testing` framework (`@Suite`, `@Test`, `#expect`).

---

## 🚀 Getting Started

### System Requirements
- **macOS 14.0 (Sonoma)** or later (including macOS 15+ Sequoia).
- Compatible with Apple Silicon (M1/M2/M3/M4) and Intel Macs.

### Run Prebuilt Application
If you have downloaded the release archive:
```bash
open Doppio.app
```

### Build from Source
Ensure Xcode 15.3+ or Swift 6.0+ toolchain is installed:

```bash
# Clone the repository
git clone https://github.com/banzaez/doppio.git
cd doppio

# Build the signed standalone application bundle
./build_app.sh

# Open the compiled app
open Doppio.app
```

### Run and Test with Swift CLI
```bash
# Run locally
swift run

# Execute comprehensive test suite
swift test
```

---

## 📂 Project Structure

```text
doppio/
├── Doppio.app/               # Compiled macOS Application Bundle
├── Package.swift             # Swift Package Manager Manifest (Swift 6.4)
├── build_app.sh              # Release bundle packager and ad-hoc code signer
├── generate_icon.swift       # Vector icon synthesis utility
├── README.md                 # English documentation
├── README.ru.md              # Russian documentation
├── Sources/
│   └── Doppio/
│       ├── DoppioApp.swift   # App entry point (@main, MenuBarExtra)
│       ├── Localization/
│       │   ├── AppLanguage.swift           # Supported locales and auto-detection
│       │   └── L10n.swift                  # Localized strings dictionary with pluralization
│       ├── Models/
│       │   ├── KeepAwakePreset.swift       # Preset duration configurations
│       │   ├── SleepAssertionType.swift    # Sleep modes (Display + System / System Only)
│       │   ├── BatteryInfo.swift           # Battery and charging state representation
│       │   ├── DeactivationReason.swift    # Session termination causes
│       │   ├── MenuBarDisplayStyle.swift   # Icon-only vs Icon + Timer styles
│       │   ├── SessionTriggerSource.swift  # Trigger origins (Manual, AC, App, Monitor)
│       │   └── TriggerApp.swift            # Process automation entity
│       ├── Services/
│       │   ├── SleepAssertionService.swift # Swift Actor wrapping IOKit assertions
│       │   ├── BatteryMonitorService.swift # Event-driven IOKit battery monitoring
│       │   ├── SmartTriggerService.swift   # Structured Concurrency process & monitor watchers
│       │   ├── AppNotificationService.swift# UserNotifications dispatcher with action buttons
│       │   ├── QuickClickMonitor.swift     # Option-click (⌥) and secondary click interceptor
│       │   ├── LaunchAtLoginService.swift  # SMAppService login item controller
│       │   └── AppUpdateService.swift      # GitHub Releases update validator
│       ├── State/
│       │   ├── DoppioState.swift           # @Observable coordinator managing UI & timers
│       │   ├── SessionTimerController.swift# ContinuousClock monotonic timer controller
│       │   └── DoppioSettingsStore.swift   # UserDefaults persistence adapter
│       └── Views/
│           ├── MenuBarLabelView.swift      # Dynamic menu bar icon & status label
│           ├── DoppioPopoverView.swift     # Interactive popover card interface
│           ├── DoppioMenuView.swift        # Native NSMenu fallback / companion
│           ├── SettingsView.swift          # Modular 3-tab preferences window
│           └── Components/
│               ├── ControlCenterHeroCard.swift    # Status card with countdown progress ring
│               ├── PresetSelectionView.swift      # Grid of quick presets and duration stepper
│               ├── SleepModeSelectorView.swift    # Fluid mode switch control
│               ├── FooterActionsView.swift        # Bottom toolbar, battery gauge, and settings trigger
│               ├── GlassStyles.swift              # Liquid Glass modifiers and materials
│               ├── ModelPresentation.swift        # Presentation-layer formatting extensions
│               ├── WindowAutoResizer.swift        # Window geometry constraints
│               └── SettingsWindowManager.swift    # Window delegate and geometry controller
└── Tests/
    └── DoppioTests/
        └── DoppioTests.swift # Swift Testing test suites (@Suite, @Test)
```

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Description |
|:---|:---|
| `⌥ + Click` on Menu Bar Icon | Instantly toggle keep-awake without opening the menu |
| `⌘ + ,` | Open Settings window |
| `⌘ + Q` | Quit Doppio |

---

## 📄 License

Doppio is distributed under the MIT License.
