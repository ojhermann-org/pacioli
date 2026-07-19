import Pacioli.Classification
import Mathlib.Algebra.Order.Group.Nat
import Mathlib.Data.Fintype.Basic

/-! # Examples

A worked instantiation of the whole stack over concrete types, so the abstract
machinery is exercised end to end: accounts are `String`, there is a single
(`Unit`) currency, values are `ℕ` minor units, and time is `ℕ`. These are
`example`s / `def`s that check the instances resolve and the theorems fire on
real data — a smoke test and a reader's worked entry, not part of the mechanics.
-/

namespace Pacioli.Examples

/-- A tiny chart of accounts — the judgment input, here a plain function. -/
def classify : String → AccountClass
  | "cash"     => .asset
  | "supplies" => .asset
  | "loan"     => .claim .liability
  | "capital"  => .claim .equity
  | _          => .asset

/-- Taking a $100 loan: debit cash (an asset), credit loan (a claim). It
balances in every currency, so it is a genuine `Transaction`. -/
def takeLoan : Transaction String Unit ℕ ℕ :=
  ⟨[⟨"cash", (), 100, .debit, 0⟩, ⟨"loan", (), 100, .credit, 0⟩], by decide⟩

/-- The accounting equation holds for this transaction, with no extra proof:
assets rise by 100 (cash debited) and claims rise by 100 (loan credited). -/
example :
    assetIncrease classify () takeLoan.entries + claimDecrease classify () takeLoan.entries
      = claimIncrease classify () takeLoan.entries + assetDecrease classify () takeLoan.entries :=
  accounting_equation_differential classify takeLoan ()

end Pacioli.Examples
