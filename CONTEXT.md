# Glossary

The shared vocabulary for hull. Keep it current; a term that drifts is a bug.
This is a glossary only — no implementation detail. Decisions live in
`docs/adr/`; the shape lives in `ARCHITECTURE.md`.

| Term | Meaning |
| --- | --- |
| **Captain** | the user (alex). Sets intent; drives the terminal for experiential / destructive steps. |
| **hull** | *this repo* — the reproducible NixOS environment ("the ship's body") you work inside: shell, editor, terminal, tools, agent config. A flake producing `nixosConfigurations` for each host type. |
| **registry** | a *separate private repo* holding **identity** data (name, GitHub accounts, per-host usernames). A flake input to hull. hull holds none of this. |
| **Opinions** | inherited, fixed configuration — the Kun-derived house style. Impersonal. Lives in hull. |
| **Identity** | personal data: name, accounts, SSH keys, per-host login. Injected via the registry. Never in hull. |
| **Host type** | a serviced kind of machine: `wsl` (NixOS-WSL under Windows) or `native` (NixOS on bare metal — laptop, desktop, or any hardware). hull is *aware of host type*, not of who you are. |
| **Panel** | a sealed concern, expressed as a module: a pure **Generator** + optional **Lifecycle tool**, mounted onto hull via an **Adapter**. Lives in this repo; gets its own repo only when a real second consumer exists (ADR 0003). |
| **Generator** | a **pure function**: data → config file contents. No side effects, no I/O. E.g. `accounts → gitconfig + ssh config`. Shared by the module adapter and the CLI. |
| **Adapter** | thin, per-platform glue that mounts a Generator's output — e.g. a Home Manager module wiring it into `programs.git` / `programs.ssh`. |
| **Lifecycle tool** | imperative action Nix must not do (mint SSH keys, upload to GitHub). Lives in the CLI. |
| **hull-fedora / v1** | the frozen previous implementation (Fedora + Home Manager, imperative bash) at `~/burnish-studio/hull-fedora`. Reference only, never edited. |

**Metaphor:** the whole system is modelled as a starship and its crew (captain,
hull, bridge, firstmate, crew, ship's computer, planets…). hull is one layer —
the body. The fuller metaphor map lives in `hull-fedora/ARCHITECTURE.md` §1–7 as
background reference (not gospel); only the terms hull needs are above.
