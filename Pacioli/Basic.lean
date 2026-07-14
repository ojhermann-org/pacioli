/-
Copyright (c) 2026 Otto Hermann. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Otto Hermann
-/
import Mathlib

/-!
# Pacioli — foundational types

The value type (`Money`) and the `TAccount`, together with the `balance`
valuation into `ℚ`.  A `TAccount` is exactly an element of Ellerman's *Pacioli
group* — the group of differences on ordered pairs of non-negative numbers — and
`balance` is the group homomorphism sending a T-account to its net signed value.
-/

namespace Pacioli

/-- Money is modelled as a non-negative rational (`ℚ≥0`).

We deliberately avoid `ℝ` (no decidable equality, not computable) and floating
point (rounding).  `ℚ≥0` keeps debit and credit amounts non-negative *by type*
and divides evenly for ratable schedules.  A later revision may switch to integer
minor units (cents) if rounding semantics must be made first-class. -/
abbrev Money := ℚ≥0

/-- A **T-account**: an ordered pair of a non-negative `debit` and `credit`.

This is an element of the Pacioli group (the group of differences built from
pairs of non-negative numbers).  The pair is kept intact — rather than collapsed
to its net — so that *gross* debits and credits are preserved, as a real ledger
requires. -/
structure TAccount where
  debit : Money
  credit : Money
  deriving DecidableEq

namespace TAccount

/-- The **balance** valuation `TAccount → ℚ`, defined as `debit − credit`.

This is the quotient map of the group of differences: the additive homomorphism
sending a T-account to its net signed value.  Kernel invariants are stated
through it. -/
def balance (t : TAccount) : ℚ := (t.debit : ℚ) - (t.credit : ℚ)

/-- The zero T-account: no activity. -/
instance : Zero TAccount := ⟨⟨0, 0⟩⟩

/-- Componentwise addition accumulates debit and credit activity. -/
instance : Add TAccount := ⟨fun a b => ⟨a.debit + b.debit, a.credit + b.credit⟩⟩

@[simp] theorem debit_zero : (0 : TAccount).debit = 0 := rfl

@[simp] theorem credit_zero : (0 : TAccount).credit = 0 := rfl

@[simp] theorem debit_add (a b : TAccount) : (a + b).debit = a.debit + b.debit := rfl

@[simp] theorem credit_add (a b : TAccount) : (a + b).credit = a.credit + b.credit := rfl

@[simp] theorem balance_zero : (0 : TAccount).balance = 0 := by
  simp [balance]

/-- `balance` is additive: it is the group homomorphism from the Pacioli group of
T-accounts into `ℚ`. -/
@[simp] theorem balance_add (a b : TAccount) :
    (a + b).balance = a.balance + b.balance := by
  simp only [balance, debit_add, credit_add]
  push_cast
  ring

end TAccount

end Pacioli
