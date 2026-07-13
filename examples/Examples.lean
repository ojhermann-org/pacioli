import Pacioli

/-!
# Worked example — straight-line depreciation crossing the boundary

The *judgment* lives in `okf/concepts/straight-line-depreciation.md`: how to
spread a depreciable asset's cost over its useful life.  That judgment produces a
**schedule** — plain data (a per-period expense amount) — which the verified
kernel then posts.  The kernel guarantees the postings balance; it neither knows
nor cares *why* the schedule looks the way it does.  This file is the handshake,
verified end to end.
-/

namespace Pacioli.Examples

open Pacioli

/-- One period of a straight-line depreciation schedule, as postings:
debit **Depreciation Expense**, credit **Accumulated Depreciation**. -/
def depreciationEntries (expense : Money) : List Entry :=
  [ { account := "Depreciation Expense", amount := ⟨expense, 0⟩ },
    { account := "Accumulated Depreciation", amount := ⟨0, expense⟩ } ]

/-- Each period's postings balance: the debit to expense exactly offsets the
credit to accumulated depreciation. -/
theorem depreciationEntries_balanced (expense : Money) :
    ((depreciationEntries expense).map Entry.balance).sum = 0 := by
  simp only [depreciationEntries, Entry.balance, TAccount.balance, List.map_cons,
    List.map_nil, List.sum_cons, List.sum_nil]
  push_cast
  ring

/-- The balanced transaction for one period, assembled from the schedule and its
balance proof. -/
def depreciationTxn (expense : Money) : Transaction :=
  { entries := depreciationEntries expense
    balanced := depreciationEntries_balanced expense }

/-- Posting a period of depreciation keeps the books balanced — directly by the
kernel's fundamental invariant.  The judgment chose `expense`; the kernel
guarantees the mechanics regardless. -/
example (l : Ledger) (expense : Money) :
    (l.post (depreciationTxn expense)).totalBalance = l.totalBalance :=
  Ledger.totalBalance_post l (depreciationTxn expense)

end Pacioli.Examples
