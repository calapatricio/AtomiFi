# AtomiFi

A personal finance app in the spirit of [Cashew](https://github.com/jameskokoska/Cashew),
with one difference at its core: a transaction is made of **items**, and each
item has its own category and its own split between you and other people.

- `packages/domain`: the domain model and rules, in pure Dart.
- `docs/domain-model.md`: the model and the rules the statistics follow.

## Tests

```sh
cd packages/domain
dart pub get
dart test
```
