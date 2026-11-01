# Architecture: the engine, the games, the repository

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **The engine is the driver for games and is never hard-coded to one.** It offers clean patterns each game project
  uses.
- **General purpose, component-based, web first with native at parity**, easy for AI from day one, visible and
  tunable by humans.
- **A monorepo**, with a test game that consumes the engine.
- **A developer platform** to build, deploy and sell games and content, and a hosted networking backend
  ([marketplace.md](marketplace.md), [networking.md](networking.md)).

## What exists now

- `kama_workspace.json` with one member, `engine/` (package `kyoten`, one placeholder module). The example games are
  separate repositories, one per game, each cloned as `games/<name>` (see *Decided*): `kyoten-fps` and `kyoten-vr` so
  far. Each depends on the engine by path; `kama run games/fps/kama.json` prints `fps example, on kyoten`.
- **The peers' lessons on engine abstraction** ([../research/peer-games.md](../research/peer-games.md) § 7):
  - "An engine abstraction must pay for itself on the game." FFD: "not an ECS, not a job system, not a scheduler
    abstraction, and not a plugin architecture… until a measurement asks otherwise". TMM: "Engine work never runs ahead
    of what a milestone needs."
  - Code moved between games by copy until it became published packages that "never name these games".
  - Both games began from a playable JS prototype.
- **What kama gives and lacks** ([../research/kama-for-engines.md](../research/kama-for-engines.md)): the platform
  packages (`@kama/gpu`, `@kama/window`, `@kama/http`) are designed, not built; `@kama/ui` exists; the job pool is not
  built; packages are published to `registry.kama-lang.org`.

kyoten's position differs from the peers' on purpose: it *is* the general engine they each declined to build early.
The tension between their lesson and that purpose is the first thing to settle.

## The questions

1. **How general, how soon?** The peers' rule is "no abstraction before a game needs it". kyoten's purpose is the
   abstraction. Does each engine feature arrive driven by the examples, an FPS and a VR game ([examples.md](examples.md)),
   so it still pays for itself on a real game, and on two different ones?
2. **The package split.** One `kyoten` package, or several (core/frame, components, platform, render, audio, net,
   database, tools), each a workspace member? What may depend on what, and which parts are useful outside kyoten
   (published to the registry, as `@kama/ui` was)?
3. **kama's platform packages.** Build kyoten's platform layer on `@kama/gpu` and `@kama/window`, build those packages
   (in kama's design) as part of kyoten's work, or keep kyoten's own layer as the peers did?
   - **Extensible to N platforms.** The owner requires that a platform (web, desktop, Steam Deck, consoles under NDA, XR)
     is added without changing the engine for the others, which points to platforms, and features such as XR, as
     packages implementing engine interfaces, some of them private ([target-platforms.md](target-platforms.md)). The
     package split in question 2 has to leave room for that.
4. **The engine/game boundary.** What a game provides (components, systems, content records, rates) and what the
   engine provides (the frame, scheduling, platform, tools, database). How a game starts: a template, a `main` the
   engine owns, or a `main` the game owns that calls the engine?
5. **Where the tools live.** In this monorepo (an editor served over HTTP, [human-tools.md](human-tools.md)), and the
   hosted platform (marketplace, backend): in this monorepo too, or their own repositories?
6. **The license and the platform.** The engine is MIT OR Apache-2.0. Is the hosted platform's code open as well, or
   only the engine?
7. **Naming.** `kyoten` as the engine package name, `tools/`, `services/`: fixed now so imports and docs do not churn
   later.
8. **Examples against a published engine.** An example reaches the engine by path, so it builds only inside a kyoten
   checkout. When the engine is published and the engine manager hands out a standalone copy of an example
   ([version-manager.md](version-manager.md)), does it depend on a registry version, with a `kama.local.json` override
   for engine work?

## Decided

- **2026-11-01, the owner: each example game is its own repository**, so the engine manager can offer them one at a
  time as starting points, and so they take no space for anyone who only wants the engine.
  - **How:** inside a kyoten checkout, an example is cloned to `games/<name>`, and kyoten's `.gitignore` leaves
    `games/` out. kyoten's `kama_workspace.json` lists only `engine` and names no game, which keeps the rule that the
    engine never names a game. Each example is a standalone project (no workspace spans them) that depends on
    `"kyoten": { "path": "../../engine" }`. The first two are `kyoten-fps` and `kyoten-vr` ([examples.md](examples.md)).
  - **Verified on kama 0.9.803:** the engine workspace installs alone, and each example installs, checks and runs from
    kyoten's root or from its own directory.
  - **Considered:** one repository holding every game, set aside because examples are downloaded individually. kama
    accepted every layout tried (an optional workspace member, a games workspace, standalone projects).
