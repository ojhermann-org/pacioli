-- This module is the root of the `Pacioli` library: it re-exports the modules
-- that make up the verified mechanics. Add an `import Pacioli.Foo` line here
-- for each new module so that a bare `lake build` compiles the whole library.
--
-- The modules, in dependency order (each depends only on those above it):
--   Entry          — EntryType, Entry, and the abstract value contract
--   Aggregation    — per-currency/direction totals and their homomorphism lemmas
--   Transaction    — the bundled per-currency balance invariant
--   Classification — asset/claim taxonomy and the accounting equation
--   Examples       — a worked instantiation over concrete types (a smoke test)
import Pacioli.Entry
import Pacioli.Aggregation
import Pacioli.Transaction
import Pacioli.Classification
import Pacioli.Examples
