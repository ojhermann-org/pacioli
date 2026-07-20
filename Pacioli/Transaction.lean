import Pacioli.Aggregation
import Mathlib.Algebra.Order.Monoid.Canonical.Defs

/-! # Transaction

A **transaction** is a collection of entries that balances **within each
currency**: for every currency, the total of its debits equals the total of its
credits.

This is the double-entry **balancing rule** — a transaction's debits equal its
credits — the debits-equal-credits identity first codified in Luca Pacioli's
*Summa de arithmetica* (1494); its ledger-wide, period-end form is the *trial
balance*. Stating it **per currency** is the multi-currency
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
Requiring a transaction to be *non-trivial* (non-empty, a positive debit and
credit) is an authoring-layer concern kept out of this substrate — see issue
#35.

`entries` is a `List`; entry order carries no accounting meaning (order-
irrelevant `Multiset` follow-up: issue #32).

An entry belongs to a transaction by **membership in `entries`** — the
association is containment, not a foreign key. The core deliberately carries no
entry/transaction IDs and no `transactionId` reference: an id reads in no
mechanical law, and a key would reintroduce the dangling/mismatched states that
containment rules out by construction (the same "illegal states unrepresentable"
discipline as the bundled `balanced` proof). Identity and persistence are
downstream — see issue #45.
-/

namespace Pacioli

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
