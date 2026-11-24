# GPS Tracker

A simple Flutter app that tracks your location and saves it even when
you're offline. Once you're back online, it sends the saved locations
to a server automatically - no button to press, no duplicates sent.

## What it does

- Start or stop tracking with one button.
- Every location point is saved to the phone first, so nothing is lost
  if there's no internet.
- When the internet comes back, it sends the saved points on its own.
- Each point shows its status in plain words: Stored locally, Syncing,
  Synced, or Sync failed.
- If something fails to send, it tries again automatically a few
  times. After that, you can tap Retry yourself.
- Keeps tracking in the background too - see the section below.

## How it's built

The code is split into three simple layers:

- **domain** - the core rules (what a location record is, what
  "start tracking" means), no Flutter code here at all.
- **data** - the real work: reading GPS, saving to SQLite, talking to
  the (mock) server, checking internet status.
- **presentation** - the screen and widgets, using a Bloc to manage
  what's shown.

Local storage uses SQLite because the data is just simple rows (lat,
lng, time, status) and we often need to update one row by its id -
that's exactly what SQL is good at.

Everything also has logging (so you can see what's happening in the
console), and the text/colors used on screen are kept in one place
instead of scattered everywhere.

## Background tracking on Android and iOS

The goal: keep recording your location even if you lock the phone or
switch to another app.

**Android** - the app starts a foreground service the moment tracking
begins. This is Android's official way of saying "please don't kill
this app, it's doing something the user asked for." It shows a small
permanent notification while it runs, which is required by Android -
that's the trade-off for being allowed to keep running.

**iOS** - the app turns on "background location updates" and declares
the "Location updates" background mode. iOS then keeps delivering
location updates even after the app is minimized. iOS also needs
"Always" location permission (not just "while using the app") for
this to work - iOS asks the user for this upgrade automatically the
first time it's needed.

In both cases, if the user force-quits the app (swipes it away), the
OS stops everything - that's expected and out of our control, on both
platforms. Opening the app again picks up where it left off, and
everything already saved is still there.

## Project layout

```
lib/
  core/        constants (text, colors) and small shared helpers
  domain/      entities, repository contract, one use case per action
  data/        GPS/storage/server code, and the main repository logic
  presentation/  the Bloc, the screen, and its widgets
test/           automated tests and test doubles
```

## Running it

Built and tested with **Flutter 3.42.2** (check yours with
`flutter --version`). If you use [fvm](https://fvm.app):

```
fvm use 3.42.2
```

Then, from the project root:

```
flutter pub get
flutter run
```

Tap **Start tracking** to begin. Turn off the network to see points
marked "Stored locally", then turn it back on to watch them sync.

## Testing

Run everything with:

```
flutter test
```

There are two test files, each covering something different:

- `test/location_repository_impl_test.dart` - the core sync logic
  (saving offline, auto-sync once back online, never sending the same
  record twice, retrying with a cap). Storage, the server, and
  connectivity are all in-memory test doubles here, so this runs fast
  with no device or emulator needed.
- `test/sqflite_persistence_test.dart` - the same kind of thing but
  against a real, on-disk SQLite database instead of a fake. It writes
  through one database connection, closes it, then reads through a
  brand new one - proving a record (its coordinates, status, and retry
  count) is still there afterwards, the way it would be after a real
  app restart - and then goes a step further: a record that failed to
  sync gets saved for real, the "app" is closed and reopened against
  that same file, and the next launch picks it back up and resyncs it
  automatically. This is deliberately kept as one file rather than
  split up: every test in it opens the exact same database file, and
  `flutter test` runs separate test files concurrently in separate
  processes by default - two of them fighting over the same SQLite
  file at once is how you get a "database is locked" error. Tests
  inside a single file always run one after another, so keeping these
  together is what makes a plain `flutter test` safe to run, with no
  extra flags needed.

This second file needs the `sqflite_common_ffi` package (already
listed under `dev_dependencies` in `pubspec.yaml`) so SQLite can run
for real inside `flutter test`, without a device or emulator.

To run just one file instead of everything:

```
flutter test test/sqflite_persistence_test.dart
```

How to check the result: `flutter test` prints a line per test as it
runs, and a clean run ends with something like `+15: All tests
passed!`. A failing test instead prints that test's name, what was
expected versus what actually happened, and the command exits with a
non-zero status - worth running before every push (or in CI) rather
than assuming yesterday's pass still holds.
