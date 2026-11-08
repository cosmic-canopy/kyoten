# Easy for AI from day one, as quick as Three.js

**Status:** draft for the design spike. Questions 1–3 are decided (1 on 2026-11-05, its target revised on
2026-11-06 and 2026-11-07; 2 and 3 on 2026-11-07); 4–7 stay outside the spike, with their roadmap rows.

## What the vision asks

- **Easy for AI to use from day one.**
- **Easy to use correctly, and high performance.**
- **As quick to prototype in as Three.js**, on web and native alike. Three.js became the quick, iterative
  environment for games on the web; kyoten wants that ease.
- **AI drives the same inputs as humans** (the owner, 2026-11-04; [../VISION.md](../VISION.md)). The input system is an
  abstraction with universal rebinding, and an agent plays through its semantic actions, as a player does
  ([../ROADMAP.md](../ROADMAP.md) KYR-54).
  - **LLMs playing against a player**, "where possible" (the owner, 2026-11-04), go the same way. A model is an outside
    clock, like a remote player: its actions enter at Input's hand-off and are recorded, so a replay needs no model
    ([frame-phases.md](frame-phases.md) § Decided, question 3; KYR-57).

## What already exists

- kama is built for agents: `kama query --json` answers from what the compiler resolved, `kama stats`
  describes a project, and `kama agents install` ships the language's rules to every project
  (this repo's `AGENTS.md`). Mandatory named parameters make a call readable without its declaration. See
  [../research/kama-for-engines.md](../research/kama-for-engines.md).
- The peers record what an LLM gets wrong in kama (reserved words, the literal-typing rules) in their gap files and
  agent guides: see [../research/peer-games.md](../research/peer-games.md) § process and lessons.
- **The bar, counted** ([../research/component-models.md](../research/component-models.md) § 2): Three.js's spinning
  cube is 25 lines (17 non-blank), 54 lit; Bevy's `3d_rotation` is 55; Godot's first script is 4, because the editor
  holds the scene.

## The questions

1. **What is the "hello cube"?** *(Decided 2026-11-05 with components question 7, below.)* The smallest program that opens a window (or a canvas), draws a lit, spinning mesh
   and reads input, on web and native. How many lines, and which concepts must a newcomer, human or agent, meet
   first? Three.js's answer is about 20 lines; kyoten's target should be written down.
2. **One way to do each thing.** *(Decided 2026-11-07, below.)* kama's own rule. How does the engine's API keep one
   obvious spelling per task, so an agent does not have to choose between three?
3. **Correct by construction.** *(Decided 2026-11-07, below.)* Which mistakes can the API make impossible (wrong phase,
   a data race, a resource freed while the GPU uses it), rather than catching them in review? kama's ownership and lock
   windows are tools here.
4. **Discoverable by an agent.** The API surface as data: `kama query` over the engine, generated reference docs,
   a schema for project-database records ([project-database.md](project-database.md)), examples that compile in CI.
5. **The iteration loop.** Edit, see the change: hot reload of tuning and assets, and of code (kama's hot-reload
   library is on its roadmap; see the kama research). How short can the loop be on web?
   - *Noted 2026-11-05, the owner:* hot reload must be good, since every change to a record's schema regenerates the
     world (components question 3's risk). kama also plans its own scripting in the same syntax: "Kama also eventually
     wants to have it's own REPL scripting system in the same syntax so developers can output scripts during
     development and compile for production or keep a hybrid approach." That is kama's 2.0, *"dual-mode: compiled +
     scripting/REPL"* (kama KR-35, `docs/ROADMAP_DETAIL.md` § 7). A system body is plain kama, so the same body could
     run as a script while a game is developed and be compiled when it ships.
6. **Templates.** A `kyoten new` (or `kama seed`) that starts a game already wired to the engine, the frame model
   and the project database?
7. **Errors that say what to do.** kama's diagnostics name the fix. What does kyoten add on top for engine-level
   misuse?

## Decided

- **2026-11-01, the owner: the engine's first consumer is AI.** kama is opinionated, strict and AI-friendly, and kyoten
  carries the same mentality. **Query support and MCP are built in**, not added later.
  - **What it settles:** the shape of question 4. The engine's API, and a running game, are data an agent can ask
    through query and MCP. Which questions and tools they answer, and how they sit beside `kama query`, stay open.
  - **On the roadmap:** KYR-25 moves into the first slice, so the first consumer can use the engine from its first
    version. The project database joins it with KYR-24.

- **2026-11-05, the owner: question 1, the hello cube, decided with components question 7 and rendering question 3.**
  "All in all I think I agree on all." The sketch, its probes, the reasons and what was considered are in
  [components.md](components.md) § Decided, question 7.
  - **The target:** a lit, spinning cube that reads input, on web and native, in at most 20 non-blank lines across all
    its files (records and kama), with seven concepts: app, record, zone, prefab, component, system and action.
    Three.js takes 35 non-blank lines lit, with about eleven concepts, and reads no input. *(Eight concepts since
    2026-11-06, below.)*
  - **Its shape:** records plus one system. Defaults are engine records, actions are generated fields, and bindings
    are records of their own, so a bot or an agent drives the same action a key does.
  - **How it is kept:** an example built and run in CI on web and native, whose line count fails CI when it grows
    (KYR-14).
  - **One way to do a thing, for what agents write.** The owner: it "is mostly a kama GOAL, but yes it does make sense
    to apply to systems that AI will be writing so we always prefer the BEST solution for something". This bears on
    question 2.

- **2026-11-06, the owner: question 1's target revised** with components question 7's hello cube. Actions belong to a
  player rather than the world, so the cube names the player that drives it, and a scene places it instead of a start
  zone. The concepts are now eight: app, record, scene, prefab, component, system, action and player. The 20-line
  limit is unchanged. The reasons and the probe are in [components.md](components.md) § Decided, 2026-11-06.

- **2026-11-07, the owner on the target, with components question 8 part b:** "The 20-line target is obviously
  arbitrary but probably a good gauge. It shouldn't limit our designs though." The hello cube in the record files
  decided there is 15 non-blank lines across five files, counting its imports and export
  ([../REFERENCE.md](../REFERENCE.md) § The hello cube).
  - **How CI holds it (KYR-14):** CI still fails when the count grows, and the number may be raised, with the reason
    in the commit that raises it. The owner: "yes your recommendation. It points to a decision that needs to be
    made."
- **2026-11-07, the owner: questions 2 and 3.** "Everything else sounds good so far", and on item 5: "Is the
  importsOnly kama gap a general systems language concept? if so feel free to file the gap." It is (item 5), so it is
  filed as KY-37.
  1. **Question 2: a table of one way per task is part of the engine's API.** It is kept in
     [../REFERENCE.md](../REFERENCE.md) § One way to do each thing, ships in every game's agent guide (KYR-30), and
     every row has an example that compiles in CI (KYR-13), so it cannot drift from the engine. Nearly every row was
     decided earlier:

     | Task | The one way |
     |---|---|
     | Put something in the world when a zone loads | a placement in the zone's record |
     | Define a kind of thing | a prefab record; a variant starts `from` another |
     | Create one while the game runs | `Create<P>` |
     | Change another entity | send it a component, `Send<C>` |
     | Read another entity | a lookup, in one of the two read modes |
     | Read input | the `Actions` component, with bindings in records |
     | Read time | the `Time` world component |
     | Use randomness | a random key the processor's record lists |
     | Draw something | `Mesh` and `Material` on the entity |
     | Give it a custom look | a material graph, or WGSL where nodes are not enough |
     | Add UI | an HTML document, bound to values and actions |
     | Tune a number | a record field, never a constant in code |
     | Meet a platform difference | a capability, never a platform's name |

  2. **Question 2: two spellings only when they are two views of one thing,** such as a record and the kama builder
     that makes the same record (a material), or a record and its generated name. Never two APIs for one job, such as
     a `spawn()` beside `Create<P>`. The docs teach the record first.
  3. **Question 2: the table is a ratchet.** A second way to do a row is a decision recorded with its reason, as the
     hello cube's line count and the web's size are.
  4. **Question 3: each mistake has a mechanism that stops it before review sees it.** Most were decided earlier:

     | Mistake | What stops it | When |
     |---|---|---|
     | Output writing the simulation | Output's access is `const ref`, and its own state is `"output": true` | compile |
     | A data race between parallel processors | access stated in signatures; a parallel group is a `scope` | compile |
     | A typo in an action, prefab, placed name, binding, UI binding or wiki link | generated names, and checked references | compile or check |
     | A stale entity handle | the handle's generation: a lookup answers "gone", never another entity | run |
     | Floats that differ across machines | `reproducible-float`, which the engine declares | build |
     | A field no type declares | strict decoding of every record | check |
     | A budget overrun | budgets, with a defined `whenFull` | run |
     | Mixed number types, or an overflow | kama: no implicit conversion, and overflow traps | compile, debug |
     | A GPU resource freed while the GPU uses it | `@kama/gpu`'s RAII handles, with no raw destroy *(to verify against `webgpu.h`'s lifetime rules, KYR-52)* | compile |
     | The simulation reading the outside world | the simulation-files import check (item 5) | check |
     | A silent divergence | the replay tripwires and the per-step hash | debug runs, CI |

  5. **Question 3: the simulation cannot reach the outside world.** kyoten's import check (KYR-53) refuses std's `time`,
     `fs`, `net`, `process`, `io`, `concurrent`, `uuid` and `random` in any file that defines an Input, Update or
     Constraints processor; a file of Output processors may use them. It is per file because a module mixes phases,
     and kama's visibility is per file too. Outside data enters only through Input's recorded hand-off, and `random`
     is refused because random keys are the one way.
     - **Why kyoten's own check:** *probed on kama 0.9.873* (`0.9.873+g7c0a6bd0`), a module declared
       `{ "visibility": "internal", "importsOnly": [] }` imported `std::time::unixNow` and called it, and `kama check`
       reported *"kama.json OK (4 units analyzed)"*. `importsOnly` restricts a module's imports from its own package
       only (kama `docs/packages.md`: *"Another package is `dependencies`' business and is never listed"*).
     - **Filed as KY-37,** since a compiler that holds the rule holds it in every build. Keeping code from parts of
       the standard library is a general systems-language concept *(general knowledge, not checked against each)*:
       Rust's `#![no_std]`, Java's `requires` in `module-info`, and linters such as Go's depguard and .NET's
       BannedApiAnalyzers. Its uses are determinism (simulations, replays, workflow engines), code with no operating
       system (kama's `EMBEDDED` target and `--no-heap`), and sandboxing or layering.
     - **KY-37 was fixed on 2026-11-07** (kama KR-344, `546dd54e`, 0.9.875): `importsOnly` holds every import, std's,
       `core`'s and other packages' included, and the probe above is now refused, naming the entry to add. The rule
       here is per file, and `importsOnly` is per module, so whether the rule moves into the modules' manifests is
       not decided here; it is asked when KYR-53 (the first slice's step 6) starts.
