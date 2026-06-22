# WakeDaddy ⏰

The alarm app that *actually* gets you out of bed. Loud, mission-gated, anti-cheat
alarms with an on-device sleep coach — built with Flutter 3.44 / Dart 3.12.

> **Status:** Fully runnable. `flutter build apk --debug` ✅ · `flutter analyze` → 0 issues.

---

## Features

### Core alarm engine
- **Multiple alarms** with per-day repeat, labels, enable/disable.
- **Loud alarm sounds** — 3 bundled tones (`classic_beep`, `siren`, `gentle`),
  played via the native `alarm` plugin with `volumeEnforced` so the OS can't
  duck the volume.
- **Gradually increasing volume** — `VolumeSettings.fade` ramp (5–120 s).
- **Snooze control** — configurable length + max-snooze cap.
- **Vibrate + screen flash** — vibration via the plugin, strobe via the ring screen.
- **Full-screen ring** even on the lock screen (`androidFullScreenIntent`, `showWhenLocked`).

### Dismiss missions (`lib/features/missions/`)
Math · Type-a-sentence · Memory game · QR scan (other room) · Photo proof · Walk 100 steps.
Each is a self-contained widget behind `MissionRunner`; difficulty/reps/target are configurable.

### "Better than Alarmy" add-ons (`lib/services/`)
| Feature | File | State |
|---|---|---|
| AI Wake-Up Coach (sleep tracking, optimal bedtime) | `sleep_coach_service.dart` | ✅ on-device, working |
| Penalty Mode (₹10–₹100 to charity) | `penalty_service.dart` | ⚙️ ledger works; needs payment gateway |
| Accountability Mode (notify a friend) | `accountability_service.dart` | ✅ SMS deep-link; cloud push stubbed |
| Morning Routine Automation | `routine_service.dart` | ✅ launches apps / audio / goals |
| Anti-Cheat (detect shutdown + force-close) | `anticheat_service.dart` | ✅ heartbeat + boot receiver |
| Cloud alarm backup | `cloud_backup_service.dart` | ⚙️ local snapshot; swap in Firebase |

### Revenue model
Free / Premium ₹299 mo / Lifetime ₹1,499 — `lib/features/premium/paywall_screen.dart`.
Premium features (penalty, accountability, routine, full coach, cloud) are gated via `isPremiumProvider`.

---

## Architecture

```
lib/
  core/        theme, utils, permissions
  data/        models (Alarm, MissionConfig, SleepLog) + Hive storage
  services/    alarm engine + all "better-than-Alarmy" modules
  state/       Riverpod notifiers (alarms, sleep logs, premium)
  features/    home · edit · ring · missions · coach · premium · settings
```
- **State:** Riverpod 3 (`Notifier`).
- **Storage:** Hive CE — models persisted as JSON (no codegen step).
- **Alarms:** `alarm` ^5.5 (exact alarms, background audio, boot persistence).

## Run it
```bash
flutter pub get
flutter run                 # on a device/emulator
# Settings ▸ "Test alarm in 5 seconds" to preview the full ring + mission flow.
```

## Before shipping (external accounts required)
1. **Firebase** — run `flutterfire configure`, add `firebase_core`/`auth`/`firestore`,
   then implement a `FirebaseCloud` class against the `CloudBackupService` interface
   (and the cloud push in `AccountabilityService.sendViaCloud`).
2. **Payments** — wire `PaywallScreen._purchase` and `PenaltyService._charge` to
   RevenueCat / Play Billing / Razorpay.
3. **Photo mission** — drop in ML Kit image-labelling at the `TODO(ml)` hook to
   verify the photographed object matches the target.
4. App icons, store listing, and a real signing config (currently debug keys).

## Notes
- `minSdk 23`, `compileSdk 36`, core-library desugaring enabled (for notifications).
- The `alarm` plugin still applies the legacy Kotlin Gradle Plugin → harmless build
  warning today; track its changelog for the Built-in-Kotlin migration.
- Bundled alarm tones are generated WAVs (`assets/audio/`); replace with licensed
  high-quality audio for production.
