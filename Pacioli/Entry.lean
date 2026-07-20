import Mathlib.Tactic.TypeStar

namespace Pacioli

/-! # Value

Monetary value is left **abstract**: a type parameter `ν` supplied by the
caller, not a fixed representation. This is the same "representation is the
caller's, not the kernel's" seam as `account` and `currency` — one system uses
integer minor units (`ℕ`), another nonnegative rationals or `NNReal`.

The mechanics constrain `ν` to be exactly what a monetary magnitude must be:

* an **additive commutative monoid** — values add, with a `0` for the empty sum,
  order-independently (needed to total debits and credits); and
* **canonically ordered** (`CanonicallyOrderedAdd`, over a `PartialOrder`) —
  every element satisfies `0 ≤ a`, so a value is **nonnegative by
  construction**. This is the load-bearing guard: it forbids instantiating `ν`
  with a signed type like `ℤ`, which would let the sign smuggle direction back
  in and defeat the magnitude-plus-`EntryType` split.

Total comparability of magnitudes (`LinearOrder`) is not required by any current
mechanic, so it is not imposed; it returns at the point of use when one compares
values — see issue #36. `ℕ` (minor units) is the canonical instance.
Parameterising `ν` this way supersedes the opaque-money-wrapper hardening once
tracked in issue #31.

These constraints are asked for at the point of use (`Pacioli.Aggregation`,
`Pacioli.Transaction`); `Entry` itself imposes none, so it is maximally abstract
data.
-/

/-! # EntryType

The **direction** of an entry against an account: a debit or a credit.
-/

/-- The direction of an entry against an account: a debit or a credit. -/
inductive EntryType where
  | debit
  | credit
  deriving DecidableEq, Repr

/-- The opposite entry direction: debit ↔ credit (the *decreasing* side, once a
class's normal side is fixed in `Pacioli.Classification`). -/
def EntryType.other : EntryType → EntryType
  | .debit  => .credit
  | .credit => .debit

@[simp] theorem EntryType.other_other (d : EntryType) : d.other.other = d := by
  cases d <;> rfl

/-! # Entry

A single accounting **entry**: it posts a `value` (of the caller's value type
`ν`), denominated in currency `γ`, to an `account`, as a debit or credit
according to `direction`, occurring at `time`.

The account identifier (`α`), the currency (`γ`), the value type (`ν`), and the
timestamp (`τ`) are all kept abstract — the chart of accounts, the set of
currencies, the representation of money, and the representation of time are the
caller's data, not the kernel's, so none of that policy leaks into the types.
`τ` is unconstrained here; mechanics that compare or order times (mapping FX
rates to entries, period boundaries) ask for that structure at the point of use,
just as aggregation asks for `DecidableEq` / an additive monoid where it needs
them.

An `Entry` deliberately carries **no identifier / surrogate key**. An id reads in
no mechanical law — balance, aggregation, and classification never reference one
— so identity is a downstream/persistence concern, not core data. (Duplicates are
distinguished by multiplicity in the containing `List`/`Multiset`, not by id.)
See issue #45.
-/

/-- A single accounting entry: posts `value`, in currency `currency`, to
`account`, as a debit or credit according to `direction`, occurring at `time`. -/
structure Entry (α γ ν τ : Type*) where
  account : α
  currency : γ
  value : ν
  direction : EntryType
  time : τ
  deriving DecidableEq, Repr

end Pacioli
