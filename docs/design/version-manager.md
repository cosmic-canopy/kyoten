# The engine version manager

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **Developers can download and run multiple versions of the engine on one machine.**
- **Developers can download individual example projects to start from** (the owner, 2026-11-01). Each example is its
  own repository for exactly this reason ([examples.md](examples.md)): the FPS and the VR (Meta Quest) example first.

## What already exists

- **kama's own toolchain manager** (`kama/docs/packages.md` § toolchain), which kyoten's can learn from or ride on:
  - `kama toolchain list | install <v> | default <v> | pin <v> <kama.json> | uninstall <v>`, and `kama update
    [--version <v>]`. Versions install side by side under `~/.kama/versions/<v>/`; `~/.kama/bin/kama` is a selector
    that re-executes the right one.
  - **Resolution order:** a `"toolchain"` in `kama.local.json` (dev-local, gitignored), then the project's pin in
    `kama.json`, then `KAMA_VERSION` for one command, then the global default in `~/.kama/default`.
  - A version is spelled as its release tag (`v1.3.0`), and **a pin to a version that is not installed fails with a
    message naming the install command. It never silently falls back.**
  - Installed by `install.sh`/`install.ps1` from GitHub Releases (see [website.md](website.md) for how kama serves
    them).
- **The engine is a kama package**, so a game's `kama.json` already pins an engine version through its dependency
  range and `kama.lock`, and kama's store keeps several versions side by side. The-mallow-man pins its compiler the
  same way (`.kama-version` and a `.kama-pin/` snapshot, per [../research/peer-games.md](../research/peer-games.md)).
- **The pattern elsewhere:** Unity Hub (installs editor versions; each project records the one it was made with),
  Godot's per-version downloads, rustup's toolchains and per-directory overrides.

## The questions

1. **What is "a version of the engine"?** The `kyoten` package source (resolved by kama), plus the tools (the editor
   and dev server, a `kyoten` CLI), plus the kama compiler that version needs (its `kama` range), plus project
   templates and docs. Are they one versioned bundle?
2. **Ride on kama's manager or have its own?** A kyoten version could simply pin `"toolchain"` and `"kama"`, with the
   engine as a registry dependency, so kama's existing manager does the work. Or kyoten gets its own `kyoten versions
   install/use/pin`, as a hub over both. Which is the one way?
3. **What does a project record?** The engine version a game is built with, in its `kama.json`, so opening an old
   project selects its engine without asking, and a missing version fails with the install command, as kama's does.
4. **CLI, GUI, or both?** A hub that lists installed engine versions and projects (as Unity Hub does) belongs with the
   tool surface ([human-tools.md](human-tools.md)): a web UI served locally?
5. **Where do the builds come from?** GitHub Releases, as kama's do, or `dl.kyotenengine.com` on the kyoten platform
   ([website.md](website.md), [marketplace.md](marketplace.md))? Signed (the question kama's KR-135 records)?
6. **Channels.** Stable, beta and nightly, and how a project opts into one.
7. **Upgrading a project.** Moving a game from one engine version to the next: migrations of project-database records
   ([project-database.md](project-database.md)), a changelog an agent can read, and a dry run.
8. **Engine developers.** Someone working on kyoten itself runs a local checkout as one of the "versions", as kama's
   dev build coexists with installed ones.
9. **Starting from an example.** The manager lists the examples (each its own repository) and creates a new project
   from one: a copy, not a clone that tracks the example's history? Pinned to an engine version the example is known to
   build with? An example today depends on the engine by path, which works only inside a kyoten checkout; a standalone
   copy needs a published engine version, or the manager rewrites the dependency
   ([architecture.md](architecture.md), question 8).

## Decided

*(nothing yet — filled in during the walk-through)*
