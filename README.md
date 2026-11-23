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

```
flutter pub get
flutter run
```

Tap **Start tracking** to begin. Turn off the network to see points
marked "Stored locally", then turn it back on to watch them sync.

## Testing

```
flutter test
```

Tests cover saving offline, auto-sync when back online, not sending
the same record twice, and retrying failed records.

## A note on how this was checked

This was written in an environment without a working Flutter/Dart
setup, so it couldn't be compiled or run here. Every file was checked
by hand and with a script that verifies brackets/braces/parens line
up correctly. Please run `flutter pub get` and `flutter test` yourself
before relying on it.
