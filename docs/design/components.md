# Components: how a game holds state and behaviour

**Status:** questions 1–5 decided on 2026-11-05.
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

Questions 6–9 are open; question 9 was added at question 2. The model's picture and vocabulary are gathered in
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
6. **Scale and storage.** Fixed capacities (FFD, the-mallow-man: predictable, `@noheap`-friendly) or growable stores?
   How are large components kept off the stack (the KM-29 lesson)?
7. **The prototype path.** A Three.js-style prototype wants "make a cube, give it a spin". What is the shortest correct
   spelling in the component model ([ai-first-api.md](ai-first-api.md))?
8. **Growing in phases.** Unity's component model grew in phases (KYR-3). Which parts of kyoten's model must be right
   on day one, because changing them later would break every game, and which can arrive later without that?
9. **World data.** *(Added 2026-11-05 at question 2.)* Some data belongs to space, not to an entity: a voxel world, a
   heightfield, a destruction state, a generated region. Question 2 puts it in world stores of cells, keyed by
   coordinate within a zone (G7). The questions are:
   - **The cell's format:** dense, palette or sparse, and who chooses it. Minecraft's sections are 16×16×16 blocks,
     each with its own palette and packed indices of at least 4 bits.
   - **How cells stream** in and out with their zone.
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
      mid-count ([../KAMA_GAPS.md](../KAMA_GAPS.md)).
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
