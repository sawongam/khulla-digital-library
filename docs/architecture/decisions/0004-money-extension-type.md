# ADR 0004 - Money as an extension type over minor units

**Status:** Accepted · **Date:** 2026-09-03

## Context

Khulla tracks fines, fees, deposits, and loan overdue amounts. Every place money appears is a decision point: what type does it have, what unit is it in, how does it cross the database boundary, and how does it reach the user's screen?

The naive answers are wrong in ways that compound:

**`double` amounts in rupees.** Binary floating-point cannot represent 0.1 exactly. `0.1 + 0.2` in Dart is `0.30000000000000004`. Across a year of daily fine accrual, a library's overdue ledger drifts. The error is small per transaction, invisible until it is not, and impossible to explain to a librarian.

**`int` amounts in some unspecified unit.** An `int fine` could be rupees, it could be paisa, it could be whatever the last developer assumed. A single column that was written in rupees and read as paisa is off by 100× - and because the type is just `int`, the compiler cannot catch it.

**`double` amounts with a named unit convention.** Naming every variable `amountInPaisa` is workable but unenforced. A reviewer who misses one `int fineInRupees = row['amount']` has introduced a 100× bug with no static help.

**A full `Money` class.** A proper value class with `==`, `hashCode`, arithmetic, and a named unit is the right design, but a class heap-allocates: every fine on a page, every row in a ledger, every sum in a dashboard is a separate object. Fines are not the bottleneck, but allocating an object for every `int` in the database is avoidable.

## Decision

Represent every monetary amount as **`Money`** - a zero-cost **extension type** over `int` of **minor units (paisa)**. The storage unit is fixed at 100 minor units per major unit and is not configurable.

```dart
extension type const Money(int minorUnits) { … }
```

An extension type compiles to its representation type. A `Money` is an `int` at runtime - no allocation, no boxing, value equality and hashing from the underlying `int` for free.

### The one rule

**Money stays in minor units internally. Only `display()` / `formatted` / `editable` / `major` divide by 100.**

```dart
final rate  = fine.perDay;          // Money, from the drift converter
final owed  = rate * daysOverdue;   // exact integer arithmetic, still paisa
Text(owed.display());               // 'Rs 45'
```

Convert at the edges only:

| Edge                  | Direction | How                                                                   |
| --------------------- | --------- | --------------------------------------------------------------------- |
| Database column ↔ app | both      | `integer().map(const MoneyConverter())` - declared once on the column |
| User text → app       | read      | `text.toMoney()` - major units the user typed, multiplied by 100      |
| App → text field      | write     | `money.editable` - blank when zero                                    |
| App → screen          | display   | `money.display()` → `Rs 1,240.50`                                     |

### The database edge

`MoneyConverter` (`lib/core/database/converters/money_converter.dart`) is declared on the drift column, not at every read site:

```dart
class Fines extends Table {
  IntColumn get amount => integer().map(const MoneyConverter())();
}
```

The generated `Fine` data class carries `Money amount`. There is no `.toMoney()` to forget on a read and no `.minorUnits` to forget on a write. The column is still a plain SQLite integer of paisa - the converter is a Dart-layer convenience with no effect on the file.

### Arithmetic operators

Operators take plain scalars, not `Money`:

```dart
Money operator *(num factor) => Money((minorUnits * factor).round());
```

`rate * rate` - minor units times minor units - does not typecheck. `rate * 3` - a rate times a day count - does. This is the type error that catches the 100× total mistake at compile time.

For percentages and ratios:

```dart
Money percent(num rate)             // Rs 200 .percent(15) == Rs 30
Money discounted(num rate)          // waiver on a fine
double ratioTo(Money other)         // for progress bars, never computes a Money
```

### Display rules that are easy to get wrong

- **Never interpolate a `Money`.** `'$owed'` prints the raw minor units - an extension type inherits `int.toString`. Every user-facing string goes through `display()`, `formatted`, or `editable`.
- **Money never appears in an ARB placeholder as a number.** The ARB owns the sentence; `Money` owns the symbol and grouping. A placeholder is `{"type": "String"}` filled with `money.display()`.
- **`Money.major(n)` is not `const`.** A placeholder list holding amounts must be `final`, not `const`. `Money(minorUnits)` _is_ const, but never write a paisa literal for readability's sake.
- **A missing amount is `Money.zero`, not null.** Keep `Money?` only where "not set" is genuinely different from zero.

### Currency format

`MoneyFormat` (`lib/core/money/money_format.dart`) owns the symbol, its side, and the digit grouping. `MoneyFormat.current` is set once in `bootstrap` from the library's settings. `kMinorUnitsPerMajor` is fixed at 100 - changing it would reinterpret every amount already in the database. A zero-decimal currency simply never shows decimal places; nothing about `Money` needs to change.

## Consequences

**What this buys**

- The compiler enforces the unit. A column read as rupees when it was stored as paisa is a type error - `int` does not assign to `Money` without `.toMoney()`.
- No allocation. `Money` is an `int` at runtime. A page listing ten thousand fines allocates no more than a page listing ten thousand integers.
- The database boundary is declared once, on the column. It cannot be forgotten on a per-read basis.
- Arithmetic mistakes - rate × rate, summing minor and major units - do not compile.
- `Money.sum()`, `min()`, `max()`, `compareTo()` cover every aggregate without reaching for a separate `Iterable` extension.

**What this costs**

- Extension types have one sharp edge: they do not prevent implicit upcasts. `Money` is assignment-compatible with `int` and `num` in some positions. The operators and the converter guard the database boundary; call-site discipline guards the arithmetic boundary.
- `Money.major(n)` is not `const`. This is a Dart restriction on extension types with non-trivial constructors, not a design choice.
- `'$money'` printing raw paisa is a footgun. The lint `avoid_interpolation_in_string_literals` on a `Money` receiver would catch it, but no such lint exists in `analysis_options_base.yaml` today. Convention and code review are the guard.
- A bare `null` literal is the one call that will not compile: it matches both `MoneyFromNum` and `MoneyFromText` equally. Give the receiver a type instead of casting.

## Revisiting

The trigger is a library that operates in a zero-decimal currency (JPY, KRW) or one that subdivides by a factor other than 100. Zero-decimal currencies are handled already - `display()` skips the decimal places. A non-100 factor cannot be added without migrating every amount in the database; that is the point of fixing it now. Revisit if a supported currency requires it before any database has shipped.
