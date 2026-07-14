# Contributing to Pacioli

Thanks for your interest in Pacioli. This guide covers **how the repository is
meant to grow** and the **mechanics of contributing** to it. For _why_ Pacioli
is split the way it is, read the [README](README.md) first; for _how the pieces
fit together_ — the type stack, the `balance` homomorphism, the fundamental
invariant, and the OKF → kernel handshake — see
[docs/architecture.md](docs/architecture.md). This document assumes both.

Pacioli values **correctness, comprehensibility, and robust discussion** over
speed. There are no deadlines. A change that is small, well-explained, and
verified is always preferred to a large one that is none of those.

---

## The one decision every change turns on

Pacioli splits accounting on a single question:

> **Can this be made total and mechanical?**

Every contribution resolves to one side of that seam, **never both at once**:

- **Yes → the mechanics.** Total functions and algebraic invariants — double
  entry, the accounting equation, aggregation, close, consolidation. These are
  codified and _proven_ in **Lean 4** under [`Pacioli/`](Pacioli/).
- **No → the judgment.** Policy, timing, materiality, classification,
  GAAP-vs-IFRS — anything that is "it depends." These are curated as cited,
  human- and agent-readable reasoning in the **OKF bundle**
  under [`okf/`](okf/).

The two halves meet at exactly one handshake: **an OKF concept encodes a
judgment → the judgment produces plain data → the Lean kernel consumes that data
deterministically and proves the mechanics.** The invariant that protects the
seam is **policy never leaks into Lean types**: if a Lean type could only be
built by making a policy choice, that choice belongs in OKF instead.

If you are unsure which side a change belongs on, **open an issue and discuss it
before writing code.** Getting the seam right matters more than the change.

---

## The agent–human loop

Pacioli is built for **agent–human collaboration**:

- A **human brings an input** — an idea from accounting literature, a new
  standard, a policy question, a worked example.
- An **agent (or human) updates the repository** — deciding whether the input is
  _mechanical_ (a Lean invariant in `Pacioli/`) or _judgment_ (an OKF concept in
  `okf/`), never both, and making the change while keeping the halves and the
  interface between them clean.

Humans can edit `Pacioli/` and `okf/` directly; the loop is the intended shape,
not a restriction.

---

## Development setup

The toolchain is managed by a **Nix flake**, so a dev shell gives you the pinned
Lean, Lake, and all lint tools — no global installs.

```sh
nix develop          # enter the dev shell (Lean + Lake + lint tools)
```

Entering the shell **installs the git hooks** (via `git-hooks.nix`).

**With direnv** (recommended), the shell loads automatically on `cd`. The repo
tracks a shared `.envrc.shared`; each clone needs a thin, untracked local
`.envrc` that sources it:

```sh
printf 'source_env .envrc.shared\n' > .envrc
direnv allow
```

Build the kernel (this recompiles Lean, which re-checks every proof):

```sh
lake exe cache get   # fetch mathlib's prebuilt oleans (do this first)
lake build           # build the default target (Pacioli)
lake build Examples  # also build the boundary examples
```

---

## What the checks enforce

The same checks run **locally and in CI** — `nix flake check` is the single
source of truth.

- **On commit** (fast hooks): `nixfmt`, `deadnix`, `statix` for Nix;
  `markdownlint` for docs; whitespace/EOF/merge-conflict hygiene; and
  **`no-sorry`**, which fails if any `.lean` file contains `sorry` or `admit`.
  **Proofs must be complete** — an incomplete proof is not a contribution.
- **On push** (slower): the full `lake build`, so a broken proof is caught
  before it leaves your machine.
- **In CI** (every PR, and `main`): two required jobs —
  - **`nix flake check`** — the fast hooks above.
  - **`lake build`** — the full Lean compile of both `Pacioli` and `Examples`.

Both CI jobs are **required status checks** on `main`: a red build — a failing
proof, a stray `sorry`, or a lint error — blocks the merge.

### Repository settings as code

This repo governs its own merge policy — the required checks, owner review,
conversation resolution, and merge queue — as a version-controlled **GitHub
ruleset** in [`.github/rulesets/main.json`](.github/rulesets/main.json).
Maintainers reconcile it with [`scripts/settings.sh`](scripts/settings.sh)
(`--check` to diff live vs. committed, `--apply` to push it). Org-wide rules
are managed separately in tofu; these two layers compose. Merging a maintainer's
own PR (which can't be self-approved) uses
[`scripts/merge.sh`](scripts/merge.sh) `<PR#>` — a ruleset-bypass squash-merge
that `gh pr merge` cannot do.

### House style

- **Markdown** wraps prose at **80 columns** (`MD013`); tables and code/Mermaid
  blocks are exempt. Table pipes must be aligned (`MD060`) — `prettier` does this.
- **Lean** follows **mathlib naming**: types/structures/classes/namespaces and
  predicates in `UpperCamelCase`; data definitions and functions in
  `lowerCamelCase`; theorems in `snake_case` naming the conclusion; proof fields
  in `snake_case`, data fields in `lowerCamelCase`. Per-definition documentation
  lives in Lean docstrings.
- **New `.lean` files** carry the Apache header block (see any existing source).

---

## Contributing a change

Everything lands through a **pull request** — no direct commits to `main`.

1. **Branch** off `main`.
2. Make the change on **one side of the seam only** (mechanics _or_ judgment).
3. Keep it **small and well-explained**; the commit message and PR should say
   _why_, not just _what_.
4. Ensure `nix develop` + `lake build` is green locally.
5. **Open a PR.** For it to become mergeable:
   - both CI checks — **`nix flake check`** and **`lake build`** — pass;
   - the repository owner (**@ojhermann**) has **approved** — they are requested
     as a reviewer automatically (via [`CODEOWNERS`](.github/CODEOWNERS)), so you
     needn't add them by hand;
   - **every review conversation is resolved.**
6. **Only the owner merges.** Approved, green PRs go through a **merge queue**:
   the PR is re-tested against the latest `main` before it lands, so a merge can
   never break `main`. Merges are **squash → delete branch**, keeping history
   linear.

---

## Authoring an OKF concept

Each concept is one Markdown file in [`okf/concepts/`](okf/concepts/) with YAML
frontmatter, following the [Open Knowledge Format][okf-spec]. Use the existing
[straight-line depreciation](okf/concepts/straight-line-depreciation.md) concept
as the template. The shape:

```markdown
---
type: concept
title: <concept name>
description: <one sentence — what it produces and why>
tags:
  - <topic>
---

# <concept name>

## Judgment
Why this is "it depends": the policy choices, estimates, and applicable
standards that make it judgment rather than mechanics. Cite the standard.

## The rule
The arithmetic, once the judgment is fixed — deterministic and mechanical.

## Output handed to the kernel
The plain **data** the concept produces (an amount, a schedule, a
classification) that `Pacioli/` then consumes and verifies.
```

Then add the concept to the list in [`okf/index.md`](okf/index.md), and, where
it crosses into the kernel, cross-link the relevant part of
[docs/architecture.md](docs/architecture.md).

A good concept is **cited** (traces to a standard or the literature) and stops
at the seam: it explains and produces data, but never encodes mechanics.

[okf-spec]: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md

---

## Questions and discussion

Open a [GitHub issue](https://github.com/ojhermann-org/pacioli/issues) — for a
bug, a concept proposal, a kernel idea, or a "which side of the seam does this
belong on?" discussion. Robust discussion is welcome and is how the seam stays
clean.
