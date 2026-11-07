# Components: how a game holds state and behaviour

**Status:** questions 1–7 decided on 2026-11-05. On 2026-11-06, question 8's first part was decided (required
components, what is promised, the handle), question 7's hello cube revised, and how a world is divided decided. On
2026-11-07, part b began: a system's parameters mean what their types say, the step's time is a `Time`, the
generator's output is split into files and not committed, systems are functions named by their kama path, and a
singleton is now a world component.
- **Question 1:** B built on A, with a table of chunks per (zone, prefab) and side stores for components gained at run
  time.
- **Question 2:** a component is a plain value, with all four kinds of data on day one, and world data is not a
  component.
- **Question 3:** the vocabulary, a system as a function plus its record, two declared modes for reading other
  entities, queued structural changes, engine modules written like a game's systems, and the layers.
- **Question 4:** the engine promises the order, removal is swap-and-pop, randomness is keyed, and combined results
  fold in chunk order.
- **Question 5:** a component is a kama type plus its record, records take the type's own format, and prefabs that
  share an archetype share generated code, so data alone can add a prefab.
- **Question 6:** every store has a ceiling from a budget record, reserved up front or committed chunk by chunk, so the
  footprint is computed and shown. A full budget refuses by default, and nothing large travels on the stack.
- **Question 7,** with ai-first-api question 1 and rendering question 3: the hello cube is records plus one system, in at
  most 20 non-blank lines and seven concepts. Defaults are records, actions are generated fields, and bindings are
  records of their own.
- **Question 8, in part (2026-11-06):** required components. Any component may require others; one with defaults is
  added at build time, one without must be listed, and the mapping is shown and can be queried. Then part a: from
  1.0.0 the promise covers what a game touches, and nothing is frozen before; the handle is 8 bytes, a slot and a
  generation; records name entities by string; a lookup answers here, gone or unloaded.
- **Question 7, revised (2026-11-06):** actions belong to a player, not to the world. The cube names the player that
  drives it, and a scene places it instead of a start zone, so the hello cube has eight concepts.
- **How a world is divided (2026-11-06),** the owner's model, without a question of its own: one active scene, zones
  in a grid loaded by rings, flat layers as the unit of loading and memory, and nested groups as switches.
- **Question 8 part b, in part (2026-11-07):** the generator reads a system's signature from the compiler, a parameter's
  meaning comes from its type alone, and `const ref Time time` replaces `float32 dt`. The generator's output is split
  into files and not committed. Systems are free functions named by their kama path (`towers::fire`), and a singleton
  is now a world component. Then the vocabulary: a **module** (engine or game) is one kama module, a **processor** is
  what this doc called a system, "system" is retired, and the generator refuses a module `static`. What a processor
  takes is decided, with `Send<C>` and a random key's `nth(n:)`.

The rest of question 8, and question 9, are open; question 9 was added at question 2. The model's picture and vocabulary are gathered in
[../REFERENCE.md](../REFERENCE.md).

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
2. **What is a component?** *(Decided 2026-11-05, below.)* A plain `type value` (copyable, serializable, hashable field
   by field), always? How does a component that owns memory (a mesh, a path) fit?
3. **What is a system?** *(Decided 2026-11-05, below.)* A functor contract (`implements System`) with a phase and a
   rate, registered by the game? How does it declare what it reads and writes, so the scheduler can run disjoint
   systems in parallel and kama can check it?
4. **Determinism.** *(Decided 2026-11-05, below.)* Iteration order is part of the simulation (FFD). Does the
   component store guarantee a stable, specified order?
5. **Records and components.** *(Decided 2026-11-05, below.)* A project-database record ([project-database.md](project-database.md)) defines an
   entity or prefab: is there a one-to-one mapping from record schema to component type, generated by serde?
6. **Scale and storage.** *(Decided 2026-11-05, below.)* Fixed capacities (FFD, the-mallow-man: predictable, `@noheap`-friendly) or growable stores?
   How are large components kept off the stack (the KM-29 lesson)?
7. **The prototype path.** *(Decided 2026-11-05, below.)* A Three.js-style prototype wants "make a cube, give it a spin". What is the shortest correct
   spelling in the component model ([ai-first-api.md](ai-first-api.md))?
8. **Growing in phases.** *(Required components and part a decided 2026-11-06, below; part b, the spellings and
   names, is open.)* Unity's component model grew in phases (KYR-3). Which parts of kyoten's model must be right
   on day one, because changing them later would break every game, and which can arrive later without that?
9. **World data.** *(Added 2026-11-05 at question 2.)* Some data belongs to space, not to an entity: a voxel world, a
   heightfield, a destruction state, a generated region. Question 2 puts it in world stores of cells, keyed by
   coordinate within a zone (G7). The questions are:
   - **The cell's format:** dense, palette or sparse, and who chooses it. Minecraft's sections are 16×16×16 blocks,
     each with its own palette and packed indices of at least 4 bits.
   - **How cells stream** in and out with their zone. *(Zones load by rings around streaming sources and views since
     2026-11-06, § Decided.)*
   - **Procedural generation:** a generator fills cells from a seed and rules, off the simulation as streaming is, and
     its result enters at Input's hand-off, recorded (G12).
   - **How cells are saved:** whole, or only the edits over a cell that can be regenerated. The second needs
     generation that is bit-identical on every platform, which is replay-and-determinism's to settle.
   - **How destruction divides:** pre-fractured pieces as entities (Unreal Chaos's geometry collections), or cut at
     run time into world data or an entity's owned data.
   - **What presentation derives:** meshes built from voxels, and terrain LOD. These are never saved (G8).
   - **Coordinates in a very large world** *(added 2026-11-05, the owner's thought exercise)*. Far from the origin a
     `float32` loses precision: about 1 m per step at 10⁷ m (Box3D,
     [large worlds](https://box2d.org/documentation3d/large-worlds.html)). G7 already makes the zone the unit of
     coordinates.
     - *Proposed:* a position is a whole-number zone coordinate plus a `float32` offset inside the zone. An entity
       crossing a boundary is rebased by a whole number of zones, which can be made exact and so stays deterministic
       (to prove in the design).
     - **Physics runs in a cluster's frame:** the zones around what is simulated, with at least 8 zones around a corner
       of cubed zones, or 4 on a flat world (the owner's count). The cluster rebases when its centre zone changes, and a
       server keeps one cluster per group of nearby players.
     - **Output draws relative to the camera,** as Box3D keeps "a draw origin near the camera", so the GPU sees small
       floats.
     - **The alternative:** doubles for the absolute position only, and floats inside, as Box3D and Unreal 5's
       [Large World Coordinates](https://dev.epicgames.com/documentation/en-us/unreal-engine/large-world-coordinates-in-unreal-engine-5)
       do. Box3D measures it at "a few percent, not the 2x of an all-double build".

   KYR-50 (AI-generated worlds) would fill the same stores.

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
    built. *(Refined at question 5: each archetype is fixed when the game is built, and a prefab of an archetype the
    build has can be added as data.)* There is no component registry, and no run-time queries or scheduler: frame-phases question 6 ruled those
    out. In C, giving an entity a component moves it to another archetype's table. Here a prefab's table never changes
    shape, so a component gained at run time lives in a side store.
  - **A table** holds one prefab in one zone. It is the budget ÷ N chunks, rounded up, allocated once when the zone
    loads and never grown. *(Refined at question 6: that is the default. A table may opt in to committing its chunks
    one at a time, up to the same ceiling.)* *(Refined 2026-11-06 with scenes, zones and layers: a table holds one
    prefab in one zone and one layer.)*
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
- **2026-11-05, the owner: a component is a plain value, all four kinds of data are on day one, and world data is not a
  component (question 2).**
  - **The owner's words:**
    - "Kinds 1-4 and world data isn't a component and add question 9."
    - On deferring kind 4, which was first recommended: "In general Kind 4 sounds like something people will want so I
      don't think we can simply 'wait' for someone to ask for it... Kyoten is a general purpose engine. procedural
      generated worlds are a major thing I want to handle as well."
    - On the first recommendation's reason: "Noheap is an opt in choice btw." So `@noheap` binds only a game that opts
      in, and that game picks kinds that do not allocate.
  - **A component is a plain `type value`**: copyable, serializable, and hashable field by field. Each one sits in a
    chunk, and the data around it comes in four kinds:

    | Kind | Example | Where it lives | Snapshot | Parallel work |
    |---|---|---|---|---|
    | **1. Fixed data** | position, health | a field of the component | copied with the chunk | across chunks |
    | **2. Bounded lists** | a path of up to 16 waypoints, inventory slots, G4's history ring | `InlineDynamicArray<T>#(N)` inside the component | copied with the chunk | across chunks |
    | **3. Shared read-only data** | a mesh, a clip, a navmesh, a dialogue table | an asset store loaded with the zone and unchanged while it runs; the component holds a `Handle` | the handle only | within one table; across tables once KY-5 or KY-18 closes |
    | **4. Owned per-entity data** | a long path found at run time, a script's state, a mesh being cut | owned by the chunk, which becomes a resource | a deep copy (`copy`) | across chunks, and a worker may grow it |

  - **A chunk owns memory only when its prefab needs it.** A prefab with kind-4 data, or a list that may spill, gets a
    `type resource` chunk, and the generator writes its methods and its `copy` constructor. Every other chunk stays a
    plain value, which copies with no allocation.
  - **Each bounded list states its rule for when it is full**: refuse, or spill past N into the chunk's own memory, which
    is how Unity's dynamic buffers behave. This is G2's stated rule for a full budget, applied to a list. The default is
    question 6's.
  - **The generator gives saved fields fixed widths** (`int32`, `int64`). kama refuses to serialize an `isize`, since it
    is 8 bytes natively and 4 on wasm, and fixed widths keep native and web saves identical.
  - **World data goes in world stores of cells**, keyed by coordinate within a zone. A voxel world, a heightfield or a
    destruction state belongs to space, not to an entity. Each cell owns its memory, as a resource chunk does, so work
    splits by cell with the same proof. Question 9 was added for its design.
  - **Physics already works this way.** Jolt owns its world, and a component holds a body id, as the-mallow-man's `BodyId`
    does.
  - **The evidence: probes on kama 0.9.850, re-run on 0.9.852** (after 0.9.851, KR-323, tightened what a `parallel_for`
    body may capture):
    - **Kind 2.** A 128-entity value chunk whose component holds an `InlineDynamicArray<Waypoint>#(16)` is stepped by
      `parallel_for` with the right result. `InlineDynamicArray` zeroes every place it vacates, so equal lists are equal
      bytes, and the world hash can hash a chunk directly.
    - **Kind 3.**
      - Within one table it works: every worker of one `parallel_for` reads a `const ref` asset parameter.
      - Across two tasks it is refused. Two `spawn`s reading `this.path` are refused (KY-5).
      - `Shared<immutable T>` works only for a `string`'s bytes, since an `immutable` type cannot hold an array, not even
        an `InlineArray` (KY-18, filed 2026-11-05).
    - **Kind 4.** A `type resource` chunk owning a `DynamicArray`, in a `FixedArray` of chunks, is split by
      `parallel_for`, and each worker grows its chunk's array (exit 37, as expected). Its snapshot is `copy` of the
      table: stepped twice afterwards, the live table reads 39 and the snapshot still reads 35.
    - **What kama refuses, and why the kinds are shaped this way:**
      - a `type value` that owns heap memory: "a `value` owns nothing, but … transitively owns a resource — declare it
        `type resource`";
      - a resource column inside a value chunk;
      - a `parallel_for` body touching `this`: "pass the data in as a local".
  - **Precedent:**
    - **Kind 2 and the spill rule:** Unity's dynamic buffers hold up to a set capacity inline in the chunk, then move to
      the heap ([manual](https://docs.unity3d.com/Packages/com.unity.entities@1.2/manual/components-buffer-introducing.html)).
      Unity's course warns that every access after the move is a cache miss
      ([DOTS best practices](https://learn.unity.com/course/dots-best-practices/unit/part-3-implementation-and-optimization/tutorial/part-3-3-minimizing-cache-misses)).
    - **Kind 3:** Unity's blob assets are "immutable binary data… you can access them safely in parallel", referenced
      from a component ([blob assets](https://docs.unity3d.com/Packages/com.unity.entities@6.6/manual/blob-assets-concept.html)).
    - **World stores:** Minecraft's chunk columns of 16×16×16 sections, each with its own palette
      ([chunk format](https://wiki.vg/Chunk_Format)).
    - **Pre-fractured destruction:** Unreal Chaos's geometry collections, a tree of fracture levels joined by a
      connection graph whose links break past a set impulse
      ([destruction](https://dev.epicgames.com/documentation/unreal-engine/destruction-overview)).
  - **What it costs:**
    - A resource chunk's snapshot allocates and grows with the data. This weighs on rollback games, which can keep to
      kinds 1–3.
    - Two chunk shapes for the generator to write, value and resource.
    - Kind 3 across tables waits on KY-5 or KY-18. Until then, the tables that read one asset run in one task, and each
      table's chunks still split across workers.
  - **Left to the later questions:**
    - **question 6:** the default rule for a full list, and how kind-4 memory draws on a zone's budget;
    - **question 9:** world stores.
  - **Considered:**
    - **(a) Always a plain value, with kind 4 deferred until a game asks** (the first recommendation). The owner refused
      it: a general-purpose engine cannot wait for kind 4, and the reason given, `@noheap`, binds only games that opt in.
    - **(b) Values, plus components that own memory kept in their own store outside the chunks.** It is flexible, but its
      work is serial like a side store's. The resource chunk gives the same data with the parallel proof intact.
- **2026-11-05, the owner: question 3, choices 1, 4, 5 and 6.** Choices 2 (what a system is made of) and 3 (how a
  system reads other entities) are still open. The picture and the vocabulary are in [../REFERENCE.md](../REFERENCE.md).
  - **The owner's words:**
    - on the vocabulary: "1. yes";
    - on queued structural changes: "4. Your spawn and despawning seems good";
    - on engine modules: "5. I assume your read here is solid";
    - on the layers: "6. so far this sounds good".
  - **Under it all, the owner's frame:** "Ideally the engine doesn't need to change much to develop a game. Much of the
    game development process work is done in the 'game' repo." A game's records, system bodies and generated world
    are in its own repository. A game changes engine behaviour by layering its records over the engine's (the project
    database's layers), never by editing the engine.
  - **Choice 1, the vocabulary.**
    - **System** means a function over components plus the record that schedules it, as Unity, Bevy and flecs use the
      word.
    - **Engine module** means one area of the engine: input, render, audio, net, physics or UI.
    - **"Subsystem" is retired.** frame-phases.md and architecture.md are reworded once question 3 closes. Until then,
      [../REFERENCE.md](../REFERENCE.md) maps the old wording.
  - **Choice 4, structural changes.**
    - A system that spawns, despawns, or makes an entity gain or lose a component queues a command.
    - Commands apply at the end of their phase, sorted by chunk, so the order never depends on which thread recorded
      them.
    - A full budget refuses the command there, which is G2's stated rule.
    - **Precedent:** Unity's command buffers play back sorted by a sort key, and its docs give the chunk's index as one
      that is "consistent regardless of scheduling"
      ([playback](https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/systems-entity-command-buffer-playback.html)).
      Unity's docs add that sorting "can have an impact on performance, so some projects may choose to accept
      non-determinism". kyoten always sorts, since its world hash requires it.
  - **Choice 5, engine modules are written the way a game's systems are.**
    - An engine module publishes its components (in the world layer), its records and its system bodies.
    - The generator reads the engine's records together with the game's, so render's extraction is scheduled in Output
      like any system, and the engine never names a game's world type.
    - A module's long-lived state (the GPU device, the physics world while Jolt is its backend) is a singleton that the
      module owns.
    - `run` reaches the generated world through one contract, the `World` contract. *Probed on 0.9.852:* a system
      generic over a contract the generated world implements splits the world's chunks with `parallel_for`, through a
      `ref`-returning contract method, and reads them through a `const` one (exit 128, as expected).
    - **Why:** the scheduler sees an engine system's access the way it sees a game's. Agents and humans learn one way
      to write a system. And a borrowed backend sits behind records and components, so replacing Jolt with kyoten's own
      solver changes no game (the owner's own-systems direction, [../SPIKE.md](../SPIKE.md) § Standing direction).
    - **Considered:** engine modules as hand-written services that the world calls, as Godot's servers are *(not
      re-checked here)*. Their access would be invisible to the scheduler, and each module would need its own bridge to
      every game's generated world.
  - **Choice 6, the layers.** Architecture question 2's draft holds, with two additions. Each layer imports only the
    layers above it:
    1. **frame:** the phases, the clock, the scheduler, the input record, the `World` contract and `run`;
    2. **world:** the engine's component types; the table, chunk, side-store, command and lookup types; and the
       contracts of published queries;
    3. **one module per engine module:** input, render, audio, net, physics, UI. Each has its records, bodies and
       singletons, and imports frame, world and its own library;
    4. **the agent surface:** it reads every module, and no module imports it.

    **The generated world lives in the game's package**, not in the engine.
  - **Found while preparing the question, on 0.9.852:**
    - **KY-20.** A `parallel_for` body may read the container it splits by `ref`. *Probed:* three runs read a counter
      mid-count ([../KAMA_GAPS.md](../KAMA_GAPS.md)). *(Fixed in kama KR-333: refused on 0.9.857, 2026-11-07.)*
    - **Reading the previous step's snapshot checks, and is sound** (exit 3).
    - **Reading this step's values works in parallel when writes are staged.** The system writes its output to a
      staging store beside the table, and a pass at the end of its group copies it in. kama proves it, since the table
      is only read and the staging store is what is split (exit 7, as expected).
  - **Choices 2 and 3 followed the same day, below.**
- **2026-11-05, the owner: question 3's choices 2 and 3, which close question 3.** "All sounds good... I take your
  recommendations yes."
  - **Choice 2: a system is a function plus its record, and any state it keeps is a singleton.**
    - **The parts:** the record holds what Unity puts in a system's attributes (phase, group, order, rate,
      iterations), and the function is its `OnUpdate`. State kept between steps (an AI cache, a timer, a physics world)
      is a singleton store, declared in the record and passed in by `ref` like any store.
    - **The owner's reading, confirmed:** "your function plus a record would act as an object as the record stores
      metadata". The difference from Unity's system object is where the state lives.
    - **Why:** the state is part of the world. It is saved, snapshotted, rolled back, hashed and budgeted, and its
      access is proven like any other store's. A field on a system object would sit outside all of that, and outside
      the scheduler's view *(reasoning; Unity's docs not checked on this point)*.
    - **What it costs:** a system has three parts to look at, which the schedule view and the editor show as one. Setup
      and teardown need a spelling. *Proposed:* a singleton's initial value comes from its record, and systems may run
      when a zone loads or unloads.
    - **Considered:** a system object with its own fields, as Unity's `ISystem` and `SystemBase` have, with lifecycle
      hooks (`OnCreate`, `OnDestroy`). It is familiar, and everything sits in one place.
  - **Choice 3: a system that reads other entities declares one of two modes.** The scheduler never chooses the mode,
    so a system sees the same values whether its group runs serially or in parallel. That keeps frame-phases question
    5's rule that serial and parallel runs hash alike, and it answers the owner's question about drift.
    - **The previous step, the default.** The system sees other entities as they were at the end of the last step,
      through a snapshot of the columns it reads. It may also write what it reads, as flocking reads old velocities and
      writes new ones. It always runs in parallel and needs no order against writers. It costs one step of latency and
      the snapshot's memory. *Probed:* it checks, and is sound (exit 3).
    - **This step.** The system sees other entities' current values. It runs after whatever writes them, which the
      no-conflict check enforces, and it may not write what it reads. When its group runs in parallel the generator
      stages its writes and copies them in at the group's end; when serial, it writes in place. Since it never reads
      what it writes, the two give the same result. *Probed:* the staged form checks and gives the right value (exit 7).
    - **The owner's aim:** "I definitely want to have as much parallelism as we can". Both modes run in parallel, and
      the default needs no ordering at all.
    - **Considered:**
      - **Unity's live reads through `ComponentLookup`**, checked by its safety system at run time
        ([ComponentLookup](https://docs.unity3d.com/Packages/com.unity.entities@1.3/api/Unity.Entities.ComponentLookup-1.html)).
        It gives current values with no snapshot or staging. But the check sees only code paths that run, a reader
        still waits for its writers, and kama cannot prove it: KY-20 is that read.
      - **A serial system reading the live world without declaring it,** which was first proposed. The owner asked
        whether it drifts from parallel runs, and it would.
  - **Left to later questions:**
    - **question 6:** the snapshot's and the staging stores' memory, within the budgets;
    - **question 8:** the spelling of a lookup, of a command, and of the two modes.

- **2026-11-05, the owner: question 4, the engine promises the order.** "1. Yes the engine promises... 3. Yes 4. Yes. I
  think we probably will take everything you recommend here. We probably don't need to worry about the 2... swap and
  pop is fine". This covers the order inside the stores and what depends on it. Already decided elsewhere: system order
  (frame-phases question 5), serial runs hashing like parallel ones, commands applied sorted by chunk, and reads that
  scheduling cannot change (question 3). Whether the simulation is bit-identical *across platforms* is
  [replay-and-determinism.md](replay-and-determinism.md) question 1's.
  - **Choice 1: the engine promises it, for every game.** The same history gives the same order on every run and every
    machine. A save or snapshot keeps chunks, free slots and handle generations exactly as they are, so a reloaded world
    steps like the one that was saved (the KY-4 lesson, fixed in kama 0.9.809).
    - **The owner asked** whether games should opt in instead, and whether the promise is slower. **It fixes the order
      results are joined in, not the order work runs in.** Threads still take chunks in any order and steal work. What
      it costs *(reasoning, not measured)*:
      - **Commands** go into one buffer per chunk and are applied in chunk order. Unity pays for the same thing with
        a sort: each command carries "a number that has a fixed and unique association with that chunk", and "the
        sorting makes the playback order deterministic"
        ([playback](https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/systems-entity-command-buffer-playback.html)).
        Per-chunk buffers need only to be concatenated.
      - **A combined result** (a sum, a minimum) is kept per chunk and then folded over the chunks: a pass over chunks,
        not entities, in place of atomic adds that contend.
      - **No container in the simulation is keyed by address or seeded at random.** kama's `DefaultHasher` is
        unseeded, and a `Map`'s order is the same natively and on wasm (probed below).
      - **Housekeeping** that moves entities, such as compacting chunks or releasing an empty one, is triggered by the
        world's own state at a step boundary, never by time or memory pressure.
      - **What comes from outside** (input, a zone finishing loading, the network) enters at Input's hand-off and is
        recorded (frame-phases question 3, G12). It is part of the history, so the promise does not make a zone's
        arrival wait.
    - **The expensive kind of determinism is the cross-platform kind.** Jolt is deterministic on one platform given
      "the same order" of calls and "the same binary code"; its cross-platform build is "approximately 8% slower"
      ([Jolt](https://jrouwe.github.io/JoltPhysics/index.html)). The libm gap is KY-19 (kama KR-328). It reaches past
      platforms: one Windows executable gives different bits with UCRT's FMA3 paths on and off, so two CPUs can
      disagree (kama `8813060d`, the same day). The promise here is the order; whether values agree across machines
      is replay question 1, and so is whether a game may choose that tier. That question is where a reason to opt in
      could still turn up.
    - **Why not opt in:** frame-phases question 5's check that serial and parallel hash alike needs the promise, as do
      replays, lockstep and rollback, bug reports from a seed and a log, and an agent re-running a test. With an opt-in,
      every engine module would carry and test both behaviours, and a game turning it on late would find what breaks
      it *(reasoning)*.
    - **Considered:** a game opts in, Unity's position
      ([../research/component-models.md](../research/component-models.md) § 5.4). Most engines disclaim order; Godot
      specifies it.
  - **Choice 2: swap-and-pop, in every table and side store.** A removal moves the chunk's last entity into the gap,
    which is deterministic, constant-time and keeps chunks dense. A spawn goes into the first chunk with room, in chunk
    order. **Spawn order is not promised.** A system that needs an order (turns, initiative, oldest first) sorts by a
    component holding the key, so the order is data.
    - **The owner asked** whether the rule could be chosen per game at compile time, and whether the others deserve a
      profile. They could be: the promise holds under all three, so a table's record could later name its rule and the
      generator would follow it. That is not built until a profile shows a need. When the others might win
      *(reasoning)*:
      - **ordered shift**, when a system wants spawn order within small chunks;
      - **tombstones**, when a table loses many entities in a step and its components are large enough that moving
        them costs more than skipping holes.
    - **Considered:** ordered shift (up to N moves a removal) and tombstones (holes slow iteration until compacted).
  - **Choice 3: randomness is keyed, not streamed.** A draw is made from a key mixing the world's seed, the step, the
    entity's handle and a purpose. The same entity gets the same number whichever entity was visited first, so a system
    that rolls dice stays parallel. A stream `Rng` in a singleton stays available to a serial system, as FFD uses one.
    - **kama needs nothing new:** std's `Rng` is xoshiro256** seeded through splitmix64, the mix `DefaultHasher` ends
      with (`lib/std/random/random.kama`), with the same stream on every platform. *Proposed:* one draw is the key's
      splitmix64 mix, and several are `Rng.seeded` on the key. The spelling is question 8's.
    - **Considered:** one stream consumed in visiting order, FFD's way, which ties every draw to the order and to a
      serial loop.
  - **Choice 4: a result that combines entities is folded in chunk order.** A sum, a minimum or "who hit first" is
    combined within each chunk, then across chunks in chunk order, by the same tree serially and in parallel. Ties
    break by handle. A floating-point sum depends on the order of its terms, so this keeps serial and parallel runs
    bit-identical. It uses kama's planned chunk binding for `parallel_for` (KR-3 decision 16).
  - **Probed** on kama 0.9.852: 5,000 `int32` keys put into a `Map` from `Rng.seeded(seed: 42)`, a third removed and
    1,000 more added, then hashed in `foreach` order. The result was `hash=10913015343159802295 length=4333`, both
    natively (Windows, `--release`) and on wasm under node.
  - **Left to later questions:**
    - **replay question 1:** the cross-platform tier and whether a game may choose it;
    - **replay question 5:** a tripwire that runs a group's chunks in a shuffled order and compares hashes;
    - **question 6:** the memory of the per-chunk command buffers and partial results, within the budgets;
    - **question 8:** the spelling of a keyed draw and of a sort key.

- **2026-11-05, the owner: question 5, decided with project-database question 11.** "Part A 1. Yes recommended 2. Yes
  recommended 3. Yes recommended". The layers half is recorded in [project-database.md](project-database.md) §
  Decided.
  - **Choice 1: a component's fields are written in kama, as its type.** The type is `@generate(Serializable,
    Deserializable)`, so every field is marked `@field` or `@skip`. The component's record says what the engine does
    with it: where it is stored (a table column or a side store, later a flag column), how much history it keeps (G4),
    how it is interpolated (frame-phases question 4), and whether it is saved or rebuilt for display (G8). **A
    component is a type plus its record, as a system is a function plus its record.**
    - **Why:** the shape lives where the compiler checks it, `kama query` sees it, and a component may have methods.
      Unity, Bevy, Godot and Unreal all keep a type's shape in code and its values in data *(general knowledge, not
      re-checked here)*.
    - **Considered:** fields written in the record, with the kama type generated. That puts everything in one kind of
      file, but a type is then described in two languages, a component cannot have methods, and a change to a field
      still needs a build.
  - **Choice 2: a record's format is the component's own type, one to one, through serde.** This answers the question
    as asked. A prefab record names its components and their values, and the generator writes the prefab's defaults as
    one field per component. A strict read refuses a field no type declares.
  - **Choice 3: prefabs with the same set of components share generated code, so data alone can add a prefab.** A set
    of component types is an **archetype**, in Unity's sense. The generator writes one table type per archetype, and
    each (zone, prefab) table is made from it when its zone loads, which already happens while the game runs.
    - **What it buys:** an elite soldier with the soldier's components is a record, not a build. An agent writes it and
      hot-reloads it, and a DLC or a mod can add one with no code.
    - **What still needs a build:** a new component, a new archetype, a new system, or a change to a component's fields
      or storage. A check names the build a record would need.
    - **It refines question 1:** where that said each prefab is fixed when the game is built, it is each archetype
      that is fixed.
    - **Considered:** generated code per prefab, as question 1 first read. The mapping is simpler, but every new
      variant is a rebuild, and a layer without code can never add one.
  - **Probed on kama 0.9.854** (`0.9.854+ga65f0c41`), a base game, a DLC and a mod merged into a
    `Map<string, SoldierDefaults>`, each field of which is a component's own type:
    - **Unnamed fields are kept:** the DLC's `{"soldier":{"health":{"max":150}}}` kept the base's `regen` of 2.
    - **New prefabs and removals work:** the DLC added `elite`, whose unnamed fields took the type's defaults, and the
      mod's `"medic":null` removed one. A list (an `InlineDynamicArray<int32>#(4)`, kind 2) is replaced whole.
    - **Bad input is refused, and nothing is written:** strictly, ``unknown field `elite.helth` ``, and
      ``type mismatch at `elite.health.regen` ``.
    - **A list over its bound** is refused, but as ``type mismatch at `soldier.patrol.stops[4]` ``, which names the
      wrong cause ([../KAMA_GAPS.md](../KAMA_GAPS.md) KY-21).
  - **Left to later questions:**
    - **question 6:** the archetype tables kept as a list per archetype, within the budgets;
    - **question 8:** the record's spelling, and which parts of a component's record are a day-one commitment.

- **2026-11-05, the owner: question 6, every store has a ceiling from a budget record.** "I agree all 8 sound good so
  far". This takes in what earlier questions left here: question 1's N, side-store capacities and matched budgets,
  question 3's snapshot and staging memory, question 4's command buffers and partial results, and question 5's archetype
  table lists. It also settles the rest of KYR-58's G1.
  - **Choice 1: fixed or growable, under one rule.** Every store has a ceiling, set by a budget record, so the footprint
    can always be computed.
    - **By default** a store reserves its whole ceiling when its zone or world is created.
    - **As an opt-in per table,** it commits chunks one at a time up to the ceiling, only at the end of a phase. Earlier
      chunks are never moved or copied. It costs one more indirection per chunk.
    - **A world sized when it is created** (a city builder, a sandbox) sets its budgets then and saves them with the
      world (G2).
    - **The owner added:** "I would even say some games could potentially have a fixed pool if they wanted... but that
      is a game specific implementation detail". A game may keep a pool of its own in a store it writes by hand, as
      question 1 allows. The engine needs no rule for it beyond the ceiling.
    - **Considered:** stores that grow with no ceiling. Cities: Skylines II is reported to have removed its predecessor's
      hard caps, leaving the hardware as the limit (G2; from press, not verified). That leaves no footprint to compute,
      and where machines simulate together a spawn could succeed on one and fail on another.
  - **Choice 2: budgets are records, per scope.** Memory comes from per-prefab budgets, so a table's capacity is its
    (zone, prefab) budget. A limit over a group is a count rule, checked when a command applies: all enemies in a zone,
    a player's population cap, a team's projectiles (G2). It does not size memory.
  - **Choice 3: when a budget is full.**
    - **The default is to refuse,** and the spawning system sees the refusal as a gameplay result.
    - **Evicting is an opt-in per budget,** in a stated order: oldest spawn step first, then handle.
    - **Output recycles** its own decals and debris.
    - **Development reports every refusal loudly but behaves exactly as release does,** so the two builds hash alike.
  - **Choice 4: the chunk size N is chosen per archetype.** A chunk is the block of entities one worker takes at once,
    and N is how many entities fit in one. The generator picks N from a byte target: 16 KiB with at most 128 entities, as
    Unity's chunks are. An archetype with small components gets up to 128 per chunk, and a large one fewer.
    - **The archetype's record can override N.**
    - **A table whose budget is below N wastes the rest of its one chunk,** and the generator warns when that is large.
    - **The rule is measured in slice B (KYR-12).** The owner was unsure of the detail and accepted it as described: "I
      think it sounds good from what I can tell".
  - **Choice 5: nothing large travels on the stack.**
    - **Large data is reached by `ref`.** Chunks live only in heap blocks, the world sits behind `Owned`, and a snapshot
      copies block to block (probed on 0.9.845).
    - **A frame guard in every manifest, on every arm but Windows:** `-Wframe-larger-than=32768
      -Werror=frame-larger-than`, as friendly-fire-department sets it. On Windows, kama's own path helpers fail it.
      Reading a file stops the build at *"stack frame size (65688) exceeds limit (32768) in 'kama__open'"* (probed
      below), which kama keeps deliberately (kama `docs/platforms/windows.md`). The-mallow-man checks Windows with its
      own `tools/check-frames`.
    - **A frame guard does not bound the chain of frames under it.** Ten frames that each pass the guard overran wasm's
      256 KiB stack at run time, with nothing reported before (probed below). The ask to kama is a computed bound for
      each entry point: [../KAMA_GAPS.md](../KAMA_GAPS.md) KY-22. The owner: "you can file a KAMA GAP and we can let
      kama determine".
  - **Choice 6: the footprint is computed and shown.** The generator adds up every ceiling per scope and reports the
    game's simulation floor in the schedule view and to agents. That covers:
    - tables, side stores and world stores;
    - singletons;
    - snapshots and staged writes (question 3);
    - per-chunk command buffers and partial results (question 4);
    - the list of tables per archetype (question 5).
  - **Choice 7: the rest of G1.**
    - **Output's budgets vary per machine:** particles, decals, debris, draw distance, level of detail.
    - **A sole authority may choose its own simulation budgets,** saved with the world. That is single player or a
      server.
    - **Where machines simulate together, they agree a match's budgets at matchmaking,** as the owner decided on
      2026-11-04.
  - **Choice 8: where memory comes from.**
    - **One block per zone,** once kama's KR-326 lands (KY-17).
    - **Until then,** one allocation per table, or per chunk under choice 1's opt-in.
    - **A step allocates nothing,** proven by `@noheap`, once kama's pool hands out work without a heap allocation
      (KY-12's second ask).
    - **The owner:** "we can see how it works in practice". Slice B measures it.
  - **Probed on kama 0.9.854** (`0.9.854+ga65f0c41`), Windows 11, msys2 UCRT64:
    - **Growth up to a ceiling:** a table of `Owned<SoldierChunk>` (128 `Pos` per chunk) whose chunk list is reserved at
      a ceiling of 3. It committed three chunks, refused a fourth, and a `parallel_for (ref Owned<SoldierChunk> c in
      this.chunks, workers: 4)` stepped them. The output was `grow true true true false; committed 3; sum 258`.
    - **A chain of frames:** `l0` to `l9`, each holding an `InlineArray<int32>#(7000)` (28,000 B) and calling the next,
      built with the frame guard. `kama check` was clean, and the guard passed natively and on wasm. Natively it printed
      `sum 45`. On wasm under node it failed: *"Stack overflow detected. You can try increasing -sSTACK_SIZE (currently
      set to 262144)"*, then `RuntimeError: memory access out of bounds` in `l9`.
    - **The guard on Windows:** `import { std::fs::readText }` and one call failed the build in `kama__open` (65,688 B)
      and `kama__wpath_long` (65,624 B).
  - **What it costs:**
    - every store needs a budget, and a game that does not care takes the engine's default records;
    - a table that commits chunks as it grows pays one indirection per chunk.
  - **Left to later questions:**
    - **question 8:** the budget record's spelling, and which parts are a day-one commitment;
    - **slice B (KYR-12):** N's rule, the cost of committing chunks as a table grows, and the footprint report.

- **2026-11-05, the owner: question 7, decided with ai-first-api question 1 and rendering question 3. The hello cube is
  records plus one system.** "All in all I think I agree on all. but you can see my notes above." The three questions
  describe one program, so they were taken together, and [ai-first-api.md](ai-first-api.md) and
  [rendering.md](rendering.md) § Decided point here. The owner's notes asked how the sketch's pieces connect, and the
  answers are part of the record.
  - **Choice 1: records plus one system,** Bevy's shape. The sketch, revised after the owner's notes; its file format is
    project-database question 2's, and its spelling is question 8's:
    ```json
    { "prefabs":  { "cube": { "mesh": { "shape": "box" }, "spin": { "rate": 2 } } },
      "systems":  { "turn": { "phase": "Update" } },
      "actions":  { "faster": { "kind": "button" } },
      "bindings": { "faster": { "keyboard": "ArrowUp", "gamepad": "RightShoulder" } },
      "zones":    { "start": { "spawn": ["cube"] } } }
    ```
    ```kama
    @generate(Serializable, Deserializable, of)
    type value Spin { @field(default) public float32 rate = 1; }

    fn void turn(ref Transform t, ref Spin s, const ref Actions input, float32 dt) {
        if (input.faster.held) { s.rate = s.rate + dt; }
        t.yaw = t.yaw + s.rate * dt;
    }
    ```
    *(Revised 2026-11-07, question 8 part b: `const ref Time time` replaces `float32 dt`, and the body reads `time.dt`.)*
    - **How the pieces connect:**
      - **`cube` is a prefab** listing two components: the engine's `mesh` and the game's `spin`, whose type is `Spin`.
      - **Its transform is not listed.** *Proposed, and confirmed at question 8 on 2026-11-06:* `mesh`'s record, in the engine's content layer, says it requires a
        transform and a material, and the generator adds both with their defaults when it makes the archetype. These
        are Bevy's required components, where "when A is inserted, B will also be initialized and inserted (if it was
        not manually specified)" ([Component](https://docs.rs/bevy/latest/bevy/ecs/component/trait.Component.html),
        0.20.1), and Unity's `RequireComponent`, where "the required component is automatically added to the
        GameObject"
        ([RequireComponent](https://docs.unity.com/en-us/engine/current/script-reference/unityengine/requirecomponent)).
        In kyoten it happens at build time, so the cube's archetype is transform, mesh, material and spin.
      - **`turn` is a system.** Its record puts it in Update. Its signature is its access: it writes `Transform` and
        `Spin` and reads `Actions`. The generator runs it on every table whose archetype has both components.
      - **`faster` is an action of the whole game,** not of a zone. **`start` is a zone,** which spawns one cube when it
        loads. *(Revised 2026-11-06, below: the cube names the player that drives it, and a scene places it.)*
      - **The generator writes the rest:** the table type for the cube's archetype, an `Actions` type with one field per
        action, and Update's call to `turn` over each chunk.
      - **`main` is the game's, not generated.** The game owns it and calls `run` (architecture question 4,
        2026-11-02), and `kyoten new` writes it in about two lines.
    - **A component needs no ctor of its own,** as the owner pointed out. *Probed on 0.9.854:* a `Spin` with none
      deserializes from `{}` to its field defaults, nested inside a prefab's defaults too. `@generate(of)` adds a
      memberwise `Spin.of(rate: 2)` for code that builds one (kama `docs/SPEC.md`, the `@generate` table: "a memberwise
      ctor `T.of(f1:, …)` — **bag only**").
    - **Probed on 0.9.854** against a mock of the engine and of the generator's output: one cube read from a record
      that sets `rate` to 2 over the default 1. A step of 0.5 with `faster` not held turned it to 1.0. A second step,
      with `faster` held, raised `rate` to 2.5 and turned it to 2.25: `yaw 2.25 rate 2.5`. The mock's `Transform` holds
      only a yaw angle.
    - **The engine ships general-purpose components where the design is sound.** The owner: "There probably will be
      some we want though that are general purpose enough and sound enough design". The defaults (choice 3) already
      need a transform, a mesh, a material, a camera and lights. A general motion component is a candidate on its own
      merits: "there will be several ways to move things in a game engine. physics is only one. many games defy
      physics." The hello cube still writes its own `Spin`, so it shows a system, the one thing every game writes.
      Which components ship on day one is question 8's, and each engine module's design.
    - **One way to do a thing, for what agents write.** The owner: it "is mostly a kama GOAL, but yes it does make
      sense to apply to systems that AI will be writing so we always prefer the BEST solution for something".
    - **Considered:**
      - **A built-in spin, so the cube is pure data.** It is shorter, but it puts a component in the engine for the
        demo's sake, and the cube would not show a system.
      - **A Three.js-style facade, `scene.add(Mesh.cube(…))`.** The owner asked why it would be a second model.
        - **Every entity lives in a table** made at build time for its archetype, within its zone's budget, and is
          saved, snapshotted, hashed and replayed.
        - **For a known prefab, `scene.add` adds nothing:** it is a spawn, which a system already issues as a command.
        - **Anything else would live outside the world:** unbudgeted, unsaved, unhashed, and outside the parallel
          proof.
        - **Behaviour would be a contract per object.** Three.js attaches it as a callback, which in kama would need a
          closure, and kama has none. A contract per object is a system by another name, outside the schedule.
        - **That second place for state and behaviour is the second model.**
  - **Choice 2: the target, written down (ai-first-api question 1).**
    - **The target:** choice 1's hello cube is a lit, spinning cube that reads input, on web and native. It takes at
      most 20 non-blank lines across all its files, and seven concepts: app, record, zone, prefab, component, system
      and action. *(Eight since 2026-11-06, below.)*
    - **The bar:** Three.js takes 25 lines (17 non-blank) unlit and 54 (35 non-blank) lit, with about eleven
      concepts, and reads no input.
    - **How it is kept:** the hello cube is an example built and run in CI on web and native. CI counts its lines and
      fails when they grow, so the target cannot erode (KYR-14; examples question 3).
  - **Choice 3: the defaults are records (rendering question 3).**
    - **The default makeup:** unless a record says otherwise, a world starts with one window or canvas, a camera
      looking at the origin, a directional light with ambient light, a lit default material and a start zone.
      *(Revised 2026-11-06, below: the app's first scene replaces the start zone, and one player joins the defaults.)*
    - **Each is an engine record** in the engine's content layer, which a game patches field by field
      (project-database question 11).
    - **Why data:** kama has no default parameters, so defaults live in data. A field's default is its
      `@field(default)` initializer.
  - **Choice 4: actions are generated fields, and bindings are separate records.**
    - **A typo is a compile error:** the generator writes one field per declared action. *Probed:* ``error: `Actions`
      has no field `fastr` ``.
    - **Bindings are their own records.** The owner pointed out that a key written into an action ties it to a device.
      So the game declares `faster` as a button, and its bindings are a record of their own: a default per device,
      which the developer and the player rebind, the player in the local layer.
    - **Anything can drive an action.** A bot, an agent or a remote player sets `faster` directly at Input's hand-off,
      recorded. The system never sees a key, and a rebind cannot move the hash (KYR-54). *(Revised 2026-11-06,
      below: every source drives an action through a player.)*
  - **Choice 5: records stay data, not attributes on the code.** kama refuses an attribute it does not know. *Probed:*
    *"unknown attribute `@system` here — expected `@interrupt`, `@section("...")`, `@noheap`, …"*. Layering also needs
    records to be data. So the minimum is two files, which an agent or `kyoten new` writes (ai-first-api question 6,
    KYR-30).
  - **Choice 6: the iteration loop:** editing, then seeing the change, not the game loop.
    - **A record change hot-reloads at a step boundary:** a rate, a colour, a new prefab of an existing archetype.
    - **A code change rebuilds,** until kama's hot reload or its scripting (KR-35) lands (ai-first-api question 5).
  - **Found while preparing, for question 8:** kama has no shadowing, so a generated column named `spin` cannot sit
    beside a system named `spin`. *Probed:* *"field `spin` has the name of a function in scope — kama has no
    shadowing, so one name means one thing; rename it"*. The owner: "this avoids common pitfalls. Kama is strict and
    opinionated on purpose". The generator needs a naming rule, which question 8 spells.
  - **What it costs:**
    - two files, not one;
    - a build step;
    - a wait: the hello cube needs the generator (KYR-7), the scene layer (rendering question 2) and actions (KYR-54)
      before it runs.
  - **Left to later questions:**
    - **question 8:** the spelling of records and how their names connect, the naming rule, required components
      (decided there on 2026-11-06), and which built-in components are on day one;
    - **project-database question 2:** the records' file format.

- **2026-11-06, the owner: required components, part of question 8.** "Ya I think your required component type makes
  sense... It also makes sense to allow authors to require components with their components. There should be a good
  visible mapping of required components and likley a query for that? If a comonent doesn't have defaults it must be
  explicitly added."
  - **Any component may require others,** the engine's and a game's alike. `mesh` requires a transform and a material,
    and a game's `Vehicle` may require its own `Fuel`. The requirement is written in the component's record, because
    kama refuses an attribute it does not know (question 7, choice 5). Its spelling is the rest of question 8.
  - **A required component with defaults is added** with them when the generator makes the archetype, unless the
    prefab lists it.
  - **One without defaults must be listed.** A component has defaults when every field has one, so an empty record
    reads, as question 7 probed for `Spin`. A prefab that lacks a required component without defaults is refused at
    build time, and the error names the component that requires it.
  - **The mapping is visible.** The generator reports each prefab's archetype and where each component came from
    ("transform: required by mesh"). A query answers what a component requires, what requires it, and what a prefab
    resolves to (ai-first-api question 4, KYR-25).
  - **Why at build time:** archetypes are fixed when the game is built (question 5). So a requirement costs nothing at
    run time, and a missing one is a build error rather than a surprise in play.
  - **Prior art:** Bevy's required components and Unity's `RequireComponent` (question 7, above) add the required
    component when the first is added. kyoten resolves it when the archetype is made.
  - **Left to the rest of question 8:** the spelling, and whether a requirement may name a default of its own, such as
    a material other than the engine's.

- **2026-11-06, the owner: the hello cube revised (question 7, choices 2–4).** "Yes we need to revise hello cube with
  our revised vision we have been building out here."
  - **Why:** the owner asked: "Is 'actions' global? how is it bound to 'turn'? Globals typically have a bad smell.
    Also Who/what provided the action? controller 1, Controller 2, an AI bot, networked player?" In question 7's
    sketch `Actions` was one value for the whole world. It could not say who acted, so split screen, bots and remote
    players had no place. Bevy's input crate says the same: "freely bind keys to distinct entities, rather than
    worrying about singular global state" (leafwing-input-manager 0.22.0,
    [docs](https://docs.rs/leafwing-input-manager/latest/leafwing_input_manager/)).
  - **The revised sketch** (the kama half is unchanged):
    ```json
    { "prefabs":  { "cube": { "mesh": { "shape": "box" }, "spin": { "rate": 2 },
                              "actions": { "player": 1 } } },
      "systems":  { "turn": { "phase": "Update" } },
      "actions":  { "faster": { "kind": "button" } },
      "bindings": { "faster": { "keyboard": "ArrowUp", "gamepad": "RightShoulder" } },
      "scenes":   { "hello": { "place": ["cube"] } } }
    ```
  - **What changed:**
    - **`Actions` is the cube's own component.** Its record names the player that drives the entity, and the Input
      phase fills its fields from that player each step. `turn` reads it as before. A player is a slot that a device,
      a network slot, a bot or an agent is bound to (KYR-54). It is Bevy's model, and Unreal's, where a player's
      controller and an AI's possess a character alike *(general knowledge)*.
    - **`Actions` has no default player,** so a prefab must list it, by today's rule at question 8.
    - **A scene places the cube,** not a start zone. The owner: "I don't think you would have a hard coded 'start'
      instead you would have a property on the 'scenes' or 'zones'." The app's record names the first scene, which is
      by default the only one, and a scene has one zone and one layer by default (the owner's model of scenes, zones
      and layers, 2026-11-06, [../REFERENCE.md](../REFERENCE.md)).
    - **The engine's defaults** gain one player, bound to the local keyboard and the first gamepad.
  - **Probed on 0.9.855** against mocks: two cubes, driven by players 1 and 2. With only player 1 holding `faster`,
    its cube turned to yaw 2.25 at rate 2.5, and player 2's to yaw 2 at rate 2. A prefab whose `actions` named no
    player was refused when read.
  - **The target, revised:** at most 20 non-blank lines, unchanged (the sketch takes 12, plus `main`'s two), and eight
    concepts: app, record, scene, prefab, component, system, action and player. Scene replaces zone, which the cube no
    longer writes, and player is new.
  - **Left to KYR-54:** player bindings, adapters and input contexts, recorded there as the owner's direction.

- **2026-11-06, the owner: how a world is divided, into scenes, zones, layers and groups.** It has no question of its
  own: the owner brought the model while question 8 was being prepared, and it was decided with the proposed
  adjustments. "Yes that all sounds good to me and is exactly the split I was considering as well. Layers give budget
  and more granular control per zone... groups give nested structure and organization."
  - **The owner's model:**
    - **A scene** is what a designer opens and the build lists. "Only one Scene is active at a time." A game may use
      one per level, one for the whole game, or scenes as demos and playgrounds. The app's record names the first, and
      a scene says whether it is in the build: "I don't think you would have a hard coded 'start'".
    - **Zones divide a scene spatially:** a regular grid of squares in 2D or cubes in 3D, sized in metres by the
      designer. This is G7's zone, the unit of loading, budgets and coordinates, made a grid, which question 9's
      coordinates assumed.
    - **Layers divide it logically:** "all layers must be specified at design time and all layers span across all
      zones... since a prefab ( bullet, enemy, character, etc. ) can belong to a layer and move between zones."
    - **Groups divide a layer:** "This would allow enemeies to be grouped within a layer for example."
    - **Every scene has at least one zone, every zone at least one layer, and every layer a group,** so "now the user
      knows they exist and can opt in".
    - **Two units of distance:** "you can measure the scene ( game world ) in units of measure like 'meters' or in
      units of zone 'x zones away'."
  - **Choice 1: two drivers decide what loads.**
    - **A streaming source decides which zones are simulated.** It is a component on a simulated entity: each
      player's character by default, a teleport target to load ahead, a camera a player watches inside the game. It is
      computed from the simulation's own state, so it is the same on every machine (G8). Unreal: "Each Player
      Controller is used as a World Partition streaming source"
      ([World Partition](https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition-in-unreal-engine)).
    - **A view decides what is drawn.** The owner: "'views' are probably render targets... aka output systems?" A
      view is Output's: a camera drawing into a target, which is the screen, part of it in split screen, a texture, or
      an eye in a headset. It streams meshes and textures and may differ per machine.
    - **Why two:** Output varies per machine, so if views loaded the simulation's zones, two machines would simulate
      different worlds. A headless server has no views at all. Minecraft keeps simulation distance apart from render
      distance the same way (G8). The two usually coincide, because the camera follows the player.
  - **Choice 2: distance in rings of zones.** Ring 0 is the zone a source is in, and ring k holds the zones k steps
    away along whichever of x, y and z is largest. A depth of k loads (2k+1)² zones per source in 2D (1, 9, 25, 49)
    and (2k+1)³ in 3D (1, 27, 125, 343).
    - **Against the owner's earlier count** of 4 or 8 zones around a corner: that is cheaper at the smallest depth,
      but gives no zone a fixed distance, and LOD by "zones away" needs one.
    - **Loaded zones stay bounded** at sources × zones per source, so the footprint (question 6) is computed even for
      an infinite world.
    - **Zone size also bounds precision,** since a position is a zone coordinate plus a `float32` offset (question
      9, proposed): within a zone of about 8 km, about 1 mm (G7's arithmetic).
  - **Choice 3: layers are the unit of loading and of memory.**
    - **Flat, declared at design time, and a block per zone.** Tables become per (zone, layer, prefab), refining
      question 1's (zone, prefab). A layer's budget is its ceiling, so layers give "budget and more granular control
      per zone".
    - **Each is spatial or not.** A spatial layer's entities live in zones, a block per zone. A non-spatial layer is
      one block for the scene, present while it is on, wherever its entities are (Unreal's "Is Spatially Loaded",
      turned off).
    - **Each is simulated or drawn only.** A drawn-only layer is loaded by views, per machine, and is never saved,
      hashed or read by the simulation. Unreal draws the same line: a client-only data layer is switched on the client,
      and a runtime one on the server, which replicates it
      ([SetDataLayerInstanceRuntimeState](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/UDataLayerManager/SetDataLayerInstanceRuntimeState)).

      | | Spatial | Non-spatial |
      |---|---|---|
      | **Simulated** | mobs, items on the ground, doors: a block per zone, loaded by rings from the streaming sources | rules, score, a match timer, inventories: one block for the scene |
      | **Drawn only** | LOD meshes, grass, far silhouettes: loaded by rings from each view | the HUD, menus, a 2D canvas |
    - **Its states:** off (not in memory), loaded (in memory, neither simulated nor drawn, ready to switch at once),
      and active. A switch is a recorded command at a step boundary, and a fade is Output's. Unreal's runtime data
      layers are "loaded but not visible" or "loaded and visible", and Epic's sample uses them for "the transition
      between the Light World and the Dark World"
      ([Data Layers](https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition---data-layers-in-unreal-engine)),
      the owner's two realities.
    - **Ring ranges are an LOD control.** The owner: "a designer could use layers as an LOD level control. Layers can
      be turned off and on based on how far the zone is away from the viewer ( zone count not measured distance in
      meters )." A spatial layer names the rings it is on in: detailed props on rings 0–1, low-detail buildings on
      0–3, far silhouettes on 2–6. A far zone then holds only the coarse layers' blocks, and the footprint per source
      is the zones in each ring times the layers on there. Unreal gives each HLOD layer its own grid, with its own cell
      size and loading range, and warns that "Using more than one grid can negatively impact performance"
      ([HLOD](https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition---hierarchical-level-of-detail-in-unreal-engine)).
      kyoten does it on one grid.
  - **Choice 4: groups are the unit of switching and organisation.** A group lives in one layer and nests freely. It
    costs an id per entity and a flag the generated loop checks, like Unity's enableable components. A child group is
    on only if its parents are. Turning a group off stops its members being simulated and drawn, and its memory stays.
    - **The rule for a designer:** a layer if the things should leave memory, a group if they only switch. Realities,
      LOD bands and UI are layers; waves, a puzzle's pieces and a room's lights are groups.
    - **An entity is in one layer and at most one group.** A set it shares with others, many to many, is a marker
      component, which already exists.
    - **Considered: nested layers,** proposed first and withdrawn. Each layer reserves its own ceiling in every loaded
      zone, so nesting multiplies blocks. Five waves of one enemy, as five layers, reserve five ceilings in each of 27
      zones; as one layer with five groups, they reserve one ceiling sized to the most alive at once. Unreal nests its
      data layers freely because each of its objects is allocated alone, so a layer there is only a label.
  - **Choice 5: moves.** An entity crossing into another zone moves to the same layer's block there, at the end of the
    phase and in sorted order, and its handle stays valid (G7). Changing layer is the same kind of move: an item picked
    up goes from a spatial "items" layer to a non-spatial "inventory".
  - **Where non-spatial is weak:** something that must always simulate yet roams, like a dragon. In a non-spatial
    layer it keeps running, but the ground under it may not be loaded, so it cannot rely on zone data there. A
    streaming source on it loads its surroundings instead, at the cost of one more set of rings. A game picks per
    case. Things that span many zones (rivers, roads, terrain) are world data (question 9).
  - **Left open:**
    - **an entity leaving the loaded area.** The lean: it is saved with the zone it enters and freezes until that zone
      loads, as Minecraft simulates only within simulation distance;
    - **what survives a scene change** (players, bindings, settings, the save). Proposed: the app keeps its own state;
    - **the cost of zone size.** Large zones load more than is needed; small ones mean more crossings and partly
      filled chunks. Slice B measures it (KYR-12), and the generator reports it;
    - **the names (question 8).** "Layer" already names the engine's layers, content layers, rendering's screen layers
      and its scene layer. "Group" also names a group of systems. Minecraft calls a zone a chunk, which kyoten's chunk
      is not;
    - **a scene's storage (project-database question 2).** A scene is what a designer opens, but it may be stored as
      a folder of records per zone: Unreal stores one file per actor, so "you do not need to check out the Level file
      from source control to make changes to the Actors in the world", and streaming reads one zone without the rest;
    - **how a drawn-only layer reaches rendering's screen layers** (rendering question 9).
  - **On the roadmap:** KYR-61. The first slice needs only one scene, one zone, one layer and one group (KYR-7).

- **2026-11-06, the owner: question 8, part a: what is promised, and the handle.** "So far this sounds good to me."
  Question 8 is taken in two parts: this one, and the spellings and names (part b).
  - **Choice 1: the promise covers what a game touches, and nothing behind it.**
    - **The research's day-one list** ([../research/component-models.md](../research/component-models.md) § 5.8) is
      now decided in full: what a component is (question 2), where a system states its phase and the phase names
      (question 3, frame-phases), order and determinism (question 4), the override format (question 5,
      project-database question 11), Output reads and never writes (frame-phases), and entity identity (choice 3).
    - **Promised:** a game's records, its system signatures, the engine components and generated names it uses,
      handles, and the order.
    - **Not promised:** tables, chunks, N, the generated loops, the scheduler and the layout of side stores. A game
      never names them, so any release may change them.
    - **Why:** Unity's surface stayed for twenty years, and its costly phase was a second model beside it. Bevy's
      largest break was a change to its surface, removing stages in 0.10 (the research, §§ 1 and 5.8).
  - **Choice 2: nothing is frozen before 1.0.0.** The owner: "I do want to make sure we have room to iterate before we
    tag 1.0.0... That is basically the same thing kama has been doing. Anotherwords I do not want to be artificially
    limited on what we do because it 'breaks' something. Kyoten has no consumers yet." From 1.0.0 the promise is kept
    by:
    - **records that never change meaning silently,** with kama's own tools: a field's wire name and id survive a
      rename in code, `@deprecated` on a field means read when present and never written, and new fields arrive with
      defaults;
    - **a migration when a record's shape must change:** a patch from the old shape to the new, applied when the stack
      loads, with the engine's version beside the stack's identity in every save;
    - **the examples as the compatibility test:** the hello cube and the example games build in CI against every
      engine change (KYR-13, KYR-14).
    - **What can arrive later without a break:** parallel work inside a phase, nested prefabs and variants,
      relationships, change hooks, a new storage layout, and editor tools.
  - **Choice 3: kyoten's own handle, 8 bytes: a 32-bit slot and a 32-bit generation.**
    - **A slot** is an entry in the world's lookup table, saying where an entity lives now (zone, layer, table, chunk,
      row). **A generation** is a counter in the slot, bumped each time the slot is freed. A handle carries the
      generation it was given, so a stale handle answers "gone" rather than reaching whatever reused the slot.
    - **Its requirements:**
      - the same bytes on every platform, in memory and written out;
      - small, since components hold handles and network messages carry them every step;
      - detects a stale reference, and survives moves (swap-and-pop, zone and layer changes);
      - deterministic: the same history gives the same handles, since randomness is keyed by handle and ties break by
        handle (question 4);
      - an array index rather than a search, and compares as a number;
      - valid while its zone is unloaded (choice 5).
    - **Why not kama's `Handle`:** its index is an `isize`. *Probed on 0.9.855:* it is 16 bytes natively and 8 on
      wasm, and a component holding one is 24 and 12. N comes from an archetype's bytes, so chunks would hold
      different counts natively and on the web, and results folded chunk by chunk (question 4) would group
      differently. A 32 + 32 handle was 8 bytes on both, and the component 12. kama's `Handle` stays right for kama's
      `SlotMap`, which indexes buffers by `isize`.
    - **Its wire form,** how it is written in a save, a replay or a network message, is fixed from 1.0.0, so a file
      written by one version or platform reads on another. Bevy promises the opposite: its bits are "liable to change
      from release to release", and `to_bits` is not for "serialization between runs" (0.20.1,
      [Entity](https://docs.rs/bevy/latest/bevy/ecs/entity/struct.Entity.html)). Unity Entities' `Entity` is also an
      index and a version
      ([Entity](https://docs.unity3d.com/Packages/com.unity.entities@1.3/api/Unity.Entities.Entity.html)).
    - **Considered: UUIDv7,** which the owner asked about. RFC 9562 (May 2024) makes it 16 bytes, a 48-bit Unix
      timestamp in milliseconds and random bits, ordered by time because "Time-ordered monotonic UUIDs benefit from
      greater database-index locality". kama ships it as `std::uuid::Uuid.v7()`, from the wall clock and the OS's
      generator. As a handle it is twice the size and needs a map search, and it is not deterministic: two machines in
      lockstep would give one spawn two ids. It fits ids made outside the simulation, on many machines: records
      agents create, assets, saves, replays, matches and mods (noted at project-database questions 6 and 10).
  - **Choice 4: two identities, and names hashed only inside the engine.**
    - **The runtime handle** is used in code and kept in saves. **A placed entity's name** in its scene's records
      ("door-12") is what other records refer to. The loader resolves names to handles when a zone loads, and records
      never hold runtime handles.
    - **Authors always write strings.** The owner: "I know some games use a hash instead of strings but you can use
      strings with utilities that hash them." Names the build knows (prefabs, actions, layers, groups) become generated
      fields and constants, so a typo is a compile error. The loader may key placed names by a 64-bit hash, and the
      wire may carry it. The build checks a scene's names for collisions, and loading checks names that arrive later
      over the stack, so a collision is refused rather than merely unlikely. Godot interns names in `StringName`
      because "Comparing them is extremely fast compared to regular Strings" (4.7,
      [StringName](https://docs.godotengine.org/en/stable/classes/class_stringname.html)). Once a hash is saved, its
      function is pinned from 1.0.0.
  - **Choice 5: a lookup answers here, gone, or unloaded.** A handle to an entity in an unloaded zone stays valid and
    resolves again when its zone loads, so its slot stays reserved meanwhile. Which unloaded entities keep a slot in a
    very large world, and the lookup table's own ceiling, are KYR-61's.
  - **Left to part b:** the spellings (a lookup, a command, the two read modes, a keyed draw, a sort key, a budget, a
    requirement, scene records), the day-one engine components, the generator's naming rule, and the names.
- **2026-11-07, the owner: question 8 part b, in part — a parameter's meaning comes from its type alone, and the step's
  time is `const ref Time time`.** The owner: "Yes types only I like your proposed const ref Time time", and "Yes file
  KY-24".
  - **How the generator reads a system:**
    - It reads only the functions a system record names. The record's key is the function's name (`"fly"` names
      `fly`), which is the one naming convention.
    - For each, it asks the kama compiler for every parameter's name, mode (`ref`, `const ref`, a copy) and type, and
      looks the type up in a fixed list. `kama query` drops the mode today and gives no signature at a declaration,
      which is KY-24, so until kama answers the generator would read the signature line itself.
    - **Names carry no meaning.** `Handle me` is this entity's handle because its type is `Handle`, and renaming it
      changes nothing. The generator uses the names only to write the call, since kama calls are named
      (`me: c.handle[i]`). It never reads the body, which kama checks.
    - Anything outside the list is refused, with a message naming the fix.
  - **`const ref Time time`** gives the step's length and number (`time.dt`, `time.step`). It replaces the hello cube's
    `float32 dt`, which only its name could identify, so the rule has no exception. The hello cube keeps its line count
    (question 7, revised below and in [../REFERENCE.md](../REFERENCE.md)).
  - **Why:** a rename never changes behaviour, a person or an agent learns one list, and the generator can check every
    parameter. Bevy's systems work the same way: their parameter types tell its scheduler what they touch.
  - **Considered:**
    - **Conventions by name,** such as `dt` or `me`. A typo or a rename would silently change what is passed.
    - **Access declared in the record** instead of read from the signature. It states the signature twice, against
      question 1's "a body's signature is its stated access", though kama would then check the generated call against
      the function, so a mismatch could not compile.
  - **Proposed with it, and still open:** the rest of the list. *Probed on 0.9.857* with two towers shooting at each
    other (three systems, hand-written stand-ins for the engine and the generator's output): seed 7 ended with both
    towers destroyed in one step, seed 8 with one left on 12 hp after a critical hit, and the same seed replayed the
    same battle.

    | A system takes | It means | The scheduler learns |
    |---|---|---|
    | `ref C`, `const ref C` (C a component) | this entity's C, written or only read | writes or reads C |
    | `ref S`, `const ref S` (S a singleton) | the world's or zone's one S | writes or reads S |
    | `Handle` | this entity's handle | nothing |
    | `const ref Previous<C>`, `const ref Current<C>` | any entity's C, as of last step or live; always written, neither is implied | nothing to wait for, or after C's writers |
    | `ref Create<P>` (P a prefab), `ref Destroy`, `ref Gain<C>`, `ref Lose<C>` | queued structural changes | adds or removes rows |
    | `ref Inbox<C>` | sends a C to other entities, combined by C's record and delivered at the phase's end | writes C at the phase's end |
    | `const ref Prefabs` | the prefab records' values, to start a new entity from | nothing |
    | `const ref <System>Draws` | keyed draws for the purposes the system's record lists, hashed by the generator | nothing |
    | `const ref Time` | the step's length and number | nothing |

    - **Why typed queues, and not `cmd.spawn(prefab:)`:** `spawn` is a kama keyword (KY-23 asks for it as a method name),
      kama has no generic methods (a recorded non-goal), and a typed queue puts what a system creates in its signature,
      which the scheduler and the budgets read.
    - **Why purposes are declared, and not strings:** a typo is a compile error, as actions' are (question 7). *Measured
      on 0.9.857:* hashing the string at every draw cost nothing in release, where the C compiler hoisted it, and 31 ns
      against 18 ns per draw in debug (125 ns for a 33-byte purpose). kama's `comptime fn` takes no strings by design;
      the generator runs first and bakes the key.
    - **The costs, measured on 0.9.857, release:** a keyed draw 1.9 ns against 0.5 ns for std's sequential `Rng`
      (xoshiro256\*\*), and a queued message 2.4 ns against 1.35 ns for a direct write. Neither ordinary form keeps a
      parallel run deterministic.
  - **Found while preparing it, on 0.9.857:** KY-23 (`spawn` as a method name), KY-24 (`kama query` and parameter
    modes), KY-25 (a method called through a misspelled field) and KY-26 (an element passed by `ref` beside its
    container by `const ref` is not refused, though the same with a field is). KY-20 is fixed and removed.
  - **Left to part b:** the rest of the list above, the record spellings, the day-one engine components, the
    generator's naming rule and the names.
- **2026-11-07, the owner: the generator's output is split into files and not committed.** The owner: "I could see the
  value in not committing generated output at all. It would provide far less noise so perhaps we do start with that.
  splitting still works well though. it allows for cached kama builds and such as well as organizing the generated
  logic."
  - **What:** the generator writes into a git-ignored folder of the game's package (question 1): a file per archetype
    (its table and chunk types), one per phase (its pass), and small ones for prefabs, draws and actions, each headed as
    generated. The repository holds the records and the system bodies. The generator runs before a build or a check,
    and before an editor reads the game.
  - **Why:** a diff shows the record change and nothing generated, and generated code never conflicts in a merge.
  - **What it costs:** the game's own systems name generated types (`Create<Bullet>`, `Prefabs`, a system's draws), so
    a fresh clone, an editor and an agent's `kama check` all need the generator to have run first. kama's manifest has
    no step that runs a tool before a build (none among the keys `docs/packages.md` lists, read 2026-11-07), so a kyoten
    command runs it. Whether to ask kama for such a step is open.
  - **The build cache, probed on 0.9.857:**
    - A debug build writes one C file per kama source file and keeps each object in `.kama-cache/`. After one file of
      the generated module was edited, only its object was rebuilt.
    - A `--release` build folds the program into one C file and caches nothing.
    - kama's `docs/targets.md` adds that a changed declaration (a new type or field, which most record edits make)
      rewrites the shared header and recompiles every file. It measures that at 0.37 s cold for 61 files.
    - So the split mostly buys organization, and the cache helps a change that leaves declarations alone. kama's SPEC
      still describes the old build, which is KY-27.
  - **Considered:** committing the output, with CI regenerating and comparing. A diff then shows what a record change
    did, and a fresh clone builds without the generator, at the cost of noise and of conflicts settled by regenerating.
  - **Also probed:** the game's modules and the generated module import each other (a system names a generated prefab
    type, which holds the game's components), and kama loads that cycle once.
- **Raised by the owner the same day, and open: collisions, readability and soundness.**
  - **What they asked:** whether objects would scope systems better than free functions ("making sure you don't have
    'fire' functions all over which is hard to reason about and grep"), and what a singleton is and where it lives.
    They noted that a singleton is usually a smell unless it is injected.
  - **Probed on 0.9.857,** with a package of three modules:
    - **Names:** two modules each export a system `fire`, and they build side by side (`game__towers__fire` and
      `game__player__fire` in C). kama refuses a second exported `fire` in one module (*"duplicate function 'fire' —
      kama has no overloading, so a name may be declared only once in its module"*).
      `kama query <kama.json> <file> --search fire` lists each with its file.
    - **Functions or methods:** the same system compiles to the same C function in all three forms: a free function, a
      method of its component, and a static of a type with no fields. A plain method cannot be added to a type another
      package declares (only a contract's adapter can), so a system that writes the engine's `Transform` cannot live on
      it.
    - **State hidden outside the world:** kama allows a module `static`, one per isolate, so each worker would hold its
      own copy. `kama query --symbols` lists one, and `--refs` finds its uses.
  - **Proposed:**
    - A system's name is its kama path (`towers::fire`), never the bare name: in a record, an error, the profiler and
      the schedule view.
    - Systems are functions only.
    - The generator refuses a module `static` in a game's package.
    - A singleton is a field of the generated world or of a zone, passed only to the systems that name it, and is
      renamed a **world component**, since "singleton" suggests global access.
- **2026-11-07, the owner: world components, and systems as functions named by their path.** The owner: "You
  answered my singleton concern and yes we should steer clear of that term... world component sounds much better",
  "Functions are fine and it sounds like you are adding scope now which helps the collision problem", and, on a
  manifest step that runs the generator, "yes you can file that as a gap". This settles the collisions, readability and
  soundness items raised above.
  - **A singleton is now a world component:** a component the world, or a zone, holds one of, rather than each entity.
    - It is a field of the generated world or zone, passed only to the systems that name it as a parameter. So it is
      injected, never reached globally, and the scheduler sees every reader and writer.
    - It is not called a "resource", Bevy's word, since a kama `type resource` is an owning type.
    - Earlier entries keep the word "singleton".
  - **Systems are free functions,** not methods or statics of a type. One parameter list states all of a system's
    access, and a system that writes the engine's `Transform` needs no type to live on.
  - **A system is named by its kama path** (`towers::fire`), never the bare name: in its record, an error, the
    profiler and the schedule view. kama keeps the path unique.
  - **Still proposed, and open** (first recorded here as decided, and corrected the same day):
    - The generator refuses a module `static` in a game's package, so no state lives outside the world.
    - The rest of the parameter list in the entry above, with `ref S` and `const ref S` naming a world component.
      The owner: "I'm not sure yet if the rest of the parameter list was decided, but it may be".
  - **Filed:**
    - KY-28: no manifest step runs a generator before analysis.
    - KY-29: a listed module whose folder is missing is reported as unlisted. That is the first message a fresh clone
      of a game shows.
  - **Raised the same day, and open:** the owner's first meaning of "system" was the large area: audio, networking,
    graphics, UI, AI and gameplay. [../VISION.md](../VISION.md) says "Each system updates at the frequency that makes
    sense for it", and question 3, choice 1 named that area an engine module. The open question is whether "system"
    goes back to the area, with the function taking another word. The owner leans that way: "'processor' or
    'handler' or something along those lines do seem to describe these small functions better", with one concern,
    the muscle memory agents bring from Bevy and Unity.
- **2026-11-07, the owner: the vocabulary is module and processor, and the generator refuses a module `static`.**
  - **The owner's words:**
    - on statics: "AH... so basically the generator refuses statics? I agree with this... I was hesitant to add globals
      to kama for this very reason but as you noted they are something a general purpose systems language does need
      for some things";
    - on the area: "I think module makes more sense as it maps to the kama module usage as well. engine module, game
      module, either in general is a 'module'";
    - on the function: "I do still like 'processor' better here ( system implies something large and processors can
      be small ). it also describes what they do", and "processor record sounds good";
    - on groups: "group still makes sense. should likely be qualified though to not confuse with layer groups.
      processor groups";
    - on rates and state: "A module's record sets a default rate sounds good to me. world component yes. owned by
      module".
  - **Module:** an area of code, exactly one kama module, with its own records, processors, components and world
    components.
    - An **engine module** is the engine's (input, render, audio, net, physics, UI). A **game module** is a game's
      (gameplay, AI, towers).
    - A library is still what an engine module sits on. The engine's third layer keeps its name, engine modules.
  - **Processor:** a function over components that the scheduler runs, whose parameters are its access. Until now this
    doc called it a system.
    - Its record is a **processor record**.
    - Its name is its kama path: module `towers`, processor `fire`, written `towers::fire`.
  - **Processor group:** the processors of one phase ordered together. It is qualified so that it is not confused with
    a group of entities.
  - **A module's record sets a default rate,** and a processor's record may override it.
  - **A world component is owned by a module.**
  - **"System" is retired,** as "subsystem" was.
    - What Bevy, flecs and Unity Entities call a system is a processor. What Bevy calls a plugin, and flecs a module,
      is a module.
    - That map goes into REFERENCE and AGENTS.kyoten.md, for the muscle memory agents bring.
    - Earlier entries keep the word "system".
  - **The generator refuses a module `static`** in a game's package, and points to a world component.
    - **Why:** a static sits outside the world. A save, a rollback or a replay does not restore it. kama gives each
      isolate its own copy, so a processor split across workers would count differently than a serial run. The
      scheduler cannot see it.
    - **How:** `kama query --symbols` lists each static, and `--refs` finds every use (probed on 0.9.857).
  - **Still open:**
    - a better name for a processor's keyed random values (`FlyDraws`), since "draw" reads as rendering. The owner
      asked about `RandomGenerator`. *Proposed the same day:* `<Processor>RandomKeys`, each purpose a `RandomKey`.
      - **The technique has a name:** a counter-based random number generator, a stateless function of a key and a
        counter (Random123's Philox, SC11, "Parallel Random Numbers: As Easy as 1, 2, 3"). Games know it as a
        noise-based RNG (Squirrel Eiserloh, GDC 2017).
      - **Why not "generator":** a generator usually holds state and returns the next number on each call, as std's
        `Rng` does. A key returns the same value for the same entity, which is the point.
      - **A gap found while naming it:** several values for one entity in one step (eight pellets) need a counter
        argument (`n:`), which the probed spelling lacks.
    - the entity group's name. The owner's "layer group" is the group of entities inside a layer ("Groups divide a
      layer", 2026-11-06), so the name is proposed for it, beside processor group;
    - the rest of the parameter list.
  - **Next:** reword REFERENCE, AGENTS.kyoten.md and SPIKE's current text to module and processor, with the map above.
- **2026-11-07, the owner: keyed random values are random keys, and the group inside a layer is a layer group.** The
  owner: "I like your keys spelling and yes we need to address the gap you found", and on the layer group, "yes agreed".
  - **A processor takes `const ref <Processor>RandomKeys`,** with one `RandomKey` per purpose its record lists:
    `random.crit.chance(who: me, p: 0.25)`. The parameter's name is free. "Draws" is retired.
  - **The gap is to be closed:** a random key takes a counter beside the entity, so one entity can get several values in
    one step (eight pellets). Its spelling comes with the record spellings.
  - **Layer group** names the group of entities inside a layer, and **processor group** the processors of one phase
    ordered together.
- **2026-11-07, the owner: what a processor takes is decided.** The owner: "Yes this all sounds good so far."
  - **The list:**

    | A processor takes | It gets | The scheduler learns |
    |---|---|---|
    | `ref C`, `const ref C` (C a component) | this entity's C, written or only read | writes or reads C |
    | `ref W`, `const ref W` (W a world component) | the world's or the zone's one W | writes or reads W |
    | `Handle` | this entity's handle | nothing |
    | `const ref Previous<C>`, `const ref Current<C>` | any entity's C, as of the last step or live. One is always written; neither is implied | nothing to wait for, or after C's writers |
    | `ref Create<P>` (P a prefab), `ref Destroy`, `ref Gain<C>`, `ref Lose<C>` | queued structural changes, applied at the end of the phase | adds or removes rows |
    | `ref Send<C>` | sends a C to other entities, combined as C's record says and delivered at the end of the phase | writes C at the end of the phase |
    | `const ref Prefabs` | the prefab records' values, to start a new entity from | nothing |
    | `const ref <Processor>RandomKeys` | a random key per purpose the processor's record lists | nothing |
    | `const ref Time` | the step's length and number | nothing |

  - **Every queue adds with `.add(…)`:** `bullets.add(prefab: b)`, `destroy.add(who: me)`,
    `damage.add(to: s.target, value: Damage.of(amount: power))`.
  - **`Send<C>` replaces the proposed `Inbox<C>`,** which read as receiving. The other queues are verbs, and `Send`
    matches them.
  - **A random key's counter is a derived key:** `random.spread.nth(n: i).unit(who: me)` gives pellet `i` its own
    value, and `random.crit.chance(who: me, p: 0.5)` stays the usual call.
    - kama has no default parameters and no overloading, so the counter cannot be an optional argument.
    - JAX derives keys the same way, rather than advancing a stream *(from memory, not checked)*.
  - **Probed on 0.9.860:** eight pellets drew distinct spreads, pellet 1 asked twice gave the same value, and a type
    named `Send` compiles.
