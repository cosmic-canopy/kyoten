# Components: how a game holds state and behaviour

**Status:** question 1 decided on 2026-11-05: B built on A, with a table of chunks per (zone, prefab) and side stores
for components gained at run time. Questions 2–8 are open.

## What the vision asks

- **A general-purpose, component-based architecture.** Component-driven is the ideal.
- **Clean patterns each game uses**; the engine does not hard-code game systems.
- **Easy to use correctly, and high performance**, across parallel phases ([frame-phases.md](frame-phases.md)).
- **Learn from Unity's growth** (the owner, 2026-11-01). Unity succeeded, and grew in phases, from its component-based
  design. kyoten takes different approaches but can learn from that model. KYR-3 is the research.
- **Start from the peers' code, and move toward generic and component-driven** (the owner, 2026-11-01;
  [architecture.md](architecture.md) § Decided).
- **Generic up front, with strong abstractions for the systems and phases** (the owner, 2026-11-02; architecture.md
  question 1): "each phase has its own components that can be written", likened to Unity's generic scene graph with
  MonoBehaviours composed on it per game, "and there may be some lessons we learn from that NOT to do". The aim is "as
  optimal as possible while being flexible and generic".
- **Every game type**, with an FPS likely the first, and "on par or better than Godot, Unity, or Unreal" (the owner,
  2026-11-04; [../VISION.md](../VISION.md)). KYR-58 stress-tested the model against each kind of game before question
  1 ([../research/game-types.md](../research/game-types.md), below).
- **Parallel work proven by the compiler** ([frame-phases.md](frame-phases.md) § Decided, question 6, 2026-11-04).
  Component types are then known at build time, so question 1 is between options A and B. **The owner's leaning**
  (2026-11-04): "B built on A with C internal storage when possible", meaning a world generated from records, whose
  generated code is A's, with ECS-shaped storage (chunks) inside it. It became question 1's decision (2026-11-05,
  *Decided*).
- **Budgets per element, per zone** (the owner, 2026-11-04; [../VISION.md](../VISION.md)): "each zone of a level can
  only have N number of X creatures and N number of bullets in flight", so a runtime footprint can be calculated and
  allocated up front, or at least in very controlled steps. This is input to question 6.
  - **Where machines simulate together, the budget matches** (the owner, 2026-11-04, on KYR-58's G1): "I agree that
    multiplayer would have to match the budget... I would assume that can be negotiated during matchmaking if needed."

## What already exists

- **Neither peer has an ECS** ([../research/peer-games.md](../research/peer-games.md) § 3).
  - **friendly-fire-department:** one `sim::World` resource, dense fixed-capacity arrays (`FixedArray`,
    `InlineArray`), systems as index-order loops in the phase methods. The order is the RNG stream, so it is a rule.
    No event lists in the world, because every field is hashed and serialized.
  - **the-mallow-man:** one plain-data `Round` value with pooled arrays and counts. Presentation reads it as
    `const ref`. Physics objects are plain-data handles (`BodyId`) owned by one `PhysicsWorld`.
  - **What hurt:** large values on the stack (a 205,880 B frame in the-mallow-man, the 64 KB wasm stack in FFD), and
    per-file visibility that kept one game's round lifecycle in an 11,108-line file.
- **kama's building blocks** ([../research/kama-for-engines.md](../research/kama-for-engines.md)): `SlotMap`,
  `DynamicArray`, `View`, contract bounds that monomorphize to direct calls, `@generate(Serializable)`. **No capturing
  closures** (a system is a functor contract: a resource implementing a contract), no overloading or default
  parameters, and module statics are per isolate. `scope` proves disjoint `ref` field borrows, which is what can make a
  phase's parallel work compiler-checked.
- **KYR-3's comparison** ([../research/component-models.md](../research/component-models.md)): Unity's phases and its
  peers, probes of kama 0.9.803, one subsection of its § 5 per question here, and three coherent options (A, a typed
  world with written phases; B, that world generated from project-database records; C, an engine-owned archetype ECS).
  Two of its probes became kama gaps: KY-4 (a `SlotMap` reloaded through serde reuses slots in a different order;
  fixed in kama 0.9.809) and KY-5 (two `spawn`s cannot share a read-only borrow).
- **KYR-58's stress test** ([../research/game-types.md](../research/game-types.md), 2026-11-04): thirteen kinds of
  game, from the FPS to rhythm games, run on paper against the decided frame model, options A and B with chunk
  storage, and per-zone budgets.
  - **No kind was found that the model cannot express.** The conditions gather into fourteen findings, G1–G14.
  - **For question 1:** A and B are the same at run time, and authoring scale favours B (G2, G11). Chunk storage per
    (zone, prefab), at budget capacity, joins budgets, snapshots and kama's data-parallel proof (G3, G7, G14). It
    still needs an answer for adding a component at run time.
  - **For question 2:** components are plain values, so a world can be copied and restored (G3), and some keep a
    declared history deeper than interpolation's two samples (G4).
  - **For question 6:**
    - a simulation budget is a game rule, and Output's budgets vary per machine (G1);
    - budgets are data, kept per scope (a zone, a player, a match), with a stated rule for when one is full (G2);
    - a zone is the unit of loading, budgets and coordinates (G7).
  - **Probed on 0.9.845:** stores sized at start-up in one `Arena`, then a `@noheap` step and a `@noheap` snapshot into
    a second block. It ran.

## The questions

1. **ECS, or not?** *(Decided 2026-11-05, below.)* Archetype ECS (entities as ids, components in per-archetype
   tables, queries), sparse-set ECS, or FFD's shape (one owner of dense arrays, systems as ordered methods) made
   general. Which gives the vision's "component-based" with the least machinery and the best fit to kama (no closures,
   contract bounds, `scope`'s disjointness proof)?
2. **What is a component?** A plain `type value` (copyable, serializable, hashable field by field), always? How does a
   component that owns memory (a mesh, a path) fit?
3. **What is a system?** A functor contract (`implements System`) with a phase and a rate, registered by the game? How
   does it declare what it reads and writes, so the scheduler can run disjoint systems in parallel and kama can check
   it?
4. **Determinism.** Iteration order is part of the simulation (FFD). Does the component store guarantee a stable,
   specified order?
5. **Records and components.** A project-database record ([project-database.md](project-database.md)) defines an
   entity or prefab: is there a one-to-one mapping from record schema to component type, generated by serde?
6. **Scale and storage.** Fixed capacities (FFD, the-mallow-man: predictable, `@noheap`-friendly) or growable stores?
   How are large components kept off the stack (the KM-29 lesson)?
7. **The prototype path.** A Three.js-style prototype wants "make a cube, give it a spin". What is the shortest correct
   spelling in the component model ([ai-first-api.md](ai-first-api.md))?
8. **Growing in phases.** Unity's component model grew in phases (KYR-3). Which parts of kyoten's model must be right
   on day one, because changing them later would break every game, and which can arrive later without that?

## Decided

- **2026-11-05, the owner: B built on A, with a table of chunks per (zone, prefab) and side stores for components
  gained at run time (question 1).** The owner's leaning was "B built on A with C internal storage when possible"
  (2026-11-04). The recommendation made it concrete, and the owner took it: "Yes I like your recommendation so far".
  - **The world is generated from records, as code a person could write.**
    - Records declare the components, the prefabs and the systems. A kyoten generator writes the world type, its stores
      and its phase methods as plain kama (option A's code), which the compiler checks like any other.
    - **The game writes system bodies, and a body's signature is its stated access.**
      `fn void integrate(ref Pos p, const ref Vel v, float32 dt)` writes `Pos` and reads `Vel`. The generator runs it
      on every prefab that has both. The match is made at build time, so there is no run-time query matching and no
      type erasure.
    - **A game may write a store or a system by hand** beside the generated ones (a voxel grid, say), as under A.
  - **From option C it takes the storage, not the run time.** Each prefab is an archetype, fixed when the game is
    built. There is no component registry, and no run-time queries or scheduler: frame-phases question 6 ruled those
    out. In C, giving an entity a component moves it to another archetype's table. Here a prefab's table never changes
    shape, so a component gained at run time lives in a side store.
  - **A table** holds one prefab in one zone. It is the budget ÷ N chunks, rounded up, allocated once when the zone
    loads and never grown.
  - **A chunk** is a plain value holding up to N entities of that prefab: one array per component, plus a count of
    live entities, packed at the front.
    - **It is the unit of three things:** parallel work (a worker takes whole chunks), a snapshot (a copy of the
      chunks, G3) and a budget (a zone's soldier budget is a number of chunks, G2 and G7).
    - **An entity's handle reaches it through a lookup** (handle → table, chunk, slot), because removing an entity can
      move another one within its chunk.
  - **A side store** holds one component type that an entity of any prefab can gain or lose while running: Burning,
    Stunned, a quest marker.
    - It is a sparse set: the values packed together, each with its owner's handle, plus an index from handle to slot.
      Its capacity is its own budget.
    - **A system over the side store alone** (ticking down Burning's timer) runs in parallel over its packed values.
    - **A system that writes a table through a side store's handles runs serially.** Burning writing the soldier's
      `Hp` reaches the soldier through its handle, and kama cannot prove those writes land on different soldiers (the
      family of [../KAMA_GAPS.md](../KAMA_GAPS.md) KY-15). The other spelling writes a damage store, which a later
      system over the table applies in parallel.
  - **Later, without breaking games: a flag column.** A prefab that knows it may gain a component can hold it as a
    column in its chunk with an on/off flag. These are Unity's enableable components, which "don't create structural
    changes", count as absent while off, and are "ideal for states that you expect to change often and unpredictably"
    ([manual](https://docs.unity3d.com/Packages/com.unity.entities@1.0/manual/components-enableable-intro.html)). Its
    work stays parallel, at the cost of memory in every chunk. It would be a per-component choice in the records, as
    Bevy's storage is. System bodies do not change, so it can arrive later.
  - **The evidence: probes on kama 0.9.845, re-run on 0.9.850.**
    - **Across the chunks of one table:** `parallel_for (ref SoldierChunk c in this.chunks, workers: cpuCount())`,
      with the chunk a `type value` whose columns are `InlineArray<Pos>#(128)` and so on. It checks.
    - **Across tables:** one task per table in a `scope` (soldiers and crates). It checks. One soldier stepped twice by
      0.5 moved from 0 to 2.0 and regenerated to `hp` 2, and `kama run` exited 0.
    - **Not across two systems of one table.** Two spawns on `this.soldiers`, for systems over different components,
      are refused: *"two children in this `scope` borrow overlapping places (`this.soldiers` and `this.soldiers`)"*.
      So the generator fuses the systems that do not conflict into one pass per chunk, and the parallel work comes from
      the chunks. In Unity a job over several components is written as one by hand. Here the generator does it.
    - **A snapshot copies the chunks**, as values.
    - **KY-13 stays out of sight.** A spawn takes one argument, so the step's `dt` rides in the generated table.
    - **An arena-backed table can be split with `parallel_for` but not handed to a task**, because
      `BumpAllocator` is not `Sendable` (KY-17, filed 2026-11-04, on 0.9.850). Until kama closes it, each table takes
      one allocation when its zone loads, which still keeps allocation up front and controlled.
  - **Precedent: every piece exists elsewhere.**
    - **Prefab tables of fixed-size chunks:** Unity Entities' archetype chunks are 16 KiB, holding at most 128
      entities
      ([archetypes](https://docs.unity3d.com/Packages/com.unity.entities%401.4/manual/concepts-archetypes.html)),
      and Unreal Mass sets a chunk size per archetype
      ([Mass](https://dev.epicgames.com/documentation/unreal-engine/overview-of-mass-entity-in-unreal-engine)).
    - **Archetypes fixed at build time, with fixed capacity:** gecs (Rust, 0.3.0) needs "all archetypes to be known and
      declared at compile-time", "precompiles all queries", and with fixed capacities "will perform zero allocations
      after startup". Its stated limit is the one side stores answer: "adding or removing components from entities at
      runtime isn't currently possible" ([README](https://docs.rs/crate/gecs/latest/source/README.md)).
    - **The loop generated from a system's signature:** in Unity, an `IJobEntity` whose `Execute(ref A, in B)` takes
      `ref` for read-write and `in` for read-only triggers source generation of a chunk job, with its query inferred
      from the parameters
      ([IJobEntity](https://docs.unity.com/en-us/engine/7000.0/script-reference/unity/entities/ijobentity.md)).
    - **Side stores beside tables:** Bevy stores components in tables by default, with an opt-in sparse set per
      component that gives "fast addition and removal of components, but slower iteration"
      ([StorageType](https://docs.rs/bevy/0.13.1/bevy/ecs/component/enum.StorageType.html)).
    - **A schedule built at compile time from declared access:** ecst (C++14, experimental, shown at C++Now 2016)
      builds its dependency graph at compile time from each system's declared reads and writes. It has the probe's
      two kinds of parallel work, systems side by side and one system split across threads
      ([ecst](https://www.github.com/vittorioromeo/ecst)).
    - **What kyoten adds is the compiler's check of the access.** Unity, Bevy, flecs, Mass and EnTT check it at run time
      or not at all ([../research/component-models.md](../research/component-models.md)). ecst is the nearest, and
      whether it holds a system's body to its declaration was not checked.
  - **What it costs:**
    - a generator to build and keep, and a build step on every schema change;
    - errors in generated code, which the generator must map back to the records that caused them;
    - the generator's output becomes a day-one commitment (question 8);
    - a new component type needs a rebuild, until KY-14 (a typed way back from an erased store) and KY-15 (parts of a
      container chosen at run time) close;
    - the handle's lookup, and the serial rule for systems that write tables through side stores.
  - **Left to the later questions:**
    - **question 2:** what a component may hold, and how one that owns memory fits;
    - **question 3:** how a system declares its phase, rate and access in its record, and how a system over a side store
      states its access;
    - **question 4:** removal inside a chunk (swap-and-pop moves the last entity into the gap, so order changes; a
      tombstone leaves a hole) and the order a side store is iterated in;
    - **question 5:** how records map to components, prefabs and systems, beside project-database question 11;
    - **question 6:**
      - N, as a count like 128 or a byte size like Unity's 16 KiB;
      - side-store capacities, and what happens when a store is full;
      - the matched budgets of a match (G1, the owner's matchmaking note);
      - chunks kept in their table's heap block, never on the stack (the KM-29 lesson);
    - **question 7:** the shortest prototype on this shape;
    - **question 8:** the handle's form, and which parts of the generated output are a day-one commitment.
  - **Considered:**
    - **A, written by hand.** It has the least machinery. But the world and its phase methods grow with every component,
      and per-file visibility pushes them into one file (FFD's 11,108 lines). And there are no records for agents to
      edit.
    - **B on A, with one sparse store per component type** (EnTT's shape, and KYR-3's `Store<T>`). Adding a component
      at run time is easy everywhere. But data-parallel work over two components cannot be proven (KY-15), and a budget
      maps to a component type rather than to a (zone, prefab).
    - **C, an engine-owned archetype ECS.** Ruled out by frame-phases question 6, since its parallel work goes through
      an `UnsafePtr` seam the compiler cannot check.
