import Pacioli.Entry
import Mathlib.Algebra.BigOperators.Group.List.Basic

/-! # Aggregation

Per-currency, per-direction totals over a list of entries, and the lemmas that
make them compose. Everything here is over `List (Entry α γ ν τ)` and needs only
`DecidableEq γ` (to match a currency) and an `AddCommMonoid ν` (to sum values) —
the value type's nonnegativity/order guard is not required to add, so it is
asked for later, on `Transaction`.
-/

namespace Pacioli

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

end Pacioli
