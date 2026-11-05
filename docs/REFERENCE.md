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
 World  (a value: copied, saved, restored — G3)
  ├─ Zone "harbor"  (the unit of loading, budgets and coordinates — G7)
  │   ├─ Table (harbor × Soldier) ── Chunk ── Chunk ── Chunk    a chunk: up to N soldiers,
  │   ├─ Table (harbor × Crate) ──── Chunk                      Pos[N] Vel[N] Hp[N] …
  │   └─ World store: terrain or voxel cells (question 9)
  ├─ Zone "keep" …
  ├─ Side stores: Burning, Stunned       any entity may gain or lose one
  ├─ Singletons: physics world, RNG      one per world or zone, owned by a module
  └─ Assets (read-only, by handle): meshes, clips, navmeshes
 Entity = Handle ──lookup──► (table, chunk, slot)
```

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

## The vocabulary

*Decided at components question 3, choice 1 (2026-11-05):* "system" means the function, as in Unity, Bevy and flecs;
the large engine areas are **engine modules**; "subsystem" is retired.

| Term | Means | Status |
|---|---|---|
| **Engine** | kyoten: one kama package in four layers | decided |
| **Engine module** | one area of the engine (input, render, audio, net, physics, UI), one kama module, with its own records, system bodies and singletons. It never imports another | decided |
| **Layer** | a group of modules with an import rule: frame, world, engine modules, the agent surface | decided |
| **Library / backend** | what an engine module sits on (`@kama/graphics`, `@kama/window`). A backend is a borrowed library behind the module's interface, replaced later (Jolt, RmlUi) | decided (the direction) |
| **Game** | a separate package and repository: its records, its system bodies, and the world generated from them | decided |
| **Record** | a project-database entry declaring a component, prefab, system, budget or zone | decided |
| **Generator** | the kyoten tool that writes the World from records, as plain kama | decided |
| **World** | the whole simulation state, generated per game: a value that can be copied, saved and restored | decided |
| **Zone** | a region of the world: the unit of loading, budgets and coordinates | decided (G7) |
| **Prefab** | an entity's fixed set of components and their defaults (an archetype) | decided |
| **Entity** | one thing in the world, an instance of a prefab | decided |
| **Handle** | an entity's id, reaching it through a lookup (handle → table, chunk, slot) | decided; its form is question 8 |
| **Component** | a plain value, one piece of an entity's data, of one of four kinds | decided |
| **Table** | all the entities of one prefab in one zone | decided |
| **Chunk** | a fixed block of up to N entities of one table, one array per component: the unit of parallel work, of a snapshot and of a budget | decided |
| **Side store** | one component type any entity can gain or lose at run time | decided |
| **World store** | data that belongs to space, not to an entity: terrain, voxels, destruction | decided; its design is question 9 |
| **Singleton** | a store holding one value per world or per zone: the physics world, an RNG, a spatial grid. A system's state between steps lives in one | decided (question 3, choice 2) |
| **Asset** | shared read-only data loaded with a zone, reached by handle: a mesh, a clip, a navmesh | decided |
| **System** | a function over components, plus a record that schedules it (phase, group, order, rate, iterations). Its signature is its access | decided (question 3, choices 1 and 2) |
| **Phase** | Input, Update, Constraints, Output: a place in the order | decided |
| **Group** | systems of one phase ordered together; a Constraints group may iterate as a whole | decided |
| **Schedule** | the resolved order of every system, with its access, rate and cost, shown to humans and agents | decided |
| **Step** | one tick of the simulation's one clock | decided |
| **Frame** | one display refresh; Output runs once per frame | decided |
| **Snapshot** | the world, or the columns other systems read, as it stood at the end of a step. A system reading other entities sees it by default | decided (question 3, choice 3) |
| **Command** | a queued structural change (spawn, despawn, gain, lose), applied at the end of its phase | decided (question 3, choice 4) |

**Older wording.** [design/frame-phases.md](design/frame-phases.md) and [design/architecture.md](design/architecture.md)
were reworded to this vocabulary on 2026-11-05, except inside quotes. Research docs written before then, and quotes,
may still say "subsystem" for **system**, or "system" for an **engine module** such as render or audio.

**How a system reads other entities** (*decided*, question 3, choice 3). It declares one of two modes, and the scheduler
never changes it, so serial and parallel runs see the same values:
- **the previous step**, the default: other entities as they were at the end of the last step. It always runs in
  parallel, needs no order against writers, and may write what it reads;
- **this step**: other entities' current values. It runs after their writers and may not write what it reads. In a
  parallel group its writes are staged and copied in at the group's end.

## Prior art

Each row is a choice kyoten made or proposes, the engines that made it before, and where kyoten differs.

| kyoten | Prior art | Where kyoten differs |
|---|---|---|
| A table of fixed-size chunks per (zone, prefab) | Unity Entities' archetype chunks, 16 KiB with at most 128 entities ([archetypes](https://docs.unity3d.com/Packages/com.unity.entities%401.4/manual/concepts-archetypes.html)); Unreal Mass, a chunk size per archetype ([Mass](https://dev.epicgames.com/documentation/unreal-engine/overview-of-mass-entity-in-unreal-engine)) | prefabs fixed at build time, tables per zone, sized from budgets |
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
| Large worlds: doubles only at the absolute position, floats inside | Box3D ([large worlds](https://box2d.org/documentation3d/large-worlds.html)); Unreal 5's double-precision types ([LWC](https://dev.epicgames.com/documentation/en-us/unreal-engine/large-world-coordinates-in-unreal-engine-5)) | proposed: zone-local floats with whole-number zone coordinates (question 9) |
| Hand-coded maths for cross-platform determinism | Box2D: *"The atan2f function in the standard library is not cross-platform deterministic"* ([math_functions.h](https://github.com/erincatto/box2d/blob/main/include/box2d/math_functions.h)) | asked of kama as KY-19 |

## Where to read more

- The decisions, with their reasons: each doc's *Decided* under [design/](design/).
- The order of work: [ROADMAP.md](ROADMAP.md). What kyoten needs from kama: [KAMA_GAPS.md](KAMA_GAPS.md), and the
  audit of kama's thread pool, [research/kr3-audit.md](research/kr3-audit.md).
- The spike's state: [SPIKE.md](SPIKE.md) § Where it stands.
