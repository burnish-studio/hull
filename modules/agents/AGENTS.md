# Global agent instructions

These apply to **every** project, not just hull. One file, linked to each agent
tool's global instructions path - see `modules/agents/default.nix`.

Project-specific rules belong in that project's own `AGENTS.md` or `CLAUDE.md`,
not here. Both Claude Code and pi read the project file in addition to this one.

## Writing

- Never use the em dash "—". Use a plain dash "-" instead.
- Write acronyms out in full where a full version exists: "garbage collection",
  not "GC"; "Home Manager", not "HM". The reader should not have to guess at an
  abbreviation to follow an explanation.

## Git

- Never auto-add an agent name as a commit co-author.
- Never hand-edit auto-generated files - changelogs, lockfiles, anything marked
  generated.

## Technical judgement

- Do not weight development cost heavily. Prefer quality, simplicity,
  robustness and long-term maintainability.
- For one-off or infrequent operational work, take the simplest direct
  end-to-end path. Do not build wrappers, control planes, policy layers or
  automation until the direct path exposes a concrete blocker or a repeated
  need that justifies the machinery.
- Verify, do not assert. Check the machine, then write down what you found.
  A claim that was never checked is worth less than no claim at all.

## Bugs and quality

- When fixing a bug, reproduce it end-to-end as the user experiences it first.
  That is how you find the real problem, so the fix actually solves it.
- Fix lint failures, test failures and flakiness you encounter, even when they
  are unrelated to the task in hand.
- When testing a user interface, be picky about what you see. If something
  clearly looks wrong, get it fixed along the way even if it is not yours.

## Scale

- Explain the tradeoffs and get explicit approval before spawning a large swarm
  of subagents, or before using any harness feature that does so.

---

Adopted 2026-07-28 from Kun Chen's dotfiles as a working default, explicitly
"not gospel today forever". It is expected to change, which is why it lives in a
diffable file rather than anywhere invisible.

The em dash in the first rule is the one place the character legitimately
survives, because the rule quotes it as its own subject.
