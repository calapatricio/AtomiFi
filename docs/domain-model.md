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
- **Category**: a name, a side (expense or income) and an optional parent.
- **Money**: an integer number of minor units plus a currency. Negative is
  money leaving an account.

## Rules

1. Account balances count every item in full.
2. Statistics count only my share of each item. Shares of other people never
   count, whether they have paid me back or not.
3. Amounts are netted per category and reported on the category's side.
4. An item that offsets another is counted on the date of the item it
   offsets. This can be switched off, so that it counts on its own date.
5. When a price cannot be divided evenly, I bear the leftover cents.

## Left out of Cashew's model on purpose

- Credit and debt transaction types and loan goals: replaced by shares and
  offsetting items.
- Shared budgets and their server-side fields.
