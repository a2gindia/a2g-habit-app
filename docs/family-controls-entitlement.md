# Family Controls entitlement — filing checklist

The **blocker + shields** system (Phase 3) needs Apple's Family Controls
entitlement. There are two levels:

- **Development** — added in Xcode with one click, no Apple approval. Enough to
  test on a real device.
- **Distribution** — requires a **request to Apple and their approval**. This is
  the long pole: *a few business days to several weeks.*

Nothing in the current v1 build uses Family Controls, so this doesn't block
today's work — but **file it now** so the approval has landed by the time Phase 3
is built.

> ⚠️ Apple changes these forms, URLs, and flows periodically. Treat the specifics
> below as a guide and confirm against the current developer portal. **This
> checklist can't be filed for you — it needs your Apple Developer account.**

---

## Prerequisites

- [ ] Active **paid** Apple Developer Program membership.
- [ ] **Account Holder or Admin** role (needed to request entitlements and manage App IDs).
- [ ] Main app bundle ID confirmed: `com.a2glifestyle.habitapp`.

---

## Step 1 — Register every App ID (main + all planned extensions)

The distribution entitlement is granted **per App ID**. Register all of them now,
even though the Phase-3 extensions aren't built yet — the request must cover each.
Extension bundle IDs must be **prefixed by the app's** bundle ID.

- [ ] `com.a2glifestyle.habitapp` — main app
- [ ] `com.a2glifestyle.habitapp.DeviceActivityMonitorExtension`
- [ ] `com.a2glifestyle.habitapp.ShieldConfigurationExtension`
- [ ] `com.a2glifestyle.habitapp.ShieldActionExtension`
- [ ] `com.a2glifestyle.habitapp.DeviceActivityReportExtension`

> **#1 failure mode:** approving the main app but missing even one extension. The
> build signs fine in development, then **fails to sign at distribution** after
> the main app was already approved. Cover all five.

---

## Step 2 — Add the Development capability (no approval needed)

- [ ] Xcode → target → **Signing & Capabilities → + Capability → Family Controls**.
- [ ] Lets you test `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
      on a **real device** (Family Controls is device-only; simulator support is limited).

---

## Step 3 — Request the Distribution entitlement (the long pole)

- [ ] Open the **Family Controls Distribution** request form
      (`developer.apple.com/contact/request/family-controls-distribution` —
      verify the current link from the portal).
- [ ] Submit a request for **each App ID** from Step 1 (main + all four extensions).
- [ ] Paste the justification (draft below); frame as **personal digital
      wellbeing, not data collection**.
- [ ] Explicitly state: **usage data is never used for advertising or profiling.**
- [ ] Record the **submission date** and track each App ID's status in the table below.

### Tracking

| App ID | Registered | Distribution requested | Approved |
|---|---|---|---|
| `…habitapp` (main) | ☐ | ☐ | ☐ |
| `…DeviceActivityMonitorExtension` | ☐ | ☐ | ☐ |
| `…ShieldConfigurationExtension` | ☐ | ☐ | ☐ |
| `…ShieldActionExtension` | ☐ | ☐ | ☐ |
| `…DeviceActivityReportExtension` | ☐ | ☐ | ☐ |

Submitted on: ____________  ·  Expected back: submission + a few days to several weeks.

---

## Step 4 — After approval

- [ ] Enable **Family Controls (Distribution)** for **each** App ID (portal / entitlements).
- [ ] **Regenerate provisioning profiles** for every App ID.
- [ ] Rebuild and re-sign for distribution; **verify signing succeeds for the app AND every extension**.

---

## Justification draft (adapt, then paste)

> A2G Habit is a personal digital-wellbeing app. It uses Family Controls,
> DeviceActivity, and ManagedSettings so a user can voluntarily shield their own
> distracting apps and add a deliberate delay before continuing, reducing
> compulsive use. All processing is on-device. Usage data never leaves the
> device, and is **never used for advertising, profiling, or shared with third
> parties**. The Device Activity report and shields exist solely to help the user
> follow their own self-set limits.

---

## Design constraints to remember (for when Phase 3 is built)

- **App/category tokens are opaque** — you cannot read app names. No "here's your
  Instagram usage" report is possible, by design. Build around it.
- A determined user can always delete the app; **strictness comes from friction +
  stakes, not an unbreakable cage.**
- **Extensions run under tight memory limits** — keep monitor-extension work minimal.
- Unlock friction: shield screen shows the time-value cost + a forced 30–60s wait
  before "continue anyway" becomes tappable.
