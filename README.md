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

## Checking a Cashew export

This prints what your Cashew CSV export turns into: account balances and
the income and expenses of each month.

```sh
cd packages/cashew
dart pub get
dart run bin/report.dart path/to/cashew-export.csv
```
