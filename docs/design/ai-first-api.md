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
     | The simulation reading the outside world | the simulation modules' `importsOnly` (item 5, moved there 2026-11-08), and kyoten's check of those lists | compile, check |
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
     - **2026-11-08, the owner: the rule moves into `importsOnly`, a module fence, and `core::env` joins the list**
       (KYR-53, step 6's question). The owner chose "Module fence" and "Yes, refuse core::env".
       - **The rule now:**
         - A **simulation module** holds Input, Update or Constraints processors and the code they call.
         - Its `importsOnly` names none of std's `time`, `fs`, `net`, `process`, `io`, `concurrent`, `uuid` or
           `random`, nor `core::env`.
         - Of its own package's modules, it names only other simulation modules.
         - Output processors, and outside work such as sockets and files, sit in modules of their own.
         - The compiler holds the rule in every build and in the editor, for engine modules and games alike.
       - **Why: it closes the hole the per-file rule leaves.** Probed on kama 0.9.876 (`+g1a969a1e`, `.scratch/kyr53`):
         - **The helper.** A helper in another file of a simulation module imported `std::time`. The module refused
           it: *"module `std::time` is not in the `importsOnly` of `game`"*. A per-file rule passes that file, because
           it defines no processor, so a processor calling the helper would read the clock unseen.
         - **Output.** An Output module beside it (`game::present`) read the clock freely.
         - **No way around.** The simulation module could not import `present` to reach the clock through it:
           *"module `game::present` is not in the `importsOnly` of `game`"*.
         - **Games too.** A game's module can list another package's tier (`eng::frame`).
       - **Why `core::env`:** KR-344 moved the environment and the command line there, and they are outside data like
         the clock. `core` and `core::env` fence separately. Probed: with `core` listed, `println` is allowed and
         `core::env::envOr` is refused. A setting reaches the simulation as a record, or through Input's recorded
         hand-off.
       - **What it costs:** simulation and Output code are split by folder.
         - **A game:** the root module can be its simulation module. The hello cube's processor and its two-line
           `main` both fit there, so the cube's line count does not change. `kyoten new` writes the layout and the
           lists (KYR-30). *(Corrected on 2026-11-08, below: `main` imports `run`, which is outside, so the root
           module is the app's and the cube moves to a module folder.)*
         - **An engine module that works in several phases splits:** a fenced part holds its simulation processors,
           and an outside part does the work that stages for them. Net's Input processor is fenced, and its sockets
           are not. This matches frame-phases question 1: work runs at any time, and reaches the simulation only at
           its phase's hand-off.
         - **The generated code splits too:** what the simulation imports (the world, `Actions`) goes in a fenced
           module, and `run` goes outside (step 5). *(Corrected on 2026-11-09, below: the world, its tables and
           passes run Output too, so they go outside with `run`. The fenced module holds `Actions` and the prefab
           types.)*
       - **kyoten's check (KYR-53) reads manifests and code records, not source:**
         - every module holding an Input, Update or Constraints processor has an `importsOnly`;
         - that list names none of the refused modules;
         - of its own package's modules, it names only other simulation modules, so the fence holds through every
           module it can reach.
       - **Considered:**
         - the per-file rule as first decided, held by the generator. It imposes no layout, but it holds only when the
           generator runs, not in `kama check` or the editor, and it misses helpers in other files;
         - both rules at once, which is two ways to say one thing.
     - **2026-11-08, the owner: `main` sits in the app's root module, outside the fence, and simulation code in module
       folders** (the first slice's step 5, question 1 of 7). "Everything sounds good so far."
       - **Why it was asked:** the decision above put the hello cube's `main` in its root module and made that module
         its simulation module, while `main` imports `run`, which sits outside. kyoten's check refuses a simulation
         module that names an outside module of its own package, so the two could not both hold.
       - **The layout:**
         - **The root module is the app's.** It holds `main` and has no `importsOnly`, since nothing in it runs in a
           simulation phase. The check refuses a processor in a module without one, so a processor cannot hide there.
           *(Since 2026-11-10 a processor or a component record in a game's root is refused even with a list, since
           the tool's query leaves the root out: components § Decided, KY-49's answer.)*
         - **The generated `run` is written beside `main`,** as `src/<game>.generated.kama`, by the naming rule (a
           module's generated names go into that module), so `main` reads `import { run };`. `run` is built at step 7.
         - **Simulation code lives in module folders,** as REFERENCE's towers layout already had it. The hello cube's
           `cube.kama` and `cube.records.json` move to `src/cube/`, module `hello::cube`, and the cube's line count
           stays 15.
         - **`<game>::generated` (`src/generated/`) is fenced:** the world, the tables, the passes, `Actions` and
           `Prefabs`, which the simulation imports. *(Since 2026-11-09 it holds `Actions`, the prefab types and
           `Prefabs`. The world, the tables and the passes are in the root module: components § Decided.)*
       - **Why it is the production answer:** the compiler holds the fence in every build and in the editor, and the
         check holds the rest. Nothing a processor can reach imports the clock, and the app's code, which must reach
         the outside world to run a loop, is in the one place the fence does not cover and no processor may sit.
       - **Probed on kama `0.9.876+g7ce86d36`** (`.scratch/step5-main`): an engine with `eng::frame` (`Time`, the
         `World` contract and `step`); a game whose root holds `main` and a hand-written `run` that reads `std::time`;
         a fenced `cube` (`"importsOnly": ["eng::frame", "generated"]`) and a fenced `generated`
         (`["eng::frame", "cube"]`), importing each other.
         - `kama check` passed, and the game printed `rate after 4 steps: 2` natively and on wasm under node.
         - In `cube`, `std::time` is refused: *"module `std::time` is not in the `importsOnly` of `hello::cube`"*.
         - In `cube`, the app's `run` is refused: *"module `hello` is not in the `importsOnly` of `hello::cube` …
           Add "." there if this edge is meant"*.
         - An `importsOnly` names its own package's modules as the `modules` map spells them (`"generated"`), and
           kama refuses the full path (`"hello::generated"`), naming the rule.
       - **Considered:**
         - **The generator writing `main`,** so a game has none. Nothing was wrong with it, and either holds the fence.
           It was kept out because the game owns `main` and calls `run` (architecture question 4, 2026-11-02,
           which considered the engine owning `main` through a generated shim), and target-platforms question 2 kept
           that `main` at two lines. The entry point stays in the game's source, the app keeps a place for its own
           code before the loop, and the manifest's `entry` never names a git-ignored file. kyoten still
           controls everything behind `run`. Revisiting it changes no step 5 code, since `run` comes at step 7.
         - `run` in a second generated module (`src/generated/app/`): a longer import, and another manifest entry.
     - **2026-11-09, the owner: kyoten's check judges each entry of a simulation module's list by what may be used,
       across packages** (the first slice's step 6, KYR-53, question 2 of 4; the other three are in components,
       target-platforms and architecture § Decided). The owner: "'may not use these' is not correct... 'may use only
       these' is more explicit."
       - **What was wrong:** kama's `importsOnly` is an allow-list, and kama holds each module to the list its author
         wrote, which is right. What a simulation module's list may contain is kyoten's rule. As decided on 2026-11-08,
         the check refused only the nine named modules, so anything else on a list passed it, and kama then honoured
         the list as written:
         - **std's other outside modules:** `std::asset` reads files and the environment, `std::archive` reads files
           and the clock, and `std::app` runs the host's loop. None of them was among the nine.
         - **another package's outside module:** `kyoten::content`, the loader, lists `std::fs`, and a game's
           simulation module could list `kyoten::content`. kama's fence governs a module's own imports only, so it
           never looks at what `kyoten::content` imports.
         - **How it arose:** the rule was first written per file, on 0.9.873, when `importsOnly` did not reach std
           (KY-37), so the check had to name what to refuse. The move into `importsOnly` on 2026-11-08 kept that
           wording.
       - **The rule now: a module is *fenced*** when it has an `importsOnly` and every entry is one of these:
         - one of std's pure modules (below), or a module under one;
         - `core`, but not `core::env`;
         - a fenced module of its own package;
         - a fenced module of another package, judged from that package's `kama.json`.

         Every module holding an Input, Update or Constraints processor is fenced. Fenced modules that import each
         other (`cube` and `generated`) are fine, because the check takes the largest set that holds. The rule fails
         closed: a module std adds later is refused until the list names it.
       - **std's pure modules,** each one's import blocks and C functions read on the pin (`0.9.899+gf32373ea`):
         - **Allowed:** `math`, `num`, `collections`, `memory`, `ascii`, `unicode`, `fmt`, `digest` and `encoding`.
           Each computes from its arguments. Their C functions are libm's (musl's, through `reproducible-float`),
           `memcpy`, the reference counts, Unicode normalization, number formatting and parsing, UTF-8 validation,
           and a constant-time compare.
         - **Left out:**
           - `time`, the clock;
           - `fs`, `net`, `process` and `io`, which are files, sockets, processes and streams to the outside;
           - `concurrent`, which is threads and the clock;
           - `uuid` and `random`, which use entropy (random keys are the one way);
           - `app`, the host's loop;
           - `asset`, which is files and `core::env`;
           - `archive`, which is files and the clock;
           - `path`, the host's path conventions;
           - `compress` and `serialization`, which are built on io's streams;
           - `ptr`, raw memory, which is FFI's tool;
           - `log`: its calls only write, as `core`'s `println` does, but its exported `logEnabled` reads the level
             that `--log` and `KAMA_LOG` set, so a processor could branch on the environment.
       - **Why it is kyoten's fix, not kama's:** kama's fence does what it says. std carries no `importsOnly` of its
         own, which is why kyoten keeps the pure list. Nothing was asked of kama.
       - **Considered:**
         - a longer deny-list, adding `asset`, `archive`, `path`, `app` and `encoding`. It fails open when std grows;
         - the rule as decided, with both leaks recorded.
     - **2026-11-09, built: the check** (the first slice's step 6, KYR-53; `tools/kyoten/src/fence.kama`), test-first on
       kyoten's pin, `0.9.899+gf32373ea`, together with the tiers (architecture § Decided) and the platform flags
       (target-platforms § Decided).
       - **Where it runs:**
         - `kyoten generate`, which `check`, `build` and `run` begin with, holds a game's lists after its records are
           read and before kama is asked anything, so a refusal writes nothing.
         - `kyoten check <library kama.json>` holds the engine's lists, then runs `kama check`. The tool's other
           commands refuse a library by name.
         - `tools/test.sh` runs it on the engine.
       - **How:**
         - The tool reads each package's `kama.json`: the game's, and each dependency's through every level.
         - It keeps the largest set of modules whose every entry is allowed, so modules that import each other, as a
           game's `cube` and `generated` do, are fenced together.
         - A processor's phase is its own or its group's. A processor whose group is not found counts as the
           simulation's.
         - A refusal names the module as `modules` spells it, the processor that makes it the simulation's, and the
           entry, followed along the chain when it is indirect: *module "deep" holds the Update processor `e`, so it
           is fenced from the outside world, and it names `helper`, which is not fenced: `fence::helper` names
           `std::time`, which is not one of std's pure modules*.
       - **Tested** by the tool's `fence` fixture.
         - Refused in one run:
           - `std::asset`;
           - `kyoten::content`, whose list names `std::fs`;
           - a module of its own with no list;
           - a simulation module with no list;
           - `std::time` reached through a module of its own;
           - `core::env`;
           - `std::random` in a Constraints group;
           - a processor in the root module (since 2026-11-10 by the records check, even with a list).
         - Not refused:
           - an Output module that reads the clock;
           - a module with no processors;
           - two simulation modules that name each other and `std::math`, `std::num`, `std::collections`, `core`,
             `kyoten::frame`, `kyoten::world`, `glow` and `generated`.
       - **Mutations caught:**
         - `std::asset` admitted to the pure list;
         - another package's module taken as fenced;
         - one pass instead of the fixed point;
         - a module with no list kept in the fence;
         - a processor's group ignored.
       - **Not done:** the row's `--json` is KYR-67, for every refusal the tool makes.
