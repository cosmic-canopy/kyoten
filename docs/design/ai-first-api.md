# Easy for AI from day one, as quick as Three.js

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **Easy for AI to use from day one.**
- **Easy to use correctly, and high performance.**
- **As quick to prototype in as Three.js**, on web and native alike. Three.js became the quick, iterative
  environment for games on the web; kyoten wants that ease.

## What already exists

- kama is built for agents: `kama query --json` answers from what the compiler resolved, `kama stats`
  describes a project, and `kama agents install` ships the language's rules to every project
  (this repo's `AGENTS.md`). Mandatory named parameters make a call readable without its declaration. See
  [../research/kama-for-engines.md](../research/kama-for-engines.md).
- The peers record what an LLM gets wrong in kama (reserved words, the literal-typing rules) in their gap files and
  agent guides: see [../research/peer-games.md](../research/peer-games.md) § process and lessons.

## The questions

1. **What is the "hello cube"?** The smallest program that opens a window (or a canvas), draws a lit, spinning mesh
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
6. **Templates.** A `kyoten new` (or `kama seed`) that starts a game already wired to the engine, the frame model
   and the project database?
7. **Errors that say what to do.** kama's diagnostics name the fix. What does kyoten add on top for engine-level
   misuse?

## Decided

*(nothing yet — filled in during the walk-through)*
