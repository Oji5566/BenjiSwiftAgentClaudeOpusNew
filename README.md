# Benji — Native iOS App

> *"How much of your life did that latte cost?"*

Benji is a personal-finance utility that translates money into the time you
worked to earn it. This repository previously housed a one-file PWA
(`index.html` + service worker). It has been **fully rewritten** as a native
SwiftUI iOS application — no WKWebView, no HTML, no CSS, no JS shim. The
app is implemented with the latest SwiftUI / SwiftData / Observation /
Keychain APIs and targets **iOS 17+** (designed against iOS 26 visual
guidelines — Liquid Glass tab bar, native presentation flows, native form
controls, Dynamic Type, VoiceOver).

---

## Running it

### iOS app

1. Open `Benji.xcodeproj` in **Xcode 16** (or newer).
2. Select an iPhone simulator (or a connected device with iOS 17+).
3. ⌘R to build and run.

The Xcode project uses a *file-system-synchronised group* (Xcode 16's
PBX `fileSystemSynchronizedGroups`) rooted at `Benji/`, so any new Swift
file you drop into a feature folder is picked up automatically — no
project-file surgery required.

### Pure-logic tests (no simulator needed)

```sh
swift test
```

This runs `BenjiCoreTests` against the cross-platform `BenjiCore` package
(see `Package.swift`). 27 tests cover: earning-rate math, real-wage
deductions, history filtering, stats aggregation, JSON export round-trip,
formatters, password hashing, decision normalisation, and the calculator
input state machine.

---

## Architecture

```
Benji/
  BenjiApp.swift           ← @main App scene wiring
  App/                     ← Root router, tab shell, session store
  Core/                    ← Pure Swift; reused by BenjiCore SPM package
    EarningRateCalculator
    Decision / IncomeType / DefaultCategories
    Formatters / RelativeTime / CalculatorInput
    HistoryFilter / HistoryStats
    ExportPayload / PasswordHasher
  Models/                  ← SwiftData @Model classes
    UserAccount, AppSettingsRecord, EntryRecord, CategoryRecord
  Persistence/             ← ModelContainer setup, AccountStore, EntryStore, CategoryStore
  Services/                ← KeychainService, ExportService
  DesignSystem/            ← Theme, glass-card modifiers
  Features/
    Auth/                  ← AuthView (login + signup)
    Onboarding/            ← OnboardingView (5-step flow)
    Calculator/            ← CalculatorView, KeypadView, ResultActionSheet, EntryFormSheet
    History/               ← HistoryView, EntryRow, EntryDetailView
    Watchlist/             ← WatchlistView
    Settings/              ← SettingsView
  Resources/               ← Info.plist, Assets.xcassets

Tests/BenjiCoreTests/      ← XCTest suite (cross-platform via SPM)
Package.swift              ← BenjiCore product + test target
Benji.xcodeproj            ← App target (synchronised folder)
```

### State management

* `@Observable` is used for the global `SessionStore` and any per-screen
  view-models. Per Apple guidance for iOS 17+ this replaces `ObservableObject`
  / `@Published`.
* SwiftData (`@Model`, `ModelContext`) owns all on-device user data:
  accounts, settings, entries, categories.
* The Keychain (`KeychainService`) holds the SHA-256 password digest for
  each account *and* the "currently signed-in" session pointer.
  Credentials never live in `UserDefaults` or SwiftData.

### Pure / testable separation

The `Benji/Core/` directory is intentionally free of UIKit, SwiftUI, and
SwiftData imports. It contains the business logic:

* `EarningRateCalculator` — preserves the web app's formula exactly,
  including the `52/12 ≈ 4.333` weeks-per-month payroll approximation.
* `EntryFilter` / `HistoryStats` — drives the history tab's filters and
  aggregates.
* `ExportPayload` / `ExportEncoder` — stable JSON schema for export.
* `CalculatorInput` — keypad state machine (digit/decimal/backspace
  rules + 8-int / 2-fraction-digit caps).
* `Formatters` — locale-independent `$1,234.56` / `1 hr 5 mins` strings
  matching the web app verbatim.

`Package.swift` exposes this as a Swift package so the same logic can be
unit-tested via `swift test` on macOS or Linux without an Xcode install.
On Apple platforms `PasswordHasher` uses the system `CryptoKit`; on
non-Apple platforms it falls back to `swift-crypto`.

---

## Migration notes — PWA → native iOS

| PWA concept | Native replacement |
| --- | --- |
| `localStorage` user db | SwiftData `UserAccount` records (per-user `entries`, `categories`, `settings` relationships) |
| `sessionStorage` session pointer | Keychain (`__session_username`) |
| SHA-256 password hash in `localStorage.users` | Same SHA-256 digest, stored in Keychain |
| `index.html` mode-switch screens (auth / onboarding / app) | `RootView` switches between `AuthView`, `OnboardingView`, `MainTabView` |
| Custom CSS tab bar at the bottom | Native `TabView` with `Tab(...)` builders → iOS 26 Liquid-Glass tab bar |
| Numeric keypad `<button>` grid | `KeypadView` with `Button` + `regularMaterial` background, haptics |
| `result-sheet` overlay div | `.sheet(item:) { ResultActionSheet }` with `.medium` detent and drag indicator |
| Form modal for naming entries | Second `.sheet` with native `Form`, `Picker(.menu)`, `LabeledContent` |
| `confirm()` / overlay for destructive actions | `.confirmationDialog` and `.alert` |
| `<a download>` JSON export | `ExportService.writeTemporaryFile(...)` + `ShareLink` |
| Custom CSS toggles | Native `Toggle` |
| Custom segmented periods | Native `Picker(.segmented)` / `Picker(.menu)` |
| `cat.split(' ')[0]` emoji extraction | `DefaultCategories.emoji(of:)` |
| Reorder via ↑/↓ buttons | `EditButton` + `.onMove` on `ForEach` |
| `formatCurrency` / `formatMinutes` JS helpers | `Formatters.currency` / `Formatters.minutes` (matching strings) |
| `setHistoryPeriod` daily/weekly/monthly/yearly | `HistoryFilter` enum + `EntryFilter.keep` |
| `decision` strings (`buy`, `skip`, `watch_list`, `give_up`) | `Decision` enum with `.normalise(_:)` for legacy values |

### Behavioural parity

* Earning-per-minute formula matches the web app to 1e-9 precision (verified
  by `EarningRateTests`).
* History "weekly" window starts on **Sunday**, matching the original
  `now.getDay()` JavaScript behaviour.
* Default categories are the exact same eleven entries with the exact same
  emoji prefixes.
* Export JSON omits `notes` (matching the original `exportData()`), uses
  ISO-8601 timestamps, and is sorted-keys / pretty-printed for stability.
* Calculator input enforces the same 8-integer / 2-fraction caps as the
  web `keyPress` function.
* Sign-up validation rules are identical (≥ 3 char username, ≥ 6 char
  password, password confirmation match, unique username).

### Things deliberately changed

* The web app stored hashes in plain `localStorage`. Here they live in the
  Keychain, scoped to the device after first unlock.
* The web app used a custom JS toggle and custom CSS overlays. The native
  app uses system `Toggle`, `Picker`, sheets and confirmation dialogs.
* The web "result sheet" is a real `.sheet` with a detent — it can be
  flicked away and respects the iOS reduce-motion / VoiceOver conventions.
* History entries are deletable via swipe-to-delete; watchlist items
  support a leading-edge "Buy / Skip" swipe and a trailing-edge "Forget"
  swipe in addition to the in-detail actions.

---

## What was built (PR summary)

* End-to-end native rewrite — auth → onboarding → calculator → result
  sheet → history → watchlist → settings → export → log out — all
  implemented with native controls.
* SwiftData persistence with relationships and cascade deletes.
* Keychain-backed auth and session restore.
* Native JSON export with `ShareLink` + temporary file URL.
* 27 unit tests covering all critical pure logic, runnable via
  `swift test` (no simulator required).
* Two-line Xcode project using Xcode 16's synchronised root groups so
  adding new Swift files needs no project edits.

### Assumptions

* Targeting iOS 17+ so `@Observable`, SwiftData, `Tab(...)` builders, and
  modern `.sheet` detents are all available.
* The user wants their data to stay on-device — **no cloud sync** in v1
  (the original app had none either).
* Existing PWA users do not have an export they need imported — there is
  no automatic data migration from `localStorage` because there is no
  bridge between a browser's storage and the iOS keychain. (An "Import
  from JSON" affordance could be added later if this turns out to matter.)

### Remaining TODOs / opportunities

* App icon assets (the Asset Catalog has the `AppIcon` slot wired up but
  no PNGs — drop in once branding is final).
* Localisation: strings are inline English. Add a String Catalog when a
  second locale is needed.
* iCloud sync via SwiftData CloudKit option — trivial flag flip, but
  intentionally out of scope for v1.
* Charts (e.g. Swift Charts on the History tab for spend over time).
