# Hisab — Income & Expense Tracker (MVP v1.0.0)

Free, offline-first, personal-use-only Flutter app for Toha. Android first,
no Play Store, no Firebase, no paid backend. Local storage only
(`shared_preferences`, whole state as one JSON document).

## Approved design (do not change)
- **Design B**: Dark + Colorful — solid dark `#0A0F14`, teal `#00B8A9`,
  cyan `#00E5FF` / `#22D3EE`, **NO violet**, high contrast, no blur/glass/haze,
  white headings, solid cards with 1px `#1E3A45` border.
- **Logo: Logo 3 — Wallet Flow (FINAL, confirmed by Toha 2026-11-17)**.
  Do NOT switch to Logo 5A/5B. Icon source:
  `~/workspace/hisab-logos/media-generation-hisab-logo-3-wallet-flow-0-e32f5ee1-cfb5-4657-a134-b18eb0d313c3.webp`
  (1600×1600, corners already dark — no white corners in the source).
  In-app asset: `assets/logo.png` (512×512, centre pixel teal `#00B9B8`,
  verified identical to the source). Launcher icons generated in
  `android/app/src/main/res/mipmap-*/ic_launcher.png` + adaptive icon
  (`mipmap-anydpi-v26`, background `#0A0F14`).
- Design reference artifacts: `hisab-design` (Design B), `hisab-logo`.

## MVP features (all built)
1. Home/Dashboard — total balance, today + this-month income/expense,
   saving remainder + %, daily average, budget warnings, today's list,
   notifications bell (budget + dhar alerts).
2. Quick Add — centre FAB, Income (teal-green) / Expense (coral-red) toggle,
   custom keypad (48px keys), category chips, account selector
   (Cash / bKash / Nagad / Bank), note, date defaults to today, Save pinned
   at the bottom, always visible.
3. History — search + type/account filters, grouped by date, tap a row to
   edit/delete.
4. Report — donut by category + 7-day income-vs-expense bars, month
   prev/next. **All derived from the same entries state** (single source of
   truth in `lib/store.dart`) — an add/edit/delete updates Home, Report and
   Budget together. (The web prototype's reviewer defect — stale Report/Budget
   after Quick Add — is fixed by construction and covered by a test.)
5. Budget — per-category monthly limit, progress bar, 80% amber warning,
   100%+ red warning, tap to change limit, "+" adds a missing category.
6. Wallets — Cash / bKash / Nagad / Bank balances; every entry adds/deducts
   from the right wallet; "ঠিক করো" corrects a balance.
7. Dhar/Pawna — Pabo (owed to me) / Debo (I owe), settle toggle, delete.
8. Savings Goal — one goal, progress bar, add money (moves from Cash wallet,
   so totals stay honest), change target.
9. Settings/More — PIN lock (4-digit, lock screen on launch), backup:
   CSV export to `Downloads/Hisab/hisab-backup.csv`, restore from that file,
   copy CSV to clipboard, demo data (prototype numbers), clear all (confirm).
10. Bangla + English labels, Taka `৳` formatting with lakh grouping
    (`৳1,49,100`), Material 3, bottom nav (Home / History / Report / More)
    + centre FAB.

## Single source of truth
`lib/store.dart` — `AppState` holds entries, wallets, budgets, debts, goal.
Every derived number (totals, charts, budgets, saving) is computed from
entries + wallets. Wallet effects are applied on add, reversed + re-applied
on edit, reversed on delete. Demo data and CSV restore both apply entries
through the wallet, so edit/delete stays consistent afterwards.

## Verified (2026-11-17)
- `flutter analyze` — **No issues found.**
- `flutter test` — **5/5 pass**, including:
  - add ৳500 Khabar Cash → month expense +500, Cash −500, total −500,
    Khabar spend +500, today out ৳1,980 → ৳2,480, 7-day chart updates;
    edit to ৳800 and delete both reconcile exactly.
  - demo wallets sum to total ৳1,49,100 (Cash 8,450 / bKash 23,150 /
    Nagad 5,200 / Bank 1,12,300).
  - Taka formatting `৳1,49,100`; CSV export/import round-trip.

## Build the APK (parent/main agent — see blocker note below)
```bash
export PATH="$HOME/flutter/bin:$HOME/jdk-17/bin:$PATH"
export JAVA_HOME=$HOME/jdk-17
export GRADLE_USER_HOME=$HOME/.gradle
cd ~/workspace/hisab-app
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk  (v1.0.0+1, debug-signed)
```
Sandbox notes (already applied in this project, copied from the working
couple-tap-app setup): Android SDK is at `~/android-sdk`, JDK 17 at
`~/jdk-17`; `android/gradle/wrapper/gradle-wrapper.properties` points at
the local `~/downloads/gradle-8.13-all.zip`; `android/settings.gradle.kts`
pins KGP 2.0.21 + local maven mirror; `android/gradle.properties` uses
2G heap + the sandbox truststore. `~/.gradle/gradle.properties` sets
`org.gradle.daemon=false` and `shrink=false`.

## ⚠️ BUILD BLOCKER in the subagent sandbox (2026-11-17)
`flutter build apk --release` could **not** produce an APK in the subagent
sandbox. Root cause, proven:
- Every Gradle attempt fails in ~4–5s with
  `DaemonConnectionException: Could not receive a message from the daemon`
  / `IllegalArgumentException: Unexpected type tag 109 found`.
- `strace` showed the Gradle client writes the build request to the daemon
  socket, then reads back 193 bytes starting with `m` (109):
  `muse: Other TCP connections is turned off for this assistant. To allow
  it, ask the user to open Muse settings -> Permissions -> Direct network
  protocols and switch other_tcp from Deny to Ask.`
- Control test: a tiny Java program connecting to a Python server on
  `127.0.0.1` gets the same interception message, while a Python client to
  the same server works fine. **Java processes in this sandbox cannot make
  TCP connections, even to localhost** — and Gradle's daemon protocol needs
  localhost TCP. The same failure hits the known-good couple-tap-app build
  right now, so it is environmental, not this project.
- The code itself is verified (analyze clean, tests pass). The APK was
  built fine for couple-tap on 2026-11-16 in the main-agent session.
- **Fix: run the build command above from the main-agent session** (or ask
  Toha to switch `other_tcp` from Deny to Ask in Muse settings), then send
  the APK to the Reviewer agent first, per Toha's standing rule — do not
  hand an unreviewed APK to Toha.
