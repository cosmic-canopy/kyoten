# Easy for AI from day one, as quick as Three.js

**Status:** draft for the design spike. Three decisions are recorded, the latest revising question 1's target; the
rest are questions.

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
2. **One way to do each thing.** kama's own rule. How does the engine's API keep one obvious spelling per task,
   so an agent does not have to choose between three?
3. **Correct by construction.** Which mistakes can the API make impossible (wrong phase, a data race, a resource
   freed while the GPU uses it), rather than catching them in review? kama's ownership and lock windows are tools
   here.
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
