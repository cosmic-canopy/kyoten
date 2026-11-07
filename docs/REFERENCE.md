# kyoten's model: the picture, the vocabulary and the prior art

**Status:** a living reference, started 2026-11-05 at [design/components.md](design/components.md) question 3. Every
item says whether it is **decided** (with a link to the decision) or **proposed** (still open, with the question that
settles it). The decisions themselves stay in each design doc's *Decided*; this page gathers them so a human or an
agent can learn kyoten's model in one read.

It becomes the core of kyoten's SPEC once code exists. It is plain markdown so it can be built into a PDF and into
kyotenengine.com's docs, the way kama-lang.org is built from kama's own `docs/`: one source, rendered, never copied
([design/website.md](design/website.md), KYR-39).

## Who writes what

**A game is made in the game's repository, not in the engine** (the owner, 2026-11-05): "Ideally the engine doesn't
need to change much to develop a game. Much of the game development process work is done in the 'game' repo... most
of that is our job to make it general purpose enough for the game repo to create projects per-game." This is the
rule in [../AGENTS.kyoten.md](../AGENTS.kyoten.md): the engine drives games and never names one.

```
 A GAME'S DEVELOPERS AND AGENTS WRITE        THE GENERATOR WRITES               KYOTEN RUNS IT
 ┌─ the game's repo ─────────────────────┐
 │ records: components, prefabs,         │──┐   ┌─ the World (plain kama) ──┐
 │   systems, budgets, zones             │  ├──►│ zones · tables · chunks   │──► run(world)
 │ system bodies:                        │  │   │ side stores · singletons  │    in the frame
 │   fn void integrate(ref Pos p,        │──┤   │ input() update()          │    layer
 │       const ref Vel v, Step s) { … }  │  │   │ constraints() output()    │
 └───────────────────────────────────────┘  │   └───────────────────────────┘
 ┌─ kyoten, written once by its team ────┐  │    generated into the game's build, and
 │ each engine module ships records and  │──┘    checked by kama like hand-written code
 │ bodies of the same kinds              │
 └───────────────────────────────────────┘
```

- **A game changes engine behaviour without editing the engine.** Its records sit in a layer above the engine's, so a
  game tunes a physics iteration count or replaces an engine system's record by stacking its own (the project database's
  layers, [design/project-database.md](design/project-database.md) § Decided).
- **When a game needs something the engine lacks,** the engine gains it as a pattern or a component every game can use
  (*decided*, [../AGENTS.kyoten.md](../AGENTS.kyoten.md) § Rules).

## The engine's layers

*Decided at components question 3, choice 6 (2026-11-05), on architecture question 2's module rule* ([design/architecture.md](design/architecture.md)
§ Decided, question 2). Each layer imports only the layers above it.

```
 ┌───────────────────────────────────────────────────────────────────────────────┐
 │ 1 frame   phases · the clock · scheduler · input record · World contract · run │
 ├───────────────────────────────────────────────────────────────────────────────┤
 │ 2 world   engine components (Transform, MeshRef…) · table, chunk, side-store,  │
 │           command and lookup types · query contracts (a raycast, a nav path)   │
 ├────────┬─────────┬─────────┬────────┬─────────┬────────┬──────────────────────┤
 │ 3 input│ render  │ audio   │ net    │ physics │ UI     │ engine modules; none  │
 │ window │ graphics│ WebAudio│ sockets│ Jolt*   │ HTML*  │ imports another       │
 ├────────┴─────────┴─────────┴────────┴─────────┴────────┴──────────────────────┤
 │ 4 agent surface: reads every module, imported by none                         │
 └───────────────────────────────────────────────────────────────────────────────┘
   * a borrowed backend first, kyoten's own later; the module's interface stays
```

Borrowed backends are the owner's direction of 2026-11-05: Jolt and RmlUi may serve first, and kyoten builds its own
as it goes. A game's UI is HTML and CSS, the browser's own on the web and kyoten's counterpart natively
([SPIKE.md](SPIKE.md) § Standing direction).

## The world at run time

*Decided at components questions 1 and 2* ([design/components.md](design/components.md) § Decided), except world stores,
which are question 9.

```
 World  (a value: copied, saved, restored — G3), holding the active scene
  ├─ Zone (0,0)  (a cell of the scene's grid: the unit of loading, budgets and coordinates — G7)
  │   ├─ Table ((0,0) × "actors" × Soldier) ── Chunk ── Chunk    a chunk: up to N soldiers,
  │   ├─ Table ((0,0) × "actors" × Crate) ──── Chunk             Pos[N] Vel[N] Hp[N] …
  │   └─ World store: terrain or voxel cells (question 9)
  ├─ Zone (1,0) …
  ├─ Non-spatial layers ("rules", "inventory"): one block each for the scene
  ├─ Side stores: Burning, Stunned       any entity may gain or lose one
  ├─ Singletons: physics world, RNG      one per world or zone, owned by a module
  └─ Assets (read-only, by handle): meshes, clips, navmeshes
 Entity = Handle (slot, generation) ──lookup──► (zone, layer, table, chunk, row), and a group id it carries
```

## How a world is divided

*Decided 2026-11-06, the owner's model* ([design/components.md](design/components.md) § Decided).

```
 Scene "level-1"   one is active at a time; the app's record names the first
  ├─ Zones    a grid of squares (2D) or cubes (3D), sized in metres            spatial
  │           loaded by rings: around each streaming source for the simulation,
  │           around each view for drawing. Depth k loads (2k+1)² or (2k+1)³ per source
  ├─ Layers   declared at design time, flat, each spanning every zone          loading and memory
  │             "actors"     spatial      simulated    rings 0–2   a block per zone
  │             "props-far"  spatial      drawn only   rings 2–6   per machine
  │             "rules"      non-spatial  simulated                one block for the scene
  │             "hud"        non-spatial  drawn only
  │           states: off · loaded (frozen and hidden) · active
  └─ Groups   inside a layer, nested freely, an id per entity                   switching
                "actors" ▸ "wave 3" ▸ "flankers"
```

- **A layer if the things should leave memory, a group if they only switch.** Realities, LOD bands and UI are layers;
  waves, a puzzle's pieces and a room's lights are groups.
- **What is simulated comes from streaming sources,** components on simulated entities, the same on every machine.
  **What is drawn comes from views,** which are Output's and may differ per machine.
- **Two units of distance:** metres, and rings of zones away.
- **Every scene starts with one zone, one layer and one group,** so each is there to be found.
- **An entity crossing a zone, or changing layer,** moves blocks at the end of the phase, and its handle stays valid.

## One step, then a display frame

*The phases, rates, order and read-only Output are decided* ([design/frame-phases.md](design/frame-phases.md) §
Decided). *Snapshot reads and queued structural changes were decided at components question 3.*

```
 each simulation step ────────────────────────────────────────────►  each display frame ►
 ┌ Input ────────┐  ┌ Update ──────────────┐  ┌ Constraints ──────┐  ┌ Output (read-only) ┐
 │ readInput     │  │ group movement       │  │ group physics ×N  │  │ reads the snapshot │
 │ netReceive    │─►│   integrate  regen   │─►│   broadphase→solve│─►│  extract → draw    │
 │ (recorded)    │  │ group ai (after it)  │  │ group rules       │  │  cues → audio      │
 │               │  │   target ← snapshot  │  │   arenaBounds     │  │  netSend           │
 └───────────────┘  └──────────────────────┘  └───────────────────┘  └────────────────────┘
   spawns and despawns are queued, and apply at the end of each phase, sorted by chunk
 A system = a function + its record.  Record: phase · group · order · rate · iterations
            Its signature is its access:  ref = writes,  const ref = reads
```

## The hello cube

*Decided at components question 7, with ai-first-api question 1 and rendering question 3* ([design/components.md](design/components.md)
§ Decided), and revised on 2026-11-06 so actions belong to a player. A sketch: the file format is project-database
question 2, and the spelling is components question 8 (`const ref Time time` since 2026-11-07, part b).

```json
{ "prefabs":  { "cube": { "mesh": { "shape": "box" }, "spin": { "rate": 2 },
                          "actions": { "player": 1 } } },
  "systems":  { "turn": { "phase": "Update" } },
  "actions":  { "faster": { "kind": "button" } },
  "bindings": { "faster": { "keyboard": "ArrowUp", "gamepad": "RightShoulder" } },
  "scenes":   { "hello": { "place": ["cube"] } } }
```
```kama
@generate(Serializable, Deserializable, of)
type value Spin { @field(default) public float32 rate = 1; }

fn void turn(ref Transform t, ref Spin s, const ref Actions input, const ref Time time) {
    if (input.faster.held) { s.rate = s.rate + time.dt; }
    t.yaw = t.yaw + s.rate * time.dt;
}
```

- **The game writes** a prefab, a component (`Spin`), a system (`turn`), an action and its bindings, and a scene that
  places the cube. It also owns a `main` of about two lines, which `kyoten new` writes.
- **The engine supplies** the defaults as records: a window or canvas, a camera, lights, a lit material, one player
  bound to the local keyboard and first gamepad, and the scene's one zone and one layer. The app's first scene is the
  only one unless its record names another. `mesh` requires a transform and a material (question 8).
- **The generator writes the rest:** the cube's table; an `Actions` component with one field per action, which the
  Input phase fills each step from the player the cube names; and Update's call to `turn`.
- **The target:** at most 20 non-blank lines across all files and eight concepts (app, record, scene, prefab,
  component, system, action, player), on web and native, held by CI.

## The vocabulary

*Decided at components question 3, choice 1 (2026-11-05):* "system" means the function, as in Unity, Bevy and flecs;
the large engine areas are **engine modules**; "subsystem" is retired.

| Term | Means | Status |
|---|---|---|
| **Engine** | kyoten: one kama package in four layers | decided |
| **Engine module** | one area of the engine (input, render, audio, net, physics, UI), one kama module, with its own records, system bodies and singletons. It never imports another | decided |
| **Layer** | a group of modules with an import rule: frame, world, engine modules, the agent surface. The word is shared with a scene's layers (below) until question 8 names them | decided |
| **Library / backend** | what an engine module sits on (`@kama/graphics`, `@kama/window`). A backend is a borrowed library behind the module's interface, replaced later (Jolt, RmlUi) | decided (the direction) |
| **Game** | a separate package and repository: its records, its system bodies, and the world generated from them | decided |
| **Record** | a project-database entry declaring a component, prefab, system, budget or zone. Its format is the kama type it describes, through serde | decided (question 5, choice 2) |
| **Source** | anything that satisfies the record-source contract: files in git, a baked pack, a database, a URI where the platform allows | decided (project-database question 11); the name is proposed |
| **Content layer** | a named slot in the order of sources: engine, game, DLC, patch, mod, local by default. Each holds any number of sources, each with a priority | decided (project-database question 11); the name is proposed |
| **Patch** | what a source says about a record: only the fields it changes, merged by RFC 7396 | decided (project-database question 11) |
| **Stack** | every source in its resolved order. Its identity is in every save, replay and match | decided (project-database question 11) |
| **Generator** | the kyoten tool that writes the World from records, as plain kama | decided |
| **World** | the whole simulation state, generated per game: a value that can be copied, saved and restored | decided |
| **Scene** | what a designer opens and the build lists. One is active at a time, and the app's record names the first. It divides spatially into zones and logically into layers | decided (2026-11-06) |
| **Zone** | a cell of the scene's grid, a square or a cube sized in metres: the unit of loading, budgets and coordinates | decided (G7; a grid since 2026-11-06) |
| **Ring** | a distance in zones: ring 0 is a source's own zone, ring k the zones k steps away. A depth of k loads (2k+1)² zones in 2D, (2k+1)³ in 3D | decided (2026-11-06) |
| **Streaming source** | a component on a simulated entity that loads the zones around it for the simulation, the same on every machine. Each player's character has one by default | decided (2026-11-06) |
| **View** | a camera drawing into a target (the screen, part of it, a texture, an eye). It loads what is drawn around it and may differ per machine | decided (2026-11-06) |
| **Layer** (of a scene) | a set of entities declared at design time that spans every zone and loads as one: the unit of loading and memory. Spatial or not, simulated or drawn only, on in a range of rings, and off, loaded or active | decided (2026-11-06); its name is question 8 |
| **Group** (of entities) | a set inside one layer that switches as one, nested freely: an id per entity, and no memory of its own | decided (2026-11-06); its name is question 8, since a group of systems is below |
| **Budget** | a record limiting one scope (world, scene, zone, layer, match, player, team). A (zone, layer, prefab) budget sizes a table, and a limit over a group is a count rule. Every store's ceiling comes from one | decided (question 6) |
| **Footprint** | the sum of every ceiling per scope, which the generator reports as the game's simulation floor | decided (question 6) |
| **Archetype** | a set of component types, fixed when the game is built. The generator writes one table type per archetype | decided (question 5, choice 3) |
| **Prefab** | a named archetype with its defaults. Prefabs of one archetype share generated code, so a record alone can add one | decided (question 5, choice 3) |
| **Entity** | one thing in the world, an instance of a prefab | decided |
| **Handle** | an entity's runtime id: 8 bytes, a 32-bit slot in the world's lookup table and a 32-bit generation, the same on every platform. The slot says where the entity lives now; the generation, bumped when the slot is freed, makes a stale handle answer "gone". A lookup answers here, gone or unloaded | decided (question 8, 2026-11-06) |
| **Placed name** | a placed entity's name in its scene's records ("door-12"), which other records use to refer to it. The loader resolves it to a handle when its zone loads, and may key it by a 64-bit hash | decided (question 8, 2026-11-06) |
| **Component** | a plain value, one piece of an entity's data, of one of four kinds. A kama type plus its record: the type holds the fields, and the record says how it is stored, kept, interpolated and saved | decided (questions 2 and 5) |
| **Table** | all the entities of one prefab in one zone and layer, made from its archetype's table type. Its ceiling is its (zone, layer, prefab) budget | decided (the layer since 2026-11-06) |
| **Chunk** | a fixed block of up to N entities of one table, one array per component: the unit of parallel work, of a snapshot and of a budget. N is chosen per archetype from a 16 KiB target, at most 128 | decided (N's rule is measured in slice B) |
| **Side store** | one component type any entity can gain or lose at run time | decided |
| **World store** | data that belongs to space, not to an entity: terrain, voxels, destruction | decided; its design is question 9 |
| **Singleton** | a store holding one value per world or per zone: the physics world, an RNG, a spatial grid. A system's state between steps lives in one | decided (question 3, choice 2) |
| **Asset** | shared read-only data loaded with a zone, reached by handle: a mesh, a clip, a navmesh | decided |
| **System** | a function over components, plus a record that schedules it (phase, group, order, rate, iterations). Its signature is its access: each parameter means what its type says, and names are free | decided (question 3, choices 1 and 2; types only at question 8 part b, 2026-11-07) |
| **Phase** | Input, Update, Constraints, Output: a place in the order | decided |
| **Group** (of systems) | systems of one phase ordered together; a Constraints group may iterate as a whole. The word is shared with a group of entities until question 8 names them | decided |
| **Schedule** | the resolved order of every system, with its access, rate and cost, shown to humans and agents | decided |
| **Step** | one tick of the simulation's one clock | decided |
| **Frame** | one display refresh; Output runs once per frame | decided |
| **Snapshot** | the world, or the columns other systems read, as it stood at the end of a step. A system reading other entities sees it by default | decided (question 3, choice 3) |
| **Command** | a queued structural change (spawn, despawn, gain, lose), applied at the end of its phase | decided (question 3, choice 4) |
| **Action** | a semantic input a game declares (`faster`, a button or an axis). The generator writes one field per action into an `Actions` component, which an entity carries to name the player that drives it; the Input phase fills it each step | decided (question 7, choice 4, revised 2026-11-06) |
| **Binding** | a record mapping an action to a device's input, a default per device, rebound by the developer and the player. It passes through adapters | decided (question 7, choice 4); adapters are the owner's direction for KYR-54 |
| **Player** | a numbered slot that drives entities through their `Actions`. A local device, a network slot, a bot or an agent is bound to it, and a budget caps how many there are | that actions belong to a player is decided (question 7, revised 2026-11-06); the rest is the owner's direction for KYR-54 |
| **Player binding** | what attaches a source to a player: keyboard 1, gamepad 2, a network slot, a bot or an agent | the owner's direction (2026-11-06), decided at KYR-54 |
| **Adapter** | a step in a binding that filters a control's value or converts it to the action's kind: a dead zone, a scale, a stick or trigger as a button, a button as an axis, two buttons as −1 to 1, a filtered accelerometer. Editor controls may use the same idea (human-tools question 4) | the owner's direction (2026-11-06), decided at KYR-54 |
| **Input context** | a set of bindings a player switches on or off, with a priority (on foot, driving) | the owner's direction (2026-11-06), decided at KYR-54 |
| **Required component** | a component another component's record requires (a mesh requires a transform), the engine's or a game's. One with defaults is added to the archetype at build time; one without must be listed, or the build refuses the prefab. The generator shows where each came from, and a query answers it | decided (question 8, 2026-11-06); its spelling is the rest of question 8 |

**Older wording.** [design/frame-phases.md](design/frame-phases.md) and [design/architecture.md](design/architecture.md)
were reworded to this vocabulary on 2026-11-05, except inside quotes. Research docs written before then, and quotes,
may still say "subsystem" for **system**, or "system" for an **engine module** such as render or audio.

**How a system reads other entities** (*decided*, question 3, choice 3). It declares one of two modes, and the scheduler
never changes it, so serial and parallel runs see the same values:
- **the previous step**, the default: other entities as they were at the end of the last step. It always runs in
  parallel, needs no order against writers, and may write what it reads;
- **this step**: other entities' current values. It runs after their writers and may not write what it reads. In a
  parallel group its writes are staged and copied in at the group's end.

**The order promise** (*decided*, question 4). The engine promises it for every game, and nothing is opted into:
- **the same history gives the same order** on every run and machine, and a save keeps chunks, free slots and handle
  generations exactly. Threads still take work in any order; only the order results are joined in is fixed;
- **removal is swap-and-pop**, in tables and side stores. Spawn order is not promised; a system that needs an order
  sorts by a key component;
- **randomness is keyed** by world seed, step, handle and purpose, so a draw does not depend on visiting order;
- **a combined result** (a sum, a minimum, "who hit first") folds within each chunk, then over chunks in chunk order,
  and ties break by handle.

Whether the simulation is also bit-identical across platforms is
[design/replay-and-determinism.md](design/replay-and-determinism.md) question 1 (*open*).

**How records layer** (*decided*, components question 5 with project-database question 11):
- **A component is a kama type plus its record,** and a record's format is that type. A prefab names an archetype the
  build has, so data alone can add one; a new component, archetype or system needs a build.
- **A source patches fields,** never whole records. Keyed maps merge per key, `null` removes, and plain lists are
  replaced whole. A prefab variant is its base plus its own patches.
- **The order is data.** Named content layers (engine, game, DLC, patch, mod, local by default) each hold any number of
  sources by priority, and the stack resolves to one order or refuses a cycle.
- **Checks run per source, strictly, then over the stack,** and an error names the topmost source that set the value.
- **The stack is part of the history:** its identity is in every save, replay and match, and a source that changes
  while running applies at a step boundary as a recorded input.

**What is promised** (*decided*, components question 8, 2026-11-06):
- **Nothing is frozen before 1.0.0.** kyoten iterates freely, as kama does at 0.9.x.
- **From 1.0.0, the promise covers what a game touches:** its records, its system signatures, the engine components
  and generated names it uses, handles, and the order. Tables, chunks, N, the generated loops, the scheduler and the
  layout of side stores are not promised, because a game never names them.
- **It is kept** by records that never change meaning silently (wire names and ids, `@deprecated`, new fields with
  defaults), a migration when a record's shape must change, the engine's version in every save, and the examples
  built against every engine change.

**How memory is bounded** (*decided*, components question 6):
- **Every store has a ceiling from a budget record.** By default it is reserved when its zone or world is created; a
  table may instead commit chunks one at a time up to its ceiling, at the end of a phase, never moving earlier ones.
- **A full budget refuses by default,** and the spawning system sees the refusal. Evicting (oldest spawn step, then
  handle) is an opt-in per budget, and development reports every refusal but behaves as release does.
- **The footprint is computed:** the generator sums every ceiling per scope, snapshots, staging and command buffers
  included, and shows the result.
- **Nothing large travels on the stack.** Chunks live in heap blocks reached by `ref`, and every manifest carries a
  32 KiB frame guard on every arm but Windows. A bound on the whole chain is asked of kama (KY-22).
- **Simulation budgets are game rules,** chosen by the sole authority or agreed at matchmaking; Output's vary per
  machine.

## Prior art

Each row is a choice kyoten made or proposes, the engines that made it before, and where kyoten differs.

| kyoten | Prior art | Where kyoten differs |
|---|---|---|
| A table of fixed-size chunks per (zone, layer, prefab) | Unity Entities' archetype chunks, 16 KiB with at most 128 entities ([archetypes](https://docs.unity3d.com/Packages/com.unity.entities%401.4/manual/concepts-archetypes.html)); Unreal Mass, a chunk size per archetype ([Mass](https://dev.epicgames.com/documentation/unreal-engine/overview-of-mass-entity-in-unreal-engine)) | archetypes fixed at build time, tables per zone with ceilings from budgets, N per archetype from the same 16 KiB target (questions 5 and 6) |
| Archetypes fixed at build time, queries precompiled | gecs ([README](https://docs.rs/crate/gecs/latest/source/README.md)) | side stores for components gained at run time |
| The loop generated from a system's signature | Unity's `IJobEntity` ([IJobEntity](https://docs.unity.com/en-us/engine/7000.0/script-reference/unity/entities/ijobentity.md)) | the whole world is generated, and kama checks it |
| Side stores beside tables | Bevy's opt-in sparse sets ([StorageType](https://docs.rs/bevy/0.13.1/bevy/ecs/component/enum.StorageType.html)) | — |
| A schedule built from declared access, at compile time | ecst ([ecst](https://www.github.com/vittorioromeo/ecst)) | **the compiler proves a system stays inside its access**; Unity, Bevy, flecs, Mass and EnTT check at run time or not at all ([research/component-models.md](research/component-models.md)) |
| Order by groups, before and after, first and last | Unity Entities' `UpdateInGroup`, `UpdateBefore`, `UpdateAfter`, `OrderFirst`, `OrderLast` ([update order](https://docs.unity3d.com/Packages/com.unity.entities%401.2/manual/systems-update-order.html)) | a cycle or an unordered conflict is refused at start-up |
| Flags for components that come and go often (later) | Unity's enableable components ([manual](https://docs.unity3d.com/Packages/com.unity.entities@1.0/manual/components-enableable-intro.html)) | — |
| Bounded lists inline in a chunk, with a stated rule when full | Unity's dynamic buffers ([manual](https://docs.unity3d.com/Packages/com.unity.entities@1.2/manual/components-buffer-introducing.html)) | refuse or spill, stated per list |
| Shared read-only assets by handle | Unity's blob assets ([blob assets](https://docs.unity3d.com/Packages/com.unity.entities@6.6/manual/blob-assets-concept.html)) | — |
| Queued structural changes, played back in an order threads cannot change | Unity's command buffers, sorted by a sort key such as the chunk's index ([playback](https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/systems-entity-command-buffer-playback.html)) | the sort is always on |
| Reading other entities from a parallel system | Unity's `ComponentLookup` reads them live, checked by the safety system at run time ([ComponentLookup](https://docs.unity3d.com/Packages/com.unity.entities@1.3/api/Unity.Entities.ComponentLookup-1.html)) | the previous step's snapshot by default, or this step's values declared by the system, both proven at compile time (question 3, choice 3) |
| World data in cells with palettes | Minecraft's sections of 16×16×16, each with its own palette ([chunk format](https://wiki.vg/Chunk_Format)) | question 9 |
| Pre-fractured destruction | Unreal Chaos's geometry collections ([destruction](https://dev.epicgames.com/documentation/unreal-engine/destruction-overview)) | question 9 |
| Grid cells loaded around streaming sources | Unreal's World Partition: "Each Player Controller is used as a World Partition streaming source", with a cell size and loading range per grid ([World Partition](https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition-in-unreal-engine)) | distance in rings of zones; streaming sources load the simulation and views load what is drawn (2026-11-06) |
| Simulation distance apart from render distance | Minecraft ([research/game-types.md](research/game-types.md) G8) | the same split, between streaming sources and views |
| Sets that load as one, across the whole world | Unreal's Data Layers, "loaded but not visible" or "loaded and visible", used for "the transition between the Light World and the Dark World" ([Data Layers](https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition---data-layers-in-unreal-engine)); client-only layers switched per machine, runtime ones by the server ([API](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/UDataLayerManager/SetDataLayerInstanceRuntimeState)) | flat layers, each a memory block per zone; nested groups switch without memory (2026-11-06) |
| Far content by distance | Unreal's HLOD layers, each with its own grid, cell size and loading range: "Using more than one grid can negatively impact performance" ([HLOD](https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition---hierarchical-level-of-detail-in-unreal-engine)) | one grid, and each layer names the rings it is on in (2026-11-06) |
| Content loaded wherever it is | Unreal's "Is Spatially Loaded", turned off ([World Partition](https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition-in-unreal-engine)) | non-spatial layers, one block for the scene (2026-11-06) |
| An entity id of an index and a generation | Bevy's `Entity`, whose bits are "liable to change from release to release", and not for "serialization between runs" (0.20.1, [Entity](https://docs.rs/bevy/latest/bevy/ecs/entity/struct.Entity.html)); Unity Entities' `Entity`, an index and a version ([Entity](https://docs.unity3d.com/Packages/com.unity.entities@1.3/api/Unity.Entities.Entity.html)) | 8 bytes on every platform, with a wire form fixed from 1.0.0, since saves keep handles exactly (question 8) |
| Names compared as numbers | Godot's `StringName`: "Comparing them is extremely fast compared to regular Strings" (4.7, [StringName](https://docs.godotengine.org/en/stable/classes/class_stringname.html)) | names the build knows become generated fields; placed names may be keyed by a hash, checked for collisions (question 8) |
| Large worlds: doubles only at the absolute position, floats inside | Box3D ([large worlds](https://box2d.org/documentation3d/large-worlds.html)); Unreal 5's double-precision types ([LWC](https://dev.epicgames.com/documentation/en-us/unreal-engine/large-world-coordinates-in-unreal-engine-5)) | proposed: zone-local floats with whole-number zone coordinates (question 9) |
| An order every game is promised | Godot specifies its order; Unity, Bevy, EnTT and Unreal disclaim it, and Unity's chunk order is "deterministic per world" ([research/component-models.md](research/component-models.md) § 5.4) | promised by the engine, serial and parallel alike (question 4) |
| Cross-platform physics as a build option | Jolt: deterministic on one platform given the same calls and binary; `CROSS_PLATFORM_DETERMINISTIC` is "approximately 8% slower" ([Jolt](https://jrouwe.github.io/JoltPhysics/index.html)) | replay question 1 |
| Hand-coded maths for cross-platform determinism | Box2D: *"The atan2f function in the standard library is not cross-platform deterministic"* ([math_functions.h](https://github.com/erincatto/box2d/blob/main/include/box2d/math_functions.h)) | asked of kama as KY-19, now kama KR-328 |
| A component's shape in code, its values in data | Unity's `IComponentData` structs, Bevy's Rust types, Godot's exported properties, Unreal's `UPROPERTY` *(general knowledge)* | the record's format is generated from the type, and strict reads refuse an unknown field (question 5) |
| Overrides per field, inherited where unnamed | Unity's prefab variants and Godot's instances per property, Bevy's BSN patches per field ([research/component-models.md](research/component-models.md) § 5.5) | RFC 7396 patches, which kama's merge implements |
| The counterexample: the last source wins the whole record | Bethesda's "rule of one", *"the last-loaded plugin's version overrides all others"* ([LOOT](https://loot.github.io/docs/help/introduction-to-load-orders/)) | patches per field, so two mods changing different fields do not collide |
| A load order resolved from dependencies | Factorio: dependency depth first, then names in natural order ([data lifecycle](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html)) | within named content layers, each holding any number of sources by priority (project-database question 11) |
| Caps as data, not code | Cities: Skylines' fixed caps (16,384 vehicles), raised only by a mod patching every routine that assumed them ([research/game-types.md](research/game-types.md) G2; from players' logs, not verified) | every cap is a budget record, and nothing in code repeats its number (question 6) |
| A hello cube in few lines | Three.js: 25 lines (17 non-blank) unlit, 54 (35 non-blank) lit, about eleven concepts ([research/component-models.md](research/component-models.md) § 2); Bevy's `3d_rotation`, 55 lines with a system | records plus one system, at most 20 non-blank lines and eight concepts, reading input, held by CI (question 7, revised 2026-11-06) |
| Actions on the entity a player drives, not in one world value | leafwing-input-manager 0.22.0, for Bevy: "freely bind keys to distinct entities, rather than worrying about singular global state" ([docs](https://docs.rs/leafwing-input-manager/latest/leafwing_input_manager/)) | the entity names a player slot, which any source can drive (question 7, revised) |
| Adapters between a control and an action | Unity's processors (axis and stick dead zones, invert, scale, normalize, clamp) and composite bindings (two buttons as a 1D axis, four as a 2D vector) ([processors](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/Processors.html), [bindings](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/ActionBindings.html)); Unreal's Enhanced Input modifiers (dead zone, negate, swizzle) and triggers (hold, chorded) ([Enhanced Input](https://dev.epicgames.com/documentation/en-us/unreal-engine/enhanced-input-in-unreal-engine)) | the owner's direction for KYR-54 |
| Input contexts with a priority | Unreal's Input Mapping Contexts, applied per local player: "the context with the highest priority will be considered and the others ignored" ([Enhanced Input](https://dev.epicgames.com/documentation/en-us/unreal-engine/enhanced-input-in-unreal-engine)) | the owner's direction for KYR-54 |
| Local players joining on their devices | Unity's PlayerInputManager: a player joins by pressing a button on an unpaired device, with a maximum count and split screen ([PlayerInputManager](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/PlayerInputManager.html)) | a player slot that a remote player, bot or agent binds to as well (KYR-54) |
| An editor control chosen per field | Godot 4.7's `@export_range`: a slider, `exp`, `suffix:m`, and `radians_as_degrees`, which "stores radians but displays and edits degrees" ([exports](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html)) | the hint is data in the component's record, an adapter like input's (human-tools question 4) |
| Components that bring the ones they need | Bevy's required components, "when A is inserted, B will also be initialized and inserted (if it was not manually specified)" ([Component](https://docs.rs/bevy/latest/bevy/ecs/component/trait.Component.html), 0.20.1); Unity's `RequireComponent` ([RequireComponent](https://docs.unity.com/en-us/engine/current/script-reference/unityengine/requirecomponent)) | resolved at build time, when the archetype is made, and one without defaults must be listed (question 8) |
| A frame-size guard in the manifest | friendly-fire-department's `-Wframe-larger-than=32768 -Werror=frame-larger-than` on every arm but Windows; the-mallow-man's `tools/check-frames` for Windows | a computed bound per entry point, asked of kama as KY-22 (question 6) |

## Where to read more

- The decisions, with their reasons: each doc's *Decided* under [design/](design/).
- The order of work: [ROADMAP.md](ROADMAP.md). What kyoten needs from kama: [KAMA_GAPS.md](KAMA_GAPS.md), and the
  audit of kama's thread pool, [research/kr3-audit.md](research/kr3-audit.md).
- The spike's state: [SPIKE.md](SPIKE.md) § Where it stands.
