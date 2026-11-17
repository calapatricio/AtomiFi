# Decisions

What the owner decided, and why. Do not reopen these without asking him.

## Product

- **Items are the core.** One transaction per bank record, split into
  items; each item has a category and shares (me and named people).
- **Only my share counts** in statistics, budgets and goals, whether or
  not the others have paid me back. Account balances count everything.
- **Leftover cents fall on me** when a price does not divide evenly.
- **An item can offset another** (a repayment, a refund, a bet payout),
  and is then counted on the date of the item it offsets. A setting can
  switch that off.
- **Mixed signs in one transaction are allowed.** The form has one
  direction (expense or income) for the whole transaction; an item amount
  typed with a minus goes the other way. Example: a bottle deposit
  returned inside a supermarket purchase.
- **Transfers are two linked records**, one per account, each with its own
  date and amount, so each matches a line in a bank's app.
- **Investments**: an account can be revalued. A revaluation stores the
  stated value; the difference with the balance is market gain, never
  income or spending.
- **Neutral categories** (Cashew's balance corrections) change balances
  but are not spending, income or part of any budget.
- **Budgets** cover all spending, some categories, or items put in one by
  one. Periods repeat every N days, weeks, months or years from a first
  day, or are one fixed stretch. A budget counts only items dated inside
  its current period, also for items put in by hand. No shared budgets.
- **Goals** are reached by saving or by spending, count the items put in
  them whatever their date, and may have a deadline.
- **Deleting an account** deletes its transactions, revaluations and both
  sides of its transfers, after a confirmation that says how much goes.
  Archiving hides it and keeps everything.
- **Every delete asks for confirmation.**
- **Currencies belong to accounts.** There is one main currency (EUR) for
  budgets, goals and statistics.
- **Loans and debts** will be tracked through shares and offsetting items
  with a "who owes me" view, not through Cashew's loan types.

- **Statistics** are the most important screen: where the owner checks
  what he spent on each thing over a month or a year. They show one
  period at a time, chosen as: a period that repeats (every N days,
  weeks, months or years from a day, with arrows to the one before and
  after), the last N days, the time between two dates, or everything.
  They open on the current calendar month and on the expenses. Tapping a
  category with subcategories shows them, and the line over time then
  follows that category alone. Cashew's separate "history" mode was left
  out on purpose.

## Sync and data

- **No server.** Backup is one file sent to Google Drive; restore takes
  the latest. Keep about ten backups. No merging between devices.
- **Cashew import** reads the SQLite backup (schema version 48) and keeps
  Cashew's ids. A CSV reader exists but carries less. Unpaid transactions
  are skipped; opposite paired transactions in different wallets become
  transfers.
- **Attachments** (photos, files) will go to Google Drive.

## Technology

- Dart and Flutter; SQLite through Drift.
- Plain `ChangeNotifier` view models with constructor injection; Provider
  only if it becomes necessary.
- Tests run only in GitHub Actions.
- The debug APK is signed with a new key on each run, so installing a new
  one may require uninstalling the old one, which wipes the data. The
  owner said not to spend time on this for now.

## Interface

- English and Spanish, following the device.
- Similar to Cashew, keeping emojis and colours of accounts and
  categories.
- Expense in red and income in green, with arrows.
- Carousels (`ChoiceCarousel`) for accounts, budgets and goals; the add
  button is just "+"; selection must not change sizes or show check marks.
- Categories are chosen in a bottom sheet with four columns, a sheet for
  subcategories with "None", and "Add category".
- When "Include me" is off for a shared item, my row disappears and the
  parts of the others must add up to the price.
- The bottom bar stays at four destinations: Transactions, Stats, Budgets
  and More. The accounts are under More.
