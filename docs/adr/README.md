# Architecture Decision Records

Each meaningful, hard-to-reverse decision is one file: `NNNN-kebab-title.md`,
numbered from `0001` and **never renumbered**. A decision is worth an ADR only
when it is hard to reverse, surprising without context, and the result of a real
trade-off — otherwise skip it.

**Status:** `Proposed` → `Accepted` → `Superseded`. To change a past decision,
write a *new* ADR that references the old one and set the old one's status to
`Superseded by NNNN`. Never rewrite history in place.

This is a greenfield log. It deliberately does **not** continue v1's decision
log (`../../../hull-fedora/.plan/DECISIONS.md`, the `D1..` series) — that is
frozen reference for a different (Fedora + Home Manager) design.

## Format

```
# N. Title

- Status: Accepted
- Date: YYYY-MM-DD
- Deciders: <who>

## Context      what forces the decision; the problem
## Decision     what we chose, stated plainly
## Consequences what follows — good and bad
## Alternatives what else was on the table, and why not
```
