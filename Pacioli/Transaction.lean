import Pacioli.Basic

/-!
# Pacioli — entries and transactions

An `Entry` posts an amount to a named account; a `Transaction` is a list of
entries carrying a *proof* that they balance.  Because `balanced` is a field, an
unbalanced transaction cannot be constructed — illegal states are unrepresentable.
-/

namespace Pacioli

/-- A single posting: an `amount` (debit/credit) applied to a named `account`. -/
structure Entry where
  account : String
  amount : TAccount
  deriving DecidableEq

namespace Entry

/-- The signed balance an entry contributes to the ledger. -/
def balance (e : Entry) : ℚ := e.amount.balance

end Entry

/-- A **transaction** is a list of entries whose balances sum to zero — that is,
total debits equal total credits.  The obligation `balanced` is a field, so an
unbalanced transaction is impossible to build. -/
structure Transaction where
  entries : List Entry
  balanced : (entries.map Entry.balance).sum = 0

end Pacioli
