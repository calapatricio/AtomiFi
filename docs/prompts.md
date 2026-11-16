# Prompts for working on AtomiFi with Claude

`CLAUDE.md` is read at the start of every session, so prompts do not need
to repeat the rules. A good prompt says what you want and what "done"
looks like. These headings work well; skip those that do not apply.

## Template for a feature

```
## Goal
One or two sentences: what I want to be able to do in the app.

## Behaviour
- What it should do, as concrete cases ("when I ..., then ...").
- What it should count or not count, if figures are involved.

## Out of scope
What not to build now.

## Open questions
Things I am not sure about. Ask me before deciding these.

## Done when
What I will check on my phone to accept it.
```

## Template for a bug

```
## What I did
Steps, with the real values (amounts, dates, account, category).

## What I expected

## What happened
The exact text on the screen, or a screenshot.

## Since when
Whether it worked before, and after which change it stopped.
```

## Template for feedback on a screen

```
## Screen
Which one.

## Changes
1. One change per line, in order of importance.

## Keep
What I like and should not change.
```

## Starting a session

```
Read CLAUDE.md and the documents it points to. Then tell me, in five
lines, where the project stands and what you would do next. Do not write
code yet.
```

## Tips

- One feature per conversation. Long conversations lose the beginning.
- Ask for the plan first when the feature is large: "Give me the plan
  and your questions before writing tests."
- Paste real examples (a line of your bank statement, a Cashew figure).
- Finish each session with: "Update docs/backlog.md and docs/decisions.md
  with what we decided."
- If something it says contradicts these documents, tell it which
  document to read again.
