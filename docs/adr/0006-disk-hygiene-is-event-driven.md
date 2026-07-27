# 6. Disk hygiene is event-driven, not pressure-driven

- Status: Accepted
- Date: 2026-07-27
- Deciders: alex (captain)

## Context

WSL provisions the guest a **dynamically-expanding virtual disk with a very large
maximum**. Measured on this machine (2026-07-27):

```
/dev/sde  1007G  8.0G  948G  1% /        # inside NixOS
ext4.vhdx 9.04 GB                        # the actual file on Windows
C: drive  474 GB total                   # what physically exists
```

The guest reports **948 GB free on a 474 GB disk**. That figure is not merely
unhelpful, it is fiction — roughly twice the physical capacity. Three consequences
follow:

1. Nix's built-in automatic garbage collection is **pressure-driven**
   (`min-free` / `max-free`: collect when free space runs low). On WSL it can never
   fire, because the guest never runs low.
2. Nothing inside the guest will ever warn about growth.
3. A WSL virtual disk **grows but never shrinks**. Space freed inside NixOS is not
   returned to Windows, so the *peak* store size is what permanently costs disk.
   Cleaning up after the fact does not undo a peak that already happened.

Together: the machine will balloon silently and the standard mechanisms are inert.
This is a **host-type-specific** property — on the `native` host, with a real disk,
pressure-driven collection works correctly.

## Decision

**On WSL, bound the store by tying hygiene to the event that grows it — the
rebuild — never to a schedule or a disk-pressure threshold.** Three layers:

1. **Cap generations during activation.** `system.activationScripts` runs on every
   `nixos-rebuild switch` regardless of how it was invoked, so the ceiling cannot
   be bypassed by rebuilding directly instead of through the CLI. Deleting old
   generation symlinks is instant, so it costs nothing per rebuild. **Keep 3:**
   current, previous, and one spare last-known-good. Made failure-tolerant so it
   can never fail a rebuild.
2. **Continuous deduplication.** `nix.settings.auto-optimise-store = true`
   hardlinks identical files as they enter the store — no trigger, no schedule.
   Well matched here because generations share most of their content.
3. **Reclaim and report in the CLI** (Phase 4). `hull switch` collects garbage
   after switching; `hull update` collects after `nix flake update`, the single
   largest growth event (a new nixpkgs revision is ~468 MB plus everything rebuilt
   against it); `hull doctor` reports store size and generation count and states
   plainly that the guest's free-space figure is meaningless on WSL.

Capping is the **precondition** for the other two: garbage collection can only
reclaim what no surviving generation pins, so an uncapped profile makes collection
ineffective no matter how often it runs.

Per ADR 0002, this variation lives at the **host layer** (`hosts/wsl.nix`), not
inside the concern modules.

## Consequences

- The store has a real ceiling, enforced automatically, without a background
  service or a threshold that will never trip.
- Losing old generations costs **time, not recoverability** — hull is in git, so
  any past system can be rebuilt from any commit. Generations only buy *instant*
  rollback. This is what makes a cap as low as 3 safe.
- `hull doctor` must actively contradict `df`. Reporting the guest's free space
  without comment would be reporting a falsehood.
- The virtual disk size is **not readable from inside the guest**, and hull never
  touches Windows (see HANDOVER boundaries). So doctor can report the store but
  must point at Windows for the disk itself; one-off compaction stays a manual
  Windows checklist item.
- `hosts/native.nix` should **not** inherit this. On a real disk, pressure-driven
  `min-free`/`max-free` is the better mechanism and this machinery is unnecessary.

## Alternatives

- **A scheduled timer (weekly GC).** Rejected. It bounds the *average*, not the
  *peak*, and on WSL only the peak has lasting cost. Six rebuilds between runs
  means six generations regardless of the cap. The trigger must be the rebuild,
  because rebuilds are the only thing that creates generations.
- **Pressure-driven `min-free` / `max-free`.** Rejected on WSL — it can never
  fire against a 948 GB apparent free figure. Correct for `native`.
- **Nothing now; clean up when it hurts.** Rejected. By the time the Windows disk
  hurts, the peak has already been paid and only manual compaction recovers it.
  Prevention is strictly cheaper than cure here.
- **Cap at 1 or 2 generations.** Rejected as too tight: a bad config can survive
  more than one rebuild before being noticed, and the third generation is nearly
  free given content sharing.
