---
type: concept
title: Straight-line depreciation
description: Spread a depreciable asset's cost evenly over its useful life, producing a per-period expense schedule.
tags:
  - depreciation
  - ppe
  - expense-recognition
---

# Straight-line depreciation

## Judgment

Straight-line depreciation allocates the **depreciable base** of a long-lived
asset evenly across the periods of its **useful life**. Choosing to use it — and
choosing the inputs below — is a matter of judgment and policy (management
estimates, applicable standard, asset class), which is why it lives here in OKF
rather than in the Lean kernel.

The inputs, each an estimate or policy choice:

- **Cost** — the capitalised cost of the asset.
- **Residual (salvage) value** — expected recoverable amount at end of life.
- **Useful life** — number of periods the asset is expected to be used.

## The rule

```
depreciable base   = cost − residual value
expense per period = depreciable base ÷ useful life
```

Under both US GAAP (ASC 360) and IFRS (IAS 16), depreciation begins when the
asset is available for use and continues over its useful life; the *method* and
*estimates* are judgment, but once fixed the arithmetic is mechanical.

## Output handed to the kernel

This concept produces a **schedule**: a per-period `expense` amount (plain data).
It does not post anything itself. The verified kernel takes each period's expense
and records the postings —

- **debit** Depreciation Expense
- **credit** Accumulated Depreciation

— and *guarantees* they balance. See `examples/Examples.lean`
(`depreciationEntries` / `depreciationTxn`), where this handshake is checked end
to end: the judgment picks `expense`; `Ledger.totalBalance_post` proves the books
stay balanced regardless of the value chosen.

## Notes and edge cases (judgment, not mechanics)

- Changes in estimate (useful life, residual) are applied prospectively, not
  restated — a policy rule, not an arithmetic one.
- Partial first/last periods, impairment, and componentisation each change the
  *schedule* that is produced, never the kernel's balancing guarantee.
