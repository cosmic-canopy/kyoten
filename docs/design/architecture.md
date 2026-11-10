# Architecture: the engine, the games, the repository

**Status:** the spike's questions here are decided: 1–4 and question 7's directories on 2026-11-02, question 7's
namespaces on 2026-11-03, and question 2's module rule (an engine module never imports another engine module) on
2026-11-04. The layer names were decided at components question 3 (2026-11-05): frame, world, engine modules and the
agent surface. Question 5 is settled with question 7's directories, question 6 moved to the platform product, and
question 8 waits for KYR-37. *Reworded 2026-11-05 to the vocabulary of [components.md](components.md) question 3:
render, audio or net is an "engine module" (this doc first called it a "system"), and a "system" is a function over
components. Quotes keep their words.*

*Since 2026-11-07 ([components.md](components.md) question 8 part b), a function the scheduler runs is a **processor**, an area of code (an engine's or a game's) is a **module**, and a singleton is a **world component**. This doc's entries keep the words they were written in.*

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
  separate repositories, one per game, each cloned as `examples/games/<name>` (see *Decided*): `kyoten-example-fps`
  and `kyoten-example-vr` so far. Each depends on the engine by path; `kama run examples/games/fps/kama.json` prints
  `fps example, on kyoten`.
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
   so it still pays for itself on a real game, and on two different ones? *Decided 2026-11-02: generic up front.*
2. **The package split.** One `kyoten` package, or several (core/frame, components, platform, render, audio, net,
   database, tools), each a workspace member? What may depend on what, and which parts are useful outside kyoten
   (published to the registry, as `@kama/ui` was)? *Decided 2026-11-02: one package with modules, and a package of
   its own for anything standalone or gated. What may import what, decided 2026-11-04: an engine module never imports
   another engine module.*
3. **kama's platform packages.** Build kyoten's platform layer on `@kama/gpu` and `@kama/window`, build those packages
   (in kama's design) as part of kyoten's work, or keep kyoten's own layer as the peers did? *Decided 2026-11-02:
   kyoten builds them.*
   - **Extensible to N platforms.** The owner requires that a platform (web, desktop, Steam Deck, consoles under NDA, XR)
     is added without changing the engine for the others, which points to platforms, and features such as XR, as
     packages implementing engine interfaces, some of them private ([target-platforms.md](target-platforms.md)). The
     package split in question 2 has to leave room for that.
4. **The engine/game boundary.** What a game provides (components, systems, content records, rates) and what the
   engine provides (the frame, scheduling, platform, tools, database). How a game starts: a template, a `main` the
   engine owns, or a `main` the game owns that calls the engine? *Decided 2026-11-02: the game's `main` calls `run`.*
5. **Where the tools live.** In this monorepo (an editor served over HTTP, [human-tools.md](human-tools.md)), and the
   hosted platform (marketplace, backend): in this monorepo too, or their own repositories? *Settled: the hosted
   platform is a separate product (2026-11-01), and the editor and kyoten's own backend server live here, as `editor/`
   and `server/` (2026-11-02).*
6. **The license and the platform.** The engine is MIT OR Apache-2.0. Is the hosted platform's code open as well, or
   only the engine?
7. **Naming.** `kyoten` as the engine package name, `tools/`, `services/`: fixed now so imports and docs do not churn
   later.
   - *The namespaces are decided (2026-11-03): `@kama/<noun>` for a package that can exist outside kyoten
     (`@kama/gpu`, `@kama/window`, `@kama/graphics`), and `@kyoten/<noun>` for what is kyoten's own.*
   - **What made them possible.** The owner wants `@kama/<noun>` for general-purpose packages and
     `@kyoten/<noun>` for kyoten's own, with `@kyoten` as a second official Cosmic Canopy scope. On kama 0.9.810 a
     scope did not reach the import, so `@kyoten/net` could not sit beside any other `net`, and no alias existed
     ([../KAMA_GAPS.md](../KAMA_GAPS.md) KY-8, 2026-11-02). **kama fixed it in 0.9.820 (KR-291), re-checked here on
     0.9.823 (2026-11-03):**
     - A package's full name is its identity, and a scoped one's C names carry the scope: `@kyoten/net`'s `who` is
       `kS_kyoten__net__who`, an unscoped `net`'s is `net__who`.
     - A consumer gives a dependency a local name, `"kynet": { "package": "@kyoten/net", … }`, and each package
       resolves its imports through its own manifest. A game's own `net` and a library's `@kyoten/net` therefore meet
       in one program. A multi-module `@kyoten/gfx` under an alias still imports itself as `gfx::math` inside.
     - A scoped package still imports under its bare name by default. A consumer holding two packages of one name
       gives one a local name, and the refusal says how.
     - **Ownership is ruled** (kama `04837b90`, decision 4). A scope the maintainer's products publish under is
       reserved in the registry project, not the compiler, and a third party's claim waits on KR-27's trust model.
   - *The directories are decided (2026-11-02): `editor/`, `server/` and `tools/`.*
8. **Examples against a published engine.** An example reaches the engine by path, so it builds only inside a kyoten
   checkout. When the engine is published and the engine manager hands out a standalone copy of an example
   ([version-manager.md](version-manager.md)), does it depend on a registry version, with a `kama.local.json` override
   for engine work?

## Decided

- **2026-11-01, the owner: each example game is its own repository**, so the engine manager can offer them one at a
  time as starting points, and so they take no space for anyone who only wants the engine.
  - **How:** inside a kyoten checkout, an example is cloned to `examples/games/<name>`, and kyoten's `.gitignore`
    leaves `examples/games/` out. kyoten's `kama_workspace.json` lists only `engine` and names no game, which keeps the
    rule that the engine never names a game. Each example is a standalone project (no workspace spans them) that
    depends on `"kyoten": { "path": "../../../engine" }`. The first two are `kyoten-example-fps` and
    `kyoten-example-vr` ([examples.md](examples.md)). *(Until 2026-11-08 they were `kyoten-fps` and `kyoten-vr`,
    cloned as `games/<name>`: examples.md § Decided, 2026-11-08.)*
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
  still question 5. *(Since settled: `server/`, in this repository, 2026-11-02 below.)*
- **2026-11-02, the owner: generic up front (question 1).** "We should be generic as much as possible up front and
  write strong abstractions for our systems and phases." The aim is "as optimal as possible while being flexible and
  generic".
  - **How:** the peers are the reference for implementation detail ("FFD, the mallow man, cosmic forge all have
    lessons for us with kama"). The FPS example shows what is needed, without the engine taking its shape: "I don't
    want to fall into a gap of being too specific for anything."
  - **For [components.md](components.md) and [frame-phases.md](frame-phases.md):** "each phase has its own components
    that can be written", likened to how Unity built a generic scene graph and composed MonoBehaviours on it per game,
    and "there may be some lessons we learn from that NOT to do".
  - **Considered:** features arriving only when an example needs them, with only what cannot change later (identity,
    order, the override format; [../research/component-models.md](../research/component-models.md) § 5.8) designed up
    front. That was the recommendation, and the owner chose strong abstractions up front instead. The peers' rule ("no
    abstraction before a game needs it") is theirs, not kyoten's.
- **2026-11-02, the owner: one `kyoten` package with modules, and "anything external/stand alone or gated can be a
  separate package" (question 2).**
  - **How:** the engine's parts are modules of `kyoten` (`kyoten::frame`, `kyoten::platform`, …). A part becomes a
    package of its own when it stands alone, so that something outside kyoten can use it (as `@kama/ui` grew out of FFD's
    UI). It also becomes one when it is gated: optional or private (a console's platform under NDA, Steamworks, XR), or
    carrying a C dependency that only some games build. `kama_workspace.json` gains a member as each one is made.
  - **Why:** a consumer compiles only what it reaches, so modules cost it only the download (kama
    `docs/packages.md:639-650`). A console's package cannot live in this public repository. Only a package boundary is
    checked by the compiler: a module may import any sibling in its own package. *(Made precise 2026-11-03, probed on
    0.9.823: a module's `visibility` may list the modules allowed to import it, and kama refuses any other. A module a
    game imports must be `public`, though, and that opens it to every sibling too. So between public modules, only a
    package boundary is checked. Re-probed on 0.9.839, 2026-11-04, with the same result.)*
  - **Which module may import which** was decided on 2026-11-04: an engine module never imports another engine module
    (below).
  - **Considered:** several workspace members from day one, as the-mallow-man (9) and cosmic-forge (8) have; and a
    core package with one package per platform and per C-backed feature.
- **2026-11-02, the owner: kyoten builds `@kama/window` and `@kama/gpu` (question 3).**
  - **How:** to kama's designs (kama `docs/ROADMAP_DETAIL.md` § 8, `s8-input` and `s8-gpu-wrapper`). Each lives in its
    own repository, `kama-window` and `kama-gpu`, the convention every `@kama` package follows, and is built from the
    harvested pieces ([../research/harvest.md](../research/harvest.md) §§ 3–5):
    - `@kama/window`: FFD's proven web platform header, with the-mallow-man's native superset, made multi-window;
    - `@kama/gpu`: cosmic-forge's resource-shaped device, with `wgpugen` over both `webgpu.h` headers.
    - kyoten's platform layer sits on them. The engine-shaped parts stay in kyoten: frame pacing, the renderer and the
      XR swapchain. kyoten claims kama's KR-25 and KR-26, and the owner relays that to kama's session. The work is
      KYR-51 and KYR-52.
  - **Why:**
    - Both are in kama's LATER with no repository, and "No consumer waits on it" (kama `docs/ROADMAP.md:154-155`).
    - kama ruled that both stand alone, since a tool needs them as much as a game does.
    - Their designs match code kyoten already has.
    - The peers' layers hold one window per process in file-static C state, which an editor and XR cannot use.
  - **Considered:** waiting for kama to build them, which puts slice A behind kama's queue; and kyoten's own layer
    beside them, a third copy of the same code.
- **2026-11-02, the owner: each engine module is built on a general-purpose library, and the graphics one is shaped like
  Three.js.** "Each system 'graphics, audio, networking, etc.' can probably be built from a more general purpose
  package library. Recall also that each should be as lean as possible on the web and rely on the best in class
  browser APIs for that purpose." On graphics: "the graphics side can be general utilities that help other projects
  build graphics applications quickly … I've used Three.js for several 'non-game' products."
  - **How:** `@kama/gpu` is only the binding: kama's design keeps a renderer out of it. The Three.js-shaped library
    (scene, meshes, materials, lights, camera, loaders) sits on it as **its own package from day one**, naming no engine
    concept, so cosmic-forge, the editor and non-game products can use it without kyoten's frame. kyoten's render
    module binds components to it. Audio (on Web Audio) and networking (on WebSocket, WebRTC and WebTransport) follow
    the same pattern when KYR-15 and KYR-18 come up.
  - **Why its own package from the start:** the owner leaned on the recommendation ("we can start with it being a
    built in module if that is easier?"). Only a package boundary keeps it from importing the engine; as a module,
    "names no engine concept" would be a convention.
  - **It is `@kama/graphics`** (question 7, 2026-11-03, below), which kama ruled a first-party package on 2026-11-04
    (kama KR-309). Where its code starts (forge's `render`, the-mallow-man's `gfx`, or fresh) is
    [rendering.md](rendering.md) question 1.
  - **Considered:** a `kyoten::render` module split out later; and widening `@kama/gpu` into the library, which would
    reverse kama's design.
- **2026-11-02, the owner: the game's `main` calls `run` (question 4).**
  - **How:** the game owns `main`. It builds the engine's app (its rates, its platform, its components and systems)
    and calls `run`, which owns the loop on every target: `requestAnimationFrame` on the web, the native loop, the
    headset's frame under XR, and the lifecycle's events. The parts stay public, so a test, a replay tool or the
    headless backend server (KYR-45) can step a world without the loop, as FFD's tests do. `kyoten new` (KYR-30)
    writes that `main`, so a game starts from a template, but the `main` stays ordinary code the game owns.
  - **The boundary:** the game provides components, systems with their phase and rate, content records and its input
    record. The engine provides the frame, scheduling, the clocks, the platform, the tools and the database.
  - **Why:**
    - In kama, `main` stays the entry on every target, and `std::app::run` drives the loop. On wasm that is
      `emscripten_set_main_loop_arg`, which never returns (kama `include/kama_app.h`). On Android it pumps the looper
      and delivers the lifecycle as events (kama `docs/ROADMAP_DETAIL.md:2523-2527`).
    - The engine cannot import a game, or a private platform package, so the game is what picks the platform. How it
      names one is [target-platforms.md](target-platforms.md) questions 1–2.
    - An engine-owned loop keeps the phase order, replay and a display clock the game does not own
      ([frame-phases.md](frame-phases.md) question 10) in one place.
  - **Considered:** the game owning the loop too, FFD's shape, where each game would carry the phase order and replay
    itself; and the engine owning `main`, which in kama needs a generated shim.
- **2026-11-02, the owner: `editor/`, `server/` and `tools/` (question 7, the directories).** `engine/` holds the
  `kyoten` package, `editor/` the human tool surface (KYR-26) and `server/` kyoten's open backend (KYR-45). `tools/`
  holds scripts, as in kama and all three peers. Each directory is made when its row starts. On the editor: "We will
  develop AI first and human tools start as visibility into the process… but obviously it will be most powerful to
  allow humans to edit as well as AI so humans can tweak" ([human-tools.md](human-tools.md)).
  - **Considered:** the brief's `tools/` for the editor and `services/` for the server, which would move the scripts.
- **2026-11-03, the owner: `@kama` for whatever can exist outside kyoten, `@kyoten` for the rest (question 7, the
  namespaces).** First: "If you are talking about general purpose things like window and gpu those can probably live
  in kama namespace. Anything wrapping those or specific to kyoten would belong to kyoten." Then, the same day, on the
  graphics library: "If we build a general purpose Three.js shaped graphics library I honestly think that may go to
  kama as well. We just would need to come up with a reasonable name for it. If it can exist outside of kyoten it
  probably will be in kama for now. I can see the light weight graphics library used by just about anything and
  doesn't need to be game engine / simulation or even real time."
  - **How:**
    - **`@kama/<noun>`** is for a package that can exist outside kyoten: `@kama/gpu` and `@kama/window` (KYR-51,
      KYR-52), and the Three.js-shaped graphics library, `@kama/graphics` (KYR-9). The general-purpose libraries under audio and
      networking (question 1's pattern) go there too, when KYR-15 and KYR-18 come up.
    - **`@kyoten/<noun>`** is for what is kyoten's own: what binds those libraries to kyoten's components and phases,
      and a platform or feature package that implements kyoten's interfaces.
    - A game names its own packages as it likes. A clash with a kyoten package is settled in the game's manifest, with
      a local name.
  - **kama ruled the graphics library first-party** on 2026-11-04, closing KY-9. Its roadmap row KR-309 reads
    "`@kama/graphics` — a lightweight 3D graphics library, a first-party package … naming no engine concept, since a
    viewer, an editor and a non-game product each use one". The row is claimed by "a downstream engine, … building it
    in its own repository", and its design lives in `cosmic-canopy/kama-graphics` (kama `docs/ROADMAP.md:157`,
    `fd3ec5eb`).
  - **Its name is `@kama/graphics`** (the owner, 2026-11-03: "kama graphics is probably the best bet"). It is imported as
    `graphics` (`graphics::Mesh`), and a path package of that name installs and runs on 0.9.823. It is a plain noun like
    kama's other first-party names, and it says nothing about games or real time. It avoids every name already in use:
    kama's (`gpu`, `window`, `http`, `ui`, `tls`, `sodium`, `postgres`, `redis`), the peers' (`gfx`, `render`, `view`)
    and kyoten's `render` module. Also considered: `@kama/scene` (a scene graph, but narrower than the library, and
    `scene::Scene` stutters), `@kama/draw` (reads as 2D or immediate-mode), and `@kama/three` (Three.js's own name).
  - **The engine package keeps its import name.** Today it is the unscoped `kyoten`. Published as `@kyoten/kyoten`, it
    imports as `kyoten` too, and its files reach their own modules as `kyoten::phase::…` (probed on 0.9.823). So which
    one it publishes as waits for its first publish (question 8, KYR-37) and changes no import.
  - **Why it holds now:** kama 0.9.820 made a package's full name its identity and gave a consumer the `package` key
    (KR-291; *What made them possible*, under question 7).
  - **Still with kama:** reserving `@kyoten` for Cosmic Canopy, which kama ruled belongs in the registry project.
    Whether it is reserved yet is not visible from here.
  - **Considered:** `@kyoten` for the graphics library, because it wraps `@kama/gpu`. That was recorded first, from the
    owner's first answer, and the owner corrected it the same day: what decides is whether a package can exist outside
    kyoten, not whether it wraps another. Also considered: a prefix in every name (`kyoten_net`), which kama refused as
    a workaround when it ruled KR-291.
- **2026-11-04, the owner: an engine module never imports another engine module (question 2, the module rule).**
  - **The rule:** an engine module never imports another engine module. It reads what other engine modules publish, in
    phase order. That is components, and read-only query resources whose contract lives in the world layer and which an
    engine module implements, such as a raycast against physics's world or a nav path.
    - Data still moves between engine modules all the time, through the world, never by one calling into another's
      module. Render reads the transforms Constraints settled. Audio derives its cues in Output from the settled tick.
      Update reads the contacts Constraints found, on the next tick.
    - It rests on the owner's direction of 2026-11-03: each engine module is driven by components in the phases
      ([frame-phases.md](frame-phases.md) § What the vision asks).
  - **Why**, in the owner's words: "The goal is that each PHASE can be made parallel safely and efficiently to increase
    overall performance and utilization of CPU and GPU resources. It is also to make the engine easy to use correctly
    and hard to use incorrectly."
    - A scheduler can run a phase's systems in parallel only if it knows what each one reads and writes. A
      component or a published query is an access a system declares. A call into another engine module is
      access the scheduler cannot see.
    - Unity's Jobs and Entities require each job's reads and writes to be declared, for the same reason.
  - **What it costs, weighed with the owner:**
    - A query one engine module answers for another needs its contract in the world layer. The rule as adopted includes
      that, rather than forbidding the query.
    - Two systems of one phase that run in parallel cannot see each other's writes in that tick. The phase orders
      them, or the reader sees the write on the next tick ([frame-phases.md](frame-phases.md) question 5).
    - A hit that Constraints finds reaches Update on the next tick. That comes from the phase order, not from this rule.
      A response that must land in the same tick is itself a constraint ([frame-phases.md](frame-phases.md) question 1).
    - **Not limited by it:**
      - one engine module working in several phases (net receives in Input and sends in Output);
      - an engine module's own general-purpose library;
      - the shared types (math, `Transform`), which live in the frame and world layers.
  - **Whom it binds:** the engine's own modules. A game is another package, so the rule does not reach its imports.
    Its systems state their access like any other ([frame-phases.md](frame-phases.md) questions 5 and 6).
  - **How it is held: a check in `tools/`, and a request to kama.**
    - **`tools/check-imports` (KYR-53):**
      - **What it reads:** `engine/kama.json`'s modules map, one layer table, then each file's one `import` block.
      - **What it does:** it fails on a forbidden edge, naming `file:line`, the edge and the rule, with `--json` for an
        agent. It runs in CI and before `kama check`, and it covers `engine/` only.
      - **When it lands:** with KYR-6, when the engine has a second module. The layer table is also the map an agent
        reads to learn where code goes.
      - **Why it reads the source:** kama reports no module's imports (`kama stats` lists the modules but not their
        edges, on 0.9.840). Reading the block is exact, because kama's grammar keeps one per file, at the top, with
        each entry a full path.
    - **KY-11 asked kama for a list on the *importing* module**, so that `kama check` and the editor refuse the edge
      and the tool can retire. `visibility` is a list on the imported module, so it cannot hold the rule between public
      modules. Re-probed on 0.9.840: fencing `audio` from `render` also fences it from the game.
    - **kama took it on 2026-11-04: `importsOnly`** (KR-308, 0.9.842). A module that writes it may import, from its
      own package, only the modules it lists. Re-probed on 0.9.845: with `"render": { "visibility": "public",
      "importsOnly": ["frame"] }`, `render`'s import of `audio` is refused (*"module `eng::audio` is not in the
      `importsOnly` of `eng::render`"*), and the game still imports both.
      - **So the compiler now holds the rule.** Each engine module lists, in `importsOnly`, the layers it may
        import, which never name another engine module.
      - **The tool narrows to a check of those lists** against the layer table (ROADMAP KYR-53): that every engine
        module has an `importsOnly`, and that none names another engine module. It no longer reads the source.
      - **2026-11-08, the owner: the simulation rule is a module fence too** ([ai-first-api.md](ai-first-api.md)
        § Decided, question 3, item 5).
        - **What the lists hold:** a module holding Input, Update or Constraints processors leaves out std's `time`,
          `fs`, `net`, `process`, `io`, `concurrent`, `uuid` and `random`, and `core::env`. Of its own package's
          modules, it names only other simulation modules.
        - **So an engine module that works in several phases splits in two:** a fenced part for its simulation
          processors, and an outside part for the work that stages for them.
        - **The check gains three things:** it reads the code records, to learn which modules hold simulation
          processors; it holds those modules' lists; and it covers games, not only `engine/`.
        - **It still reads source for one thing:** target-platforms question 3's refusal of an OS flag
          (`@compileFor(OS_WINDOWS)`) in an engine module or a game's processors (ROADMAP KYR-53).
      - **2026-11-09, the owner: the tier table is data, a `tier` in each engine module's records file** (the first
        slice's step 6, KYR-53, question 4 of 4; the other three are in components, ai-first-api and target-platforms
        § Decided). The owner: "AH yes this sounds good".
        - **Why it was asked:** kama holds whatever each `importsOnly` says. If `content`'s list named `input`, kama
          would let `content` import `input`, and the rule would break with nothing to say so. The check holds the
          lists against the tier table, which until now was REFERENCE's diagram: prose that a program cannot read.
        - **The table:** `kyoten::records`'s `ModuleRecord` gains `tier`: `Frame`, `World`, `Module` or `Agent`, spelled
          as a phase is. Each engine module's records file states its tier:
          - the root module, which keeps `version()`, and `frame` are `Frame`;
          - `world`, and `records` beside it, are `World`;
          - `input` and `content` are `Module`.

          These are the engine's first code records. The engine's root module gains `"importsOnly": []`.
        - **The check** (`kyoten check engine/kama.json`): every engine module has a tier and an `importsOnly`, and
          each entry that names a module of its own package names one of a tier above its own, so no engine module
          names another. It reads no source for this.
        - **Why there:** the tier is a fact about the module, so it sits beside the module's code. That is where an
          agent learning where code goes reads it, and it is the records file that will declare render's processors
          at step 9.
        - **Considered:**
          - a table in the `kyoten` tool's source, which is smaller but puts the engine's map outside the engine;
          - deferring the tier half of the check until the agent surface (KYR-25).
        - **2026-11-09, built** (step 6, KYR-53; `tools/kyoten/src/fence.kama`, with the fence in ai-first-api
          § Decided), test-first on kyoten's pin, `0.9.899+gf32373ea`.
          - **In the engine:**
            - `kyoten::records` gained `Tier` and `ModuleRecord`'s `tier`, with 3 cases, so the engine's tests are 158.
              A tier spelled any other way is refused: ``` `module` is not a `Tier` (at `tier`) ```.
            - Six records files state the tiers above.
            - The root module's `importsOnly` is `[]`.
          - **In the tool:** the `kyoten check engine/kama.json` leg in `tools/test.sh` passes. The tool's `tiers`
            fixture, a library shaped like the engine, is refused for:
            - a `Module` naming a `Module`;
            - a `World` naming a `Module`;
            - a module that states no tier;
            - a module with no `importsOnly`.

            Modules naming only tiers above their own are not refused, and `kyoten generate` on a library says that
            nothing is generated for one.
          - **Mutations caught:** a same-tier entry accepted, and a missing tier accepted.
  - *Renamed 2026-11-07 ([components.md](components.md) question 8 part b): these layers are the engine's **tiers**,
    since a bare "layer" now means a scene's layer. This entry keeps its words.*
  - **The layer names: decided 2026-11-05 at [components.md](components.md) question 3, choice 6.** The four layers
    are frame, world, one module per engine module, and the agent surface. The `World` contract and `run` sit in the
    frame layer, and the generated world in the game's package. The draft as first written follows. The names waited
    for [frame-phases.md](frame-phases.md) question 1 (2026-11-04) and [components.md](components.md) question 1
    (2026-11-05). They were then proposed for components question 3, because a game's world is generated, and how an
    engine module reads a world it did not write is decided there. The draft had four layers, each importing only the
    ones above it:
    1. the frame: phases, clocks, the scheduler and the input record;
    2. the world: components, their stores, and the contracts of published queries;
    3. the engine modules (input, render, audio, net, and later physics and UI), each also importing its own
       general-purpose library (`@kama/window`, `@kama/graphics`, …);
    4. the agent surface (KYR-25), which reads every module and which no module imports.

    The platform seam's interfaces go with the frame or with each engine module, as
    [target-platforms.md](target-platforms.md) question 1 settles.
  - **Considered:**
    - the rule as first worded, with no query between engine modules, so anything one engine module needs from another
      arrives as a component, a tick later if need be;
    - deferring the rule to components question 1;
    - holding it by convention only, or by kama's gap alone.
- **2026-11-08, the owner: the `kyoten` tool is the package `@kyoten/cli`, in `tools/kyoten/`** (the first slice's step
  5, question 5 of 7). "Sounds good so far."
  - **What:** the generator and the other `kyoten` commands (`generate`, `check`, `build`, `run`, `clean`, later
    `test`, `merge`, `fmt`, `migrate` and `new`) are one executable, as components.md decided on 2026-11-07. Its package
    is `@kyoten/cli`, an executable in `tools/kyoten/` that depends on the engine by path, and the workspace lists it.
    `tools/` held only scripts until now; this is its first package.
  - **Why `@kyoten/cli`:** it is kyoten's own, so it takes the `@kyoten` scope (2026-11-03, above), and the plain name
    `kyoten` is the engine package's. A prefix in the name (`kyotencli`) is the workaround kama refused when it ruled
    KR-291.
  - **Why a package and not a module of the engine** (the owner asked): the tool is a program with its own `main`, and
    a kama package is either a library or an executable. The engine is a library that every game links, with no entry,
    as its tests are a program of their own (`engine/tests/`). The dependency runs one way: the tool imports the
    engine's record types (`kyoten::records`, components.md, 2026-11-08), and the engine never imports the tool.
  - **The program is named `kyoten`.** kama names an executable after its package, scope stripped, so a plain
    `kama build` writes `cli`. The tool's build passes `-o kyoten`, and the engine manager installs it under that name
    ([version-manager.md](version-manager.md)).
  - **Probed on kama `0.9.876+g7ce86d36`** (`.scratch/step5-cli`): `@kyoten/cli`, depending on another package by
    path, built as `out/x86_64-windows-gnu/debug/cli.exe`, and with `-o out/kyoten.exe` as `kyoten.exe`, which ran.
- **2026-11-10, the owner: how the libraries grow toward complete.** Asked after the owner asked what remains for the
  hello cube: "I don't want to rush anything... Ideally kama graphics and the other packages will be as comprehensive
  as possible... but we can work our way there and I would like your recommendation on all of that." The hello cube
  is "Kyoten's proof of concept and first vertical slice". Each answer was as recommended.
  1. **Each library's whole architecture is decided first, then built depth-first** ("this sounds good to me"). The
     hello cube (KYR-14) is the first vertical slice through every tier, and each later example widens one library.
     - **Why:** a subset built on an architecture that cannot grow is rebuilt later. Three.js's `WebGPURenderer`
       replaced its WebGL-era material path (`ShaderMaterial`, `onBeforeCompile`) with TSL ([rendering.md](rendering.md)
       § Decided, 2026-11-07).
  2. **Each package repository has its own spec and roadmap** ("Yes each repo deserves it's own spec and roadmap,
     etc."): a `SPEC.md` and a `ROADMAP.md` beside its `AGENTS.*.md`.
     - `@kama/graphics`'s come from its design pass ([rendering.md](rendering.md) § Decided, 2026-11-10; KYR-68).
     - `@kama/gpu`'s and `@kama/window`'s come from their departures lists and the checklists in items 3 and 4.
  3. **`@kama/gpu`: every call in webgpu.h before 1.0** ("Sounds good").
     - It is tracked by a coverage report `tools/wgpugen` prints: which of the header's functions the safe API wraps.
     - It grows by the spec's sections, in the order graphics pulls them: the render pipeline's set first, then compute,
       queries and timestamps, and indirect draws.
  4. **`@kama/window`: the browser's platform APIs are its checklist** ("Sounds good so far"), with native at parity.
     - Beyond what the cube needs (a window or canvas, physical keys, a gamepad and a headless window): pointer and
       touch, text input with IME composition, the clipboard, cursor shapes, fullscreen and pointer lock, DPI changes,
       several windows natively, and file drop.
  5. **The order to the cube** ("Sounds good"; [../FIRST-SLICE.md](../FIRST-SLICE.md) § The order of work):
     1. the stopgaps that change an API: `@kama/gpu` item 2; `@kama/window` item 6, then `@kama/gpu` item 9;
        `@kama/window` item 5;
     2. the web leg, brought forward: the window's web half (W2, now `@kama/window`'s WIN-3), then a canvas surface in
        Edge (G6, now `@kama/gpu`'s GPU-3). Nothing has run in
        a browser yet, and the seventh session found wgpu-native unlike its own docs, so the browser's surprises are
        found before graphics is built on assumptions;
     3. the graphics design pass (KYR-68), alongside 1 and 2, since it needs no code from them;
     4. `@kama/gpu`'s render pipeline set, shaped by that design;
     5. `@kama/graphics`' first slice on both legs;
     6. the join: the platform seam, input and the render module;
     7. the cube, with its four checks in CI;
     8. then breadth, slice by slice, with non-game examples beside the games.
- **2026-11-10 (the eighth session), the owner: each package's documents, ids, names and coverage.** Four questions,
  each answered as recommended, before either package's `SPEC.md` or `ROADMAP.md` was written.
  1. **Each package numbers its own roadmap rows,** with permanent ids and a "Next id" counter, as kama's `KR-` and
     kyoten's `KYR-` are: `GPU-<n>` in `@kama/gpu`, `WIN-<n>` in `@kama/window`, and `GFX-<n>` in `@kama/graphics`
     when its design pass writes one. The owner: "Yes each repo has it's own." The gap files keep `KGPU-` and `KWIN-`.
     The step labels the briefs used before (W2 for the window's web half, W3 for gamepads, G6 for a canvas surface run
     in Edge) were defined nowhere, so they give way to the rows' ids: WIN-3, WIN-4 and GPU-3.
  2. **Each document keeps to one purpose,** as kama's and friendly-fire-department's do. The owner: "we shouldn't be
     polluting these foundational documents. Each serves a specific purpose and we have several peer repos to reference
     for patterns."
     - `SPEC.md` is what the package is, and never what it will be: each type's ctors and methods with their parameter
       names, what each refuses and why, each leg's measured behaviour, and the invariants.
     - `ROADMAP.md` is the order of work and nothing else, each row linking to its reasoning.
     - `AGENTS.*.md` is the agent's brief: the rules, the build, where the truth is, and the departures from kama's
       design with their reasons, which is the record kama reads.
  3. **The packages' public names follow kama's constructor rule** (KR-367, kama 0.9.911, its SPEC § Construction),
     renamed before either is published, since a rename after that breaks every consumer. The owner: "We should be
     consistent yes." `Window.headless` keeps its name: kama's own design names it, and `Window.make` beside
     `Window.open` would hide that nothing is behind it.
  4. **`@kama/gpu`'s coverage report counts a webgpu.h function as covered when the safe API calls it:** a call site of
     its binding outside the bindings, as `kama query --refs` answers, or a call in a seam function the safe API calls.
     The owner: "I think this sounds good from what I can tell."
     - **1.0 is all of webgpu.h:** the functions both legs declare, and those only one leg's webgpu.h has yet. Built
       the same day, the report counted 206: 199 on both legs, 3 only in wgpu-native's (`SetImmediates`), and 4 only in
       emdawnwebgpu's, which wgpu-native declares in `wgpu.h` instead. The question named 204, missing those 4.
       wgpu-native's own extensions (`wgpu.h`) are reported apart, and whether any belongs in 1.0 is the graphics design
       pass's question of what goes beyond WebGPU (KYR-68).
     - **A `Destroy` stays uncovered until its row decides a safe form.** No raw destroy in the safe API
       (ai-first-api question 3) rules out a raw one, not every one.
     - It is grouped by the spec's sections, written by `tools/wgpugen` as a committed `COVERAGE.md`, and held as the
       bindings are: the gate regenerates and compares it, and the covered count is a ratchet.
