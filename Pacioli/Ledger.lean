/-
Copyright (c) 2026 Otto Hermann. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Otto Hermann
-/
import Pacioli.Transaction

/-!
# Pacioli — ledger and the fundamental invariant

The ledger is the journal of posted entries.  `post` appends a transaction's
entries; `totalBalance_post` proves that posting a (balanced) transaction leaves
the ledger's total balance unchanged.  Starting from the empty ledger, whose
total balance is `0`, every reachable ledger has total balance `0` — the **trial
balance identity** (total debits equal total credits), guaranteed by
construction.

This is *not* the **accounting equation** (`assets = liabilities + equity`).
That statement needs each account to carry a *classification*, and classifying an
account is judgment rather than mechanics — so it is not something this module
can state from what it knows.  See `okf/` for where such a classification would
come from.
-/

namespace Pacioli

/-- A **ledger** is the journal: the list of all posted entries. -/
abbrev Ledger := List Entry

namespace Ledger

/-- The **total balance** of the ledger: the sum of all entry balances.

In a double-entry system this is invariantly `0` — equivalently, total debits
equal total credits (the trial balance identity). -/
def totalBalance (l : Ledger) : ℚ := (l.map Entry.balance).sum

/-- **Post** a transaction: append its entries to the journal. -/
def post (l : Ledger) (t : Transaction) : Ledger := l ++ t.entries

@[simp] theorem totalBalance_nil : totalBalance [] = 0 := by
  simp [totalBalance]

/-- **The fundamental invariant.** Posting a (balanced) transaction leaves the
ledger's total balance unchanged.  Combined with `totalBalance_nil`, every ledger
reachable by posting keeps total balance `0`: the trial balance identity holds by
construction, not by a runtime check. -/
theorem totalBalance_post (l : Ledger) (t : Transaction) :
    (l.post t).totalBalance = l.totalBalance := by
  simp only [post, totalBalance, List.map_append, List.sum_append, t.balanced, add_zero]

end Ledger

end Pacioli
