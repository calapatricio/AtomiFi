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
  (period chooser, summary, ring by category with subcategories, line
  over time, expenses or income).

## Next, in the order the owner asked

Nothing is fixed after budgets and goals; ask him. Candidates he has
mentioned:

1. Recurring and scheduled transactions (reuse `Recurrence`), including
   subscriptions.
2. More in the statistics: the transactions behind a category when it is
   tapped, comparing with the period before, net worth over time, a
   filter by account, and the switch for dating offsetting items.
3. "Who owes me": linking repayments to items (`Item.offsets` exists in
   the domain, there is no interface for it) and a view per person.
4. Creating transfers and revaluations in the app (they only arrive
   through the import today).
5. Attachments, Google sign-in and backup to Google Drive.
6. Category management screen (editing, colours, subcategories).
7. Receipt scanner (an idea for later).

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
