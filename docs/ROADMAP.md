# kyoten roadmap

**The order of work, and nothing else.** One row per item, a one-line summary, and a link to its reasoning.

Ids are `KYR-<n>`, permanent, never reused or renumbered. **Next id: KYR-61**

**Everything the vision asks for has a row, at the owner's request (2026-11-01),** so this file is the record of what is
wanted, including what is far off. A row past NOW is a place in the order, not a decision. Its design questions are
decided when the row comes up, in the doc it links. friendly-fire-department and the-mallow-man ship on their own
engines, so nothing here gates either one ([design/architecture.md](design/architecture.md)).

**The gate: when KYR-12 passes, a game can start on kyoten.**

## NOW: the narrowed spike, and the probes it needs

| id | item | detail |
|---|---|---|
| KYR-1 | **Design spike, narrowed (2026-11-01)**: decide what the first slice needs, and the design of the project database and wiki. Which questions are in it, and which row each other doc waits for, is in the brief | [SPIKE.md](SPIKE.md#narrowed-2026-11-01) |
| KYR-2 | **What to take from the peers**: an inventory of FFD, the-mallow-man and cosmic-forge code, with each piece's game-shaped assumptions and the cost of making it generic. **Done 2026-11-01** | [research/harvest.md](research/harvest.md) · [architecture.md](design/architecture.md) |
| KYR-3 | **Component models compared**: how Unity grew in phases from its components, and what it later added or replaced, against other engines' models. A research doc for the component decision. **Done 2026-11-01** | [research/component-models.md](research/component-models.md) · [components.md](design/components.md) |
| KYR-4 | **The Quest probe, answered by the owner's Quest prototype** (its own project): WebXR with WebGPU in the Quest browser, and a kama program built, loaded and run on the headset (KY-2). Its findings come back as research | [xr.md](design/xr.md) |
| KYR-5 | **Measure the web first**: the cost of a `wgpu*` call crossing into JS, and the size of a minimal wasm build. **Done 2026-11-01** | [research/web-baseline.md](research/web-baseline.md) · [web-and-native.md](design/web-and-native.md) |
| KYR-55 | **The rates, researched**: for each subsystem, the floor and what breaks below it, from perception studies, physics engines' guidance, engines' defaults and shipped games by genre, with sources. It ends in a universal default per subsystem, so frame-phases question 3's numbers are decided from evidence. **Done 2026-11-04** | [research/rates.md](research/rates.md) · [frame-phases.md](design/frame-phases.md) |
| KYR-58 | **Game types, stress-tested**: walk each kind of game through the frame model, components options A and B (with chunk storage inside) and per-zone budgets, and record what each stresses and where the model holds or breaks. The kinds: FPS (the first example), RTS and the "generals" view, open worlds with streaming zones, fighting games with rollback, VR, simulation and city builders, MMO and server scale, turn-based and puzzle, 2D and mobile. The peers cover only a 2D game and a 3D co-op round game. Done before components question 1 is decided, so the component model serves every game type (the owner, 2026-11-04: "we want to support all game types"). **Done 2026-11-04**: no kind of game was found that the decided frame model cannot express; fourteen conditions (G1–G14) go to the questions they feed | [research/game-types.md](research/game-types.md) · [components.md](design/components.md) · [frame-phases.md](design/frame-phases.md) |
| KYR-59 | **kama's KR-3 pool brief, audited against kyoten**: kama's KR-3 row waited on "an audit by the engine that asked". Check the brief's seventeen decisions against kyoten's decided designs, answer kama's two questions (KR-326, KR-327), and map what each of the spike's open questions leans on in kama (the owner, 2026-11-05: "a full picture of Kama Gaps from Kyoten as soon as we can"). **Done 2026-11-05**: the brief conflicts with nothing decided and answers KY-5, KY-12, KY-13 and KY-15; KR-326 needs both shapes; KR-327 is a per-build setting, as frame-phases decided; KY-19 found (`reproducible-float` does not cover `std::math`); needs added to KR-320, KR-325, KR-298, KR-79 and KY-18 | [research/kr3-audit.md](research/kr3-audit.md) · [KAMA_GAPS.md](KAMA_GAPS.md) |

## NEXT: the first slice, after which a game can start on kyoten

| id | item | detail |
|---|---|---|
| KYR-6 | **The frame core**: phases, the fixed-tick clock and its sub-rates, the RNG, the world hash and the input log, starting from FFD's `engine::phase`. Waits are deadlines in simulation steps, held in each waiting subsystem's own queue (frame-phases question 9). The scheduler runs serially by default, and CI runs every test scene both serially and in parallel and requires one world hash (frame-phases question 7) | [frame-phases.md](design/frame-phases.md) · [replay](design/replay-and-determinism.md) |
| KYR-7 | **The component model, first version**, as KYR-1 decides it. Question 1 (2026-11-05): records generate the world as plain kama (B built on A), and the game writes system bodies whose signatures are their access. Storage is a table per (zone, prefab) of fixed-size value chunks, allocated when the zone loads, plus side stores (sparse sets) for components gained at run time. So this row holds the generator (in `tools/`, mapping its errors back to the records), the table, chunk, side-store and handle types, and the fusing of one table's non-conflicting systems into one pass per chunk. Its input format is components question 5, with project-database question 11. Question 6 (2026-11-05) adds budget records per scope with a ceiling on every store, reserved up front or committed chunk by chunk as an opt-in; refusal when full, with eviction as an opt-in; N chosen per archetype from a 16 KiB target; the footprint report per scope; and the 32 KiB frame guard in the engine's and every example's manifest, on every arm but Windows | [components.md](design/components.md) |
| KYR-53 | **The module-rule check**: the compiler holds the rule through kama's `importsOnly` (KR-308, 0.9.842, which closed KY-11), so each engine system module lists the layers it may import. `tools/check-imports` checks those lists against one layer table: every system module has one, and none names another system. It has `--json` for an agent, and lands with KYR-6, when the engine has a second module | [architecture.md](design/architecture.md) · [KAMA_GAPS](KAMA_GAPS.md) |
| KYR-51 | **`@kama/window`, built by kyoten** (kama's KR-26, to kama's design): several windows or canvases, one event queue, physical keys, pointer lock, gamepad, and a headless window for tests. In its own `kama-window` repository, from FFD's web platform header and the-mallow-man's native one | [architecture.md](design/architecture.md) · [kama § 8](../../kama/docs/ROADMAP_DETAIL.md#s8-input) |
| KYR-52 | **`@kama/gpu`, built by kyoten** (kama's KR-25, to kama's design): the safe WebGPU binding, a resource per handle and a typed acquire, generated from both `webgpu.h` headers. In its own `kama-gpu` repository, from cosmic-forge's device and `wgpugen` | [architecture.md](design/architecture.md) · [kama § 8](../../kama/docs/ROADMAP_DETAIL.md#s8-gpu-wrapper) |
| KYR-8 | **The platform seam**: a window or canvas, keyboard, mouse, gamepad and the app loop, on the web and on Windows, Linux and macOS, on KYR-51. The game's `main` builds the app and calls `run`, which owns the loop on every target | [web-and-native.md](design/web-and-native.md) · [platforms](design/target-platforms.md) · [architecture](design/architecture.md) |
| KYR-54 | **The input system, first version**: semantic actions a game declares, bound to devices on KYR-8 and rebindable by the developer and the player, never hard-coded. An agent drives the same actions a human does. Input's record holds the actions, so a rebind cannot move the hash (as FFD's bound-key bits do). Its design questions are decided when the row comes up | [VISION.md](VISION.md) · [replay](design/replay-and-determinism.md) · [frame-phases](design/frame-phases.md) · [ai-first-api](design/ai-first-api.md) |
| KYR-9 | **The graphics library and the first renderer**: a standalone, Three.js-shaped package, `@kama/graphics`, on `@kama/gpu` (KYR-52), in its own repository (`cosmic-canopy/kama-graphics`; kama ruled it first-party as KR-309, closing KY-9), with meshes, materials, lights, a camera and loaders, that names no engine concept; and kyoten's render module, which binds components to it | [rendering.md](design/rendering.md) · [architecture](design/architecture.md) |
| KYR-10 | **Assets, first version**: glTF/GLB, KTX2 textures and WGSL, bundled on the web | [rendering.md](design/rendering.md) |
| KYR-11 | **Slice A in kyoten-fps**: a first-person camera moving over a level, on the web and native | [examples.md](design/examples.md) |
| KYR-12 | **Slice B**: the phases at their own rates, and a session recorded and replayed bit-identically, with one world hash on every leg. Its scene is where the default rates (research/rates.md) are first measured, and lowered wherever they still hold. It is also where parallel execution is first switched on, group by group, wherever a phase measures over budget, and where kama's pool (KY-12) is first needed (frame-phases question 7). It also measures components question 6's rule for the chunk size N, the cost of committing chunks as a table grows, and the footprint report | [examples.md](design/examples.md) · [replay](design/replay-and-determinism.md) · [rates](research/rates.md) |
| KYR-13 | **CI on every leg**: native on three OSes, wasm, and a headless browser leg for COOP/COEP and WebGPU | [web-and-native.md](design/web-and-native.md) |
| KYR-14 | **The hello cube**: the Three.js bar, written down as a number and met | [ai-first-api.md](design/ai-first-api.md) |
| KYR-25 | **Query support and MCP, built in, first version**: the engine and a running game as data an agent can ask, because AI is the engine's first consumer. The project database joins it with KYR-24 | [ai-first-api.md](design/ai-first-api.md) · [database](design/project-database.md) |

## AFTER THE GATE: what a shipping game needs

| id | item | detail |
|---|---|---|
| KYR-15 | **Audio, first version**: Web Audio and a native backend behind one interface | [audio.md](design/audio.md) |
| KYR-16 | **UI, first version**: HTML and CSS, as the DOM on the web and through `@kama/ui` natively | [web-and-native.md](design/web-and-native.md) |
| KYR-17 | **Physics in the Constraints phase**, and whether it is deterministic across platforms | [frame-phases.md](design/frame-phases.md) · [replay](design/replay-and-determinism.md) |
| KYR-56 | **Game AI, first version**: finite state machines and other deterministic procedural logic, as components in Update on the simulation clock, staggered per entity, playing through the same semantic actions as a player (KYR-54) | [frame-phases.md](design/frame-phases.md) · [VISION.md](VISION.md) |
| KYR-18 | **Netcode in the engine**: transports behind one interface, with lockstep (FFD) and snapshots with rollback (the-mallow-man) as patterns a game picks | [networking.md](design/networking.md) |
| KYR-45 | **The kyoten backend server**: open, and anyone may host it. A game reaches it the same way whoever runs it, so the platform's hosting is the easy option, never a lock-in | [networking.md](design/networking.md) |
| KYR-19 | **Steamworks as a feature package**: sign-in, achievements, the overlay, invites and Steam networking | [target-platforms.md](design/target-platforms.md) |
| KYR-20 | **Steam Deck**: the Linux build, the controller, and the Deck's own checks | [target-platforms.md](design/target-platforms.md) |
| KYR-21 | **Shipping a game**: release builds, crash reports, licence notices, and bundles for Steam on Windows, Linux and a notarized macOS, plus a web release | [target-platforms.md](design/target-platforms.md) |
| KYR-22 | **Parallel work inside a phase**: a job pool (kama's, or kyoten's until kama's lands), when a measurement asks for one | [frame-phases.md](design/frame-phases.md) |
| KYR-23 | **Live tuning and asset hot reload** | [ai-first-api.md](design/ai-first-api.md) · [tools](design/human-tools.md) |
| KYR-49 | **2D, as layers**: sprites, shapes, text and a 2D camera, rendered onto a screen layer (over a 3D scene or alone) or into a texture. For 2D games such as FFD's port, HUDs, and screens inside a 3D world | [rendering.md](design/rendering.md) · [examples](design/examples.md) |

## THE AI-DRIVEN LAYER: slice C

| id | item | detail |
|---|---|---|
| KYR-24 | **The project database and wiki, first version**: one per game project, so agents on separate machines keep one game direction. Typed records, consistency checks, live reload, and lookups through one abstraction whose sources stack by priority (on disk, DLC). As decided 2026-11-05 (question 11): field patches, named content layers each holding any number of prioritized sources, a stack resolved to one order, checks per source and over the stack, and the stack's identity in every save, replay and match | [project-database.md](design/project-database.md) |
| KYR-26 | **The human tool surface, first version**: a local web editor with the database's change feed, entities, timings per phase, and tuning that writes records | [human-tools.md](design/human-tools.md) |
| KYR-27 | **Replay as a tool**: scrub, step, and compare two runs | [replay-and-determinism.md](design/replay-and-determinism.md) |
| KYR-28 | **Slice C in kyoten-fps**: an agent builds and tunes a level through records while a human watches and adjusts | [examples.md](design/examples.md) |
| KYR-29 | **The content pipeline**: the kyoten adapter for cosmic-forge, shared ids and provenance, and a live preview. Heavy assets stay out of code repositories (the owner, 2026-11-05): source assets in a team's own store, built runtime assets hosted and fetched by a delivery tool that matches each asset build to the code that reads it ([SPIKE.md](SPIKE.md) § Standing direction) | [content-pipeline.md](design/content-pipeline.md) |
| KYR-30 | **Templates**: `kyoten new`, a game born wired to the frame and the project database | [ai-first-api.md](design/ai-first-api.md) |

## XR AND MOBILE

| id | item | detail |
|---|---|---|
| KYR-31 | **The XR package**: one interface (session, frame timing, views, poses, input sources) with WebXR and OpenXR backends. kyoten's to build: kama ruled XR out of its own packages (2026-11-02) | [xr.md](design/xr.md) |
| KYR-32 | **Android, Quest first**: the platform package on kama's Android target (kama's KR-280, shipped in 0.9.830; the app is KR-283, KY-2), Vulkan with OpenXR's extensions, and the lifecycle events kama delivers to `main`; `kama build` makes the signed APK (KR-283) | [xr.md](design/xr.md) · [platforms](design/target-platforms.md) |
| KYR-33 | **kyoten-vr on Quest**: the example, holding the headset's frame rate | [examples.md](design/examples.md) · [xr](design/xr.md) |
| KYR-34 | **iOS**: the platform package on kama's iOS target (KY-3), and Safari on the web route | [target-platforms.md](design/target-platforms.md) |

## SHOWCASE: shipped games on kyoten

The owner wants as many games running on kyoten as possible to showcase when it is ready to host games: the examples
(KYR-11, KYR-33, KYR-40) and these ports. A port starts only after its game has shipped on its own engine, and it
happens in that game's own repository, never here.

| id | item | detail |
|---|---|---|
| KYR-46 | **friendly-fire-department's simulation on kyoten's frame**, once FFD has shipped and slice B passes: its rounds reproduce FFD's pinned world hash on every leg. The engine's acceptance test against a shipped game | [architecture.md](design/architecture.md) |
| KYR-47 | **friendly-fire-department on kyoten, the whole game**: 2D (KYR-49), its UI, voice, lockstep netcode and Steam, on kyoten's packages | [architecture.md](design/architecture.md) · [examples](design/examples.md) |
| KYR-48 | **the-mallow-man on kyoten**, once it has shipped: 3D, physics, snapshot netcode and voice, on kyoten's packages | [architecture.md](design/architecture.md) · [examples](design/examples.md) |

## LATER

| id | item | detail |
|---|---|---|
| KYR-35 | **The DAW**: tracks, clips, a mixer and automation, editing records the runtime plays | [audio.md](design/audio.md) |
| KYR-36 | **Timeline and cinematic tools**, sharing a transport with the DAW. Also game-logic sequences for designers ("open door; wait 2 s; play sound; wait until the player enters"), written as records and generated into state-machine components over the simulation's deadlines, so they save, hash and roll back (frame-phases question 9) | [timeline.md](design/timeline.md) · [frame-phases.md](design/frame-phases.md) |
| KYR-37 | **The engine on the registry**: an example depends on a published version, with a local override for engine work | [architecture.md](design/architecture.md) |
| KYR-38 | **The engine version manager**, and example projects to start from | [version-manager.md](design/version-manager.md) |
| KYR-39 | **kyotenengine.com**: the home page, the docs and getting started, provisioned and deployed automatically. The docs are built from the repository's markdown, one source rendered and never copied, as kama-lang.org is built from kama's `docs/` (`tools/site/build.mjs`), with an `llms.txt` index for agents. [REFERENCE.md](REFERENCE.md) is the first page, and it is also built into a PDF (the owner, 2026-11-05) | [website.md](design/website.md) |
| KYR-40 | **More examples, each a different shape**: a 2D game, a racing game, a networked arena | [examples.md](design/examples.md) |
| KYR-41 | **Code hot reload**, on kama's hot-reload library, desktop first | [ai-first-api.md](design/ai-first-api.md) |
| KYR-57 | **LLM players**: a model playing against a player "where possible", as an outside clock like a remote player. Its semantic actions (KYR-54) enter at Input's hand-off and are recorded, so a replay needs no model. A likely shape: the model sets goals at its own pace and game AI (KYR-56) carries them out each step | [frame-phases.md](design/frame-phases.md) · [ai-first-api](design/ai-first-api.md) · [VISION.md](VISION.md) |
| KYR-60 | **Mods with code**: "code is content" (the owner, 2026-11-05), likely through kama's scripting when it lands (kama KR-35, *"dual-mode: compiled + scripting/REPL"*). A mod's script is a source in the mod layer, hashed into the stack like its data. Until then a mod is data only, adding what the build already has code for | [project-database.md](design/project-database.md) · [components.md](design/components.md) |

## FUTURE

| id | item | detail |
|---|---|---|
| KYR-42 | **Consoles**: Switch 2, Xbox and PlayStation, as private packages under NDA | [target-platforms.md](design/target-platforms.md) |
| KYR-43 | **Roblox and UEFN as export targets** | [target-platforms.md](design/target-platforms.md) |
| KYR-50 | **Generative worlds, on high-end machines**: a world generated and changed interactively while it is played, beside the traditional pipeline rather than in place of it. Prior art: Wizard (Tencent, NUS and NTU, 2026), where agents keep the game's explicit state and a video model renders it | [rendering.md](design/rendering.md) · [database](design/project-database.md) |

## ALONGSIDE: the platform, a separate product

The marketplace and its hosting are the owner's separate product: the easy button, never a lock-in. kyoten ships its
own backend server that anyone may host (KYR-45), and keeps one row for what the engine owes the platform, decided
before the engine's packaging settles (KYR-37).

| id | item | detail |
|---|---|---|
| KYR-44 | **What the engine owes the platform**: what a game and a content package are, the web deploy shape, and identity, all working the same with or without the platform | [marketplace.md](design/marketplace.md) |
