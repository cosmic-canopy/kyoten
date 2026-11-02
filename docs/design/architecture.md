# Architecture: the engine, the games, the repository

**Status:** draft for the design spike. Four decisions are recorded; the rest are questions.

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
- **The inventory of what to take** ([../research/harvest.md](../research/harvest.md), KYR-2): every candidate piece
  of FFD, the-mallow-man and cosmic-forge, with what it assumes about its game and what making it generic would cost.
  Only FFD's pieces have a proven web leg, and no donor has a 3D renderer on both legs. Its *What this does not decide*
  frames questions 2 (copy, depend or publish) and 3.
- **What kama will and will not build** (kama `docs/ROADMAP_DETAIL.md` § 8, ruled by the owner 2026-11-02 at kama
  `62322f93`). The rule: a capability is kama's (the language or std) if it belongs there, a first-party package if it
  stands alone, and otherwise the engine's.
  - **GPU and window stand alone**, since FFD and the-mallow-man each wrote their own WebGPU binding and GLFW layer,
    and a tool needs them as much as a game does. So `@kama/gpu` (KR-25) and `@kama/window` (KR-26) stay first-party
    packages in their own repositories, designed and unbuilt, with kyoten as their first consumer. Who builds them is
    question 3.
  - **XR is kyoten's** ([xr.md](xr.md) § Decided). kama filed `@kama/xr` (KR-284) on 2026-11-01 and retired it the
    next day: its one consumer is an engine, and its hard half is engine design.

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
   - **The namespaces wait on kama** ([../KAMA_GAPS.md](../KAMA_GAPS.md) KY-8, 2026-11-02). The owner wants
     `@kama/<noun>` for general-purpose packages and `@kyoten/<noun>` for kyoten's own, with `@kyoten` as a second
     official Cosmic Canopy scope. On kama 0.9.810, a scope does not reach the import: `@kyoten/net` imports as `net`,
     so it cannot sit beside any other `net`, the game's own included, and a consumer cannot alias a dependency.
     kama triages it, and this question is settled once it rules.
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
- **2026-11-01, the owner: friendly-fire-department and the-mallow-man ship on their own engines.** kyoten is built in
  parallel and gates neither. The owner has Steam partner approval and wants FFD out as soon as possible.
  - **Why:** FFD is one milestone from shipping. M0–M5 are done and M6 is down to its tuning pass, with the ship list in
    `friendly-fire-department/docs/ROADMAP_DETAIL.md` § M7, current at FFD's last commit (2026-10-13). kyoten has no
    engine code. Moving FFD first would rebuild what its engine already does (FFD's `engine` is 18,733 lines of kama,
    `view` 7,427, `gfx` 5,910, counted 2026-11-01), then re-prove its world hash on five legs and its 3,538 checks, for
    nothing a player sees.
  - **Considered:** porting FFD to kyoten before launch, set aside for that reason. The same holds for the-mallow-man.
  - **What follows:** the two games are kyoten's donors and references, not yet its customers.
  - **And after each ships, it is ported to kyoten** (the owner, 2026-11-01), to showcase as many games running on
    kyoten as possible. FFD's simulation goes first, as the engine's acceptance test: kyoten's frame must reproduce
    FFD's pinned world hash (KYR-46). Then the whole of FFD (KYR-47) and the-mallow-man (KYR-48), each in its own
    repository.
- **2026-11-01, the owner: kyoten starts from the peers' code, and moves toward generic and component-driven.** FFD,
  the-mallow-man and cosmic-forge are the starting point, and "at the very least great references".
  - **How:** a piece taken from a peer is made generic as it moves. It names no game, and it fits the component model
    the spike decides ([components.md](components.md)) rather than bringing a game's shape with it. KYR-2 inventories the
    candidates and what each assumes. For scale, counted 2026-11-01: FFD's `engine` (18,733 lines), the-mallow-man's
    `gfx` (18,013), `net` (8,080), `voice` (3,802) and `physics` (1,878), and cosmic-forge's `render` (7,860).
  - **The model to learn from is Unity's**, which grew in phases from its component-based design. kyoten takes
    different approaches but learns from that growth (KYR-3).
  - **Still open:** question 1 (how soon generality arrives) and question 3 (whether the platform layer is built on,
    as, or beside kama's platform packages).
- **2026-11-01, the owner: the marketplace and platform are a separate product**, which the owner builds in parallel
  ([marketplace.md](marketplace.md)). That settles question 5's second half (the hosted platform lives outside this
  monorepo) and moves question 6 (whether the platform's code is open) to that product. kyoten's own backend server,
  which anyone may host ([networking.md](networking.md) § Decided), is open like the engine; where its code lives is
  still question 5.
