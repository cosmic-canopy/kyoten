# Component models: what Unity's growth and its peers teach kyoten

Research for KYR-3, made 2026-11-01. It feeds [../design/components.md](../design/components.md) questions 1–8 and
gathers evidence; it decides nothing. **Scope:** Unity, phase by phase; then Godot, Unreal (Actors, Mass and UEFN's
Scene Graph), Bevy, flecs, EnTT and Three.js; then probes of kama 0.9.803 (`../kama` at `cd549777`).

**Versions current that day:**

| Project | Version |
|---|---|
| Unity | 6.6 (6000.6), the manual's "current"; 6.7 LTS "coming soon" |
| Godot | 4.7 |
| Unreal Engine | 5.8 |
| Bevy | 0.20 (2026-10-08) |
| flecs | v4.1.6 |
| EnTT | 3.16.0 *(unverified: read from the README only)* |
| three.js | r187 |

**Reading this doc:**

- Every URL was read on 2026-11-01. Official docs and release notes were preferred over posts.
- *(unverified)* marks a claim not confirmed from a page that loaded.
- *(secondary)* marks press or Wikipedia, used where no primary source loaded.
- *(inferred)* marks my own conclusion.
- The kama probes ran on Windows 11 under msys2 UCRT64. Their sources lived in the session scratchpad and are not kept;
  the two that matter are reproduced in § 4.

## Summary

- **Unity grew by adding, almost never by replacing.** GameObject + MonoBehaviour (2005) is still the default.
  - **Added beside it:** nested prefabs and variants (2018.3), the Job System (2018.1) and Entities (1.0 in June 2023).
  - **What the second model cost:** five years of preview churn before Entities 1.0, then a second migration.
  - **The fix under way:** Unity is folding Entities back under GameObjects ("ECS for All"). EntityId replaced
    InstanceID in 6.4–6.5; "GameObjects are Entities" is still unshipped in August 2026.
- **What made Unity easy:** a component is a script on an object, its public fields appear in the Inspector, and
  `Update()` is called for you.
- **What Unity could never fix later:**
  - **Order.** Update order across objects "is not deterministic … it isn't guaranteed across builds, machines, or
    Unity versions".
  - **Identity.** Moving from an `int` InstanceID to an 8-byte EntityId took 2025–2026.
- **Order is unspecified almost everywhere:**
  - Bevy: query order "is not guaranteed"; unordered systems are non-deterministic by rule.
  - EnTT: "Do not make assumption on the order".
  - flecs: system order by id is "not guaranteed".
  - Unreal: no order within a tick group.
  - **Godot is the exception:** priority, then tree order.
  - So FFD's rule, "order is the stream", would be a promise few engines make *(inferred)*.
- **Overrides layer the same way everywhere.** A change is made per property, the most specific layer wins, and fields
  it does not mention inherit. This holds for Unity variants, Godot instances, flecs `IsA`, Bevy's BSN patches and UEFN
  prefabs. It is kama serde's `mergeJsonBuffer` rule, and it matches the project database's priority stacks.
  - **Unreal is the outlier.** It infers an override from a value that *differs* from the default.
  - **UEFN overrides per component, not per field.**
- **Phases.** flecs's built-in pipeline maps onto Input / Update / Constraints / Output almost one to one.
  - Its `OnValidate` exists for "validating the state of the game after processing the game play systems".
  - Its `PostUpdate` is where "you may want to apply some corrections". Together they are FFD's Constraints.
- **Rates.**
  - **One global fixed rate:** MonoBehaviour (50 Hz), Bevy (64 Hz) and Godot (60 Hz).
  - **Per-unit rates:** Unreal (`TickInterval` per tick function), flecs (`interval`, `rate` and shared tick sources)
    and Unity Entities (a `RateManager` per system group).
  - flecs's `rate` (every Nth tick) is FFD's tick-arithmetic sub-rate, made a feature.
- **Access declarations are never checked at compile time.** Bevy, flecs, Unity Entities, Mass and EnTT's organizer all
  declare reads and writes, but each checks them at run time or when the schedule is built. Unity's safety checks run
  only in the Editor, per its 2018.1 manual.
  - **kama's `scope` can prove disjointness at compile time,** but only where the spawning code names the fields (§ 4).
- **kama probes (0.9.803):**
  1. `scope` admits two systems on disjoint fields of a world, from the world's own method.
  2. It refuses a store reached through a `ref`-returning accessor.
  3. It refuses **two read-only children of one place**, as SPEC states, so "many systems read `Transform` in parallel"
     has no `scope` spelling today.
  4. One type cannot implement a generic contract for two type arguments (no overloading).
  5. **A `SlotMap` reuses a different slot after a serde round trip than it does live**, so a reloaded world iterates in
     a different order from the world it was saved from.
- **Every engine that changed its model paid for it.**
  - **Bevy** ships breaking releases about every 3 months; 0.19→0.20 has about 75 migration items.
  - **Godot** 3→4 was a largely manual migration.
  - **flecs** v3→v4 turned prefab inheritance off by default.
  - **Unity** replaced conversion with baking for Entities 1.0, then removed `Entities.ForEach` and Aspects in 6.5.
  - **Unreal** kept Actors and put Mass beside them. UE6's Scene Graph is to replace Actors "eventually"
    *(secondary)*.
- **The prototype bar.** Three.js's spinning cube is 25 lines (17 non-blank), or 54 (35 non-blank) lit. Bevy's
  `3d_rotation` is 55 lines. Godot's first script is 4 lines, because the editor holds the scene.

## 1. Unity, phase by phase

| Phase | When | What it added | What it kept | What it replaced | What it cost users |
|---|---|---|---|---|---|
| GameObject + Component + MonoBehaviour | 1.0, June 2005 *(secondary)* | objects as "containers for Components"; scripts as components; Inspector-serialized fields; `Update`/`FixedUpdate`/`LateUpdate` | — | — | order unspecified; one global fixed rate; heavy objects (later) |
| ScriptableObject | 1.x (API history) | data assets shared **by reference**, where prefab data is copied per instance | everything | — | none recorded |
| C# Job System; Burst and ECS as experimental | 2018.1, May 2018 | jobs over `NativeContainer`s with a safety system; Burst compiler | GameObjects as the main model | — | a second programming style for hot code |
| Nested prefabs and variants | 2018.3, Dec 2018 | nesting, variants, Prefab Mode, overrides per property and per component/GameObject | the prefab asset format, upgraded automatically | "disconnect" (now unpack); editing prefabs in the Project Browser | editor scripts had to change |
| Entities 0.x | 2018–2022 | archetype ECS, conversion from GameObjects | GameObjects | — | stuck on 2020 LTS through 2021; "pausing releases altogether" |
| Entities 1.0 | released June 2023 (2022 LTS) | Baking (editor-only), subscenes, `ISystem` | GameObjects for authoring | the conversion workflow; runtime conversion | a 21-step upgrade guide |
| Unity 6.x clean-up | 1.4, then 6.5 | — | — | `Entities.ForEach`, `Job.WithCode` and Aspects, obsolete in 1.4 and removed in 6.5 | ports of every system using them |
| "ECS for All" | announced Sept 2024; incremental from 6.4 | Entities as core packages (6.4); EntityId for GameObjects and entities (6.4–6.5); entities in the Hierarchy (6.6) | GameObjects | `int` InstanceID | an 8-byte id migration; "GameObjects are Entities" not yet shipped |

### The original model, and why it was easy

- **A GameObject is a container.** GameObjects "do not accomplish much in themselves but they act as containers for
  Components, which implement the functionality"
  ([manual](https://docs.unity.com/en-us/engine/current/manual/working-with-gameobjects/game-objects)).
- **A script is a component, and its fields are the UI.** "All public fields are editable in the Inspector window by
  default"; `[SerializeField]` exposes a private one
  ([manual](https://docs.unity.com/en-us/engine/current/manual/scripting/get-started/inspecting-scripts)). So one
  class is the data, the behaviour and the editor surface at once.
- **The engine calls you.** `Update`, `FixedUpdate` and `LateUpdate` need no registration. `LateUpdate` is "called after
  all Update functions have been called"
  ([API](https://docs.unity.com/en-us/engine/current/script-reference/unityengine/monobehaviour/lateupdate)).
- **Unity 1.0** was "first announced and released in June 2005 at the Apple Worldwide Developers Conference"
  ([Wikipedia](https://en.wikipedia.org/wiki/Unity_(game_engine)), *(secondary)*).

### What the original model left unspecified, for good

- **Order.**
  - "You can't specify the order in which an event function is called for different instances of the same
    MonoBehaviour script"
    ([manual](https://docs.unity.com/en-us/engine/current/manual/scripting/managing-update-order/execution-order)).
  - `[DefaultExecutionOrder]` orders *scripts*, not instances: "When multiple scripts have either the same configured
    execution order or the default execution order, the order of execution between them is not deterministic … it
    isn't guaranteed across builds, machines, or Unity versions"
    ([API](https://docs.unity.com/en-us/engine/current/script-reference/unityengine/defaultexecutionorder)).
- **Rates.**
  - `FixedUpdate` defaults to "0.02 seconds (50 calls per second)" and "may be called zero, one, or multiple times per
    frame" ([API](https://docs.unity.com/en-us/engine/current/script-reference/unityengine/monobehaviour/fixedupdate)).
  - `Time.fixedDeltaTime` is one static value
    ([API](https://docs.unity.com/en-us/engine/current/script-reference/unityengine/time/fixeddeltatime)). I found no
    per-component rate.
- **Physics determinism.** PhysX "Enhanced Determinism" promises consistency "provided that the game inserts the actors
  in a deterministic order". It makes no claim across machines
  ([manual](https://docs.unity.com/en-us/engine/6000.3/manual/unity-editor/editor-settings-reference/comp-manager-group/class-physics-manager)).

### Prefabs: overrides that could grow

- **2018.3 added nesting and variants on "a backward compatible Prefab backend that now supports nesting and
  inheritance"**, with overrides "per property, per Component/GameObject"
  ([blog, 2018-12-13](https://unity.com/blog/technology/introducing-unity-2018-3)).
- **What an override is:** a property value, "Adding or removing a component", or "Adding or removing a child
  GameObject".
  - "An overridden property value on a prefab instance always takes precedence over the value from the prefab asset."
  - Apply and revert work on all overrides, a selection, or one
    ([manual](https://docs.unity.com/en-us/engine/current/manual/working-with-gameobjects/prefabs/override/prefab-instance-overrides)).
- **Variants:** "Overrides in the variant take precedence over the base values. A variant can use any prefab as its
  base, including other variants"
  ([manual](https://docs.unity.com/en-us/engine/current/manual/working-with-gameobjects/prefabs/prefab-variants)).
- **Nested levels** ([2019.3 manual](https://docs.unity3d.com/2019.3/Documentation/Manual/PrefabOverridesMultiLevel.html)):
  - Changing an inner asset affects every instance "except where that property is overridden".
  - Applying to the inner asset reverts the matching override in the outer one.
  - The manual states no single "outermost wins" sentence; that rule is *(inferred)* from these.
- **The cost** ([2018.3 upgrade guide](https://docs.unity3d.com/es/2018.4/Manual/UpgradeGuide20183.html)):
  - Prefabs upgraded automatically.
  - "You can no longer disconnect a Prefab instance."
  - Editing moved to Prefab Mode.
  - Scripts that modified prefab assets had to use `PrefabUtility.LoadPrefabContents`/`SaveAsPrefabAsset`.
- *(inferred)* **Nesting arrived without breaking scenes because overrides were already stored per property.** The
  override format was the day-one decision that let the feature come later.

### Data assets

- A ScriptableObject is "a data container that you can use to save large amounts of data, independent of class
  instances". With prefabs the data is copied per instance; with a ScriptableObject you "access it by reference from all
  of the Prefabs". "In a deployed build, however, you can't use ScriptableObjects to save data"
  ([2023.1 manual](https://docs.unity3d.com/2023.1/Documentation/Manual/class-ScriptableObject.html)).
- It is listed under Unity 1.x's new classes
  ([API history](https://docs.unity3d.com/410/Documentation/ScriptReference/40_history.html)).
- `[SerializeReference]` (2019.3, *(unverified)*) serializes a field "as a reference instead of as a value", for
  polymorphism and shared graphs. "By-value serialization is more efficient"
  ([API](https://docs.unity.com/en-us/engine/current/script-reference/unityengine/serializereference)).

### Jobs and Burst: the safety system is a run-time check

- "The C# Job System ships in 2018.1"; ECS and Burst ship as experimental, "not production ready"
  ([forum, Unity staff, 2018-03-20](https://discussions.unity.com/t/welcome-to-the-dots-forums/695418)).
- **How the check works:**
  - The safety system "tracks what reads or writes to any NativeContainer".
  - Two unordered writers make it throw "when you schedule the second job"
    ([manual](https://docs.unity.com/en-us/engine/current/manual/scripting/programming-distribute-work-threads/job-system/thread-safe-types/native-container)).
  - `[ReadOnly]` lets readers share.
- **The checks are "only available in the Unity Editor and Play Mode"**
  ([2018.1 manual](https://docs.unity3d.com/es/2018.1/Manual/JobSystemNativeContainer.html)).

### Entities: the long road, and the turn back

- **The case for it.** GameObjects are "heavy c++" objects with "Cache misses galore"; the hybrid admits "two different
  worlds that are glued together"; and "Game Objects aren't going anywhere"
  ([blog, 2019-03-08](https://unity.com/blog/engine-platform/on-dots-entity-component-system)).
- **The road to 1.0:**
  - **Apr 2021:** "You must stay on Unity 2020 LTS and on Entities 0.17 for now"
    ([forum](https://discussions.unity.com/t/notice-on-dots-compatibility-with-unity-2021-1/836547)).
  - **Dec 2021:** "we ended up having to rewrite APIs more often than we wished… We ended up pausing releases altogether"
    ([forum](https://discussions.unity.com/t/dots-development-status-and-next-milestones-december-2021/864804)).
  - **0.50 (Mar 2022)** and **0.51 (May 2022)**, both still experimental
    ([0.50](https://discussions.unity.com/t/experimental-entities-0-50-is-available/874972),
    [0.51](https://discussions.unity.com/t/experimental-entities-0-51-is-available/881501)).
  - **Experimental 1.0 (Sept 2022):** "We have completely reengineered the conversion pipeline, which is now referred to
    as the Baking system" ([forum](https://discussions.unity.com/t/experimental-entities-1-0-is-available/895383)).
  - **Released (June 2023):** "This past June, we celebrated the Entities package officially entering Released status"
    ([forum](https://discussions.unity.com/t/dots-development-status-and-next-milestones-november-2023/933505)).
- **What 1.0 replaced:**
  - "The previous conversion system has been replaced with Baking", and "the only way to use Baking is through Sub
    Scenes" ([upgrade guide](https://docs.unity3d.com/Packages/com.unity.entities@1.0/manual/upgrade-guide.html)).
  - "Baking only happens in the Editor and never in-game, just like asset importing"
    ([manual](https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/baking-overview.html)).
- **Removals after 1.0.**
  - `Entities.ForEach`, `Job.WithCode` and `IAspect` were "marked as obsolete" in 1.4
    ([1.4](https://docs.unity3d.com/Packages/com.unity.entities@1.4/manual/whats-new.html)) and removed in Unity 6.5
    ([6.6 upgrade guide](https://docs.unity3d.com/Packages/com.unity.entities@6.6/manual/upgrade-guide.html)).
  - Aspects had become "a growing cost in both complexity and compilation time"
    ([forum, Sept 2024](https://discussions.unity.com/t/dots-development-status-and-milestones-ecs-for-all-september-2024/1519286)).
- **Order and rates** ([update order](https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/systems-update-order.html)):
  - **Groups.** There are three root groups: Initialization, Simulation and Presentation.
  - **Ordering.** `UpdateBefore`/`UpdateAfter` "only apply relative to direct children of the same system group". The
    page does not say how unconstrained systems are ordered.
  - **Fixed step.** `FixedStepSimulationSystemGroup` defaults to 1/60 s, overridable per group
    ([API](https://docs.unity3d.com/Packages/com.unity.entities@1.3/api/Unity.Entities.FixedStepSimulationSystemGroup.html)).
  - **Rates.** Any group may take a `RateManager`, an "Optional field to control the update rate of this system group"
    ([API](https://docs.unity3d.com/Packages/com.unity.entities@1.3/api/Unity.Entities.ComponentSystemGroup.RateManager.html)).
- **Reads and writes.**
  - "Unity analyzes the data dependencies of each system based on the ECS components that the system reads and writes".
    This is system-level, so jobs can wait on components they do not need
    ([manual](https://docs.unity3d.com/Packages/com.unity.entities@1.3/manual/scheduling-jobs-dependencies.html)).
  - A system "updates the version whether or not you actually write any component data — always specify read-only
    access when possible"; change versions are per chunk
    ([API](https://docs.unity.com/en-us/engine/7000.0/script-reference/unity/entities/archetypechunk/getchangeversion)).
- **Iteration order** (Joachim Ante, 2021-05-08,
  [forum](https://discussions.unity.com/threads/some-questions-about-ijobchunk-determinism.1105990/)):
  - Chunk order "is based on the order in which chunks are created and destroyed".
  - "The work stealing system and number of threads can vary the order", so "Your code has to be deterministic against
    chunkIndex".
  - A 2023 reply in the same thread says chunk order "remains deterministic per world".
- **Determinism, late.**
  - Unity Physics is "a completely deterministic rigid body dynamics" system, stateless to ease rollback
    ([manual](https://docs.unity3d.com/Packages/com.unity.physics@1.3/manual/design.html)).
  - It was "deterministic per architecture" in 2020
    ([forum](https://discussions.unity.com/threads/what-is-the-current-state-of-the-cross-platform-determinism-of-unity-physics.922055/)).
  - Burst's `FloatMode.Deterministic` shipped only in 1.8.25, on 2025-09-16
    ([changelog](https://docs.unity3d.com/Packages/com.unity.burst@1.8/changelog/CHANGELOG.html)). It covers 64-bit
    architectures and Burst-compiled code alone
    ([manual](https://docs.unity.com/en-us/engine/current/manual/programming-environment/script-compilation/burst/compilation/float-precision-determinism)).
  - Netcode for Entities says its fixed step gives "a baseline level of determinism … (although it's not strict
    determinism)" ([manual](https://docs.unity3d.com/Packages/com.unity.netcode@6.5/manual/client-server-worlds.html)).
- **Project Tiny**, the DOTS web runtime, targeted "the Web (both asmjs and WebAssembly)"
  ([manual](https://docs.unity3d.com/Packages/com.unity.tiny@0.23/manual/index.html)).
  - Its last release was 0.32.0 on 2020-11-13
    ([changelog](https://docs.unity3d.com/Packages/com.unity.tiny@0.32/changelog/CHANGELOG.html)).
  - I found no official statement that it ended.

### Where Unity 6 stands

- **Sept 2024 (Unite):**
  - The plan was "every GameObject be backed by an Entity" and a "Unified Transform".
  - It was to address the fact that many creators "have been unable to enjoy these benefits due to the advanced nature
    of ECS".
  - Six days later the same thread said "ECS for All will not be part of Unity 6 (or any 6.x release)" (thread above).
- **Dec 2025, reversed:**
  - "We've changed our plans with the intent to deliver as much as we can incrementally through major Unity 6
    versions."
  - Entities, Collections, Mathematics and Entities Graphics became core packages in 6.4.
  - EntityId "will become the preferred type for identifying objects in Unity and InstanceID methods will be marked as
    deprecated". It is to "allow us to treat GameObjects as Entities in future Unity 6.X releases", with no version
    given ([forum, 2025-12-11](https://discussions.unity.com/t/ecs-development-status-december-2025/1699284)).
- **Shipped by mid-2026:**
  - "All of the ECS packages are now core packages."
  - The "EntityId 8-byte migration" is complete.
  - Managed components are deprecated for `UnityObjectRef<T>`.
  - Source: [forum, 2026-06-29](https://discussions.unity.com/t/ecs-development-status-for-unity-6-6/1724480).
- **Aug 2026:**
  - A reply lists "GameObjects are Entities" and "Unified Transform" as pillars "for the short (1-2 year) future"
    ([forum](https://discussions.unity.com/t/2026-ecs-for-all/1732447)).
  - The poster's staff status is not labelled on the page.
- **Unity 7:**
  - Preview "launches in December, with full release targeted for Q1 next year", with "No breaking changes"
    ([blog, 2026-07-21](https://unity.com/blog/unite-seoul-keynote-2026-recap)).
  - The CoreCLR move slipped from 6.8 to 7.0
    ([March](https://discussions.unity.com/t/coreclr-scripting-and-ecs-status-update-march-2026/1711852),
    [June 2026](https://discussions.unity.com/t/coreclr-scripting-and-serialization-update-june-2026/1723299)).
- **Two sources disagree on timing:** Sept 2024 said "not in any 6.x"; Dec 2025 said incremental within 6.x.

### What Unity's history says to kyoten *(inferred)*

1. **Easy came from one idea:** an object you can see, with parts you attach, whose fields are its editor. Every later
   phase kept that surface.
2. **What could not be fixed later was semantic, not structural.** Unordered `Update` could never be given an order
   without breaking games that leaned on the accidental one; the docs now warn instead. The 32-bit id took two
   releases to widen.
3. **What could be added later was additive by design:** nested prefabs (per-property overrides already existed), data
   assets, jobs, Burst, and per-group rates.
4. **The expensive phase was a second model.** Two runtimes glued by conversion, then baking, ran from 2018 to at least
   2026. The fix under way is one identity (EntityId) under both.
5. **Unity's safety checks are dynamic and editor-only.** kama can do part of this statically (§ 4).

## 2. The contrasts

### Godot: nodes and scenes, composition by tree

- **The model.**
  - "a Godot game is a tree of scenes and that each scene is a tree of nodes". An instance "appears as a single node with
    its internals hidden" ([manual](https://docs.godotengine.org/en/stable/getting_started/step_by_step/nodes_and_scenes.html)).
  - Signals are "Godot's version of the observer pattern"
    ([manual](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)).
- **Why not ECS** (Juan Linietsky, 2021-02-26,
  [article](https://godotengine.org/article/why-isnt-godot-ecs-based-game-engine/)):
  - "Godot does composition at a higher level than in a traditional ECS."
  - "Godot does not have the concept or distinction between prefabs and scenes."
  - Performance lives below the nodes: "Godot puts most of the high performance/low level parts of the engine in
    Servers."
  - Per-frame user processing is "very rare"; most work runs from signal callbacks.
  - Games with tens of thousands of objects are pointed at the servers directly.
- **Order is specified** ([Node](https://docs.godotengine.org/en/stable/classes/class_node.html), 4.7 docs, re-read for
  this doc).
  - "Nodes whose priority value is *lower* call their process callbacks first, regardless of tree order".
  - Ties go "in tree order", a pre-order traversal.
  - Physics has its own `physics_process_priority`.
- **One global physics rate.** `physics_ticks_per_second` defaults to 60, with at most 8 steps a frame
  ([Engine](https://docs.godotengine.org/en/stable/classes/class_engine.html)). There is no per-node rate, only on/off.
- **Threaded processing came later, opt-in and checked at run time.**
  - 4.1 (July 2023) added "experimental multithreading for your scenes"
    ([release](https://godotengine.org/article/godot-4-1-is-here/)). The 4.7 docs no longer mark it experimental.
  - Access across groups is "forbidden (and it will result in an error in debug mode)"
    ([manual](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html)).
- **Overrides.**
  - "Changing a property on an instance always overrides values from the corresponding packed scene", and it is
    preserved when the base changes ([manual](https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html)).
  - `SceneState` keeps "exported and overridden properties" and a base scene to inherit from
    ([API](https://docs.godotengine.org/en/stable/classes/class_scenestate.html)).
  - I found no manual page on inherited scenes.
- **Growth.** 4.0 (March 2023) "breaks compatibility", and "a large part of the upgrade process remains manual"
  ([release](https://godotengine.org/article/godot-4-0-sets-sail/),
  [guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.html)). Within 4.x, renaming
  or removing API is reserved for a major release
  ([policy](https://docs.godotengine.org/en/stable/about/release_policy.html)).
- **Prototype.** The first script is 4 lines: `extends Sprite2D`, then `rotation += angular_speed * delta` in `_process`
  ([manual](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_first_script.html)). The scene
  itself is made in the editor.

### Unreal: Actors and Components, then Mass beside them, then Scene Graph

- **Actors and Components.**
  - Actors are "containers that hold special types of Objects called Components", and "Actors themselves do not have
    transforms" ([docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/actors-in-unreal-engine)).
  - "By default, Actor Components do not update"
    ([docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/components-in-unreal-engine)).
- **Overrides are inferred from difference.**
  - When a class default changes, the engine applies it to loaded instances. A differing instance value is assumed to
    be "set intentionally" and is kept. The docs' example: 100→150 propagates, an instance at 500 stays 500
    ([docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-object-handling-in-unreal-engine)).
  - *(inferred)* An instance deliberately set to the old default therefore loses its override silently.
- **Data inheritance.** For "data inheritance or a more complex hierarchy", Epic recommends "Data Only Blueprint
  Classes" over Data Assets ([docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/data-assets-in-unreal-engine)).
- **Ticking** ([docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/actor-ticking-in-unreal-engine)):
  - **Groups:** `TG_PrePhysics`, `TG_StartPhysics`, `TG_DuringPhysics`, `TG_EndPhysics`, `TG_PostPhysics`,
    `TG_PostUpdateWork` and more ([API](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/ETickingGroup)).
  - **Barriers:** "Each tick group will finish ticking every actor and component assigned to it before the next tick
    group begins", and "many actors can be updated in parallel if they're in the same group".
  - **No order within a group** is stated; prerequisites order pairs.
  - **Per-unit rates.** Each tick function has a `TickInterval`, "The time in seconds between executions of this tick
    function" ([API](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/FTickFunction)).
- **Chaos determinism is never promised.**
  - Async physics "improves the determinism of the simulation"
    ([docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/physics-in-unreal-engine)).
  - Networked physics resimulates on divergence
    ([docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/networked-physics-overview)).
- **Mass Entity**:
  - **What it is:** "a framework for data-oriented calculations". "Fragments and Entities are data-only", and
    "Processors are stateless classes"
    ([docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/overview-of-mass-entity-in-unreal-engine)).
  - **Phases:** `PrePhysics`, `StartPhysics`, `DuringPhysics`, `EndPhysics`, `PostPhysics`, `FrameEnd`
    ([API](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/MassEntity/EMassProcessingPhase)).
  - **Ordering:** `ExecuteBefore`/`ExecuteAfter`/`ExecuteInGroup`.
  - **Access:** each fragment is `ReadOnly` or `ReadWrite`
    ([API](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/MassEntity/EMassFragmentAccess)), and a
    dependency solver orders processors by it
    ([API](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/MassEntity/FMassProcessorDependencySolver)).
  - **5.8** "completely overhauled Mass processor execution and dependency resolution"
    ([notes](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-8-release-notes)).
  - **Status:** the docs page carries an "experimental" tag. Its 5.0 / City Sample origin is *(unverified)*.
- **Mass bridges to Actors rather than replacing them.** Its representation LOD picks "A high resolution Actor," "A low
  resolution Actor," "An Instanced Static Mesh (ISM)," or "No representation"
  ([docs](https://dev.epicgames.com/documentation/en-us/unreal-engine/overview-of-mass-gameplay-in-unreal-engine)).
- **UEFN Scene Graph** (entities, components and prefabs in Verse):
  - **Status:** experimental in UEFN 30.10, when publishing was not yet allowed
    ([notes](https://dev.epicgames.com/documentation/fortnite/30-10-fortnite-ecosystem-updates-and-release-notes-in-creative-and-unreal-editor-for-fortnite)).
    Publishable in beta from June 2025 ([forum](https://forums.unrealengine.com/t/scene-graph-beta-is-now-live/2545876)).
    Still "Beta" in the docs ([docs](https://dev.epicgames.com/documentation/en-us/fortnite/scene-graph-in-unreal-editor-for-fortnite)).
  - **Overrides are per component:** "Overrides supersede the parent prefab's design, at the affected component's
    level", and an override "stays the same even if you make changes to the parent prefab"
    ([docs](https://dev.epicgames.com/documentation/en-us/fortnite/prefabs-and-prefab-instances-in-unreal-editor-for-fortnite)).
- **UE6** *(secondary; Epic's page returned 403)*:
  - **The announcement.** It was announced on 2026-06-17 at State of Unreal. It merges UE5 and UEFN, with Verse and
    Scene Graph as the gameplay framework.
  - **The Actors path.** "Actors and Blueprints will eventually be deprecated when the new framework is sufficiently
    mature".
  - **Timing.** Early Access is targeted at late 2027.
  - **Sources:** [Game Developer](https://www.gamedeveloper.com/programming/unreal-engine-6-will-merge-ue5-and-uefn-into-a-single-unified-engine-),
    [GameFromScratch](https://gamefromscratch.com/unreal-deprecating-blueprints-and-actors/), and the deprecation line
    as quoted in a [forum reply](https://forums.unrealengine.com/t/state-of-unreal-2026-top-news-from-the-show/2729341).
  - **The press disagrees on how soon** Actors are deprecated.
- **UE4→UE5** kept projects loading ("will load in Unreal Engine 4.27, 5.0, and newer") and swapped PhysX for Chaos
  ([guide](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-migration-guide)).

### Bevy: archetype ECS, systems as plain functions, breaking by design

- **Storage.** "By default, components are added to the Table storage, which is optimized for query iteration". Sparse
  sets are opt-in per component
  ([docs.rs](https://docs.rs/bevy/latest/bevy/ecs/component/trait.Component.html)).
- **Access is the function signature.**
  - "Non-conflicting systems … in parallel"; a conflict "prevents them from running in parallel"
    ([docs.rs](https://docs.rs/bevy/latest/bevy/ecs/schedule/index.html)).
  - A conflict *inside* one system panics when the system is initialized
    ([docs.rs](https://docs.rs/bevy/latest/bevy/ecs/system/struct.Query.html),
    [B0001](https://bevy.org/learn/errors/b0001/)).
  - Ambiguity detection ("systems with conflicting access but indeterminate order") defaults to `Ignore`
    ([docs.rs](https://docs.rs/bevy/latest/bevy/ecs/schedule/struct.ScheduleBuildSettings.html)).
- **Order is not promised.**
  - "Iteration order is not guaranteed" (Query docs above).
  - 0.10: "The order of systems is nondeterministic unless there is an explicit ordering relationship between them"
    ([0.10](https://bevy.org/news/bevy-0-10/)).
  - 0.20 (re-read for this doc): "So far, the rule has been that this is non-deterministic". In practice, schedules pick
    the order of conflicting systems "deterministically, but arbitrarily".
  - 0.20 adds a `shuffle_seed` to randomize unordered systems and flush out hidden dependencies. It advises the
    single-threaded executor to avoid orders "not possible in single-threaded execution"
    ([0.20](https://bevy.org/news/bevy-0-20/)).
  - It also adds `chain_weak`, which orders only conflicting systems.
- **Phases and rates.**
  - Each frame runs `First`, `PreUpdate`, `StateTransition`, `RunFixedMainLoop`, `Update`, `SpawnScene`, `PostUpdate`
    and `Last`; rendering is a separate sub-app ([docs.rs](https://docs.rs/bevy/latest/bevy/app/struct.Main.html)).
  - The fixed schedule is "64 hertz" by default and may run "0, 1 or more times" a frame
    ([docs.rs](https://docs.rs/bevy/latest/bevy/time/struct.Fixed.html)). It is one global clock.
- **Change detection** marks a component "added or mutably dereferenced" and "does not compare components to their
  previous values" ([docs.rs](https://docs.rs/bevy/latest/bevy/ecs/query/struct.Changed.html)).
- **Growth in phases** (each breaking):
  - **0.10 (2023):** "Stages have been removed. Replace these with system sets"; the fixed-timestep run criterion
    became a schedule ([migration](https://bevy.org/learn/migration-guides/0-9-to-0-10/)).
  - **0.14:** hooks and observers ([0.14](https://bevy.org/news/bevy-0-14/)).
  - **0.15:** bundles deprecated: "Required Components are now the preferred / idiomatic approach"
    ([0.15](https://bevy.org/news/bevy-0-15/)).
  - **0.16:** relationships ([0.16](https://bevy.org/news/bevy-0-16/)).
  - **0.19:** resources became components on singleton entities, and BSN arrived as macros
    ([0.19](https://bevy.org/news/bevy-0-19/)).
  - **Cadence:** "A new version of Bevy containing breaking changes to the API is released approximately once every 3
    months" ([quick start](https://bevy.org/learn/quick-start/introduction/)).
- **BSN overrides.**
  - "Unmentioned fields keep their existing values (from a included scene, an earlier patch, or the type's defaults)";
    patches "are applied in order, only overwriting the fields they changed"
    ([docs.rs](https://docs.rs/bevy_scene/latest/bevy_scene/)).
  - `.bsn` files do not load yet ([macro docs](https://docs.rs/bevy/latest/bevy/scene/macro.bsn.html)).
- **Prototype.** `examples/transforms/3d_rotation.rs` is 55 lines (47 of code). It has a cube, a camera, a light, and a
  `rotate_cube` system over `Query<(&mut Transform, &Rotatable)>`
  ([source](https://github.com/bevyengine/bevy/blob/main/examples/transforms/3d_rotation.rs)).

### flecs: relationships, prefab inheritance, and a phase pipeline like kyoten's

- **Built-in phases, "listed in topology order":** `OnStart`, `OnLoad`, `PostLoad`, `PreUpdate`, `OnUpdate`,
  `OnValidate`, `PostUpdate`, `PreStore`, `OnStore` (re-read for this doc,
  [Systems.md](https://raw.githubusercontent.com/SanderMertens/flecs/master/docs/Systems.md)).
  - Phases are "just tags", and an application may add phases or "define a pipeline from scratch"
    ([design guide](https://www.flecs.dev/flecs/DesignWithFlecs.html)).

| kyoten | flecs phase | The flecs design guide's own words |
|---|---|---|
| Input | `OnLoad` | "systems that load data into your ECS … a good place to load keyboard and mouse inputs" |
| Input | `PostLoad` | "Often the imported data needs to be processed" |
| Update | `PreUpdate` | "get ready to start processing our game logic" |
| Update | `OnUpdate` | "This is usually where the magic happens!" |
| Constraints | `OnValidate` | "validating the state of the game after processing the game play systems"; e.g. entities "too close to each other", collision detection |
| Constraints | `PostUpdate` | "you may want to apply some corrections" |
| Output | `PreStore` | "prepare the frame for rendering" |
| Output | `OnStore` | "Your frame is ready to be rendered, and that is exactly what you would do in this phase" |

*(inferred)* The match is close. flecs splits FFD's Constraints into detecting (`OnValidate`) and correcting
(`PostUpdate`). Its pipeline has no recorded-input notion, and no rule that Output only reads.

- **Access declarations.**
  - Terms are `In` ("readonly"), `Out` ("write only"), `InOut` or `None`, and "the scheduler may use access modifiers to
    determine where sync points are inserted"
    ([Queries](https://www.flecs.dev/flecs/Queries.html)).
  - A sync point is a moment when commands are flushed.
- **Threads.**
  - The scheduler "runs each multithreaded system on all threads, and divides the number of matched entities across
    the threads". The same entity stays on one thread until the next sync point (Systems.md).
  - That is data parallelism inside a system, not systems in parallel.
- **Order.**
  - "A pipeline by default orders systems by their entity id, to ensure deterministic order", and "this is not
    guaranteed", because a recycled id can sort lower (Systems.md).
  - Unsorted queries iterate tables, then rows, in no stated order.
  - v4.1.6: "Query groups are no longer iterated in order by default"
    ([release](https://github.com/SanderMertens/flecs/releases/tag/v4.1.6)).
- **Rates.** `interval` (by time), `rate` (every Nth tick) and shared `tick_source` entities keep systems in phase.
  Tick sources nest ([Systems](https://www.flecs.dev/flecs/Systems.html)).
- **Prefabs and overrides** ([PrefabsManual](https://www.flecs.dev/flecs/PrefabsManual.html)):
  - **Override:** "To override a component, simply add or set it on the instance".
  - **Revert:** "When an override is removed, the original value of the prefab is reexposed".
  - **Variants:** "Prefabs can inherit from each other to create prefab variations without duplicating the prefab data".
  - **Shared storage:** inherited components "are only stored once in memory, and shared across instances".
  - **Per-component policy:** `OnInstantiate` is `Copy` (the default), `Inherit` or `DontInherit`
    ([ComponentTraits](https://raw.githubusercontent.com/SanderMertens/flecs/master/docs/ComponentTraits.md)).
- **Data definitions.** Flecs Script is "optimized for defining scenes, assets and configuration". `:` adds an `IsA`,
  and assigning a value needs the type described to reflection
  ([FlecsScript](https://raw.githubusercontent.com/SanderMertens/flecs/master/docs/FlecsScript.md)).
- **v3→v4** ([migration](https://raw.githubusercontent.com/SanderMertens/flecs/master/docs/MigrationGuide.md)):
  - "components no longer inherit by default when instantiating a prefab".
  - `override` was renamed `auto_override`.
  - Query fields start at 0, and snapshots were removed.

### EnTT: sparse sets, no scheduler

- **Storage.** "Each pool contains all the instances of a single component type". A view "is iterated along the pool
  that contains the smallest number of elements", and owning groups are "the fastest tool"
  ([entity.md](https://github.com/skypjack/entt/blob/master/docs/md/entity.md)).
- **Order.**
  - "There are no guarantees that entities are returned in the insertion order … Do not make assumption on the order in
    any case" ([sparse_set.hpp](https://raw.githubusercontent.com/skypjack/entt/master/src/entt/entity/sparse_set.hpp)).
  - Sorting is explicit (`sort`, `sort_as`).
  - Removal is swap-and-pop unless `in_place_delete` is set.
- **Systems.**
  - The organizer builds "an execution graph from a set of functions and their requirements on resources", where "The
    _constness_ of a type also dictates its access mode (RO/RW)".
  - "The actual scheduling of the tasks is the responsibility of the user" (entity.md).
- **Threads.** "the entire registry is not thread safe as it is" (entity.md).
- **Users.** "used in Minecraft by Mojang" ([README](https://github.com/skypjack/entt)). "Bedrock" specifically is
  *(unverified)*.

### Three.js: the prototype bar

- **The model.** `Object3D` is "the base class for most objects in three.js", and "an object can have at most one
  parent". `userData` holds custom data
  ([docs](https://threejs.org/docs/pages/Object3D.html)).
  - There is no component system or fixed step. `Timer` takes variable deltas
    ([docs](https://threejs.org/docs/pages/Timer.html)).
- **"Creating a scene" is 25 lines of JavaScript (17 non-blank)**
  ([manual source](https://raw.githubusercontent.com/mrdoob/three.js/dev/manual/pages/creating-a-scene.html)).
  - **What a newcomer meets:** `Scene`, `PerspectiveCamera`, `WebGLRenderer`, `BoxGeometry`, `MeshBasicMaterial`,
    `Mesh`, `scene.add`, `setAnimationLoop` and `render`.
  - **The lit version** adds `DirectionalLight` and `MeshPhongMaterial`, and is 54 lines (35 non-blank) (the
    `fundamentals-with-light` page beside it).
- **`WebGPURenderer` is "still in an experimental state"** per the manual
  ([manual source](https://raw.githubusercontent.com/mrdoob/three.js/dev/manual/pages/webgpurenderer.html)). Blogs
  that call it production-ready contradict it *(unverified)*.

## 3. Compared

| | Unit of composition | Storage and performance | Order specified? | Data definitions and overrides | Access declared for parallelism | Per-unit rates | Growth without breaking games |
|---|---|---|---|---|---|---|---|
| **Unity GameObjects** | object + attached scripts | heap objects; Jobs/Burst for hot code | no ("not deterministic") | prefabs; per-property overrides; variants; ScriptableObject by reference | none on scripts; jobs: `[ReadOnly]`, checked at run time in the Editor | one global fixed rate | additive (prefabs 2018.3, jobs) |
| **Unity Entities** | entity + data components | archetype chunks; Burst | systems by explicit constraints; chunk order by history | baked from GameObject authoring in subscenes | query `ReadOnly`/`ReadWrite`; run-time safety | `RateManager` per group | 0.x churn, then 1.0 removed conversion, and 6.5 removed `ForEach` and Aspects |
| **Godot** | node; scene = node tree | nodes for logic, servers for hot paths | **yes**: priority, then tree order | scenes; instance overrides persist; inherited scenes | thread groups (4.1), debug-mode run-time errors | one global physics rate | 3→4 manual; minor versions conservative |
| **Unreal Actors** | Actor + components | objects; tick groups | groups yes, within a group no | CDO + Blueprint subclasses; override inferred from a differing value | tick groups, `bRunOnAnyThread` | `TickInterval` per tick function | UE4→5 loads old projects; Mass added beside |
| **Unreal Mass** | entity + fragments/tags | archetype ECS | topological by declared order | traits | `ReadOnly`/`ReadWrite` per fragment; solver | via processing phases | "experimental" tag |
| **UEFN Scene Graph** | entity + components + prefabs | not documented here | not found | prefabs; per-*component* overrides | not found | not found | beta; UE6 to adopt it *(secondary)* |
| **Bevy** | entity + components (required components) | tables by default; opt-in sparse sets | no; `shuffle_seed` to expose reliance | BSN patches (unmentioned fields keep values); `.bsn` files not yet | function parameter types; conflicts serialize systems | one global fixed clock (64 Hz) | breaking every ~3 months, with migration guides |
| **flecs** | entity + components + relationships | archetype tables | by system id, "not guaranteed" | Flecs Script; `IsA` prefabs, variants, overrides on set | `In`/`Out`/`InOut`; sync points | `interval`, `rate`, tick sources | v3→v4 changed defaults |
| **EnTT** | entity + components | sparse set per type; groups | "Do not make assumption" | none built in; snapshots | organizer reads `const`; no executor | none | library, no model shifts found |
| **Three.js** | `Object3D` tree | scene graph, render-driven | child order (tree) | none; code builds the scene | none | none (variable delta) | — |
| **FFD / TMM** ([peer-games § 3](peer-games.md#3-component--entity-model)) | one world type of fixed arrays | dense arrays, µs ticks | **yes**: "order is the stream" | code constants (FFD); live-tuned JSON (TMM) | `scope` rules written, unused | tick arithmetic | — |

## 4. Probes of kama 0.9.803

Built with `out/UCRT64-x86_64/kama.exe` (`0.9.803+gaa9093dc`). Each probe is my own scratch program.

1. **Disjoint stores, from the world's own method: admitted.**
   - **The program:** a `type resource World` holds `DynamicArray<Pos> pos` and `DynamicArray<Hp> hp`. A method runs
     `scope { spawn stepPos(ps: ref this.pos); spawn stepHp(hs: ref this.hp); }`.
   - **The result:** it builds and runs.
2. **The same store twice: refused** at compile time. The message is "two children in this `scope` borrow overlapping
   places (`this.pos` and `this.pos`)".
3. **A store reached through an accessor: refused.**
   - **The program:** `spawn stepPos(ps: ref w.positions())` from outside the world.
   - **The message:** "An element (`a[i]`) or a call result names no place a static disjointness rule can pin". So the
     spawning code must name fields: the world's own methods, a world that is a `type value` with public fields, or a
     `friend` grant *(inferred from AGENTS.md; not probed)*.
4. **Two read-only children of one place: refused.**
   - **The program:** two `spawn reader(c: ref c)` calls, where `reader` takes `const ref`.
   - **The result:** refused with the same overlap error.
   - **By design:** SPEC § Structured concurrency says "so is the same local twice". The check treats every `ref`
     handed to a spawn as mutable (`src/kama.cemit.cpp:22093-22112`).
   - **The one read-only sharing form** is `parallel_for (const ref T e in coll)`.
   - **Why it matters:** Bevy, Unity and Mass all win their parallelism by letting several systems read one component
     at once. Filed as [KY-5](../KAMA_GAPS.md), reproduced again by the coordinator.
5. **One world implementing `HasStore<T>` for two `T`: refused.** The messages are "duplicate method 'store' in 'World'
   — kama has no overloading", and a signature mismatch. So an engine-generic system cannot ask a game's world for
   "the store of `T`" through one contract.
6. **SlotMap order after a serde round trip: diverges.**
   - **The program:** insert 0, 1, 2 and 3; remove slot 1, then slot 3; JSON-serialize; deserialize; insert one value
     into each.
   - **The result:** the live map reuses **slot 3** and iterates `0 2 9`. The reloaded map reuses **slot 1** and
     iterates `0 9 2`.
   - **The cause:**
     - Live, the free list is a stack (`lib/std/collections/slot_map.kama:177-179`, `:228-229`).
     - On deserialize it is rebuilt "descending so the LOWEST vacant slot is reused first" (`:369-375`).
     - The comment at `:300-302` says the order "is not observable through any accessor". But `values()` iteration
       (slot order, `:244`) and `Handle.index` both observe it.
   - **The consequence:** a world saved, loaded and stepped is not the world stepped. Filed as
     [KY-4](../KAMA_GAPS.md), reproduced again by the coordinator.
     This bears on replay from a snapshot and on rollback.

```kama
// probe 6, condensed: prints "live reused slot 3; round-tripped reused slot 1"
@generate(Serializable, Deserializable) type value Pos { @field public int32 v; public ctor make(int32 v) { this.v = v; } }
SlotMap<Pos> live = SlotMap.empty();
Handle h0 = live.insert(value: Pos.make(v: 0)); Handle h1 = live.insert(value: Pos.make(v: 1));
Handle h2 = live.insert(value: Pos.make(v: 2)); Handle h3 = live.insert(value: Pos.make(v: 3));
Optional<Pos> r1 = live.remove(handle: h1); Optional<Pos> r3 = live.remove(handle: h3);
// serializeJsonBuffer(v: live) -> deserializeJsonBuffer::<SlotMap<Pos>>(…) -> loaded
Handle a = live.insert(value: Pos.make(v: 9)); Handle b = loaded.insert(value: Pos.make(v: 9));   // a.index 3, b.index 1
```

Already established elsewhere:

- Contract bounds monomorphize to direct calls; kama's `tests/ecs_pattern.kama` and `tools/check-ecs-zero-dispatch.sh`
  keep it so.
- `mergeJsonBuffer` writes only the fields a document names, atomically
  ([kama-for-engines.md § 5](kama-for-engines.md#5-data-and-tooling-for-an-ai-driven-engine)).
- There are no capturing closures, overloading or default parameters, and module statics are per isolate (§ 7 there).

## 5. What this means under kama's constraints

Each question from [components.md](../design/components.md) gets its evidence, the options the engines suggest, and
what kama does to each.

### 1. ECS, or not?

- **Evidence.**
  - **Unity** went from objects to an archetype ECS and is now unifying the two under one id.
  - **Godot** refused ECS for usability and put performance in its servers.
  - **Unreal** kept Actors, put Mass beside them, and plans Scene Graph (entities, components, prefabs) as the
    successor *(secondary)*.
  - **The peers** have no ECS, and ticks cost microseconds
    ([peer-games § 7](peer-games.md#7-lessons-relevant-to-a-general-purpose-engine)).
- **Options.**
  - **(a) An archetype ECS** (Bevy, flecs, Mass).
  - **(b) Sparse sets**: a `Store<T>` per component type, dense values plus entity handles (EnTT).
  - **(c) FFD made general**: a world of typed stores, with systems as functions over them.
- **kama.**
  - **Archetypes block.** An archetype table holds columns whose types are known only at run time. That needs
    type-erased bytes, a size, and a `fnptr` drop per column: `UnsafePtr` code inside `unsafe fn` seams, with no
    runtime type ids to key them *(inferred)*. kama's ownership and type checks would stop at the column boundary.
  - **(b) and (c) fit.** They are `SlotMap`/`DynamicArray`/`View` and generics, and each store is a field, so `scope`
    can see it (probe 1).
  - **What (c) cannot do:** an engine-generic `HasStore<T>` world (probe 5). Generic code must be handed the store
    itself.

### 2. What is a component?

- **Evidence.**
  - Mass fragments are "data-only"; Bevy, flecs and Unity Entities components are plain data.
  - Unity deprecated managed (object-holding) components in 2026 for `UnityObjectRef<T>`, a reference by id.
  - TMM holds physics bodies as plain-data `BodyId` handles.
  - Unity's ScriptableObject is shared by reference, where a prefab's data is copied per instance.
- **Options.**
  - **(a) Always a `type value`,** with owned memory (a mesh, a path) in an asset store and the component holding a
    `Handle` or an id.
  - **(b) Values plus a separate resource-store kind** for owning components.
- **kama.**
  - **Helps:**
    - A `type value` is copyable and can `@generate(Serializable)` with every field marked.
    - It hashes field by field, as FFD does.
    - `Handle` already serializes portably (`int64` on the wire).
    - `Shared<immutable T>` lets many isolates read one asset with no copy.
  - **Blocks:** a `type resource` has only private fields, so a resource component cannot expose data to systems
    except through methods. Probe 3 shows that a method's result cannot be a spawn place.

### 3. What is a system?

- **Evidence.**
  - **Declaring access:** every engine declares reads and writes. Bevy uses parameter types, flecs `In`/`Out`, Unity
    `ReadOnly`, Mass `EMassFragmentAccess`, and EnTT `const`.
  - **Checking it:** none checks before run time. Bevy panics on initialization or serializes conflicting systems;
    Unity throws in the Editor; Godot errors in debug builds.
- **Options.**
  - **(a) Systems are free functions whose parameters are their stores:**
    `fn void integrate(ref Store<Pos> p, const ref Store<Vel> v)`. A phase method calls them in a written order and
    wraps a parallel group in `scope`. The signature *is* the access declaration, as in Bevy, but the compiler checks
    it (probes 1–2).
  - **(b) Registered `Owned<System>` functors** with access as data, and a run-time scheduler as in Bevy and Unity.
    Parallel work then goes through the `UnsafePtr` "primary isolate idiom"
    ([kama-for-engines § 1](kama-for-engines.md#1-parallelism-primitives)), so disjointness is kyoten's invariant.
  - **(c) (a), generated:** systems are declared in records (phase, rate, stores read and written), and a kyoten tool
    writes the phase methods.
- **kama.**
  - **No closures,** so (b) needs one type per system that implements a contract. An `Owned<System>` call is one
    indirect call per system per tick *(inferred: negligible)*.
  - **Probe 4 blocks the common case,** two readers of one store in one `scope`.
    - **Workarounds:** `parallel_for`'s `const ref` form for data parallelism; Output reading a snapshot, which
      [replay-and-determinism.md](../design/replay-and-determinism.md) question 6 may want anyway; or a kama change.

### 4. Determinism

- **Evidence.**
  - **Only Godot specifies order.** Unity, Bevy, EnTT and Unreal disclaim it, and flecs aims for it but does not
    guarantee it.
  - **Each engine has its own patch:**
    - Unity Entities: chunk order is "deterministic per world", but parallel scheduling varies it, so code "has to be
      deterministic against chunkIndex".
    - Bevy: randomizes unordered systems to *find* reliance on order.
  - **Float determinism came late.** Burst's deterministic float mode arrived in 2025, 64-bit only.
- **Options.**
  - **(a) The engine promises it.** Systems run in declared order, and each store iterates in a specified order:
    insertion order with ordered removal, or slot order with a specified reuse rule. Parallel groups admit only disjoint
    writes, which `scope` proves.
  - **(b) A game opts in** (Unity's position).
- **kama.**
  - **Helps:** `reproducible-float`, `Rng.seeded`, overflow traps, and `scope`'s disjointness. Disjoint writers give the
    same result in any interleaving.
  - **Blocks: probe 6.** A store whose reuse rule changes across a save is not deterministic. If kyoten builds on
    `SlotMap`, the reuse policy must be canonical in both paths, or the store must be kyoten's own.
  - **Swap-and-pop** (EnTT's default, cheap removal) also reorders. Whether removal is ordered is a day-one semantic
    *(inferred)*.
  - **A tripwire in Bevy's spirit:** step a parallel group serially in two different orders and compare world hashes
    *(inferred)*.

### 5. Records and components

- **Evidence: how overrides layer.**

| Engine | Unit of override | Stored as | When the base changes |
|---|---|---|---|
| Unity | property; added/removed component or child | explicit modification | instance or variant value wins |
| Godot | property | explicit, in `SceneState` | override "preserved" |
| Unreal | property | inferred from a value differing from the CDO | non-differing instances follow |
| flecs | component (add/set on instance) | the instance's own copy | removing it "reexposes" the prefab value |
| Bevy BSN | field | ordered patches | unmentioned fields keep earlier values |
| UEFN | component | override at "the affected component's level" | override "stays the same" |

  Unity's baking ("never in-game, just like asset importing") is the authoring-to-runtime boundary that
  [project-database.md](../design/project-database.md) question 8 asks about.
- **Options.**
  - **(a) One record schema per component type, generated by serde.** A prefab record is a list of component records
    plus a parent id (a variant). An instance or a higher layer is a patch of the fields it names, merged in priority
    order.
  - **(b) Component-level overrides** (UEFN, flecs): simpler to show, coarser to merge.
  - **Removing a component** needs an explicit tombstone in either, as Unity records "removed component" overrides.
- **kama.**
  - **Helps:** `mergeJsonBuffer` *is* the field-level patch: it writes only the named fields and leaves the value
    untouched on error. Strict decoding refuses a misspelt key. `@field(id:)` lets JSON and binary coexist, and
    `@deprecated` keeps old fields readable.
  - **Blocks:** a patch that removes something is not a merge, and Unreal's inferred overrides would need comparing
    against a default *(inferred)*.

### 6. Scale and storage

- **Evidence.**
  - FFD and TMM use fixed capacities.
  - Bevy chooses table or sparse set per component.
  - EnTT makes pointer stability opt-in.
  - flecs added non-fragmenting storage to curb archetype explosion.
- **Options.**
  - **(a) A capacity per store, declared by the game:** predictable and `@noheap`-friendly.
  - **(b) Growable stores.**
  - **(c) Both,** fixed by default.
- **kama.**
  - **The world's kind decides where spawning can live.**
    - **A resource world** keeps its stores private, so its parallel spawns live in its own methods (probes 1, 3).
    - **A value world** with public `InlineArray` fields can be spawned from outside. But it is a large value: KM-29's
      frame-size lesson applies, so it lives behind `Owned`
      ([peer-games § 7](peer-games.md#7-lessons-relevant-to-a-general-purpose-engine)).
  - **`@noheap` proves a tick allocates nothing,** which favours fixed capacity or a bump allocator.

### 7. The prototype path

- **Evidence.**
  - **Three.js** needs 25 lines unlit and 54 lit, with nine concepts.
  - **Bevy** needs 55 lines and a system.
  - **Godot** needs 4 lines of script, with the scene made in an editor.
- **Options.**
  - **(a) A built-in `Spin` component** (axis, rate), so the cube is pure data: a record or three calls, no system.
  - **(b) A one-system minimum,** as Bevy does.
  - **(c) An object-style facade** (`scene.add(Mesh.cube(…))`) over the component model, as Three.js does.
  - Because the first consumer is AI ([ai-first-api.md](../design/ai-first-api.md)), (a) puts the cube in the
    project database, where agents work *(inferred)*.
- **kama.**
  - **Helps:** named constructors keep calls short, and mandatory named arguments make them readable.
  - **Blocks:** no default parameters means every call states everything. No closures means a custom behaviour is a
    type plus a contract, longer than a Three.js lambda.

### 8. Growing in phases: what must be right on day one

*(inferred, from Unity's history and the others' migrations)*

**Day one, because changing it breaks every game:**

1. **Entity identity and its wire form.**
   - **Unity's cost:** a 32-bit InstanceID became an 8-byte EntityId twenty years in.
   - **kyoten's case:** handles appear in every save, record and network message. kama's `Handle` is already
     `int64` + `uint32` on the wire.
2. **Order and the determinism promise.**
   - **Unity's case:** it cannot add an order now.
   - **Bevy's case:** it added tools to cope with not having one.
   - **The decision:** declared system order, a specified store order (including removal and slot reuse), and whether
     determinism is promised.
3. **The override format.**
   - **Unity's case:** 2018.3 nesting worked because overrides were already per property.
   - **The decision:** field or component granularity, explicit or inferred, how removal is recorded, and the order in
     which layers apply.
4. **What a component is.**
   - **Unity's case:** MonoBehaviour fused data, behaviour and editor, so the fast path needed a second model.
   - **Bevy's case:** bundles to required components was a migration. Data-only components keep that door open.
5. **Where a system states its phase, and the phase names.**
   - **Bevy's case:** removing stages (0.10) was its largest break.
   - **flecs's case:** it kept its phase tags stable.
6. **Output reads, never writes** (replay-and-determinism.md question 6). Enforcing it later would break every
   renderer that writes back.

**Later, without breaking games, if the above hold:**

- **Parallel execution inside a phase.**
  - Unity's jobs came 13 years in, additively; Godot's thread groups were opt-in.
  - With access stated in signatures from day one, parallelism is a scheduler change.
- **Prefab nesting and variants,** given a per-field patch format.
- **Relationships and hierarchy** (Bevy 0.16), given handles are plain data.
- **Change detection, hooks and observers** (Bevy 0.14, additive).
- **A different store layout behind the same `Store<T>` API** (Bevy's per-component storage choice).
- **Per-system rates beyond tick division,** and editor and visual tools.
- **A fast path for very many entities**, as Mass sits beside Actors. Risky if it becomes a second model (Unity's
  lesson).

## Options for the walk-through

**Input, not decisions.** Three coherent shapes, each answering questions 1–8 together.

### A. Typed world, written phases (FFD made general)

- **The shape.**
  - The engine supplies `Store<T>` (dense values, generational handles, specified order), the frame harness, and serde
    loading from records.
  - A game declares its world: one store per component.
  - Systems are free functions over stores. Phase methods call them in a written order, and a parallel group is a
    `scope` block.
- **For:**
  - It is the least machinery and the strongest fit with kama.
  - Access is checked by the compiler (probes 1–2), and order is explicit, so determinism is by construction.
  - It is closest to the peers' code, which kyoten starts from.
- **Against:**
  - The game writes the world and its phase methods. That boilerplate grows with the component count, and per-file
    visibility pushes it into one large file, which is FFD's 11,108-line lesson.
  - Adding a component at run time to any entity needs every store sparse-indexed by entity.
  - Two systems reading one store in parallel is refused today (probe 4).
  - Tools learn each game's world through `kama query` and serde.
- **Day one:** the `Store<T>` semantics (identity, order, removal) and the phase names.

### B. Generated world, declared systems (A, driven by the project database)

- **The shape.**
  - Component schemas, prefabs and system declarations (phase, rate, stores read and written) are records.
  - A kyoten tool generates the world type and the phase methods (A's code). The game writes only system bodies.
- **For:**
  - Agents edit records, which suits AI as the first consumer, and the wiki can show the schedule as data.
  - The compiler still checks the generated `scope` blocks.
  - Overrides and layers are the database's own stack.
- **Against:**
  - A generator, and generated code to keep in step with the records, plus a build step on every schema change.
  - Errors surface in generated files unless the tool maps them back.
  - The generator's output format becomes a day-one commitment.
- **Day one:** A's commitments, plus the record schema for systems.

### C. Engine-owned archetype ECS (Bevy- or flecs-shaped)

- **The shape.**
  - The engine owns the world: type-erased columns per archetype and a component registry.
  - Systems are `Owned<System>` functors with access declared as data.
  - A run-time scheduler applies a specified order, with parallelism through an `UnsafePtr` seam.
- **For:**
  - It is most familiar to people and agents trained on Bevy or Unity DOTS.
  - Run-time composition, reflection for tools, and editor inspection are straightforward.
  - No per-game world type is needed.
- **Against:**
  - kama's type and ownership checks stop at the column boundary (`UnsafePtr`, `fnptr` drop glue, hand-rolled type
    ids), and disjointness is kyoten's invariant, not the compiler's.
  - It is the most machinery.
  - The peers' ticks are microseconds, so the performance case is unmeasured
    ([peer-games § 7](peer-games.md#7-lessons-relevant-to-a-general-purpose-engine)).
  - Order must still be specified on top, which no archetype engine surveyed does by default.
- **Day one:** the registry and handle format, scheduler order rules, and column layout semantics.

*(inferred)* Any of the three can put a Three.js-style facade on top for the prototype path (question 7). The day-one
list in question 8 applies to all three; what differs is how much of it the compiler checks.

## Not verified

- Unity 1.0's date and Unity 6's release date (Wikipedia only).
- That `[SerializeReference]` arrived in 2019.3.
- Mass's introduction with UE 5.0 and the City Sample, and its status in 5.8.
- UEFN Scene Graph's experimental date.
- Everything about UE6, which rests on press: Epic's own page returned 403.
- EnTT's current version and the "Bedrock" attribution.
- Whether three.js's `WebGPURenderer` is production-ready, where the manual and blogs disagree.
- The order in which flecs merges per-thread command queues, which the docs do not state.
- Who posted the Aug 2026 Unity forum reply: the page does not label a staff role.
