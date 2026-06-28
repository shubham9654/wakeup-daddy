# Wakeup Daddy ⏰

The alarm app that *actually* gets you out of bed. Loud, mission-gated, anti-cheat
alarms with an on-device sleep coach — built with Flutter 3.44 / Dart 3.12.

> **100% local** — no accounts, no network calls, no tracking. Everything is
> stored privately on the device.
>
> **Status:** Fully runnable. `flutter analyze` → 0 issues · `flutter build apk` ✅.

---

## Features

### Core alarm engine
- **Multiple alarms** with per-day repeat, labels, enable/disable.
- **10 bundled alarm sounds** (Uplift, Digital, Classic Beep, Pulse, Chime, Radar,
  Marimba, Siren, Cosmic, Bells) — original, royalty-free, played via the native
  `alarm` plugin with `volumeEnforced` so the OS can't duck the volume.
  Tap-to-preview in the editor.
- **10 animated GIF wallpapers** (Rings, Aurora, Embers, Plasma, …) shown as the
  full ring-screen background — original & royalty-free.
- **Gradually increasing volume** — `VolumeSettings.fade` ramp (5–120 s).
- **Snooze control** — configurable length + max-snooze cap.
- **Vibrate + screen flash** — vibration via the plugin, strobe via the ring screen.
- **Full-screen ring** even on the lock screen (`androidFullScreenIntent`, `showWhenLocked`).

### Dismiss missions (`lib/features/missions/`)
Math · Type-a-sentence · Memory game · QR scan (other room) · Photo proof · Walk 100 steps.
Each is a self-contained widget behind `MissionRunner`; difficulty/reps/target are configurable.

### Extras (`lib/services/`)
| Feature | File | State |
|---|---|---|
| Sleep coach (sleep tracking, optimal bedtime) | `sleep_coach_service.dart` | ✅ on-device |
| Wake-up reports (real dismissal history) | `wakeEventsProvider` | ✅ local, per-week |
| Penalty Mode (₹ to charity if ignored) | `penalty_service.dart` | ⚙️ ledger only; needs payment gateway |
| Accountability Mode (notify a friend) | `accountability_service.dart` | ✅ SMS deep-link |
| Morning Routine Automation | `routine_service.dart` | ✅ launches apps / audio / goals |
| Anti-Cheat (detect shutdown + force-close) | `anticheat_service.dart` | ✅ heartbeat + boot receiver |

All features are free — there is no paywall.

---

## App structure
5 bottom tabs: **Alarm · Sleep · Morning · Report · Setting**.

```
lib/
  core/        theme, utils, permissions, wallpapers
  data/        models (Alarm, MissionConfig, SleepLog, WakeEvent) + Hive storage
  services/    alarm engine + sleep coach / accountability / routine / anti-cheat
  state/       Riverpod notifiers (alarms, sleep logs, wake events)
  features/    home · edit · ring · missions · coach · sleep · morning · report · settings
```
- **State:** Riverpod 3 (`Notifier`).
- **Storage:** Hive CE — models persisted as JSON (no codegen step).
- **Alarms:** `alarm` ^5.5 (exact alarms, background audio, boot persistence).
- **Theme:** dark, single brand-red accent `#FB4E63`.

## Run it
```bash
flutter pub get
flutter run                 # on a device/emulator
# Settings ▸ "Test alarm in 5 seconds" to preview the full ring + mission flow.
```

## Build a small release APK
```bash
flutter build apk --release --split-per-abi
# → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  (~30 MB)
```

## Regenerating assets
Sounds and wallpapers are procedurally generated (royalty-free) by the scripts in
`tool/` / scratchpad: `gen_sounds.py` (WAVs → `assets/audio/`) and
`gen_wallpapers.py` (animated GIFs → `assets/wallpapers/`). The app icon is built
from `assets/icon/logo.png` via `gen_icon.py`, then `dart run flutter_launcher_icons`.

## Before shipping
1. **Release signing** — currently debug keys; add a real keystore + signing config.
2. **Payments** (optional) — wire `PenaltyService._charge` to a payment provider if
   you enable Penalty Mode for real money.
3. **Photo mission** — drop in ML Kit image-labelling at the `TODO(ml)` hook to
   verify the photographed object matches the target.

## Notes
- `minSdk 23`, `compileSdk 36`, core-library desugaring enabled (for notifications).
- The `alarm` plugin still applies the legacy Kotlin Gradle Plugin → harmless build
  warning today; track its changelog for the Built-in-Kotlin migration.
