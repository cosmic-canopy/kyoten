# Architecture: the engine, the games, the repository

**Status:** the spike's questions here are decided: 1–4 and question 7's directories on 2026-11-02, question 7's
namespaces on 2026-11-03. Question 2's module rules (which module may import which) are still to draft. Question 5 is
settled with question 7's directories, question 6 moved to the platform product, and question 8 waits for KYR-37.

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
   so it still pays for itself on a real game, and on two different ones? *Decided 2026-11-02: generic up front.*
2. **The package split.** One `kyoten` package, or several (core/frame, components, platform, render, audio, net,
   database, tools), each a workspace member? What may depend on what, and which parts are useful outside kyoten
   (published to the registry, as `@kama/ui` was)? *Decided 2026-11-02: one package with modules, and a package of
   its own for anything standalone or gated.*
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
     (`@kama/gpu`, `@kama/window`, the graphics library), and `@kyoten/<noun>` for what is kyoten's own.*
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
    package boundary is checked.)*
  - **Still to settle: which module may import which.** A draft for the owner, not decided:
    - **The rule it rests on** (the owner, 2026-11-03, [frame-phases.md](frame-phases.md) § What the vision asks):
      each engine system is driven by components in the phases. So **a system never imports another system**, and data
      moves between systems only through components, in phase order. That is also what lets a phase run its
      subsystems in parallel, each at its own rate.
    - **The layers, each importing only the ones above it:**
      1. the frame: phases, clocks, the scheduler and the input record;
      2. the world: components and their stores (named by [components.md](components.md));
      3. one module per system (input, render, audio, net, and later physics and UI), each also importing its own
         general-purpose library (`@kama/window`, the `@kama` graphics library, …);
      4. the agent surface (KYR-25), which reads every module and which no module imports.
      - The platform seam's interfaces go with the frame or with each system, as
        [target-platforms.md](target-platforms.md) question 1 settles.
    - **How it is checked.** A helper module fences itself with a list (`"visibility": ["render"]`). The system rule
      is between public modules, which `kama.json` cannot state. The options:
      - (a) a check in `tools/` that reads each file's one `import` block and fails CI on a forbidden edge;
      - (b) ask kama for a rule on what a module may import, filed as a gap;
      - (c) convention only.
    - **Recommended:** (a) now, and (b) filed if the owner wants the compiler to hold it. The layer names wait for
      frame-phases question 1 and components question 1, but the system rule can be decided first.
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
- **2026-11-02, the owner: each system is built on a general-purpose library, and the graphics one is shaped like
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
  - **It is a `@kama` package** (question 7, 2026-11-03, below), once kama rules on KY-9. Its name is the owner's to
    pick. Where its code starts (forge's `render`, the-mallow-man's `gfx`, or fresh) is
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
      KYR-52), and the Three.js-shaped graphics library (KYR-9). The general-purpose libraries under audio and
      networking (question 1's pattern) go there too, when KYR-15 and KYR-18 come up.
    - **`@kyoten/<noun>`** is for what is kyoten's own: what binds those libraries to kyoten's components and phases,
      and a platform or feature package that implements kyoten's interfaces.
    - A game names its own packages as it likes. A clash with a kyoten package is settled in the game's manifest, with
      a local name.
  - **The graphics library needs kama's ruling first** ([../KAMA_GAPS.md](../KAMA_GAPS.md) KY-9). kama's roadmap
    keeps "the renderer" in the engine today (kama `docs/ROADMAP_DETAIL.md:2862-2863`). Its name is the owner's to
    pick.
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
