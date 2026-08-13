# Habit app — build & structure

## Layout

```
EconomyKit/            Pure domain logic — NO SwiftUI/SwiftData. Compiles &
  Sources/EconomyKit/  verifies on plain macOS with the `swift` CLI (no Xcode).
  Sources/verify/      Dev-only assertion harness (`swift run verify`).
  Tests/EconomyKitTests/  XCTest suite — the real tests, run under Xcode/CI.
HabitApp/              The iOS app. Requires full Xcode to build.
  Models/              SwiftData @Model types; import EconomyKit.
  App/, Features/…     (added in later slices)
```

**Why the split:** the `@Model` macro and the iOS SDK both ship only with full
Xcode. Keeping the load-bearing math (rates, scoring, framing, formatting) in
EconomyKit means it stays compilable and testable before Xcode is installed, and
the SwiftData/UI layer just consumes it.

## Verifying the domain logic without Xcode

```bash
cd EconomyKit && swift run verify
```

Runs the load-bearing assertions (spec headline rates, Indian formatting,
divide-by-zero guards). Exits non-zero on failure.

## Building & running the app

Xcode 26 + the iOS 26.5 simulator runtime are installed. `HabitApp.xcodeproj`
already exists (hand-generated, synchronized-folder format, links the local
`EconomyKit` package). Open it in Xcode and press Run, or from the CLI:

```bash
# build
xcodebuild build -scheme HabitApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath .build-xcode CODE_SIGNING_ALLOWED=NO

# install + launch on a booted iPhone 17 sim
xcrun simctl boot "iPhone 17"; open -a Simulator
xcrun simctl install "iPhone 17" .build-xcode/Build/Products/Debug-iphonesimulator/HabitApp.app
xcrun simctl launch "iPhone 17" com.a2glifestyle.habitapp
```

Bundle id: `com.a2glifestyle.habitapp`. Deployment target iOS 17.

### Debug seeding (skip onboarding for screenshots / manual testing)

Launch straight into a populated dashboard with a sample goal:

```bash
SIMCTL_CHILD_SEED_DEMO_GOAL=1 xcrun simctl launch "iPhone 17" com.a2glifestyle.habitapp
```

Gated behind `#if DEBUG` + the `SEED_DEMO_GOAL` env var — never fires in normal runs.

### Known: native simulator panel

Claude Code's embedded simulator panel cached the developer dir from before Xcode
was installed and reports "Xcode not selected" even though `xcode-select -p` is
correct. **Restart Claude Code** to re-read it and get live tap/swipe/watch.
Until then, build/install/launch/screenshot work via `simctl`, but touch
injection does not.

## Day-0 side task (not code)

File the Family Controls entitlement request now — main app bundle ID **and**
each extension bundle ID (`DeviceActivityMonitorExtension`,
`ShieldConfigurationExtension`, `ShieldActionExtension`,
`DeviceActivityReportExtension`). It's the long pole on the (out-of-this-build)
Phase 3 blocker.
