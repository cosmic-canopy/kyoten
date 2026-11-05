# Game types, stress-tested

KYR-58, a desk exercise done on 2026-11-04 before [components.md](../design/components.md) question 1. The owner
asked for it: "we want to support all game types", with an FPS first, and "on par or better than Godot, Unity, or
Unreal" ([../VISION.md](../VISION.md)). Nothing was built for it. Each kind of game is taken as it is usually made,
from published sources, and run against what is already decided, to find where the model holds and where it would
break before anything is built on it. Only building proves the model holds. That falls to the FPS example
([../design/examples.md](../design/examples.md)), and examples.md's questions decide which other kinds of game are
ever built.

**What each kind is run against:**

- **The frame** ([frame-phases.md](../design/frame-phases.md) § Decided, all ten questions):
  - Input → Update → Constraints → Output, with Output read-only;
  - one simulation clock, with subsystems handed their step;
  - timestamped interpolation;
  - parallelism from stated access, proven by the compiler and serial by default;
  - waits as deadlines in steps;
  - the headset as one more frame source.
- **Components options A and B** ([component-models.md](component-models.md) § Options), with chunk storage inside: the
  owner's leaning, "B built on A with C internal storage when possible".
- **Per-zone budgets** (VISION, 2026-11-04): "each zone of a level can only have N number of X creatures and N number
  of bullets in flight", allocated up front, or at least in very controlled steps.

**How evidence is marked:**

- **[read]:** the named page was fetched and the claim read there.
- **[search]:** the claim was read in a search excerpt of the named page, which was not fetched. Valve's wiki refused a
  fetch (403).
- **[secondary]:** a write-up of a talk or a game, not its studio's own words.
- *(arithmetic)*, *(inferred)* and *(from memory)* mean what they say. Everything not [read] is listed again under
  *Not verified*.

## Summary

**No kind of game was found that the decided frame model cannot express.** Every kind holds, most of them only if a
condition is met, and the conditions gather into fourteen findings (G1–G14, below). One thing sits outside the model:
gameplay computed on the GPU (*Limits*).

| Kind | What it leans on hardest | Verdict | Conditions |
|---|---|---|---|
| FPS, the first example | server authority with prediction, lag compensation, bullets in flight | holds, if | G3, G4, G6, G13 |
| RTS and the "generals" view | lockstep, thousands of units, cross-platform determinism | holds, if | G2, G5, G13, G14; replay q1 |
| Fighting games with rollback | save and restore every step; up to 8 steps re-run in a frame | holds, if | G3, G5, G6 |
| Racing and vehicle physics | physics at 120–400 Hz; force feedback on its own clock | holds | G12 |
| Simulation, city and factory builders | huge counts, speed controls, unbounded growth, big saves | holds, if | G2, G9, G14 |
| Open worlds with streaming zones | zones loading and unloading, entities crossing them, precision far from the origin | holds, if | G7, G8 |
| Sandbox and voxel worlds | a mutable grid that is not entities; simulation distance apart from render distance | holds, if | G1, G7, G8 |
| MMO and server scale | headless worlds, many to a process, entities migrating between servers, time dilation | holds, if | G3, G5, G7, G9 |
| VR | the headset's clock, late poses, a hard frame budget | holds (decided at frame-phases q10) | G1 |
| Turn-based, puzzle, card and board games | doing nothing cheaply, undo, many unique behaviours | holds, if | G3, G10, G11 |
| Rhythm and music games | the audio clock as gameplay's authority | holds, if | G12 |
| 2D and mobile | battery, suspension in the background, small devices | holds, if | G1, G10 |
| Story-driven and cinematic | cutscenes and dialogue, saving anywhere | holds | G3; KYR-36 |

**What it means for components question 1** (*For components question 1*, below):

- **A and B are the same at run time,** since B generates A's code. So no kind of game separates them at run time.
- **What separates them is authoring scale,** which favours B (G2, G11).
- **Chunk storage pays wherever counts are large.** It is also the shape that makes budgets, snapshots and kama's
  data-parallel proof fit together (G3, G7, G14).
- **Nothing found argues against the owner's leaning.** The stress test adds conditions it must meet, not a case
  against it.

## The findings

**G1. A simulation budget is a rule of the game, and Output's budgets are what vary per machine.**

- **The owner's idea:** "allocation up front based on the machine it runs".
- **Where machines simulate together, simulation budgets are fixed.** Lockstep, rollback, replay and cross-play all
  run one simulation on several machines. A budget of N creatures in a zone must then be the same on each, or a spawn
  is refused on one machine and allowed on another, and the simulations diverge. Games already treat such limits as
  rules: an RTS's population cap, or a fighting game's limit on projectiles *(from memory)*.
- **Where one machine is the authority, it may choose its simulation budgets.** In single player, or on a server,
  only one machine simulates. Minecraft's simulation distance is such a setting: which chunks tick is a server's choice
  [read]. The choice is then part of that world's definition: saved with it and named in its record.
- **What varies per machine is Output's budgets:** particles, decals, cosmetic debris, draw distance and level of
  detail.
- **The footprint:** a game's simulation budgets give the smallest machine it runs on, which is the owner's "you know
  exactly what machines it can and can't run on". Output's budgets then scale above that floor.
- **Feeds:** components question 6, target-platforms question 3 (capabilities), and budgets as records in
  project-database.

**G2. Budgets are data, kept per scope, with a stated rule for when one is full.**

- **Data, never constants in code.**
  - Cities: Skylines shipped fixed caps of 16,384 active vehicles and 65,536 citizen instances. These figures come from
    players' game logs [search].
  - Raising them took a mod that patched every routine assuming the 16K figure, and other mods that hardcode 16K may
    break [search].
  - Its sequel removed the hard agent limits, so its limit depends on the hardware [search, secondary].
  - So in kyoten a budget is a record. Raising one is a record change, and nothing in code repeats its number.
- **Per scope, not only per zone.**
  - A zone is the owner's case. A player is an RTS's population cap. A team, or a match, is a fighting game's
    projectile rule.
  - So the owner's "per element, per zone" generalizes to per element, per scope, where a zone is one kind of scope
    *(inferred)*.
- **When a budget is full:**
  - **The options:** refuse the spawn, which is then a gameplay result; recycle the oldest, as decals and corpses do in
    Output; or fail loudly in development.
  - **In the simulation, the rule must be deterministic:** refuse, or evict in a stated order.
- **Growth:** a city builder or a sandbox chooses its budgets when a world is created and saves them with it. A save
  from a large machine then says it will not fit a small one, which is the footprint working (G1).
- **Feeds:** components question 6.

**G3. The world is a value: several can exist at once, and each can be copied and restored.**

- **Who needs it:**
  - rollback, every step;
  - an FPS client's prediction, for its own player;
  - lag compensation's history (G4);
  - undo in a puzzle game;
  - a server hosting many matches in one process;
  - tests, and the editor's preview.
- **What it requires:**
  - **No module statics in the simulation.** They are per isolate (kama), and the donors' renderers keep 16 and 63 of
    them ([harvest.md](harvest.md)).
  - **Components are plain values**, with owned memory behind handles (components question 2, option a). A snapshot
    is then a copy of fixed blocks.
  - **Every queue lives in the world.** frame-phases question 9's wait queues are already stores, and kyoten keeps the
    heap in its own array until KY-16 closes.
  - **A physics library that can be restored.** Jolt saves and restores its world through `StateRecorder` (`SaveState`
    and `RestoreState`) [search], and one wrapper preallocates a ring of states for a rollback window [search].
- **Probed on 0.9.845** (*The probe*, below): stores sized at start-up in one `Arena`, stepped and then snapshotted into
  a second preallocated block, both in `@noheap` code. It ran, with exit code 0.
- **The cost is known from the budgets** *(arithmetic)*.
  - A snapshot's size is the sum of each budget times its component's size: 10,000 units of 128 bytes is 1.28 MB.
  - Copying that takes about 0.1 ms at an assumed 10 GB/s single-threaded copy *(inferred)*.
  - A fighting game's whole state is far smaller.
- **Feeds:** components questions 2 and 6, and replay questions 1 and 2.

**G4. Some components keep more history than interpolation's two samples.**

- **Why:** an FPS server rewinds other players to what the shooter saw. Valve keeps one second of position and
  animation history (`sv_maxunlag`, whose default and maximum are 1 s) [search].
- **What changes:** frame-phases question 4's two timestamped samples become a declared depth, two to blend and more
  to rewind. At 60 Hz, one second is 60 samples per player's hitboxes.
- **Where it lives:** the history is a store in the server's world, so the rewind is deterministic, and a Constraints
  subsystem reads it.
- **Feeds:** components question 2, which spells the interpolation declaration and now also its depth.

**G5. How many steps `run` may take is the netcode's policy.**

- **What is decided covers the local case:** at frame-phases question 10, `run` asks the frame source how many steps
  are owed, and FFD's cap of five drops the rest. The other models plug in where `run` counts steps:

  | Model | What decides the steps |
  |---|---|
  | Local | the clock, with a cap |
  | Lockstep | the clock, and every peer's input for the step being in. Age of Empires scheduled commands from turn 1000 for turn 1002, with turns "typically 200 msec in length" [read] |
  | Rollback | rewind to the step a late input changed, and re-run up to now. GGPO requires a game to "load, save, and execute a single simulation frame without rendering" [read], and its Rust ports cap prediction at 8 frames [search] |
  | Server with prediction | the client re-runs its own predicted entities after a correction [secondary] |

- **Each input entry carries the step it applies at,** not the step it arrived.
- **Falling behind is also a policy (G9):** drop time (FFD), dilate (EVE), or stall (lockstep).
- **Feeds:** networking question 1, replay question 2, and KYR-6, the frame core.

**G6. Output's cues have an identity, so re-running steps neither repeats nor strands one.**

- **The problem:** rollback and prediction re-run steps that were already shown. Frame-phases question 1 has audio cues
  decided by the settled tick, but under rollback a step can be settled again.
- **The rule:** a cue keyed by (entity, step made, kind) plays once. If a rollback removes it, its own rule decides
  whether it is stopped or left to finish *(inferred)*.
- **The same applies** to a muzzle flash an FPS client predicts and the server later confirms.
- **Feeds:** audio question 3 and replay question 6.

**G7. A zone is the unit of loading, of budgets and of coordinates.**

- **One block per zone.** In the probe, one `Arena` holds a zone's stores. kama's `Arena.reset()` "bulk-frees the
  whole region in O(1)", once its containers are dropped (kama `lib/std/collections/allocator.kama`). That is the
  owner's "very controlled allocations which helps with load transitions".
- **Chunk storage and budgets are one mechanism.** A chunk per (zone, prefab), at its budget's capacity, is the
  "chunks inside" of the owner's leaning.
- **An entity crossing zones moves between blocks.**
  - Its handle names it through an indirection (a generational slot that says which block and which index), so the
    handle stays valid across the move.
  - Its pending waits move with it (MMO, below).
- **Precision far from the origin** *(arithmetic)*.
  - A float32 position is spaced about 1 mm apart at 8 km, 8 mm at 65 km, and 12.5 cm at 1,000 km.
  - Unreal 5 gives its "core data types" a 64-bit double, and its default `WORLD_MAX` is 88 million km [read].
  - **kyoten's options:** float64 positions in the simulation, or a zone plus a float32 position local to it, which
    the zone structure gives for free *(inferred)*. Rendering is camera-relative either way.
- **Feeds:** components questions 1 and 6, and rendering.

**G8. A zone has simulation data and presentation data, and only the first gates the simulation.**

- **The precedents:**
  - Minecraft ticks the chunks within simulation distance, which is separate from render distance [read].
  - Unreal's World Partition loads grid cells by distance from streaming sources, which are player controllers by
    default [search].
- **The rule:**
  - A simulation rule decides which zones are active, from the simulation's own state, never from how fast a machine
    loads.
  - A zone's simulation data must be present at the step the rule activates it. That means preloading ahead, or a
    loading stall, which is frame-phases question 9's I/O wait.
  - Presentation data (meshes, textures) streams freely, because pop-in is cosmetic.
- **Feeds:** project-database question 8, content-pipeline, and components question 6.

**G9. Game speed is steps per real second.**

- **One lever covers:**
  - pause (0 steps);
  - slow motion;
  - fast-forward: ×8 is 8 steps per 60 Hz frame, past FFD's cap of five;
  - time dilation: EVE slows its server's clock under load to no slower than 10% [search].
- **The simulation never notices,** because it never reads a clock (frame-phases question 2).
- **Per game:** the cap, and the policy when a frame cannot fit its steps (G5).
- **Feeds:** KYR-6.

**G10. Doing nothing costs nothing, including frames.**

- **Steps already do:** a step with nothing due costs nothing (frame-phases question 2).
- **Frames do not yet.** Turn-based games, puzzles, mobile and tools want a frame source that can draw on demand: only
  when something visible changed or input arrived *(inferred)*.
- **Feeds:** rendering question 4, web-and-native, and target-platforms (battery).

**G11. Many distinct behaviours want generated code.**

- **The cases:** cards, abilities and items can each number in the hundreds.
- **What kama allows:** with no closures, each behaviour is a type or a variant of an enum, dispatched with a `match`.
- **B against A:** a generator writes the enum and the match from records, as frame-phases question 9 already does for
  waits. Under A, a person writes them.
- **Feeds:** components questions 1 (a point for B) and 3, and KYR-36.

**G12. An outside clock that gameplay reads enters as a recorded input.**

- **The cases:**
  - **A rhythm game judges input against the song's position.** Unity's advice is `AudioSettings.dspTime`, which is
    based on the samples the audio system has processed [search]. It must be smoothed, because playback position
    advances in buffer-sized steps [search, secondary].
  - **VR reads head and hand poses,** as decided at frame-phases question 10.
  - **A racing wheel's force feedback** is an output device on its own clock, reading the settled state (frame-phases
    question 1).
- **What it needs:** the audio interface exposes its position on the same timebase as input events, and a player's
  latency offset is a recorded setting.
- **Feeds:** audio question 3 and KYR-54.

**G13. Lockstep does not suit mixed roles, and it cannot keep secrets.**

- **Mixed roles need server authority.**
  - The owner's example mixes iPad "generals" with PC FPS players in one simulation.
  - Lockstep delays every command until all peers have it: two 200 ms turns in Age of Empires [read]. FPS aiming cannot
    absorb that.
  - So mixed roles need server authority with prediction, and the generals' orders are ordinary inputs to it
    *(inferred)*.
  - Lockstep suits matches where every player is an RTS player. Age of Empires chose it because sending each unit's
    state "would have limited us to 250 moving units" [read].
- **Lockstep cannot keep secrets.** Every peer holds the whole state, so fog of war can be fair (the VISION's rule that
  concealment is simulated) but not secret.
  - Competitive hidden information wants server authority, which sends each client only what it may see.
- **Feeds:** networking questions 1 and 9.

**G14. Data-parallel Update pays from tens of thousands of simple units, on today's numbers** *(arithmetic, to
measure)*.

- **The comparison:** handing work to a channel-fed pool costs 245–252 µs a frame today (0.9.793,
  [kama-for-engines.md](kama-for-engines.md) § 1).
- **Simple units:** a cache-friendly update of one might cost 20–50 ns *(inferred)*.
  - 10,000 of them take 0.2–0.5 ms serially, which today's pool cannot beat.
  - 100,000 take 2–5 ms, which it can.
- **Costly units:** thousands with expensive AI pay sooner.
- **With kama's planned pool (KY-12),** thousands of simple units would pay, if a hand-out costs microseconds; that is
  unmeasured.
- **Who measures:** slice B (KYR-12). This answers frame-phases question 7's pointer, "KYR-58's RTS row says how
  large".

## The kinds, one by one

### FPS (the first example)

- **How it is usually built:**
  - **The server is the authority.** A client predicts its own movement and, after a correction, replays its inputs.
    Overwatch's movement is "highly deterministic", so the replay reproduces the correct state
    ([GDC 2017](https://gdcvault.com/play/1024001/-Overwatch-Gameplay-Architecture-and),
    [secondary](https://edgegap.com/blog/game-backend-deep-dive-overwatch-2016-netcode-architecture-rollback)).
  - **The server rewinds other players** to what the shooter saw: one second of history, with clients interpolating
    100 ms behind by default ([Valve](https://developer.valvesoftware.com/wiki/Lag_Compensation) [search]).
- **What it stresses:**
  - prediction, which re-runs steps for part of the world (G3, G5);
  - the rewind, which needs history deeper than two samples (G4);
  - cues a client predicts and the server confirms (G6);
  - bullets in flight, the owner's own example of a budget. Hitscan and fast projectiles are swept in Constraints
    (frame-phases question 2).
- **What it budgets:**
  - in the simulation: players, bullets, grenades, and ragdolls that gameplay reads;
  - in Output: decals, shell casings, cosmetic ragdolls.
- **The verdict:** holds, if G3, G4 and G6 are met. A mix with the generals' view needs server authority (G13).

### RTS and the "generals" view

- **How it is usually built:**
  - **Deterministic lockstep,** in which only commands cross the network
    ([1500 Archers](https://www.gamedeveloper.com/programming/1500-archers-on-a-28-8-network-programming-in-age-of-empires-and-beyond)
    [read]).
    - Turns were "typically 200 msec", and turn 1000's commands ran at turn 1002.
    - "Any simulation that ran differently was tagged as "out of sync" and the game stopped."
  - **StarCraft II runs 22.4 game loops a second** at its Faster speed ([rates.md](rates.md)).
  - **Population caps,** a limit per player *(from memory)*.
- **What it stresses:**
  - a simulation bit-identical across machines (replay question 1);
  - inputs that name a future step, and stepping gated on every peer (G5);
  - large counts in Update (G14);
  - desyncs found by a periodic world hash (replay question 5);
  - hidden information (G13).
- **What it budgets:** units per player (the population cap) and per zone, and projectiles. This is G2's scope beyond
  zones.
- **The verdict:** holds, if cross-platform determinism is promised (replay question 1) and G5 is met.

### Fighting games with rollback

- **How it is usually built:** GGPO
  ([guide](https://github.com/pond3r/ggpo/blob/master/doc/DeveloperGuide.md) [read]).
  - A game implements the callbacks to save, load and advance its state.
  - "The game simulation must be fully deterministic", and "The game state must be fully encapsulated and
    serializable".
  - The guide states no prediction limit. Its Rust ports set `MAX_PREDICTION_FRAMES` to 8
    ([GGRS](https://docs.rs/ggrs/0.3.0/i686-pc-windows-msvc/ggrs/constant.MAX_PREDICTION_FRAMES.html),
    [backroll](https://docs.rs/crate/backroll/latest/source/src/sync.rs) [search]).
- **What it stresses:**
  - save and restore every step (G3);
  - re-running up to 8 steps plus the new one inside one 16.7 ms frame, so a step must cost well under a millisecond
    *(arithmetic)*. FFD's tick is about 7.5 µs;
  - cues (G6);
  - the wait queues inside the snapshot (G3, KY-16);
  - animation that is gameplay (a hitbox on each animation frame), which is evaluated in Update (frame-phases question
    1).
- **What it budgets:** two characters, and a few projectiles each.
- **The verdict:** holds, if G3, G5 and G6 are met. The snapshot is small.

### Racing and vehicle physics

- **How it is usually built:**
  - **Racing simulators run physics fast.** Assetto Corsa Competizione went from 333 Hz to 400 Hz in its update 1.8
    ([GTPlanet](https://gtplanet.net/acc-console-update-18-20220916) [search]).
  - **iRacing** is reported to run its main physics at 60 Hz, with a 360 Hz inner loop for force feedback
    ([OverTake](https://www.overtake.gg/threads/what-rate-do-physics-run-at-1000hz-500.159380/) [search, secondary]).
  - **Rocket League** runs Bullet physics at 120 Hz so that contacts come out more alike
    ([GDC 2018](https://www.gdcvault.com/play/1024972/);
    [secondary](https://gamedeveloper.com/design/video-the-rocket-science-behind-i-rocket-league-s-i-physics)).
- **What it stresses:**
  - **The clock.** 360 Hz over 60 gives a base of 360. 400 over 60 gives 1,200, which trips frame-phases question 2's
    warning near 1,000 Hz, and the warning suggests a rate that fits, such as 360 or 420 (each its own base). Or the
    subsystem sub-steps inside its own step, which question 3 allows.
  - **Force feedback,** which is G12.
  - **Predicting a shared physics object,** the ball. That needs a physics library that can be restored (G3) and that
    is deterministic.
- **The verdict:** holds.

### Simulation, city and factory builders

- **How they are usually built:**
  - **Cities: Skylines** shipped hard caps, and its sequel removed them (G2).
  - **Factorio** multiplayer is deterministic lockstep. A desync is a bug, and the wiki says network or performance
    problems "do not cause desyncs" ([wiki](https://wiki.factorio.com/Desynchronization) [search]).
  - **When a Factorio server falls behind,** the whole game slows ([hosting guide](https://low.ms/knowledgebase/factorio-troubleshooting)
    [search, secondary]).
- **What they stress:**
  - speed controls (G9);
  - huge counts (G14, chunk storage);
  - unbounded growth against budgets (G2);
  - saving the whole world (G3, KY-16);
  - sleeping entities. A waiting entity is a deadline in a queue, not a polled update (frame-phases question 9), so it
    costs nothing until due.
- **The verdict:** holds, if G2 and G9 are met.

### Open worlds with streaming zones

- **How they are usually built:**
  - **Unreal's World Partition** loads and unloads grid cells by distance from streaming sources
    ([Epic](https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition-in-unreal-engine) [search]).
  - **Unreal's large world coordinates** use 64-bit doubles
    ([Epic](https://dev.epicgames.com/documentation/en-us/unreal-engine/large-world-coordinates-in-unreal-engine-5)
    [read]).
- **What they stress:**
  - a zone's block, loaded and unloaded whole (G7, the probe);
  - entities crossing zones (G7);
  - precision (G7);
  - load timing kept out of the simulation (G8);
  - distant zones simulated coarsely, either at AI's lower rates (distant agents down to about 1 Hz, frame-phases
    question 3) or frozen by a rule.
- **The verdict:** holds, if G7 and G8 are met.

### Sandbox and voxel worlds

- **How they are usually built:** Minecraft ([wiki](https://minecraft.wiki/w/C-tick) [read]).
  - It runs at "a fixed rate of 20 ticks per second".
  - It ticks the chunks within simulation distance.
  - It random-ticks blocks in 16×16×16 subchunks.
- **What they stress:**
  - **World data that is not entities:** a grid that players change, saved per chunk. A zone may own a store that is
    not a component store, such as a voxel grid. A store in A or B is any typed field, so this fits, though not as an
    archetype chunk *(inferred)*.
  - **Simulation distance apart from render distance,** which is G8.
  - **A simulation budget chosen per server,** which is G1's authority case.
- **The verdict:** holds.

### MMO and server scale

- **How it is usually built:** EVE Online's time dilation slows the server's clock under load, to no slower than 10%
  ([EVE](https://www.eveonline.com/news/view/introducing-time-dilation-tidi),
  [EVE University](https://wiki.eveuniversity.org/Tidi) [search]).
  - In 2013 it hit that limit and "still allowed a more graceful degradation than the unpredictable battles of old"
    ([DCK](https://datacenterknowledge.com/servers/experiencing-heavy-server-load-just-slow-down-time) [search]).
- **What it stresses:**
  - **Headless worlds.** There is no renderer, and Output is net send, with a pass per client choosing what it is sent.
    That pass reads the simulation, so it fits a read-only Output.
  - **Many worlds to a process,** which is G3.
  - **A zone's budget is a shard's capacity.** This is the owner's footprint, as zones per server.
  - **Time dilation,** which is G9's dilate policy.
  - **Migration between servers.** An entity crossing a zone across processes takes its waits with it. Each subsystem
    holds its own queue (frame-phases question 9), so migration either scans those queues or keeps an index from
    entity to entries *(inferred)*. This is a strain on question 9's queues, carried to networking.
  - **Persistence.**
- **The verdict:** holds, if G3, G5, G7 and G9 are met. Migration is carried to networking.

### VR

- **What is decided:** frame-phases question 10. The headset is one more frame source, with poses read late for
  drawing.
  - Hand physics at 90 Hz makes the base 180.
  - FFD's cap of five steps a frame bounds a stall.
- **What is left:**
  - Output's budgets per machine, Quest against PC (G1);
  - multiplayer VR, which is the FPS row.
- **The verdict:** holds. KYR-4 measures it.

### Turn-based, puzzle, card and board games

- **What they stress:**
  - **Doing nothing cheaply,** for steps and frames (G10).
  - **Durations that gameplay depends on.** A unit's move that gates the next turn is a deadline in the simulation,
    and Output animates it (frame-phases question 9's split).
  - **Undo:** restore a snapshot, or replay the log without the last input (G3).
  - **Asynchronous play over days:** the world and its input log, saved.
  - **Hundreds of unique cards** (G11).
- **The verdict:** holds, if G10 and G11 are met.

### Rhythm and music games

- **How they are usually built:** the audio clock is gameplay's authority. Unity's advice is `dspTime` over frame time
  ([Unity](https://docs.unity3d.com/462/Documentation/ScriptReference/AudioSettings-dspTime.html) [search];
  [Game Developer](https://gamedeveloper.com/programming/music-syncing-in-rhythm-games),
  [itch.io](https://itch.io/blog/744936/the-right-way-to-interpolate-the-audio-playback-time-unity) [search,
  secondary]).
- **What they stress:** G12. The song's position enters at Input's hand-off as a recorded value, like a headset pose,
  and input timestamps are converted to song time there.
- **The verdict:** holds, if the audio interface exposes its position on input's timebase (audio question 3).

### 2D and mobile

- **What is decided:** 2D is a layer ([rendering.md](../design/rendering.md) § Decided), and touch enters as semantic
  actions (KYR-54).
- **What they stress:**
  - battery (G10);
  - small devices: Output's budgets per device (G1), and the web build's size (web-and-native question 4);
  - suspension in the background. The simulation resumes from its step count, because it never read a clock. A
    networked game needs frame-phases question 2's carried resync policy (web-and-native question 2);
  - a 30 Hz display in battery saver. That is two steps a frame, which interpolation covers.
- **The verdict:** holds, if G1 and G10 are met.

### Story-driven and cinematic

- **What they stress:**
  - **Cutscenes and dialogue as sequences** over deadlines (KYR-36), and the timeline ([timeline.md](../design/timeline.md)).
  - **Saving anywhere, mid-cutscene included.** It works because a sequence is data (frame-phases question 9) and the
    world is a value (G3).
- **The verdict:** holds.

## Limits: what the model does not reach

- **Gameplay computed on the GPU,** such as physics or a fluid that pushes players.
  - GPU float results are not specified to be bit-identical across vendors *(inferred)*, and Output, where the GPU
    lives, is read-only.
  - So GPU work that affects gameplay either moves to the CPU, or the game gives up cross-machine determinism and runs
    it on one authority (a server, or single player).
  - Cosmetic GPU simulation (particles, cloth that nothing collides with) is Output's, and fine.
  - **Feeds:** replay question 1 and rendering.
- **A variable `dt`** is a later mode a game opts into (frame-phases question 2), not the default.
- **An LLM player** is an outside clock (frame-phases question 3).

## For components question 1

- **Run time does not separate A and B.** B generates A's code, so every kind above runs the same either way.
- **Authoring separates them.**
  - **B gains** where a game has many component types, prefabs and behaviours (G11), and where budgets are records
    (G2): RPGs, card games, ability-heavy games, city builders with hundreds of building types.
  - **A is enough** for a small game. B must keep that case short (components question 7, the prototype path).
- **Chunk storage inside:**
  - **It gains** for large, homogeneous counts: RTS units, a city's agents, an MMO zone, bullets.
  - **It is neutral** for small counts: a fighting game, a puzzle.
  - **It is the shape that joins three things:**
    - G7's per-(zone, prefab) blocks at budget capacity;
    - G3's snapshot by copy;
    - the data-parallel proof kama gives, `parallel_for` over chunks (frame-phases question 6).
- **What chunk storage must still answer:**
  - **Adding a component at run time,** such as a status effect (burning, stunned). Either the entity moves to another
    chunk, or the component lives in a sparse store beside the chunks. This is components questions 1 and 6.
  - **Handles that survive a move,** which is G7.
- **The result:** the stress test supports the owner's leaning, "B built on A with C internal storage when possible",
  and found no kind of game against it. The conditions it adds are G2, G3, G7 and G11, and the run-time composition
  question. The decision is the owner's, at question 1.

## The probe

kama **0.9.845** (`fd3ec5eb`), `kama check` then `kama run`, 2026-11-04, exit code 0. The source is in this session's
scratchpad, `k58/src/app.kama`. Its shape:

```kama
// budgets arrive at start-up; one Arena per zone holds every store
Arena zone = Arena.make(capacity: need);
FixedArray<Soldier, BumpAllocator> units = FixedArray.filledWithAllocator(allocator: zone.handle(), size: maxUnits, value: idle);
FixedArray<Soldier, BumpAllocator> saved = FixedArray.filledWithAllocator(allocator: zone.handle(), size: maxUnits, value: idle);
FixedArray<Bullet, BumpAllocator> bullets = FixedArray.filledWithAllocator(allocator: zone.handle(), size: maxBullets, value: spent);

@noheap fn void step(ref FixedArray<Soldier, BumpAllocator> units, ref FixedArray<Bullet, BumpAllocator> bullets, float32 dt) { … }
@noheap fn void snapshot(const ref FixedArray<Soldier, BumpAllocator> from, ref FixedArray<Soldier, BumpAllocator> into) { … }
```

- **What it shows:**
  - a store's size can be chosen at start-up and allocated once, from one region;
  - a step and a snapshot into a preallocated block both pass `@noheap`;
  - the snapshot holds the earlier state after the next step.
- **What it does not show:**
  - a parallel step, since `parallel_for` heaps a bundle per call and is refused in `@noheap` (KY-12);
  - an entity moving between zones;
  - any cost.
- **Found on the way:** `Unit` is a language name in kama and cannot name a type. A `FixedArray` of a type with no
  `default` is built with `filledWithAllocator` from one value.

## Not verified

- **Cities: Skylines' caps** come from players' logs and mod threads, not Colossal Order. Its sequel's removal of them
  is from press.
- **Factorio:** that its game slows as a whole is from a hosting provider's guide.
- **Overwatch's prediction and replay** come from a third-party write-up. The talk itself is behind GDC Vault.
- **Rocket League's 120 Hz** is from a summary of the talk, not its slides.
- **The racing simulators' rates** are from forums and press.
- **GGPO's 8-frame limit** is from its Rust ports. The C++ header was not read.
- **Valve's lag compensation figures** are from a search excerpt, since the wiki refused a fetch.
- **World Partition** and **Jolt's `StateRecorder`** are from search excerpts of their docs.
- **EVE's 10% floor** is from a developer's forum replies, a wiki and a 2013 article, not the original blog post.
- **Unity's `dspTime` advice** and its smoothing caveat are from search excerpts.
- **Population caps and fighting games' projectile limits** are from memory.
- **The arithmetic's assumed rates** are inferred, not measured: a copy at 10 GB/s, and 20–50 ns to update a simple unit.
- **That GPU floats differ across vendors** is inferred.
