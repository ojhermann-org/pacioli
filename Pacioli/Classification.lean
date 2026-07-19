import Pacioli.Aggregation
import Pacioli.Transaction

/-! # Assets and claims

The **classification** half of the seam. Every account is either an **asset** or
a **claim** on assets, and a claim is a **liability** (a creditor's claim) or
**equity** (the owners' residual claim). Treating equity as a claim — rather than
a separate term — is **entity theory** (W. A. Paton, *Accounting Theory*, 1922),
which collapses the familiar `assets = liabilities + equity` into
`assets = claims`; GAAP and IFRS agree on the arithmetic, so the stance is
mechanical, not jurisdictional.

This taxonomy and the normal-balance convention (`AccountClass.normalSide`) are *mechanical* —
a fixed skeleton. The *assignment* of accounts to classes is *judgment*: it
enters as a function `classify : α → AccountClass` supplied from the OKF half,
never baked into a type. Every theorem below holds for **any** total `classify`.

The taxonomy is deliberately minimal (two-way, with two claim kinds). Revenue and
expense are *temporary equity* accounts, so at this layer they classify as
`.claim .equity`; distinguishing them (for the income statement and
period-close) is deferred, as are contra accounts (see `AccountClass.normalSide`).
-/

namespace Pacioli

variable {α γ ν τ : Type*}

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
def AccountClass.normalSide : AccountClass → EntryType
  | .asset   => .debit
  | .claim _ => .credit

/-- Claims sit on the side opposite assets: a claim's normal side is the other
of the asset normal side. (`AccountClass.normalSide` ignores the claim kind.) -/
theorem AccountClass.normalSide_claim (k : Claim) :
    AccountClass.normalSide (.claim k) = (AccountClass.normalSide .asset).other := rfl

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
  totalBy c (AccountClass.normalSide .asset) (assetEntries classify es)

/-- Value in currency `c` that **decreases** the asset side. -/
def assetDecrease [DecidableEq γ] [AddCommMonoid ν] (classify : α → AccountClass)
    (c : γ) (es : List (Entry α γ ν τ)) : ν :=
  totalBy c (AccountClass.normalSide .asset).other (assetEntries classify es)

/-- Value in currency `c` that **increases** the claim side: claims posted on
their normal side. -/
def claimIncrease [DecidableEq γ] [AddCommMonoid ν] (classify : α → AccountClass)
    (c : γ) (es : List (Entry α γ ν τ)) : ν :=
  totalBy c (AccountClass.normalSide .asset).other (claimEntries classify es)

/-- Value in currency `c` that **decreases** the claim side. -/
def claimDecrease [DecidableEq γ] [AddCommMonoid ν] (classify : α → AccountClass)
    (c : γ) (es : List (Entry α γ ν τ)) : ν :=
  totalBy c (AccountClass.normalSide .asset) (claimEntries classify es)

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
    claimEntries, AccountClass.normalSide, EntryType.other]
  rw [totalBy_filter_add, add_comm (totalBy c .credit _) (totalBy c .credit _),
    totalBy_filter_add]
  simpa [totalDebits, totalCredits] using t.balanced c

end Pacioli
