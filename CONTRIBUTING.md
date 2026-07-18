# Contributing to Pacioli

Thanks for your interest in Pacioli. This guide covers **how the repository is
meant to grow** and the **mechanics of contributing** to it. For _why_ Pacioli
is split the way it is, read the [README](README.md) first.

Pacioli has begun landing its **first mechanics**: the thesis is settled and the
mechanics are built from the ground up as small, deliberate increments. This
guide describes the collaboration model and workflow; the Lean- and OKF-specific
conventions return to it alongside the code they govern (the first are under
"Development conventions" below).

Pacioli values **correctness, comprehensibility, and robust discussion** over
speed. There are no deadlines. A change that is small, well-explained, and
verified is always preferred to a large one that is none of those.

---

## The one decision every change turns on

Pacioli splits accounting on a single question:

> **Can this be made total and mechanical?**

Every contribution resolves to one side of that seam:

- **Yes → the mechanics.** Total functions and algebraic invariants — double
  entry, aggregation, close, consolidation. These belong in **Lean 4**, codified
  and proven.
- **No → the judgment.** Policy, timing, materiality, classification,
  GAAP-vs-IFRS — anything that is "it depends." These are curated as cited,
  human- and agent-readable reasoning in the **OKF bundle**.

Some statements straddle the seam and arrive as _both_: a judgment input plus a
mechanical theorem (the accounting equation is the canonical example — see the
README). The invariant that protects the seam is **policy never leaks into Lean
types**: if a Lean type could only be built by making a policy choice, that
choice belongs in the judgment half instead.

If you are unsure which side a change belongs on, **open an issue and discuss it
first.** Getting the seam right matters more than the change.

---

## The agent–human loop

Pacioli is built for **agent–human collaboration**:

- A **human brings an input** — an idea from accounting literature, a new
  standard, a policy question, a worked example.
- An **agent (or human) updates the repository** — deciding whether the input is
  _mechanical_ or _judgment_, and making the change while keeping the halves and
  the interface between them clean.

The loop is the intended shape, not a restriction; humans can edit directly.

---

## Development setup

The toolchain is managed by a **Nix flake**, so a dev shell gives you the pinned
lint tools — no global installs.

```sh
nix develop          # enter the dev shell (lint + hygiene tools)
```

Entering the shell **installs the git hooks** (via `git-hooks.nix`).

**With direnv** (recommended), the shell loads automatically on `cd`. The repo
tracks a shared `.envrc.shared`; each clone needs a thin, untracked local
`.envrc` that sources it:

```sh
printf 'source_env .envrc.shared\n' > .envrc
direnv allow
```

---

## What the checks enforce

The same checks run **locally and in CI** — `nix flake check` is the single
source of truth.

- **On commit** (fast hooks): `nixfmt`, `deadnix`, `statix` for Nix;
  `markdownlint` for docs; and whitespace/EOF/merge-conflict/YAML hygiene.
- **In CI** (every PR, and `main`): one required job — **`nix flake check`** —
  running exactly those hooks. A red run blocks the merge.

The mechanics have begun to land, so the Lean proof gates — a `no-sorry`/axiom
guard and the full `lake build` compile — are being added as required checks
(tracked in issue #37); until then, [`scripts/lean-check.sh`](scripts/lean-check.sh)
runs them locally.

### Repository settings as code

This repo governs its own merge policy — the required checks, owner review,
conversation resolution, and merge queue — as a version-controlled **GitHub
ruleset** in [`.github/rulesets/main.json`](.github/rulesets/main.json).
Maintainers reconcile it with [`scripts/settings.sh`](scripts/settings.sh)
(`--check` to diff live vs. committed, `--apply` to push it). Org-wide rules are
managed separately in tofu; these two layers compose. Merging a maintainer's own
PR (which can't be self-approved) uses [`scripts/merge.sh`](scripts/merge.sh)
`<PR#>` — a ruleset-bypass squash-merge that `gh pr merge` cannot do.

### House style

- **Markdown** wraps prose at **80 columns** (`MD013`); tables and code/Mermaid
  blocks are exempt. Table pipes must be aligned (`MD060`) — `prettier` does
  this.

### Development conventions

Two standing practices, adopted with the first mechanics:

- **Cite load-bearing invariants.** A Lean invariant traces to its mathematical
  or accounting source (README design principle 6) — put the citation in the
  declaration's docstring when it lands, not later.
- **Keep documentation in step with the code.** Update the affected docs
  (README status, this guide, module/declaration docstrings) in the _same_
  change as the code, so the docs never claim something the code has outgrown.

---

## Contributing a change

Everything lands through a **pull request** — no direct commits to `main`.

1. **Branch** off `main`.
2. Make the change on **one side of the seam** where it applies (mechanics _or_
   judgment).
3. Keep it **small and well-explained**; the commit message and PR should say
   _why_, not just _what_.
4. Ensure `nix flake check` is green locally.
5. **Open a PR.** For it to become mergeable:
   - the required check — **`nix flake check`** — passes;
   - the repository owner (**@ojhermann**) has **approved** — they are
     requested as a reviewer automatically (via
     [`CODEOWNERS`](.github/CODEOWNERS)), so you needn't add them by hand;
   - **every review conversation is resolved.**
6. **Only the owner merges.** Approved, green PRs go through a **merge queue**:
   the PR is re-tested against the latest `main` before it lands, so a merge can
   never break `main`. Merges are **squash → delete branch**, keeping history
   linear.

---

## Questions and discussion

Open a [GitHub issue](https://github.com/ojhermann-org/pacioli/issues) — for a
concept proposal, a kernel idea, or a "which side of the seam does this belong
on?" discussion. Robust discussion is welcome and is how the seam stays clean.
