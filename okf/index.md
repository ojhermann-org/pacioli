---
type: index
title: Pacioli OKF bundle
description: Curated accounting judgment that guides the inputs the Lean kernel verifies.
---

# Pacioli knowledge bundle

This is the *judgment* half of Pacioli, expressed in the
[Open Knowledge Format][okf-spec]. Each concept captures accounting reasoning
that is inherently "it depends" — policy, timing, classification — and cannot
(or should not) be frozen into the Lean kernel's types.

A concept's job is to explain *what* the accounting inputs should be and *why*,
and to produce **data** (an amount, a schedule, a classification) that the
verified kernel in `Pacioli/` then consumes deterministically. Policy lives here;
mechanics live in Lean; neither leaks into the other.

## Concepts

- [Straight-line depreciation](concepts/straight-line-depreciation.md) — spread
  a depreciable asset's cost evenly over its useful life.

[okf-spec]: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
