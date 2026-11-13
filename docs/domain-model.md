# Domain model

## Entities

- **Transaction**: one record of a bank or cash account. It has a name, a
  note, a date and time, an account and one or more items. Its total is the
  sum of its items and is never stored separately.
- **Item**: a name, one category and one or more shares. Its price is the sum
  of its shares. It may offset an earlier item (a repayment, a refund, the
  payout of a bet).
- **Share**: the part of an item borne by one party, either me or a named
  person. All shares of an item have the same sign.
- **Account**: a name, a currency and an appearance (color, icon, emoji).
  It can be archived, which keeps all its records but puts it out of sight,
  or removed, which also removes its transactions, its revaluations and
  both sides of the transfers it took part in.
- **Transfer**: money moved between two of my accounts. It is two linked
  records, one per account, each with its own date and amount, so each one
  matches a line in that bank's app. The amounts may be in different
  currencies.
- **Revaluation**: what an account was worth at one moment, typed in by me.
  The difference with the balance until then is the market's gain or loss.
- **Category**: a name, a side (expense or income), an optional parent and
  an appearance.
- **Money**: an integer number of minor units plus a currency. Negative is
  money leaving an account.

## Rules

1. Account balances count every item in full, plus transfers. A revaluation
   replaces the balance with the stated value.
2. Statistics count only my share of each item. Shares of other people never
   count, whether they have paid me back or not.
3. Amounts are netted per category and reported on the category's side.
4. An item that offsets another is counted on the date of the item it
   offsets. This can be switched off, so that it counts on its own date.
5. Transfers and revaluations never count as spending or income.
6. Amounts in other currencies are converted to the statistics currency at
   the current rate.
7. When a price cannot be divided evenly, I bear the leftover cents.

## How changes are made

Each slice is built on its own branch: first a commit with failing tests,
then the code that makes them pass. `main` only receives green branches.

## Left out of Cashew's model on purpose

- Credit and debt transaction types and loan goals: replaced by shares and
  offsetting items.
- Shared budgets and their server-side fields.
