# Habit app — v1 build spec

Personal-use build first, public release after iteration. iOS only.

## Scope

Four systems. Three build now, one is gated on Apple approval.

| System | Phase | Blocked by |
|---|---|---|
| Goal math + time-value dashboard | 1 | nothing |
| Habit / addiction logging | 1 | nothing |
| Points economy + daily scoring | 2 | needs 1 |
| Blocker + shields | 3 | Family Controls entitlement |

Money is a **simulated ledger** in v1. Real stakes in v2, once the loop is proven on real usage data.

## Day 0 — before writing code

File the Family Controls entitlement request. It runs from a few business days to several weeks, and it is the long pole on phase 3.

- Request `com.apple.developer.family-controls` for the main app bundle ID.
- **Also request it separately for every extension bundle ID** — `DeviceActivityMonitorExtension`, `ShieldConfigurationExtension`, `ShieldActionExtension`, `DeviceActivityReportExtension`. Missing one means the build fails to sign at distribution, after the main app was already approved.
- Justification should read as personal digital wellbeing, not data collection. State explicitly that usage data is never used for advertising or profiling.
- After approval: enable Family Controls (Distribution) per bundle ID, regenerate provisioning profiles, rebuild.

## Stack

- SwiftUI, iOS 17+
- SwiftData for persistence
- No backend in v1. Everything local. Add sync only when a second user exists.
- Swift Charts for the dashboard

## Phase 1a — goal math + time-value engine

### Model: `Goal`

```
targetAmount: Decimal        // e.g. 1_000_000_000 (100 cr)
currency: String             // "INR"
horizonYears: Double         // e.g. 5
denominator: Denominator
startDate: Date
```

### Model: `Denominator` (enum)

This is a **user setting, not a constant**. It changes the entire emotional weight of the app.

- `.calendarHours` — every hour of the horizon counts. 5y = 43,800 h → ₹22,831/h
- `.workingHours(perDay: Double, daysPerWeek: Int)` — 8h × 5d = ~10,400 h → ~₹96,000/h
- `.custom(totalHours: Double)`

### Derived rates

```
perHour   = targetAmount / totalHours
perMinute = perHour / 60
perSecond = perMinute / 60
```

Round for display. Never show raw float artifacts.

### Honesty requirement

Somewhere in onboarding, in plain language: this is a **pacing metaphor, not a forecast**. Wealth does not accrue linearly per hour. The number exists to make time feel concrete, not to predict a bank balance. If the app pretends otherwise, the user stops trusting every other number in it.

## Phase 1b — habit / addiction logging

### Model: `Habit`

```
name: String
kind: HabitKind              // .build or .break
targetPerDay: Int?           // for .build habits
```

### Model: `HabitLog`

```
habit: Habit
timestamp: Date
note: String?
```

### Seed habits (personal build)

Build: workout, shower-after-workout, cooked meal, deep work block, lights-out by target time
Break: doomscroll session, porn, cigarette, late-night phone

### Critical design rule — decouple logging from scoring

**Logging a relapse must never itself cost points or money.** Score the behaviour, not the confession. If honest logging is punished, logging stops, and a tracker that isn't logged is a dead product.

Practically: the cigarette costs points at the moment it happened, whether or not it's logged. Logging it late, or logging a slip you could have hidden, earns a small **honesty bonus**. The user should feel that telling the truth is always the cheaper move.

Copy in the logging flow stays flat and factual. No "you failed", no red, no shame animation. Log it, move on.

## Phase 2 — points economy + daily scoring

### Earning

- Deep work: points ∝ minutes, at the goal's per-minute rate
- Build habits: flat points on completion
- Honesty bonus: small, for logging a break-habit slip
- Streak multiplier: caps at ~1.5x, do not let it grow unbounded

### Break habits

Deduct against the day's earned total. **Floor the day at zero.** A user should never end a day owing. Negative balances produce despair, and despair produces uninstalls.

### End of day

Roll up to a `DayScore`. Simulated rupees earned. Pace vs goal. Never a "lost" total in the primary display — see framing below.

## Phase 1c — A/B framing harness

Ship both framings and let your own data settle it. Build this into phase 1 so every day of usage is a data point.

### Model: `FramingVariant` (enum)

- `.gain` — "you earned ₹18,400 toward your goal today"
- `.loss` — "you burned ₹4,000 today"

Same underlying math. Only the copy and the primary displayed number change.

### Assignment

Alternate weekly. Store the active variant on every `DayScore` so results are attributable.

### Instrument these

- Days logged / days elapsed (**engagement — the one that matters most**)
- Break-habit slips logged per day (a *drop* here may mean under-reporting, not improvement — watch it against deep-work minutes)
- Deep work minutes per day
- Self-rated mood, one tap, end of day, 1–5
- Uninstall / abandonment gaps of 2+ days

### Prior going in

An RCT on deposit-contract incentives found loss framing performed *worse* than gain framing, and specifically reduced participants' sense of goal commitment. Research on self-forgiveness and procrastination points the same direction. Expect `.gain` to win. Ship both anyway — you are n=1 and you may be the exception.

## Phase 3 — blocker + shields

Only after entitlement approval.

- `FamilyControls` — `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
- `FamilyActivityPicker` — user selects what to shield
- `ManagedSettingsStore` — apply the shields
- `DeviceActivitySchedule` + `DeviceActivityMonitorExtension` — turn shields on/off on schedule, and re-arm automatically

### Constraints to design around

- App and category tokens are **opaque**. You cannot read app names. No "here's your Instagram usage" report is possible, by design.
- A determined user can always delete the app. Strictness must come from friction and stakes, not from an unbreakable cage.
- Extensions run under tight memory limits. Keep monitor-extension work minimal.

### Unlock friction (instead of impossibility)

When a shield is hit, the shield screen shows the time-value cost of continuing, and requires a deliberate delay — a forced wait of 30–60 seconds before the "continue anyway" button becomes tappable. That pause is the mechanism; a hard block that gets rage-uninstalled protects nothing.

## Explicitly out of scope for v1

- Any real money movement, escrow, or payment gateway
- Backend, accounts, sync
- Social / accountability partners
- Android

## Week 1 definition of done

Entitlement request filed. Goal configured with a real target and denominator. Habits seeded. Logging working. Dashboard showing today's earned figure and pace. Both framings implemented, alternating weekly, with metrics recording to a local store you can export.
