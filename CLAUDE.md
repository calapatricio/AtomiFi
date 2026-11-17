# AtomiFi: instructions for Claude

Read this file fully before doing anything. Then read
`docs/domain-model.md`, `docs/decisions.md` and `docs/backlog.md`.

## What this is

A personal finance app like Cashew, built from scratch in Dart and Flutter
by one person (GitHub `calapatricio`) for his own use. The one idea that
sets it apart: **a transaction is made of items, and each item has its own
category and its own split between the owner and other people.**
Statistics, budgets and goals count only the owner's share.

Android first; iOS and web later.

## Rules that are not negotiable

1. **TDD.** Every change starts with a failing test, pushed in its own
   commit. Then the code that makes it pass. No code without a test that
   needed it.
2. **SOLID, clean code, no code smells.** Small classes with one reason to
   change, dependencies passed through constructors, no duplication. When
   two features need the same logic, extract it (see `ItemAssignments`,
   used by budgets and goals) instead of copying it.
3. **Everything in the repository is in English**: code, comments, names,
   commit messages, documents. Only the translation file `app_es.arb` is
   in Spanish. Talk to the owner in the language he writes in.
4. **Every text the user sees comes from the translation files**
   (`app/lib/l10n/app_en.arb` and `app_es.arb`), always in both.
5. **`main` only receives branches whose CI is green.**
6. **Ask before deciding anything about behaviour** the documents do not
   settle: what a figure counts, what happens to data, what a screen
   offers. Decide code structure yourself; the owner reviews the result.
7. Priorities: models and features first, visual polish later. In a
   screen, what matters most is that it is intuitive: where the buttons
   are, what is shown first, how few taps a common task takes. Colours and
   fine details come after.

## The sandbox cannot run Dart

There is no Dart or Flutter SDK here and it cannot be installed. **All
checking happens in GitHub Actions.** Never claim something works until
the CI run for that commit is green. The loop is:

```sh
git checkout -b <slice-name>           # one branch per slice, from main
# 1. write the failing tests
git commit -m "Add failing tests for ..." && git push -u origin <slice-name>
# 2. write the code
git commit -m "..." && git push
tool/ci.sh <slice-name>                # waits and prints each job's result
tool/failures.sh <slice-name>          # if red: what failed
tool/fmt.sh <slice-name>               # if the formatter changed files: apply, commit, push
# 3. when every job is green
git checkout main && git merge --ff-only <slice-name> && git push origin main
tool/ci.sh main                        # also builds the debug APK
```

- Use the `gh` CLI with `--repo calapatricio/atomifi`.
- The "Check formatting" step fails when `dart format` changes anything.
  You cannot run the formatter, so expect one extra round: `tool/fmt.sh`
  applies its diff. The packages use the older formatting style and the
  app the newer "tall" style; do not try to guess, let CI tell you.
- Because CI is the only compiler, read your own code twice before
  pushing: imports, named parameters, exhaustive `switch`es, unused
  imports (fatal in the analyzer).
- Commit messages: imperative, in English, a short body saying why when it
  is not obvious. End them with the attribution lines the session gives
  you.

## Editing files safely

- Prefer the Edit tool for small changes. If you script edits (Python),
  make every replacement assert that the text it replaces exists, and make
  the shell stop when the script fails (`python3 - <<'EOF' || echo FAILED`).
  A failed script once committed half an edit; check before committing.
- Do not use regular expressions to rewrite Dart code.
- After a batch of edits, `git status --short` and re-read the diff.

## Map of the code

| Path | What it holds |
| --- | --- |
| `packages/domain` | The model and the rules, pure Dart (`atomifi_domain`). `package:atomifi_domain/testing.dart` exports `InMemoryStore`, the fake storage used by tests. |
| `packages/data` | SQLite storage with Drift (`atomifi_data`): tables, database, one `Drift*Repository` per repository interface. Generated `.g.dart` files are not committed. |
| `packages/cashew` | Import from Cashew (`atomifi_cashew`): CSV export and SQLite backup, `bin/report.dart`. |
| `app` | The Flutter app. One folder per feature (`accounts`, `budgets`, `goals`, `stats`, `transactions`, `categories`, `more`), `widgets` for shared ones, `l10n` for texts. |
| `docs` | The model, the decisions, the backlog, prompts for the owner. |
| `tool` | CI helper scripts. |

Layers depend inwards only: `app` → `data`, `cashew` → `domain`. The
domain imports nothing but Dart.

### Conventions in the domain

- Ids are extension types over `String` in `ids.dart` (`ItemId`, `GoalId`).
- `Money` is an integer number of minor units plus a `Currency`. Negative
  means money leaving an account. Never use `double` for money outside
  the Cashew readers.
- Value classes are `final class` with `const` constructors where
  possible; "changes" return a new object (`withItems`, `archived()`).
- Repositories are `abstract interface class`es in the domain; storage
  implements them. Each new repository also gets an in-memory version in
  `InMemoryStore`.
- Sealed classes for closed sets (`Party`, `BudgetPeriod`, `BudgetScope`),
  always handled with exhaustive `switch`es, never `default`.

### Conventions in storage

- Amounts are stored as bare minor units; the currency comes from the
  account (budgets and goals store their own currency).
- No cascades: repositories delete dependent rows explicitly inside a
  transaction.
- Links from budgets and goals to items are **not** foreign keys, because
  saving a transaction deletes and reinserts its items.
- Changing a table means a schema version bump and a migration once the
  owner has real data in the app (he does: he imported his Cashew backup).
  **Ask before the first schema change after this point**; so far tables
  were only added and the owner reinstalled.

### Conventions in the app

- State: plain `ChangeNotifier` view models, created in `app.dart` and
  passed through constructors. No state-management package unless really
  needed (then Provider, agreed with the owner).
- A view model takes repositories or domain services, `newId` and `now`
  as constructor parameters (private named initializing formals:
  `required this._goals`). It never touches widgets.
- Screens take their view model and callbacks (`openForm`) and are tested
  with `pumpScreen` from `app/test/support/harness.dart`, which also has
  the fixtures (`seededStore`, `spending`, `income`, `monthlyBudget`,
  `pizzaGoal`, `transactionFormOn`, ...). Add fixtures there, not in each
  test.
- Material comes from `package:material_ui/material_ui.dart`.
- Charts are small widgets drawn with `CustomPainter` in `app/lib/widgets`
  (`DonutChart`, `LineChart`). They know nothing about money or
  categories: the screen turns its figures into fractions and points. Do
  not add a chart package without asking.
- A screen is made of small widgets, each in its own file when it has a
  job of its own (`stats/summary_card.dart`, `stats/period_bar.dart`), and
  all its figures come ready from the view model, which gets them from the
  domain. Widgets do not calculate.
- Before writing a field or a control, look in `app/lib/widgets` for one
  that already does it (`ChoiceCarousel`, `DayButton`, `RhythmFields`,
  `AppearanceAvatar`), and move a private widget there when a second
  screen needs it.
- Import `ChangeNotifier` with
  `import 'package:flutter/foundation.dart' show ChangeNotifier;` because
  Flutter's own `Category` clashes with the domain's.
- New texts: add the key to **both** `.arb` files; placeholders are
  declared with `@key` in `app_en.arb` only.
- The bottom bar must not grow. New sections go under **More** (see
  `docs/backlog.md`).

### Conventions in tests

- Test names are sentences about behaviour: `'takes an item out of its
  budget when none is chosen'`. Groups name the subject.
- View-model tests for logic, widget tests for what the screen shows and
  wires. Storage tests run against an in-memory SQLite database.
- In widget tests `find.byTooltip` finds the `Tooltip`, not the button:
  use `find.widgetWithIcon(IconButton, ...)`.

### Comments and names

- Doc comments (`///`) say what a thing is for in plain words, not how it
  works. No comments that repeat the code.
- Names are whole words. Avoid `export` and `import` as identifiers.

## Definition of done for a slice

1. Failing tests were pushed first, then the code.
2. Every CI job is green on the branch, and on `main` after merging.
3. Texts exist in English and Spanish.
4. `docs/domain-model.md` reflects any new entity or rule,
   `docs/decisions.md` any new decision by the owner, and
   `docs/backlog.md` the new status.
5. The final message to the owner says, briefly: what he can do now in the
   app, what was left out, and anything he should check or decide.
