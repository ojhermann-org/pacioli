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

/-- Splitting the entries by a boolean predicate splits the total: `totalBy` over
the whole list is the sum of the totals over the `p`- and non-`p`-entries. (Used
to partition a transaction's entries by account class.) -/
theorem totalBy_filter_add [DecidableEq γ] [AddCommMonoid ν] (c : γ) (d : EntryType)
    (p : Entry α γ ν τ → Bool) (es : List (Entry α γ ν τ)) :
    totalBy c d (es.filter p) + totalBy c d (es.filter fun e => !p e) = totalBy c d es := by
  rw [← totalBy_append]
  exact totalBy_perm c d (List.filter_append_perm p es)

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

/-! # Assets and claims

The **classification** half of the seam. Every account is either an **asset** or
a **claim** on assets, and a claim is a **liability** (a creditor's claim) or
**equity** (the owners' residual claim). Treating equity as a claim — rather than
a separate term — is **entity theory** (W. A. Paton, *Accounting Theory*, 1922),
which collapses the familiar `assets = liabilities + equity` into
`assets = claims`; GAAP and IFRS agree on the arithmetic, so the stance is
mechanical, not jurisdictional.

This taxonomy and the normal-balance convention (`normalSide`) are *mechanical* —
a fixed skeleton. The *assignment* of accounts to classes is *judgment*: it
enters as a function `classify : α → AccountClass` supplied from the OKF half,
never baked into a type. Every theorem below holds for **any** total `classify`.

The taxonomy is deliberately minimal (two-way, with two claim kinds). Revenue and
expense are *temporary equity* accounts, so at this layer they classify as
`.claim .equity`; distinguishing them (for the income statement and
period-close) is deferred, as are contra accounts (see `normalSide`).
-/

/-- The two kinds of claim on an entity's assets. -/
inductive Claim where
  | liability
  | equity
  deriving DecidableEq, Repr

/-- The classification of an account: an asset, or a claim (of some kind) on
assets. A fixed, total, two-way taxonomy. -/
inductive AccountClass where
  | asset
  | claim (kind : Claim)
  deriving DecidableEq, Repr

/-- Whether a class is an asset (rather than a claim on assets). -/
def AccountClass.isAsset : AccountClass → Bool
  | .asset   => true
  | .claim _ => false

/-- The normal (increasing) side of a **class** (not of an individual account):
assets are debit-normal, claims (liabilities and equity alike) credit-normal. A
fixed double-entry convention — this is where the debit-positive sign choice is
finally pinned down.

Because it is per *class*, a **contra account** (e.g. accumulated depreciation, a
credit-normal account classified `asset`) is handled by *net-pool* semantics: it
is assigned to the pool it reduces, and its entries net correctly there. A
per-*account* normal side (to flag contras or abnormal balances) is a later
concept. -/
def normalSide : AccountClass → EntryType
  | .asset   => .debit
  | .claim _ => .credit

/-- The opposite entry direction — the *decreasing* side of a class. -/
def EntryType.other : EntryType → EntryType
  | .debit  => .credit
  | .credit => .debit

@[simp] theorem EntryType.other_other (d : EntryType) : d.other.other = d := by
  cases d <;> rfl

/-- Claims sit on the side opposite assets: a claim's normal side is the other
of the asset normal side. (`normalSide` ignores the claim kind.) -/
theorem normalSide_claim (k : Claim) :
    normalSide (.claim k) = (normalSide .asset).other := rfl

/-- Entries posted to an asset account, under classification `classify`. -/
def assetEntries (classify : α → AccountClass) (es : List (Entry α γ ν τ)) :
    List (Entry α γ ν τ) :=
  es.filter fun e => (classify e.account).isAsset

/-- Entries posted to a claim account, under classification `classify`. -/
def claimEntries (classify : α → AccountClass) (es : List (Entry α γ ν τ)) :
    List (Entry α γ ν τ) :=
  es.filter fun e => !(classify e.account).isAsset

/-- Value in currency `c` that **increases** the asset side: assets posted on
their normal side. -/
def assetIncrease [DecidableEq γ] [AddCommMonoid ν] (classify : α → AccountClass)
    (c : γ) (es : List (Entry α γ ν τ)) : ν :=
  totalBy c (normalSide .asset) (assetEntries classify es)

/-- Value in currency `c` that **decreases** the asset side. -/
def assetDecrease [DecidableEq γ] [AddCommMonoid ν] (classify : α → AccountClass)
    (c : γ) (es : List (Entry α γ ν τ)) : ν :=
  totalBy c (normalSide .asset).other (assetEntries classify es)

/-- Value in currency `c` that **increases** the claim side: claims posted on
their normal side. -/
def claimIncrease [DecidableEq γ] [AddCommMonoid ν] (classify : α → AccountClass)
    (c : γ) (es : List (Entry α γ ν τ)) : ν :=
  totalBy c (normalSide .asset).other (claimEntries classify es)

/-- Value in currency `c` that **decreases** the claim side. -/
def claimDecrease [DecidableEq γ] [AddCommMonoid ν] (classify : α → AccountClass)
    (c : γ) (es : List (Entry α γ ν τ)) : ν :=
  totalBy c (normalSide .asset) (claimEntries classify es)

/-- **The accounting equation** — differential form — at the single-transaction
level and per currency: a balanced transaction's net change to the **asset** side
equals its net change to the **claim** side (entity theory; see the section
docstring). This is the *preservation* step, not the standing balance-sheet
identity `assets = claims`; that identity follows by composing this over a ledger
from an opening state where `0 = 0` (a later theorem).

Because `ν` is an additive monoid (not a group), there is no subtraction, so the
equation is stated as the equality of monoid *differences*:
`increase-to-assets + decrease-to-claims = increase-to-claims + decrease-to-assets`,
which is exactly `Δassets = Δclaims`.

It is a **corollary of `balanced`**: since every account is an asset or a claim,
the asset- and claim-side totals partition the debit total and the credit total,
and `balanced` equates those. So the accounting equation *is* the trial-balance
identity seen through the classification — it holds for **any** total `classify`,
and so provides *no* check that a classification is correct: a misclassification
cannot be caught here; that correctness lives entirely in the judgment/OKF
half. -/
theorem accounting_equation [DecidableEq γ] [AddCommMonoid ν] [PartialOrder ν]
    [CanonicallyOrderedAdd ν] (classify : α → AccountClass)
    (t : Transaction α γ ν τ) (c : γ) :
    assetIncrease classify c t.entries + claimDecrease classify c t.entries
      = claimIncrease classify c t.entries + assetDecrease classify c t.entries := by
  simp only [assetIncrease, claimDecrease, claimIncrease, assetDecrease, assetEntries,
    claimEntries, normalSide, EntryType.other]
  rw [totalBy_filter_add, add_comm (totalBy c .credit _) (totalBy c .credit _),
    totalBy_filter_add]
  simpa [totalDebits, totalCredits] using t.balanced c

end Pacioli
