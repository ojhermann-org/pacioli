# Pacioli

_A verified core of accounting mechanics, paired with curated accounting judgment._

This repository splits accounting into two cleanly isolated layers:

- **The mechanics**: deterministic mechanics are codified in _Lean 4_ so illegal states are mathematically unrepresentable and invariants are proven.
- **The Judgment**: Contextual decisions (policy, jurisdiction, timing, materiality, and classification) are captured in the _Open Knowledge Format (OKF)_, allowing humans and AI agents to share the same auditable reasoning.

_Lean guarantees that any given accounting inputs
are handled correctly; OKF guides the judgment about what those inputs should
be._

---

## Why this split

Most attempts to "formalize accounting" stall because they try to _prove the
judgment calls_. Revenue-recognition timing, impairment, fair-value estimates,
GAAP-vs-IFRS classification — these are not theorems. They are policies that
vary by jurisdiction and change over time. Forcing them into a type system
produces brittle types that secretly encode policy and rot the moment a standard
changes.

So the seam we cut on is a single question: **can this be made total and mechanical?**

|              | Belongs in **Lean** (mechanics)                                                                           | Belongs in **OKF** (judgment)                                                                                     |
| ------------ | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Nature       | Total functions, algebraic invariants                                                                     | Policy, "it depends", context                                                                                     |
| Examples     | Double-entry balance, the accounting equation, aggregation/rollup, period close arithmetic, consolidation | Revenue recognition timing, depreciation policy choice, impairment triggers, materiality thresholds, GAAP vs IFRS |
| Guarantee    | Machine-checked proof / uninhabited illegal states                                                        | Auditable, cited, human- and agent-readable reasoning                                                             |
| Changes when | The _mathematics_ changes (rarely)                                                                        | A _standard or policy_ changes (often)                                                                            |

---

## The interface contract (the crux)

The halves meet at exactly one handshake, and keeping it clean is the whole
design:

> An OKF concept encodes a **judgment** → the judgment produces **inputs**
> → the Lean kernel
> consumes those inputs **deterministically** and guarantees the mechanics.

Worked example (SaaS revenue):

1. An OKF concept states: _"For SaaS contracts, recognize ratably over the
   service period per ASC 606."_ — this is the **judgment**, auditable in OKF.
2. From it, a **recognition schedule** is produced — just data: amounts and
   periods.
3. The Lean kernel takes the schedule and proves the resulting postings
   **balance** and **sum to the contract value**. It neither knows nor cares
   _why_ the schedule looks the way it does.

The invariant that protects this: **policy never leaks into Lean types.** If a
Lean type can only be constructed by making a policy choice, that choice belongs
in OKF instead. The kernel is deliberately ignorant of _why_; it is expert in
_that the mechanics are sound_.

---

## Mathematical foundation

The Lean kernel is built on [David Ellerman](https://www.ellerman.org/?s=accounting)'s
group-theoretic formulation of double-entry bookkeeping rather than an ad-hoc
algebra of our own.

Double-entry implicitly uses the **group of differences** — the "**Pacioli
group**" — constructed from ordered pairs of non-negative numbers. A **T-account
is exactly such an ordered pair** `(debit, credit)`, and equality in the group is
the equivalence `(d, c) ≡ (d', c') ⟺ d + c' = d' + c`.

This gives us a rigorous, citable base where:

- a **T-account** is a group element,
- a **balanced transaction** is a tuple of elements summing to the group
  identity,
- **posting** is the group operation, and the balance invariant is a _theorem_
  about it, not a runtime check.

Reference: David Ellerman, _On Double-Entry Bookkeeping: The Mathematical
Treatment_, [arXiv:1407.1898](https://arxiv.org/abs/1407.1898) (see also
Ellerman 1982).

---

## Design principles

1. **Make illegal states unrepresentable first, prove second.** Use Lean's type
   system so that an unbalanced transaction cannot even be _constructed_. This
   buys most of the safety for little proof effort.
2. **Reserve full proofs for kernel invariants.** A handful of load-bearing
   theorems (posting preserves the accounting equation; close is
   sum-preserving), not one proof per rule. Avoid the proof-burden trap.
3. **Policy never leaks into types.** When in
   doubt, judgment goes to OKF, mechanics to Lean.
4. **Determinism at the boundary.** Everything Lean touches is a total function
   of explicit data inputs. No hidden policy, no I/O, no ambiguity.
5. **Everything is citable.** Lean invariants trace to their mathematical source;
   OKF concepts trace to the standard or literature that justifies them.

---

## Toolchain rationale

**[Lean 4](https://lean-lang.org/)** was chosen over other dependently typed / verification languages
because it uniquely combines: real dependent types, a growing and well-supported
ecosystem (mathlib, active community), a genuine programming language that also
proves theorems, and compilation to a portable binary. The nearest serious
alternative for "verified software" alone is **F\*/Dafny** (SMT-backed refinement
types, often more ergonomic for pure verification), but this project's value
includes being a _citable formalization adjacent to mathematics_, where Lean's
community gravity and proof culture win.

**OKF** ([Google Cloud, June 2026](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)) was chosen because it is a vendor-neutral,
git-shippable standard — a directory of markdown files with YAML frontmatter, one
concept per file — that is already structurally aligned with how coding agents
store curated memory. That alignment means the judgment half is natively
readable by the agents that will consume it.

---

## Repository layout (proposed)

```
.
├── README.md            # this charter
├── LICENSE              # Apache-2.0
├── flake.nix            # Nix-managed toolchain (Lean + Lake)
├── lean-toolchain       # pinned Lean version
├── lakefile.toml        # Lake package manifest
├── lake-manifest.json   # dependency lock — Reservoir requires this at the repo root
├── Pacioli.lean         # library root (imports the modules below)
├── Pacioli/             # kernel: Pacioli group, T-accounts, postings, invariants
├── okf/                 # curated accounting judgment (OKF bundle)
│   ├── index.md          # progressive-disclosure entry point
│   └── concepts/         # one file per concept (policies, standards, playbooks)
└── examples/            # worked slices crossing the boundary end-to-end
```

The Lean package sits at the repository **root** (not under a `lean/`
subdirectory) so that `lake-manifest.json` lands at the top level, which
[Reservoir](https://reservoir.lean-lang.org/) requires for indexing.

_(Layout is provisional and will settle as the first vertical slice lands.)_

---

## How this is meant to be used

This repository is built for **agent–human collaboration**. The expected loop:

- A **human brings an input** — an idea from accounting literature, a new
  standard, a policy question, a worked example.
- An **agent is responsible for updating the repository** — deciding whether the
  input is _mechanical_ (a new Lean invariant in `Pacioli/`) or _judgment_ (a new
  OKF concept in `okf/`), never both, and making that change while keeping the
  two halves and the interface between them clean.
- The **OKF bundle** then tells humans and agents _what_ the accounting inputs
  should be and _why_; the **Lean kernel** guarantees that, given those inputs,
  the mechanics are correct — by construction and by proof.

Humans can, of course, edit `Pacioli/` and `okf/` directly. But the repository is
designed around the agent–human loop: the human supplies intent and judgment,
and the agent translates it into verified mechanics and curated knowledge.

---

## Status & license

Licensed under the **[Apache License 2.0](LICENSE)** — a permissive,
OSI-approved open-source license (the same license used by Lean core and
mathlib), which also carries an explicit patent grant. Free to use, modify, and
distribute, including commercially, under the terms of the license. The same
license applies to the whole repository, both the Lean kernel (`lean/`) and the
OKF knowledge bundle (`okf/`).
