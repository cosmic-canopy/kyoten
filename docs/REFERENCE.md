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
 │   modules, processors, budgets, zones │  ├──►│ zones · tables · chunks   │──► run(world)
 │ processors:                           │  │   │ side and world components │    in the frame
 │   fn void integrate(ref Pos p,        │──┤   │ input() update()          │    tier
 │       const ref Vel v,                │  │   │ constraints() output()    │
 │       const ref Time t) { … }         │  │   └───────────────────────────┘
 └───────────────────────────────────────┘  │
 ┌─ kyoten, written once by its team ────┐  │    generated into the game's build, and
 │ each engine module ships records and  │──┘    checked by kama like hand-written code
 │ processors of the same kinds          │
 └───────────────────────────────────────┘
```

- **A game changes engine behaviour without editing the engine.** Its records sit in a content layer above the
  engine's, so a game tunes a physics iteration count or replaces an engine processor's record by stacking its own
  (the project database's content layers, [design/project-database.md](design/project-database.md) § Decided).
- **When a game needs something the engine lacks,** the engine gains it as a pattern or a component every game can use
  (*decided*, [../AGENTS.kyoten.md](../AGENTS.kyoten.md) § Rules).
- **The generator's output is not committed** (components question 8 part b, 2026-11-07). It is split into files by
  archetype and by phase, in a git-ignored folder of the game's package, and the generator runs before a build or a
  check. The repository holds the records and the processors.

## The engine's tiers

*Decided at components question 3, choice 6 (2026-11-05), on architecture question 2's module rule* ([design/architecture.md](design/architecture.md)
§ Decided, question 2), and named tiers at components question 8 part b (2026-11-07). Each tier imports only the
tiers above it.

```
 ┌───────────────────────────────────────────────────────────────────────────────┐
 │ 1 frame   phases · the clock · scheduler · input record · World contract · run │
 ├───────────────────────────────────────────────────────────────────────────────┤
 │ 2 world   engine components (Transform, Mesh…) · table, chunk, side-store,     │
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

**On the web** (*decided*, web-and-native questions 1 and 2, 2026-11-07): the libraries below the engine modules are
kama packages shaped after the browser's API, and a game touches only kyoten's interfaces. A web build is
single-threaded, everything on the page, unless a game turns threads on. Then the page is the browser's edge (input,
the gamepad, the DOM UI, the AudioContext), kama's `main` runs the steps and renders through WebGPU on a worker, the
job pool takes further workers, and shared-memory rings join them. Such a game is hosted with COOP `same-origin` and
COEP `require-corp`, and ships its single-threaded build as the fallback.

**UI and the headset** (*decided*, web-and-native questions 3 and 8, 2026-11-07): a game's UI is one set of HTML and
CSS documents within kyoten's **UI profile**, the part `@kama/ui` renders natively, checked at build. The DOM renders
it on the web, and no webview is used natively. UI shows what Output writes and sends actions, which enter at Input's
hand-off and are recorded like a key's, so UI never touches the simulation. UI documents are content, and the names
they bind are checked against the generated ones. A headset is not a third family: Quest natively is the Android
family with OpenXR, which players get first, and the Quest browser is the web family with WebXR, which renders on
the page thread.

**Platforms** (*decided*, target-platforms questions 1–4, 2026-11-07): a **platform** is a kama type implementing
kyoten's `Platform` contract. The open ones (the web, Windows, Linux, macOS, Android, later iOS) live in kyoten and
its libraries, picked per build target by `@compileFor`. A console's is a private package that the game's manifest
names for that build only, and the generated `run` passes it in, so the engine never names it and every call is
direct. Engine modules and games ask for **capabilities**, never platforms, and only in Input and Output; OS flags
stay in the libraries and the platform types. Features (XR, store services such as achievements) are interfaces
kyoten defines, with a backend per platform or store in **feature packages** a game opts into.

**Rendering** (*decided*, rendering questions 1, 2 and 4, 2026-11-07). The bar is Three.js's ease of use on every
platform, with production-grade visuals and shaders that compete with Unreal, Unity and Godot. Three tiers:
`@kama/gpu`, safe WebGPU handles; `@kama/graphics`, a library of meshes, materials, lights, cameras and render
targets that names no engine concept, starting from cosmic-forge's `render`; and kyoten's render module, whose
Output processors **extract** what is drawn, interpolated and relative to the camera's zone, into the library's
buffers once a frame. GPU work reads only the extracted data, serially by default and overlapping the next steps
when a measurement asks. Each view runs a fixed list of passes until a frame graph is needed.

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
  ├─ Non-spatial layers ("rules", "inventory"): each held once for the scene
  ├─ Side stores: Burning, Stunned       any entity may gain or lose one
  ├─ World components: Time, RNG         one per world or zone, owned by a module
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
  │             "actors"     spatial      simulated    rings 0–2   held per zone
  │             "props-far"  spatial      drawn only   rings 2–6   per machine
  │             "rules"      non-spatial  simulated                held once for the scene
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
- **An entity crossing a zone, or changing layer,** moves to that zone's or layer's table at the end of the phase,
  and its handle stays valid.
- **A position is a zone and a `float32` offset from the zone's centre** (question 9, 2026-11-07): Y up,
  right-handed, metres. Zone sizes are whole metres, so moving an entity into the next zone is exact, and precision
  is the same in every zone of an endless world.
- **A zone loads from its saved state,** else from the scene's world generator with its zone file laid over it,
  else empty (question 8 part b, 2026-11-07). A zone file with `"generate": false` replaces the generated zone. A
  scene's `bounds` keep zones beyond them from being created: by default the box around its zone files, and none
  for a scene with a world generator, so an infinite world is a generated one.
- **World data lives in world stores of cells,** in sections of 16×16×16 (question 9, 2026-11-07). A store belongs
  to a spatial layer and loads with it; the game chooses the cell type and sizes, and the engine encodes each
  section from its contents. A world generator fills a zone from the scene's seed, the zone's coordinate and the
  records: never recorded, the same bits on every platform under kama's `reproducible-float`.
- **A save holds only what cannot be rebuilt** (question 9, 2026-11-07): each loaded zone's changeable layers and
  its changed sections, whole. Untouched sections regenerate, a `readOnly` layer reloads from content, and derived
  data (meshes, LOD, colliders, navigation meshes) is rebuilt. Destruction is cell edits or pre-fractured prefabs,
  and visual debris is Output's.

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
 A processor = a function + its record.  Record: phase · processor group · order · rate · iterations
               Its signature is its access:  ref = writes,  const ref = reads
 A module's record sets the default rate its processors inherit.
```

## The hello cube

*Decided at components question 7, with ai-first-api question 1 and rendering question 3* ([design/components.md](design/components.md)
§ Decided); revised on 2026-11-06 so actions belong to a player, and laid out in question 8 part b's record files
(2026-11-07), with `run` from the game's generated module (target-platforms question 2, 2026-11-07). A sketch: no
engine compiles it yet, and an action's kind is KYR-54's.

```kama
// src/app.kama, written by `kyoten new`
import { hello::generated::run };
fn uint8 main() { return run(); }
```
```kama
// src/cube.kama
import { kyoten::Transform, kyoten::Time, hello::generated::Actions };
export { Spin, turn };
@generate(Serializable, Deserializable, of)
type value Spin { @field(default) public float32 rate = 1; }
fn void turn(ref Transform t, ref Spin s, const ref Actions input, const ref Time time) {
    if (input.faster.held) { s.rate = s.rate + time.dt; }
    t.rotateY(by: s.rate * time.dt);
}
```

`src/cube.records.json`, the code records:

```json
{ "processors": { "turn": { "phase": "Update" } },
  "actions":    { "faster": { "kind": "Button" } } }
```

`content/cube.records.json`, and the scene's one zone, `content/scenes/hello/zone.0.0.records.json`:

```json
{ "prefabs":  { "cube": { "Mesh": { "shape": "Box" }, "Spin": { "rate": 2 }, "Actions": { "player": 1 } } },
  "bindings": { "faster": { "keyboard": "ArrowUp", "gamepad": "RightShoulder" } } }
```
```json
{ "place": { "cube": { "prefab": "cube" } } }
```

- **The game writes** a prefab, a component (`Spin`), a processor (`turn`), an action and its bindings, and a zone
  that places the cube. It also owns a two-line `main`, which `kyoten new` writes.
- **The engine supplies** the defaults as records: a window or canvas, a camera, lights, a lit material, one player
  bound to the local keyboard and first gamepad, and the scene's one zone and its layer, `main`. The app's first scene
  is the only one unless its record names another. `mesh` requires a transform and a material (question 8).
- **The generator writes the rest:** the cube's table; an `Actions` component with one field per action, which the
  Input phase fills each step from the player the cube names; Update's call to `turn`; and the `run` that `main`
  calls, which passes the world and the build's platform to the engine.
- **The target:** at most 20 non-blank lines across all files and eight concepts (app, record, scene, prefab,
  component, processor, action, player), on web and native, held by CI. This layout is 15, counting its imports and
  its export. The owner (2026-11-07): "The 20-line target is obviously arbitrary but probably a good gauge. It
  shouldn't limit our designs though." CI fails when the count grows, and raising the number is a decision, made
  with its reason.

## What a processor takes

*Decided at components question 8 part b (2026-11-07).* Each parameter means what its type says, and its name is free.
The generator reads the types from the compiler and refuses any other.

| A processor takes | It gets | The scheduler learns |
|---|---|---|
| `ref C`, `const ref C` (C a component) | this entity's C, written or only read | writes or reads C |
| `ref W`, `const ref W` (W a world component) | the world's or the zone's one W | writes or reads W |
| `Handle` | this entity's handle | nothing |
| `const ref Previous<C>`, `const ref Current<C>` | any entity's C, as of the last step or live; one is always written | nothing to wait for, or after C's writers |
| `ref Create<P>` (P a prefab's generated type, `BulletPrefab`), `ref Destroy`, `ref Gain<C>`, `ref Lose<C>` | queued structural changes, applied at the end of the phase | adds or removes rows |
| `ref Send<C>` | sends a C to other entities, combined as C's record says and delivered at the end of the phase | writes C at the end of the phase |
| `const ref Prefabs` | the prefab records' values, to start a new entity from | nothing |
| `const ref <Processor>RandomKeys` | a random key per purpose the processor's record lists, generated into the processor's module | nothing |
| `const ref Time` | the step's length and number | nothing |
| `const ref S`, `const ref Current<S>` (S a world store) | its cells by position across loaded zones, as of the last step or live | nothing to wait for, or after S's writers |
| `ref Edit<S>` | cell edits, applied at the end of the phase in sorted order and combined as S's record says | writes S at the end of the phase |
| `ref Section<S>` with `const ref Previous<S>` | a processor over the store itself: its own section, and its neighbours as of the last step | writes S, section by section |

```kama
fn void fly(ref Transform at, const ref Shot s, Handle me, const ref Previous<Transform> others,
            ref Send<Damage> damage, ref Destroy destroy, const ref FlyRandomKeys random, const ref Time time) {
    match (others.get(of: s.target)) {
        case Here(value: goal): { … if (random.crit.chance(who: me, p: 0.25)) { power = power * 2; } … }
        case Gone: { destroy.add(who: me); }
        case Unloaded: { destroy.add(who: me); }
    };
}
```

- **Every queue adds with `.add(…)`,** and what it queues applies at the end of the phase, sorted by chunk.
- **`Create<BulletPrefab>` creates `bullet`'s family:** `bullet` and its variants with the same components, a mod's
  included. A component field of type `BulletPrefabId`, written in records as a prefab's name, lets data choose:
  `BulletPrefab b = prefabs.bullet(id: t.shot); b.transform = at; bullets.add(prefab: b);`.
- **A random key's counter is a derived key:** `random.spread.nth(n: i).unit(who: me)` for pellet `i`.
- **The generator refuses** a processor that writes C and reads `Current<C>`, a module `static` in a game, and any
  parameter outside this list, each with a message naming the fix.

## The engine's day-one components

*Decided at components question 8 part b (2026-11-07).* Day one is the first slice. Each module designs its
components' fields, and more arrive with their roadmap rows.

| Component | Tier or module | Holds |
|---|---|---|
| `Transform` | world tier | `zone` (an `int32` per axis), `position` (the `float32` offset from the zone's centre) and `scale` (`std::math::Vec3`, scale 1), `rotation` (`std::math::Quat`); `rotateY(by:)`, `offsetTo(other:)`, `place(zone:, position:)` |
| `Mesh` | render | a built-in `shape` (`Box`, `Sphere`, `Plane`…) or a glTF mesh; requires a Transform and a Material |
| `Material` | render | a lit material (base colour, metallic, roughness), or a glTF one |
| `Camera` | render | a perspective or orthographic projection, near and far, and a `target`, the screen by default: a view is an entity with a Camera |
| `Light` | render | `Directional`, `Point` or `Spot`, with colour, intensity and range |
| `Actions` | input | generated per game; the engine fixes `player` |
| `Time` (world component) | frame | the step's length and number |
| `Environment` (world component) | render | ambient light and the clear colour, later sky and fog |

- **Not yet:** streaming sources, physics, audio, UI and network components arrive with their rows. Parent and child
  (the transform hierarchy) is KYR-62; until then a glTF level is flattened at load.
- **No `Name` component:** the loader maps placed names to handles.
- **Transform keeps a quaternion,** which glTF, WebXR, OpenXR and Jolt all speak. A geometric-algebra rotor is the
  same four numbers; a rotor or motor type can be tried later beside it.

## Records and their files

*Decided at components question 8 part b, with project-database question 2 in part (2026-11-07).* A record is the
engine's own kama type, read from strict JSON (question 5). **A record lives with what it describes:** records that
describe code sit beside it, and content records sit under `content/`. The generator and the loader read every
`*.records.json` under both.

```
kyoten-towers/
├─ kama.json
├─ .gitignore                       src/generated/, *.generated.kama and out/
├─ src/                             code: what a build compiles
│  ├─ app.kama                      main, which calls run
│  ├─ towers/                       module towers
│  │  ├─ components.kama            Turret, Shot, Health, Damage
│  │  ├─ fire.kama                  processors, one or a few per file
│  │  ├─ fly.kama
│  │  ├─ hurt.kama
│  │  ├─ towers.generated.kama      its random keys, generated, never committed
│  │  └─ towers.records.json        the module: rate, groups, processors, components
│  └─ generated/                    the generator's kama, never committed
└─ content/                         data: no build needed, hot-reloads, layered by DLC and mods
   ├─ app.records.json              the first scene, the window
   ├─ bindings.records.json         default bindings per device
   ├─ prefabs/
   │  ├─ tower.records.json
   │  └─ bullet.records.json
   └─ scenes/
      └─ battle/
         ├─ scene.records.json      the grid, layers, layer groups, budgets
         ├─ zone.0.0.records.json   what is placed in zone (0,0)
         └─ zone.1.0.records.json
```

- **A file's module is its folder,** as a kama file's is. A bare name is the module's own, and a full kama path
  (`kyoten::Transform`) reaches another.
- **Records hold only what differs from the defaults,** enum values are kama's case names (`"Update"`), rates are
  whole hertz, and a `note` string replaces comments, which kama's JSON refuses.
- **A module may split its records across files;** they merge by key, and a key twice in one content layer is refused.

```json
{ "rate": 30,
  "groups":     { "combat": { "phase": "Update" } },
  "processors": { "fire": { "group": "combat" },
                  "fly":  { "group": "combat", "after": ["fire"], "rate": 60, "random": ["crit"] },
                  "hurt": { "group": "combat" } },
  "components": { "Health": { "requires": ["kyoten::Transform"] },
                  "Damage": { "store": "Side", "combine": "Sum", "saved": false } } }
```

| Record | Fields, with their defaults |
|---|---|
| Module | `rate` in Hz (the engine's default for the phase) |
| Processor group | `phase` (required); `after`, `before` ([]); `first`, `last` (false); `iterations` (1; a Constraints group may raise it); `parallel` (false: serial until measurement says otherwise) |
| Processor | `phase` or `group` (one is required); `after`, `before`, `first`, `last`; `rate` (its module's); `iterations` (1); `random`, its purposes ([]); `orderBy`, a sort key such as `"towers::Initiative.value"`, ties broken by handle (none) |
| Component | `store`, `Table` or `Side` (Table); `blend`, `Snap`, `Linear` or `Custom` (Snap); `history` in steps (0); `saved` (true; false is rebuilt for display); `requires` ([]); `combine`, `Sum`, `Min`, `Max` or `First`, needed by a component sent with `Send<C>` (none) |

Every record kind also takes an optional `note`, a string.

**The content records** *(part 2, 2026-11-07):*

```
content/
├─ app.records.json
├─ prefabs.records.json          or a file per prefab, as part 1's tree has it: files merge by key
├─ bindings.records.json
└─ scenes/battle/                the folder names the scene
   ├─ scene.records.json         the scene's own record
   └─ zone.0.0.records.json      the file name names the zone
```

```json
{ "app": { "firstScene": "battle", "title": "Towers" } }
```
```json
{ "prefabs": {
    "tower":  { "Transform": {}, "Turret": { "cooldown": 2 }, "Health": { "hp": 100 } },
    "bullet": { "Transform": {}, "Shot": { "power": 12 } },
    "keep":   { "from": "tower", "Health": { "hp": 300 }, "note": "the boss tower" } } }
```
```json
{ "bindings": { "fire": { "keyboard": "Space", "gamepad": "RightTrigger" } } }
```
```json
{ "place": {
    "tower-west": { "prefab": "tower", "values": { "Transform": { "position": { "x": -20 } }, "Turret": { "target": "tower-east" } } },
    "tower-east": { "prefab": "keep", "group": "boss",
                    "values": { "Transform": { "position": { "x": 20 } }, "Turret": { "target": "tower-west" } } } } }
```

| Record | Fields, with their defaults |
|---|---|
| App | `firstScene` (the only scene); `title` |
| Prefab | an entry per component it has, keyed by its type name (`"Turret"`, or `"towers::Turret"` where two share it) and holding that component's values; the components present make its archetype. `from`: another prefab it starts from, as a variant (none). `layer`: where it is placed and created (a placement's `main`, a created entity's its creator's) |
| Bindings | per action, a control per device: `keyboard`, `mouse`, `gamepad` |
| Scene | `inBuild` (true); `zoneSize` in whole metres (64); `zoneShape`, `Square` or `Cube` (Square); `layers`; `limits`; `bounds`, `{from, to}` in zones (the box around its zone files; none with a world generator); `worldGenerator`, a function by kama path (none) |
| Layer | `spatial` (true); `simulated` (true; false is drawn only); `rings`, `{from, to}` (every loaded ring); `start`, `Active`, `Loaded` or `Off` (Active); `groups`, nested; `budgets` by prefab; `readOnly` (false; true: processors read it and never write it, and it is never saved) |
| Budget | `max` per zone, or for the scene in a non-spatial layer; `grow` (false: reserved up front); `whenFull`, `Refuse` or `EvictOldest` (Refuse) |
| Layer group | `on` (true); `groups`, nested |
| Limit, a count rule | `per`, `World`, `Zone` or `Layer`; `prefabs`; `max` |
| Zone | `place`: placements keyed by placed name |
| Placement | `prefab` (required); `layer` (its prefab's, else `main`); `group` (none); `values`, laid over the prefab's |
| Action, a code record | in a module's records file, under `actions`: its `kind` (KYR-54's to name) |

- **A prefab variant starts `from` another,** and lays its values over it, as a placement does.
- **The default layer is `main`,** where a placement that names no layer goes.
- **A prefab may name its layer,** where it is placed and created; a created entity otherwise joins its creator's.
  How a game uses its layers is its own choice.
- **Zone files exist only where something is authored,** and may sit in subfolders: the file's name names the
  zone.
- **Actions are code records and bindings are content.** Action kinds are KYR-54's.

**The project database** (*decided*, project-database questions 1–4, 2026-11-07) has two halves sharing one id space
and one query surface. **Game data** is what the running game reads: the records above, and a game's own **data
kinds**, keyed entries of a kama type it declares (a loot table, dialogue), read through the stack by generated ids.
**The wiki** is the game's direction, design notes, decisions and tasks, never read by the running game and never
layered. Its pages are generated for every record and written in Markdown under `wiki/`, with links to records
checked like any reference. The files live in git, the reference backend. `kyoten merge` merges two agents' changes
to a record by field and `kyoten fmt` keeps one layout. kama types are the only schema, and the generator exports a
JSON Schema of each for editors and agents.

**Checks, agents and shipping** (*decided*, project-database questions 5, 6 and 8, 2026-11-07, a first version that
building games will revise). Every write is checked for shape and references; `kyoten check` and CI add the rules a
module writes in kama, CI checks every merged result, and a hot reload that fails keeps the last good stack. Agents
meet in git, each on its own branch. Tasks are wiki pages with advisory claims, and each commit's trailers carry its
provenance. Humans override everything, and roles and approvals are off until a project turns them on. A shipped
game reads a **pack** per source, its merge patches in JSON, through the same stack. A wiki's screenshots are
**captures**, kept in the asset store with the recipe that retakes them.

## The vocabulary

*Decided at components question 3, choice 1 (2026-11-05), and renamed at question 8 part b (2026-11-07):* a
**processor** is a function the scheduler runs, and a **module** is an area of code, one kama module: an engine module
or a game module. "System" and "subsystem" are retired. *Coming from another engine*, below the table, maps their
words.

| Term | Means | Status |
|---|---|---|
| **Engine** | kyoten: one kama package in four tiers | decided |
| **Module** | an area of code, exactly one kama module, with its own records, processors, components and world components. Its record sets the default rate its processors inherit. An **engine module** is the engine's (input, render, audio, net, physics, UI) and never imports another; a **game module** is a game's (gameplay, AI, towers) | decided (engine modules at question 3, choice 1; module and game module at question 8 part b, 2026-11-07) |
| **Tier** | a group of modules with an import rule: frame, world, engine modules, the agent surface, each importing only the tiers above it. A module's own levels of code are tiers too | decided; named at question 8 part b (2026-11-07), "layer" until then |
| **Library / backend** | what an engine module sits on (`@kama/graphics`, `@kama/window`). A backend is a borrowed library behind the module's interface, replaced later (Jolt, RmlUi). Libraries are kama packages shaped after the browser's API; the engine modules' interfaces above them are kyoten's own, and a game touches only those | decided (web-and-native question 1, 2026-11-07) |
| **Platform** | a kama type implementing kyoten's `Platform` contract: the loop and its frame source, the lifecycle, capabilities, files, and the libraries' window, GPU, audio, input and network. The open ones live in kyoten and its libraries, chosen by `@compileFor`; a console's is a private package the game names for that build | decided (target-platforms questions 1 and 2, 2026-11-07) |
| **Capability** | something a platform has (pointer lock, threads, files, haptics, XR, a store's services), fixed for a build or changing while running. Asked for in Input and Output, never in the simulation, and never a platform's name | decided (target-platforms question 3, 2026-11-07) |
| **Feature package** | a package with a backend for an interface kyoten defines, which a game opts into: XR, store services (achievements, leaderboards, cloud saves, presence), later voice | decided (target-platforms question 4, 2026-11-07) |
| **Game** | a separate package and repository: its records, its processors, and the world generated from them | decided |
| **Record** | a project-database entry declaring a component, prefab, module, processor, budget or zone. Its format is the kama type it describes, through serde | decided (question 5, choice 2) |
| **Data kind** | a game's own record kind for keyed data that is neither a component nor a world component (a loot table, dialogue, quests): a kama type listed in its module's records, its entries under `content/`, read through the stack by generated ids | decided (project-database question 1, 2026-11-07) |
| **Source** | anything that satisfies the record-source contract: files in git, a baked pack, a database, a URI where the platform allows | decided (project-database question 11); the name is proposed |
| **Content layer** | short for a **content database priority level**: a named slot in the order of sources, engine, game, DLC, content patch, mod, local by default. Each holds any number of sources, each with its own priority within it. Always written with "content", since a bare "layer" is a scene's | decided (project-database question 11); named in full at components question 8 part b (2026-11-07) |
| **Merge patch** | what a source says about a record: only the fields it changes, merged by RFC 7396 ("JSON Merge Patch"). A bare "patch" is a game's patch, and the content patch is the content layer that holds them | decided (project-database question 11); named at components question 8 part b (2026-11-07) |
| **Wiki** | the project database's other half: the game's direction, design notes, decisions and tasks. Generated pages for every record and written Markdown pages under `wiki/`, sharing the records' ids. Never read by the running game, and not layered | decided (project-database questions 1 and 3, 2026-11-07) |
| **Pack** | one source as a shipped game reads it: its merge patches, checked and joined into one JSON file, with its id, version, hash and the commit it was baked from. A source like any other, so DLC and mods still layer by field | decided (project-database question 8, 2026-11-07) |
| **Capture** | a wiki's screenshot or clip, kept in the asset store with the recipe that took it (scene, build, stack, step, view), so the tools can tell it is stale and retake it | decided (project-database question 6, 2026-11-07) |
| **Stack** | every source in its resolved order. Its identity is in every save, replay and match | decided (project-database question 11) |
| **Generator** | the kyoten tool that writes the World from records, as plain kama. Procedural generation is the **world generator**, always so called | decided |
| **World** | the whole simulation state, generated per game: a value that can be copied, saved and restored | decided |
| **Scene** | what a designer opens and the build lists. One is active at a time, and the app's record names the first. It divides spatially into zones and logically into layers | decided (2026-11-06) |
| **Zone** | a cell of the scene's grid, a square or a cube sized in whole metres, with its origin at its centre: the unit of loading, budgets and coordinates | decided (G7; a grid since 2026-11-06) |
| **Ring** | a distance in zones: ring 0 is a source's own zone, ring k the zones k steps away. A depth of k loads (2k+1)² zones in 2D, (2k+1)³ in 3D | decided (2026-11-06) |
| **Streaming source** | a component on a simulated entity that loads the zones around it for the simulation, the same on every machine. Each player's character has one by default | decided (2026-11-06) |
| **View** | a camera drawing into a target (the screen, part of it, a texture, an eye). It loads what is drawn around it and may differ per machine | decided (2026-11-06) |
| **Layer**, or **scene layer** | a set of entities declared at design time that spans every zone and loads as one: the unit of loading and memory. Spatial or not, simulated or drawn only, on in a range of rings, and off, loaded or active | decided (2026-11-06); its name is question 8 |
| **Layer group** | a set inside one layer that switches as one, nested freely: an id per entity, and no memory of its own | decided (2026-11-06); named at question 8 part b (2026-11-07) |
| **Read-only layer** | a layer marked `"readOnly": true`: processors read it and never write it, so it needs no snapshot, stays out of the per-step hash, and is never saved | decided (question 9, 2026-11-07) |
| **Screen layer** | rendering's target composed onto the screen: a 2D layer over a 3D scene, or alone. Always written so, since a bare "layer" is a scene's | rendering's (2026-11-01); named at question 8 part b (2026-11-07) |
| **Budget** | a record limiting one scope (world, scene, zone, layer, match, player, team). A (zone, layer, prefab) budget sizes a table, and a limit over a group is a count rule. Every store's ceiling comes from one | decided (question 6) |
| **Footprint** | the sum of every ceiling per scope, which the generator reports as the game's simulation floor | decided (question 6) |
| **Archetype** | a set of component types, fixed when the game is built. The generator writes one table type per archetype | decided (question 5, choice 3) |
| **Prefab** | a named archetype with its defaults. Prefabs of one archetype share generated code, so a record alone can add one | decided (question 5, choice 3) |
| **Entity** | one thing in the world, an instance of a prefab | decided |
| **Handle** | an entity's runtime id: 8 bytes, a 32-bit slot in the world's lookup table and a 32-bit generation, the same on every platform. The slot says where the entity lives now; the generation, bumped when the slot is freed, makes a stale handle answer "gone". A lookup answers here, gone or unloaded | decided (question 8, 2026-11-06) |
| **Placed name** | a placed entity's name in its scene's records ("door-12"), which other records use to refer to it. The loader resolves it to a handle when its zone loads, and may key it by a 64-bit hash | decided (question 8, 2026-11-06) |
| **Component** | a plain value, one piece of an entity's data, of one of four kinds. A kama type plus its record: the type holds the fields, and the record says how it is stored, kept, interpolated and saved | decided (questions 2 and 5) |
| **Table** | all the entities of one prefab in one zone and layer, made from its archetype's table type, with the prefab's variants that have no budget of their own. Its ceiling is its (zone, layer, prefab) budget | decided (the layer since 2026-11-06; variants at question 8 part b, 2026-11-07) |
| **Chunk** | a fixed block of up to N entities of one table, one array per component: the unit of parallel work, of a snapshot and of a budget. N is chosen per archetype from a 16 KiB target, at most 128 | decided (N's rule is measured in slice B) |
| **Side store** | one component type any entity can gain or lose at run time | decided |
| **World store** | data that belongs to space, not to an entity: terrain, voxels, destruction. One kind of cell for every zone, belonging to a spatial layer | decided; designed at question 9 (2026-11-07) |
| **Cell** | one value of a world store at one grid point: a voxel, a height sample (Minecraft's block) | decided (question 9, 2026-11-07) |
| **Section** | a fixed block of cells, 16×16×16 or 16×16: the unit of a world store's memory, encoding, parallel work, streaming and saving, as a chunk is for entities | decided (question 9, 2026-11-07) |
| **World generator** | a function named in a scene's record that fills a zone, its cells and entities, from the scene's seed, the zone's coordinate and the records. Never recorded; what is not deterministic (an LLM) is input | decided (question 9, 2026-11-07) |
| **World component** | a component the world or a zone holds one of, rather than each entity: the step's `Time`, the physics world, a spatial grid. It is a field of the generated world or zone, passed only to the processors that name it, never reached globally, and owned by a module. A processor's state between steps lives in one | decided (question 3, choice 2; renamed from "singleton" at question 8 part b, 2026-11-07) |
| **Asset** | shared read-only data loaded with a zone, reached by handle: a mesh, a clip, a navmesh | decided |
| **Processor** | a function over components that the scheduler runs, plus a record that schedules it (phase, processor group, order, rate, iterations). Its signature is its access: each parameter means what its type says, and names are free. A free function, never a method, named by its kama path (`towers::fire`: module `towers`, processor `fire`). What Bevy, flecs and Unity Entities call a system | decided (question 3, choices 1 and 2, as "system"; types only, functions and paths, and the name, at question 8 part b, 2026-11-07) |
| **Random key** | a processor's key for one purpose its record lists (`random.crit`, in a generated `<Processor>RandomKeys`). The same entity, step and counter give the same value on any thread, in any order: a counter-based generator, holding no state. `random.spread.nth(n: i)` derives the key for value `i` | decided (question 8 part b, 2026-11-07) |
| **Phase** | Input, Update, Constraints, Output: a place in the order | decided |
| **Processor group** | the processors of one phase ordered together; a Constraints processor group may iterate as a whole | decided (named at question 8 part b, 2026-11-07) |
| **Schedule** | the resolved order of every processor, with its access, rate and cost, shown to humans and agents | decided |
| **Step** | one tick of the simulation's one clock | decided |
| **Frame** | one display refresh; Output runs once per frame | decided |
| **Snapshot** | the world, or the columns other processors read, as it stood at the end of a step. A processor reading other entities sees it by default | decided (question 3, choice 3) |
| **Command** | a queued change, applied at the end of its phase: structural through `Create<P>`, `Destroy`, `Gain<C>` and `Lose<C>`, or a value sent to another entity through `Send<C>` | decided (question 3, choice 4; the queues at question 8 part b, 2026-11-07) |
| **Action** | a semantic input a game declares (`faster`, a button or an axis). The generator writes one field per action into an `Actions` component, which an entity carries to name the player that drives it; the Input phase fills it each step | decided (question 7, choice 4, revised 2026-11-06) |
| **Binding** | a record mapping an action to a device's input, a default per device, rebound by the developer and the player. It passes through adapters | decided (question 7, choice 4); adapters are the owner's direction for KYR-54 |
| **UI profile** | the HTML and CSS a game's UI documents may use: what `@kama/ui` renders natively, checked at build. It grows as the native renderer does, and a document marked web-only is exempt | decided (web-and-native question 3, 2026-11-07) |
| **Player** | a numbered slot that drives entities through their `Actions`. A local device, a network slot, a bot or an agent is bound to it, and a budget caps how many there are | that actions belong to a player is decided (question 7, revised 2026-11-06); the rest is the owner's direction for KYR-54 |
| **Player binding** | what attaches a source to a player: keyboard 1, gamepad 2, a network slot, a bot or an agent | the owner's direction (2026-11-06), decided at KYR-54 |
| **Adapter** | a step in a binding that filters a control's value or converts it to the action's kind: a dead zone, a scale, a stick or trigger as a button, a button as an axis, two buttons as −1 to 1, a filtered accelerometer. Editor controls may use the same idea (human-tools question 4) | the owner's direction (2026-11-06), decided at KYR-54 |
| **Input context** | a set of bindings a player switches on or off, with a priority (on foot, driving) | the owner's direction (2026-11-06), decided at KYR-54 |
| **Required component** | a component another component's record requires (a mesh requires a transform), the engine's or a game's. One with defaults is added to the archetype at build time; one without must be listed, or the build refuses the prefab. The generator shows where each came from, and a query answers it | decided (question 8, 2026-11-06); its spelling is the rest of question 8 |

**Older wording.** Until 2026-11-07 these docs said "system" for a **processor** and "singleton" for a **world
component**, and the design docs' *Decided* entries keep the words they were written in. Before 2026-11-05,
[design/frame-phases.md](design/frame-phases.md), [design/architecture.md](design/architecture.md) and the research
docs also said "subsystem" for a processor, or "system" for an **engine module** such as render or audio. Quotes keep
their words.

**Coming from another engine** (the owner's concern for agents, 2026-11-07). These words mean something else here.
*Unreal Mass's processor is in [research/component-models.md](research/component-models.md); the rest is general
knowledge, not checked against each engine's docs.*

| Their word | Here |
|---|---|
| a **system** (Bevy, flecs, Unity Entities) | a processor |
| a **processor** (Unreal Mass) | a processor |
| a **plugin** (Bevy), a **module** (flecs) | a module |
| a **server** (Godot's `RenderingServer`, `AudioServer`) | an engine module |
| a **resource** (Bevy), a **singleton** (Unity Entities, flecs) | a world component |
| a **system group** (Unity Entities) | a processor group |
| a **random number generator** (a stream, such as kama's `Rng`) | not a random key, which holds no state |
| a **Layer** (Unity: a 32-slot mask for physics and camera culling) | not a layer. Unreal's **Data Layer** is the closest to a layer here |
| a **chunk** (Minecraft) | a zone. A chunk here is Unity Entities' chunk: up to N entities of one archetype |
| a **block** (Minecraft) | a cell of world data (question 9) |
| a **level** or **map** (Unreal, most games) | a scene |
| a **scene** (Godot: a reusable node tree) | a prefab |
| a **Data Table** (Unreal), a **ScriptableObject** (Unity) | a data kind's entries |

**How a processor reads other entities** (*decided*, question 3, choice 3). It declares one of two modes, and the scheduler
never changes it, so serial and parallel runs see the same values:
- **the previous step**, the default: other entities as they were at the end of the last step. It always runs in
  parallel, needs no order against writers, and may write what it reads;
- **this step**: other entities' current values. It runs after their writers and may not write what it reads. In a
  parallel group its writes are staged and copied in at the group's end.

**The order promise** (*decided*, question 4). The engine promises it for every game, and nothing is opted into:
- **the same history gives the same order** on every run and machine, and a save keeps chunks, free slots and handle
  generations exactly. Threads still take work in any order; only the order results are joined in is fixed;
- **removal is swap-and-pop**, in tables and side stores. Spawn order is not promised; a processor that needs an order
  sorts by a key component;
- **randomness is keyed** by world seed, step, handle, purpose and a counter, so a value does not depend on visiting
  order. A processor reaches it through its random keys (question 8 part b);
- **a combined result** (a sum, a minimum, "who hit first") folds within each chunk, then over chunks in chunk order,
  and ties break by handle.

Whether the simulation is also bit-identical across platforms is
[design/replay-and-determinism.md](design/replay-and-determinism.md) question 1 (*open*).

**How records layer** (*decided*, components question 5 with project-database question 11):
- **A component is a kama type plus its record,** and a record's format is that type. A prefab names an archetype the
  build has, so data alone can add one; a new component, archetype or processor needs a build.
- **A source's merge patch changes fields,** never whole records. Keyed maps merge per key, `null` removes, and plain
  lists are replaced whole. A prefab variant is its base plus its own merge patches.
- **The order is data.** Named content layers (engine, game, DLC, content patch, mod, local by default) each hold any
  number of sources by priority, and the stack resolves to one order or refuses a cycle.
- **Checks run per source, strictly, then over the stack,** and an error names the topmost source that set the value.
- **The stack is part of the history:** its identity is in every save, replay and match, and a source that changes
  while running applies at a step boundary as a recorded input.

**Determinism and the record** (*decided*, replay-and-determinism questions 1–3, 5 and 6, 2026-11-07):
- **The same inputs give the same world hash on every platform,** browser and native, debug and release. kyoten's
  manifest declares kama's `reproducible-float`, which reaches every game. The simulation never runs on the GPU.
- **One ordered log per step of Input's hand-off:** actions after adapters, network receives, outside clocks, every
  I/O result. Nothing deterministic is recorded, and the simulation never reads the wall clock.
- **One serializer:** records in JSON, saves in kama's numbered binary (`KNUM`, migrates), the log and the wire in
  its positional binary (`POS`, tied to the build).
- **Tripwires:** a world hash every step, replay at exit in development, serial against parallel, watched against
  unwatched, and `kyoten test --replay` across platforms.
- **Output is read-only by structure:** `const ref` parameters only, and its own state marked `"output": true`.

**What is promised** (*decided*, components question 8, 2026-11-06):
- **Nothing is frozen before 1.0.0.** kyoten iterates freely, as kama does at 0.9.x.
- **From 1.0.0, the promise covers what a game touches:** its records, its processor signatures, the engine components
  and generated names it uses, handles, and the order. Tables, chunks, N, the generated loops, the scheduler and the
  layout of side stores are not promised, because a game never names them.
- **It is kept** by records that never change meaning silently (wire names and ids, `@deprecated`, new fields with
  defaults), a migration when a record's shape must change, the engine's version in every save, and the examples
  built against every engine change.

**How memory is bounded** (*decided*, components question 6):
- **Every store has a ceiling from a budget record.** By default it is reserved when its zone or world is created; a
  table may instead commit chunks one at a time up to its ceiling, at the end of a phase, never moving earlier ones.
- **A full budget refuses by default,** and the spawning processor sees the refusal. Evicting (oldest spawn step, then
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
| The loop generated from a processor's signature | Unity's `IJobEntity` ([IJobEntity](https://docs.unity.com/en-us/engine/7000.0/script-reference/unity/entities/ijobentity.md)) | the whole world is generated, and kama checks it |
| Side stores beside tables | Bevy's opt-in sparse sets ([StorageType](https://docs.rs/bevy/0.13.1/bevy/ecs/component/enum.StorageType.html)) | — |
| A schedule built from declared access, at compile time | ecst ([ecst](https://www.github.com/vittorioromeo/ecst)) | **the compiler proves a processor stays inside its access**; Unity, Bevy, flecs, Mass and EnTT check at run time or not at all ([research/component-models.md](research/component-models.md)) |
| Order by groups, before and after, first and last | Unity Entities' `UpdateInGroup`, `UpdateBefore`, `UpdateAfter`, `OrderFirst`, `OrderLast` ([update order](https://docs.unity3d.com/Packages/com.unity.entities%401.2/manual/systems-update-order.html)) | a cycle or an unordered conflict is refused at start-up |
| Flags for components that come and go often (later) | Unity's enableable components ([manual](https://docs.unity3d.com/Packages/com.unity.entities@1.0/manual/components-enableable-intro.html)) | — |
| Bounded lists inline in a chunk, with a stated rule when full | Unity's dynamic buffers ([manual](https://docs.unity3d.com/Packages/com.unity.entities@1.2/manual/components-buffer-introducing.html)) | refuse or spill, stated per list |
| Shared read-only assets by handle | Unity's blob assets ([blob assets](https://docs.unity3d.com/Packages/com.unity.entities@6.6/manual/blob-assets-concept.html)) | — |
| Queued structural changes, played back in an order threads cannot change | Unity's command buffers, sorted by a sort key such as the chunk's index ([playback](https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/systems-entity-command-buffer-playback.html)) | the sort is always on |
| Reading other entities from a parallel processor | Unity's `ComponentLookup` reads them live, checked by the safety system at run time ([ComponentLookup](https://docs.unity3d.com/Packages/com.unity.entities@1.3/api/Unity.Entities.ComponentLookup-1.html)) | the previous step's snapshot by default, or this step's values declared by the system, both proven at compile time (question 3, choice 3) |
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
| A hello cube in few lines | Three.js: 25 lines (17 non-blank) unlit, 54 (35 non-blank) lit, about eleven concepts ([research/component-models.md](research/component-models.md) § 2); Bevy's `3d_rotation`, 55 lines with one Bevy system | records plus one processor, at most 20 non-blank lines and eight concepts, reading input, held by CI (question 7, revised 2026-11-06) |
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
