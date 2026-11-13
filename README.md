# AtomiFi

A personal finance app in the spirit of [Cashew](https://github.com/jameskokoska/Cashew),
with one difference at its core: a transaction is made of **items**, and each
item has its own category and its own split between you and other people.

- `packages/domain`: the domain model and rules, in pure Dart.
- `packages/data`: SQLite storage built on Drift, in pure Dart.
- `packages/cashew`: reads a Cashew CSV export into the model.
- `app`: the Flutter app (Android and web).
- `docs/domain-model.md`: the model and the rules the statistics follow.

## Running the tests

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install),
which includes Dart.

```sh
cd packages/domain
dart pub get
dart test
```

`packages/data` uses generated code that is not committed, so generate it
before analysing or testing:

```sh
cd packages/data
dart pub get
dart run build_runner build
dart test
```

Every push runs the same checks in GitHub Actions.

## Running the app

Every push to `main` builds a debug APK. Open the latest run of the `ci`
workflow in the Actions tab, download the `atomifi-debug-apk` artifact,
unzip it and install the APK on your phone.

To run it from source, with a device or emulator connected:

```sh
cd packages/data
dart pub get
dart run build_runner build
cd ../../app
flutter pub get
flutter run
```

The app is in English and Spanish and follows the language of the device.

## Checking a Cashew import

This prints what a Cashew backup turns into: how many transactions and
transfers it holds, the balance of each account and the income and expenses
of each month. Compare them with what Cashew shows.

```sh
cd packages/cashew
dart pub get
dart run bin/report.dart path/to/cashew-backup.sql
```

The backup is the file Cashew writes from its import and export settings.
The command also accepts a CSV export, which carries less: no colors or
icons, no transfers, and the side of each category has to be guessed.
