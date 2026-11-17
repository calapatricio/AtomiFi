# Backlog

Keep this file current: move things between sections as they are done.

## Done

- Domain: money, accounts, categories with subcategories, transactions
  with items and shares, transfers, revaluations, balances, statistics,
  currency conversion, receivables, recurrence, budgets, goals, the
  period, breakdown by category and trend of the statistics.
- Storage for all of the above.
- Cashew import: CSV and SQLite backup, including budgets and goals;
  a command-line report to compare with Cashew.
- App: accounts (add, archive, restore, delete), transactions list,
  transaction form (items, categories, shares, budget and goal per item,
  amounts with a minus), budgets (list, add, edit, delete), goals under
  More (list, add, edit, delete), import of a Cashew backup, statistics
  under More (period chooser, summary, ring by category with
  subcategories, line of the balance over time, list of the transactions
  that count).

## Waiting for the owner

- **Income recorded in expense categories.** In the statistics the
  expenses were sometimes negative and the payroll was missing from the
  income ring. The likely cause, to confirm with his data: Cashew lets an
  income transaction use any category, and the import takes the side of a
  category from Cashew's flag alone, so a payroll in a category that is
  not flagged as income is netted against the expenses. Options put to
  him: decide the side of an imported category from the money in it, or
  let him change the side of a category in the app. Do not change how
  amounts are netted (rule 2 of the domain model) without his say.

## Next

The owner wants what exists finished before new features. Candidates he
has mentioned, the first at the top:

1. Recurring and scheduled transactions (reuse `Recurrence`), including
   subscriptions. Cashew's unpaid transactions are skipped by the import.
2. Net worth in the statistics: what all the accounts held at the end of
   the period shown, and how it changed over it. Needs exchange rates
   first, because one account in another currency would make it fail.
3. More in the statistics: comparing with the period before, a filter by
   account, and the switch for dating offsetting items.
4. "Who owes me": linking repayments to items (`Item.offsets` exists in
   the domain, there is no interface for it) and a view per person.
5. Creating transfers and revaluations in the app (they only arrive
   through the import today).
6. Attachments, Google sign-in and backup to Google Drive.
7. Category management screen (editing, colours, subcategories, side).
8. Receipt scanner (an idea for later).

## Known limits

- **No exchange rates in the app.** A transaction in a currency other
  than EUR makes budgets, goals and statistics fail. Needs a source of
  rates and a decision from the owner.
- Icons are stored by name only; there is no icon set to draw them.
- New accounts cannot choose a colour or emoji.
- Not imported from Cashew: per-category limits inside a budget, wallet
  filters of budgets, transactions excluded from a budget, loans.
- No database migrations yet (see `CLAUDE.md`).

## Interface changes agreed but not done

See `docs/ui-backlog.md`: a Home screen is still to be built, and where
it goes in the bottom bar is for the owner to decide.
