# Pacioli

_An attempt to build accounting on two honest halves: verified mechanics and
curated judgment._

> **Status: charter.** This repository is being rebuilt from its foundations.
> It currently contains only this charter — the motivation and the thesis. No
> mechanics are implemented yet. They will be developed as small, rigorous,
> fully-proven increments, each worked through deliberately. Nothing below
> describes code that exists today; it describes what Pacioli is _for_ and the
> shape it intends to take.

Pacioli proposes to split accounting into two cleanly isolated layers:

- **The mechanics** — the deterministic, total parts of accounting, to be
  codified in _Lean 4_ so that illegal states are unrepresentable and the
  invariants that matter are machine-checked.
- **The judgment** — the contextual decisions (policy, jurisdiction, timing,
  materiality, classification), to be curated in the _Open Knowledge Format
  (OKF)_ so that humans and AI agents can share the same auditable reasoning.

The ambition: Lean guarantees that _given_ a set of accounting inputs the
mechanics are handled correctly; OKF guides the judgment about _what_ those
inputs should be.

---

## Why this split

Most attempts to formalize accounting fail because they try to prove judgment
calls. Revenue-recognition timing, impairment, fair-value estimates, and
GAAP-vs-IFRS classifications are not mathematical theorems — they are shifting
policies. Forcing these fluid rules into a strict type system creates brittle
code that secretly hardcodes compliance policy, and it rots the moment an
accounting standard changes.

So the seam is a single question, asked of every rule:

> **Can this be made total and mechanical?**

That question sorts each kind of accounting work onto one side of the seam:

|              | Yes → the mechanics (Lean)                                                                      | No → the judgment (OKF)                                                                                           |
| ------------ | ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Nature       | Total functions, algebraic invariants                                                           | Policy, _"it depends"_, context                                                                                   |
| Examples     | Double-entry balance, aggregation and rollup, period-close arithmetic, consolidation arithmetic | Revenue-recognition timing, depreciation-method choice, impairment triggers, materiality thresholds, GAAP vs IFRS |
| Guarantee    | Machine-checked proof; illegal states uninhabited                                               | Auditable, cited, human- and agent-readable reasoning                                                             |
| Changes when | The _mathematics_ changes (rarely)                                                              | A _standard or policy_ changes (often)                                                                            |

Some statements straddle the seam on purpose. The **accounting equation**
(`assets = liabilities + equity`) is the canonical one: it needs each account
_classified_ as an asset, liability, or equity — that classification is
judgment — and _then_ a mechanical theorem that the classified parts sum
correctly. It is not one side or the other; it is a judgment input plus a
mechanical proof, meeting at the seam.

---

## The interface contract (the crux)

The two halves are meant to meet at exactly one kind of handshake, and keeping
it clean is the whole design:

> A judgment (an OKF concept) produces **inputs** — plain data — and the Lean
> kernel consumes those inputs **deterministically** and guarantees the
> mechanics. The kernel neither knows nor cares _why_ the inputs are what they
> are.

Illustratively: a policy for how to recognize revenue over a contract is
judgment; from it a recognition _schedule_ is produced — just amounts and
periods; and the kernel's job is to prove the resulting postings satisfy the
mechanical properties it is responsible for (that they balance). The intent is
that this seam be real — a typed, checkable artifact — rather than a human
copying a number from a document into code.

The invariant that protects the seam: **policy never leaks into Lean types.** If
a Lean type could only be constructed by making a policy choice, that choice
belongs in OKF instead.

---

## Design principles

1. **Make illegal states unrepresentable first, prove second.** Use Lean's type
   system so that, e.g., an unbalanced transaction cannot even be _constructed_.
   This buys much of the safety for little proof effort.
2. **Reserve full proofs for load-bearing invariants.** A handful of theorems
   the rest rests on, not one proof per rule.
3. **Policy never leaks into types.** When in doubt, judgment goes to OKF,
   mechanics to Lean.
4. **Determinism at the boundary.** Everything Lean touches is a total function
   of explicit data inputs — no hidden policy, no I/O, no ambiguity.
5. **Rigour over speed.** Small, complete, well-explained increments. A proof
   that is partial is not finished; there are no deadlines.
6. **Everything is citable.** Lean invariants trace to their mathematical
   source; OKF concepts trace to the standard or literature that justifies them.

---

## Toolchain rationale

**[Lean 4](https://lean-lang.org/)** is the intended home for the mechanics: it
combines real dependent types, a growing and well-supported ecosystem (mathlib,
an active community), a genuine programming language that also proves theorems,
and compilation to a portable binary. The nearest serious alternative for
"verified software" alone is **F\*/Dafny** (SMT-backed refinement types, often
more ergonomic for pure verification), but part of Pacioli's value is being a
_citable formalization adjacent to mathematics_, where Lean's community gravity
and proof culture win.

**OKF** ([Google Cloud, 2026][okf-spec]) is the intended home for the judgment:
a vendor-neutral, git-shippable standard — a directory of markdown files with
YAML frontmatter, one concept per file — already structurally aligned with how
coding agents store curated memory. That alignment means the judgment half is
natively readable by the agents meant to consume it.

[okf-spec]: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md

---

## How this is meant to be used

Pacioli is built for **agent–human collaboration**. The intended loop:

- A **human brings an input** — an idea from accounting literature, a new
  standard, a policy question, a worked example.
- An **agent (or human) updates the repository** — deciding whether the input is
  _mechanical_ (a Lean invariant) or _judgment_ (an OKF concept), and making the
  change while keeping the halves and the interface between them clean.
- The **judgment half** then says _what_ the accounting inputs should be and
  _why_; the **mechanical half** guarantees that, given those inputs, the
  mechanics are correct — by construction and by proof.

The human supplies intent and judgment; the agent translates it into verified
mechanics and curated knowledge.

---

## Status & license

This repository is at its charter stage: the thesis above is settled, the
mechanics are being rebuilt from the ground up, and the design and proofs are
worked through deliberately rather than quickly.

Licensed under the **[Apache License 2.0](LICENSE)** — a permissive,
OSI-approved open-source license (the same one used by Lean core and mathlib),
which also carries an explicit patent grant. Free to use, modify, and
distribute, including commercially, under the terms of the license.
