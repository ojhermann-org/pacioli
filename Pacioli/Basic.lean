import Mathlib.Algebra.BigOperators.Group.List.Basic
import Mathlib.Algebra.Order.Monoid.Canonical.Defs

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
-/

/-! # EntryType

The **direction** of an entry against an account: a debit or a credit.
-/

/-- The direction of an entry against an account: a debit or a credit. -/
inductive EntryType where
  | debit
  | credit
  deriving DecidableEq, Repr

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
them (issue #34).
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

/-! # Transaction

A **transaction** is a collection of entries that balances **within each
currency**: for every currency, the total of its debits equals the total of its
credits.

This is the *trial-balance identity* — the debits-equal-credits equality at the
heart of double-entry bookkeeping, first codified in Luca Pacioli's *Summa de
arithmetica* (1494). Stating it **per currency** is the multi-currency
refinement: a transaction spanning several currencies must balance in each one
independently, never by coincidentally-equal magnitudes summed across units.

Per-currency balance is a modelling commitment: a genuine cross-currency trade
does not balance within each currency at spot, so it must route through an
explicit FX-bridge (clearing) account whose entries make each currency leg
self-balance. There is no reporting-currency balance at this layer.

Balance is bundled into the type — a `Transaction` carries a proof that it
balances, so an *unbalanced* transaction cannot be constructed at all.

The empty transaction balances trivially (`0 = 0` in every currency), and this
is **deliberate**: the empty / all-zero case is degenerate-but-valid, not
illegal (the illegal state — an unbalanced transaction — is exactly what the
type forbids), and the empty transaction will be the identity element once the
journal / ledger layer defines composition of balanced entry-collections.
Requiring a transaction to be *non-trivial*
(non-empty, a positive debit and credit) is an authoring-layer concern kept out
of this substrate — see issue #35.

`entries` is a `List`; entry order carries no accounting meaning (order-
irrelevant `Multiset` follow-up: issue #32).
-/

variable {α γ ν τ : Type*}

/-- The total `value` of the entries in `es` denominated in currency `c` with
direction `d`. -/
def totalBy [DecidableEq γ] [AddCommMonoid ν]
    (c : γ) (d : EntryType) (es : List (Entry α γ ν τ)) : ν :=
  (es.filter fun e => decide (e.currency = c ∧ e.direction = d)).map (·.value) |>.sum

/-- The total `value` of the `c`-denominated debit entries in `es`. -/
def totalDebits [DecidableEq γ] [AddCommMonoid ν] (c : γ) (es : List (Entry α γ ν τ)) : ν :=
  totalBy c .debit es

/-- The total `value` of the `c`-denominated credit entries in `es`. -/
def totalCredits [DecidableEq γ] [AddCommMonoid ν] (c : γ) (es : List (Entry α γ ν τ)) : ν :=
  totalBy c .credit es

/-! ## Aggregation lemmas

`totalBy` — and hence `totalDebits`/`totalCredits` — is a **list homomorphism**:
it sends the empty list to `0` and concatenation to `+`, and is invariant under
reordering. These structural lemmas are what every downstream result — composing
into a journal, aggregating a ledger, closing a period — will rest on. -/

@[simp] theorem totalBy_nil [DecidableEq γ] [AddCommMonoid ν] (c : γ) (d : EntryType) :
    totalBy c d ([] : List (Entry α γ ν τ)) = 0 := by
  simp [totalBy]

@[simp] theorem totalBy_cons [DecidableEq γ] [AddCommMonoid ν]
    (c : γ) (d : EntryType) (e : Entry α γ ν τ) (es : List (Entry α γ ν τ)) :
    totalBy c d (e :: es) =
      (if e.currency = c ∧ e.direction = d then e.value else 0) + totalBy c d es := by
  simp only [totalBy, List.filter_cons]
  by_cases h : e.currency = c ∧ e.direction = d <;> simp [h]

@[simp] theorem totalBy_append [DecidableEq γ] [AddCommMonoid ν]
    (c : γ) (d : EntryType) (a b : List (Entry α γ ν τ)) :
    totalBy c d (a ++ b) = totalBy c d a + totalBy c d b := by
  simp [totalBy, List.filter_append, List.map_append, List.sum_append]

/-- `totalBy` ignores entry order: a permutation of the entries has the same
total. This is the formal content of "entry order carries no accounting
meaning", and the fact the `Multiset` refinement (issue #32) will rest on. -/
theorem totalBy_perm [DecidableEq γ] [AddCommMonoid ν] (c : γ) (d : EntryType)
    {a b : List (Entry α γ ν τ)} (h : a.Perm b) : totalBy c d a = totalBy c d b :=
  List.Perm.sum_eq ((h.filter _).map _)

@[simp] theorem totalDebits_nil [DecidableEq γ] [AddCommMonoid ν] (c : γ) :
    totalDebits c ([] : List (Entry α γ ν τ)) = 0 := by
  simp [totalDebits]

@[simp] theorem totalDebits_append [DecidableEq γ] [AddCommMonoid ν]
    (c : γ) (a b : List (Entry α γ ν τ)) :
    totalDebits c (a ++ b) = totalDebits c a + totalDebits c b := by
  simp [totalDebits]

theorem totalDebits_perm [DecidableEq γ] [AddCommMonoid ν] (c : γ)
    {a b : List (Entry α γ ν τ)} (h : a.Perm b) : totalDebits c a = totalDebits c b :=
  totalBy_perm c .debit h

@[simp] theorem totalCredits_nil [DecidableEq γ] [AddCommMonoid ν] (c : γ) :
    totalCredits c ([] : List (Entry α γ ν τ)) = 0 := by
  simp [totalCredits]

@[simp] theorem totalCredits_append [DecidableEq γ] [AddCommMonoid ν]
    (c : γ) (a b : List (Entry α γ ν τ)) :
    totalCredits c (a ++ b) = totalCredits c a + totalCredits c b := by
  simp [totalCredits]

theorem totalCredits_perm [DecidableEq γ] [AddCommMonoid ν] (c : γ)
    {a b : List (Entry α γ ν τ)} (h : a.Perm b) : totalCredits c a = totalCredits c b :=
  totalBy_perm c .credit h

/-- A **transaction**: a list of entries together with a proof that it balances
per currency (for every currency, total debits equal total credits). Bundling
`balanced` into the type makes an unbalanced transaction unrepresentable.

The value type `ν` carries the monetary contract here — additive and
canonically ordered (nonnegative) — since a balanced transaction is where money
is actually treated as money. -/
@[ext]
structure Transaction (α γ ν τ : Type*)
    [DecidableEq γ] [AddCommMonoid ν] [PartialOrder ν] [CanonicallyOrderedAdd ν] where
  entries : List (Entry α γ ν τ)
  balanced : ∀ c : γ, totalDebits c entries = totalCredits c entries

end Pacioli
