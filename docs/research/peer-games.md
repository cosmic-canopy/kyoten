# Peer games: friendly-fire-department and the-mallow-man

Research for kyoten's architecture walk-through: a read-only survey of two kama games, made 2026-11-01. **FFD** is
`friendly-fire-department` (HEAD `77a2604`, 2D, started 2026-08-31). **TMM** is `the-mallow-man` (HEAD `70fe7ef`, 3D,
seeded 2026-10-04 "laid out as friendly-fire-department is"). TMM's two uncommitted edits (`game/src/camerakit.kama`,
`game/src/roundplay.kama`) were not considered.

Pointers are relative to `C:\Users\Matt\Documents\`, with line numbers as read that day. A pointer with no repo prefix
belongs to the project its section is about. *(inferred)* marks a conclusion drawn from reading, not a statement either
project makes.

## Summary

- **FFD built Input → Update → Constraints → Output by name.** "E-6, the four-phase frame" landed 2026-09-02 (commits
  `dd1a76a`, `4f15185`). It runs in the shipping client as `drainPlatform` (Input), then `stepWorld` (Update, then
  Constraints ×N, once per owed fixed tick), then `frameStep` (Output).
- **FFD amended the model before building it.** Constraints is an *iteration count per tick, not a rate*. Phases *do
  not pipeline across threads*. Only Input+Update have a fixed rate (60 Hz). Output runs at display rate and is handed
  an interpolation `alpha` that nothing reads yet.
- **No phase runs in parallel, in either game.** FFD wrote down the rules that would allow it: state hangs off one
  `World` as field borrows, grids are dense arrays, and nothing lives in statics. Its scope rule was "single-isolate
  until a measurement asks otherwise", and no measurement ever asked. No `.kama` file in either repo uses `spawn`,
  `scope` or `parallel_for`.
- **The only concurrency is threads outside the kama loop:** the audio device thread (both games), whisper's worker
  (FFD), and Jolt's job pool (TMM, 2 threads). FFD's web build is single-threaded on purpose.
- **TMM did not adopt the model.** It copied FFD's platform, input and WebGPU layer but not `engine::phase`. Its loop
  is a hand-written accumulator that runs the rules at 30 Hz and interpolates the frame. Physics is not a phase: the
  rules call Jolt inline, per body, through a `WorldQuery` contract.
- **FFD is lockstep over recorded inputs,** with world hashes pinned identical on five legs. TMM is host-authoritative,
  with a whole-state mirror and rollback prediction; its rules are bit-exact, but Jolt is not cross-platform
  deterministic.
- **Neither has an ECS.** Each keeps the whole game in one struct of fixed-capacity arrays (`World`, `Round`).

## 1. The phase model

### FFD: present, by name, sequential

**Where it is defined.** The E-6 row is `friendly-fire-department/docs/ENGINE_TODO.md:16`: "Input → Update →
Constraints → Output, each with a configured rate, feeding the next". The design is at `:1574-1652`, its cost at
`:1806-1846`, and the as-built summary at `docs/SPEC.md:1730-1765` § "The four-phase harness".

| Piece | File (`friendly-fire-department/…`) | What it is |
|---|---|---|
| `PhaseClock`, `PhaseRates`, `PhaseSteps` | `engine/src/phase/clock.kama` | fixed-step accumulator: owed steps, plus `alpha` |
| `Rng` | `engine/src/phase/rng.kama` | xoshiro256\*\* seeded via SplitMix64, the sim's only randomness |
| `Hasher` | `engine/src/phase/hash.kama` | FNV-1a 64, fed field by field |
| `InputFrame`, `TickInput`, `InputLog` | `engine/src/phase/input.kama` | one tick of settled outside state; a fixed-capacity log plus the seed |
| `Countdown` | `engine/src/phase/countdown.kama` | tick-counted deadlines (vote, payout) |
| `World.step` / `stepAll` | `sim/src/world.kama:2234-2275` | Input → Update → Constraints×N → `tick++` |

**The order in the frame.** `game/src/game.kama:10282-10283`: *"INPUT, then the owed UPDATE/CONSTRAINTS ticks, then
OUTPUT. The four phases, in the order E-6 names them, for the first time in a shipping binary rather than in a test."*
The full sequence is `pumpAudio` → `drainPlatform` → `stepWorld` → `frameStep` (`docs/SPEC.md:1732-1734`).

**What each phase holds** (`sim/src/world.kama:16-26`):

- **Input** "folds one `InputFrame` in. THE ONLY PLACE non-determinism enters." The *seed* is the tracked input, not
  the draws: Update draws from the world's `Rng` freely, because the stream position is world state
  (`engine/src/phase/input.kama:3-22`).
- **Update** is "the fire, the wreckage, then the crew in index order", bots' state machines (`updateBot`) included
  (`sim/src/world.kama:1413-1440`, `:1770`). *"Order is the stream, so this is a rule and not a preference."*
- **Constraints** "projects what Update proposed back into bounds" and must be **idempotent**: the suite steps one
  world at 1 iteration and one at 5 and demands the same hash, which caught a facing renormalisation that was not
  idempotent in float32 (`sim/src/world.kama:2094-2115`; `README.md:236-240`). Wall vetoes and bounces live in Update,
  since a bounce applied twice is not a projection. It is clamping, not a solver (`docs/ENGINE_TODO.md:1609-1614`).
- **Output** is draw commands in `engine::render::Batcher`, a GPU-free buffer that the `view` package fills: *"E-6
  names a boundary this tree already drew"* (`ENGINE_TODO.md:1649-1652`). Audio cues are Output too, derived from
  world deltas (§2).

**Rates.**

- `PhaseRates.standard()` is 60 Hz, one input sample per tick, one constraint pass, and at most 5 steps per frame
  (~83 ms of catch-up) (`engine/src/phase/clock.kama:40-55`). Output runs at display rate with `alpha`.
  *"Constraints has an ITERATION COUNT, not a rate"* (`clock.kama:18-26`).
- Past 5 owed ticks the clock discards the excess and counts it, so there is no spiral of death (`clock.kama:28-36`,
  `:143-149`). The clock is "not on the deterministic path": replay drives ticks directly (`clock.kama:6-16`).
- **Sub-rates are tick arithmetic inside the 60 Hz tick, never separate clocks.** Fire spread waits on an integer
  counter of 27 ticks, or 0.45 s (`docs/SPEC.md:2465-2474`). Bots re-decide accusations when
  `(tick + seat*37) % ACCUSE_PERIOD` is zero: a cadence that is "derived, not stored" (`sim/src/bots.kama:999-1016`).

**Interpolation.** `alpha` is computed (`clock.kama:91-93`) and passed through `frameStep`
(`gfx/src/gpu/gpu.kama:1117-1121`), but only the demo card receives it (`game/src/game.kama:9744-9783`).
`docs/ROADMAP_DETAIL.md:359-362`: *"`PhaseSteps.alpha` is plumbed through the scene seam and read by nobody… It is
carried so that adding interpolation later is not a signature change."*

**Parallelism: designed for, not used.** Three kama facts shaped the design (`ENGINE_TODO.md:1580-1602`):

1. **Statics.** A module `static` is per-isolate, so "no phase that touches those may ever be spawned". The rule:
   **"Phase state hangs off one `World` and is passed as `ref` field borrows. Never through a static."** That is
   what lets `scope` accept `spawn step(a: ref w.fire)` beside `spawn step(a: ref w.crew)`.
2. **Containers.** `parallel_for` needs a contiguous container, so the fire grid is a dense array, not a `Map`.
3. **Widths.** `workers:` is mandatory, so "`grep 'workers:'` finds every parallelism-width decision".

What FFD decided from them:

- **The scope rule** (`ENGINE_TODO.md:1643-1647`): *"It is not an ECS, not a job system, not a scheduler abstraction,
  and not a plugin architecture. It stays single-isolate until a measurement asks otherwise."*
- **Phases stay sequential** (`:1615-1619`): *"overlapping Output for frame N with Input for N+1 buys throughput at a
  frame of latency and destroys the data flow… The parallelism worth having is inside a phase."*
- **No measurement asked.** A one-minute catch-up of 3,600 ticks takes 27 ms in release, about 7.5 µs a tick
  (`docs/ROADMAP_DETAIL.md:936-944`).
- **A finding against the plan** (`ENGINE_TODO.md:1870-1877`; `SPEC.md:1818-1822`). `parallel_for (ref T e in coll,
  workers: K)` binds the element and no index, so a neighbour-reading stencil like fire spread "is not expressible
  with it as shipped". It would need "a cell carrying its own coordinates plus double buffering". Separately,
  `stepFire` mutates the grid it reads, in scan order, on purpose: a double buffer "would be a *different game*"
  (`SPEC.md:2476-2479`).

**What does run concurrently** (native only):

- The audio synth runs on miniaudio's thread as a pull, behind a lock-free command ring, using `@foreignEntry` and
  `@onPanic(recover:)` (`SPEC.md:1436-1445`, `:1691-1712`).
- whisper.cpp runs on its own worker thread (`README.md:90-91`).
- The web build has no threads; `grep -c PROXY_TO_PTHREAD out/web/game.js` must print 0 (`SPEC.md:1450-1461`).
  Threaded wasm needs COOP/COEP headers, which they say break the relay's cross-origin WebSocket, a claim their own
  doc asks to have re-measured (`docs/ROADMAP_DETAIL.md:1412`, `:1703-1705`). A stray `-pthread` once moved `main` to
  a worker and broke WebGPU in the browser.

**Why FFD built it** (`ENGINE_TODO.md:1621-1641`; `docs/ROADMAP.md:40-50`). FFD's goal 2 is *"Prototype for the
general-purpose engine built next"*, but E-6 had to "pay for itself on goal 1 alone", and it did, as determinism for
networking. *"The phase boundary, the recorded-input harness and the world hash are the parts most likely to
generalise."*

### TMM: no named phases; a fixed tick that only partly fits

**No trace of the model.** A grep for `E-6`, `four-phase`, `engine::phase` and `Constraints` finds only Jolt's
`maxContactConstraints`. The one piece reused from `engine::phase` is the RNG, as audio's own stream
(`the-mallow-man/docs/PROVENANCE.md:164`). TMM's stated reason for copying files rather than depending on FFD:
*"kama refuses a dependency's own path-dependencies across workspaces, and FFD's engine is shaped around 2D and
lockstep"* (`PROVENANCE.md:10-12`).

**The loop** is in `the-mallow-man/game/src/roundplay.kama` (header `:6-21`, tick block `:729-760`). Each frame
latches key presses, adds its time to an accumulator capped at 4 ticks (`:208`, `:732-733`), runs the owed ticks
(`netTick` or `session.tick`, then `roundAudioTick` and `roundFxTick`), sets `alpha = acc / dt` (`:757`), and draws.

**One tick** (`the-mallow-man/play/src/session.kama:629-656`) gathers every seat's input (remote, human, or
`botInput`: bot brains run *before* the rules, as input producers), calls `stepRound(r, inputs, world)`, then
`world.sync(r)` to move the Jolt capsules where the rules put the bodies, then feeds the tick's `r.events` out.

**Physics is called from inside the rules.** `the-mallow-man/play/src/world.kama:5-9`: *"moveBody INLINE: one Jolt
CharacterVirtual per body, one ExtendedUpdate… per request, at the point in the tick the rules ask"*. The rules own
velocity, Jolt owns where it can take a body, and body separation stays in the rules (`:35-37`). `docs/NEXT.md:472`:
*"The round never steps Jolt: `play::world` uses CharacterVirtual and queries only."* Ragdolls are a separate,
cosmetic client-side world "driven off the Round, never in it" (`:472-474`).

**Parallelism.**

- Jolt's `JobSystemThreadPool` runs inside its own calls, sized by `WorldConfig.threads`
  (`physics/src/types.kama:269`). The game uses 2: *"the renderer and the driver want the cores"*
  (`game/src/game.kama:548-550`); the ragdoll world uses 1 (`play/src/ragdoll.kama:575`). Every Jolt call comes from
  the one owning thread (`physics/src/world.kama:12-14`).
- The audio callback is a miniaudio pull on its own thread (`game/src/audio.kama:230-240`). On Windows a thread timer
  runs the tick during the OS's modal move/size loop (`gfx/src/platform/tmm_platform.c:582-610`).

| What (TMM) | Rate | Pointer |
|---|---|---|
| Rules, bots, networked round | 30 Hz fixed (`RoundTuning.tickHz`, live-tunable) | `sim/src/round/tuning.kama:475`; `round.kama:73,108` |
| Free-walk camper (E4, outside a round) | 60 Hz Jolt tick, camera interpolated | `game/src/player.kama:1-16`, `:74-76` |
| Mouse look | every frame, never ticked: "a look that waits for the next tick is latency" | `player.kama:11-13` |
| Input edges | latched until a tick consumes them | `engine/src/input/state.kama:27-31` |
| Net inputs / snapshots | 30 Hz / 30 Hz (the spike ran a 60 Hz sim with 30 Hz snapshots) | `docs/M3_PLAN.md:36-46`; `net/README.md:8-17`, `:245-249` |
| Remote seats on a client | interpolated 3–4 ticks behind on `net::ServerClock` | `docs/M3_PLAN.md:60-66` |
| Audio cues / listener | per tick / per frame | `game/src/roundaudio.kama:3-6` |
| Singing detector | per 20 ms voice frame | `roundplay.kama:16-18` |
| Bot retargeting | every 0.5 s, a `thinkT` timer inside the tick | `sim/src/bots/bots.kama:2006-2019` |
| Tuning and settings files | polled by mtime once a second | `roundplay.kama:13-15`, `:783` |
| Springs (jiggle, hair) | per frame, sub-stepped; "a 30 Hz tick, a 60 Hz frame and a 144 Hz frame all wobble alike" | `engine/src/gltf/anim.kama:31-33` |

### The owner's model against each game

| Owner's phase | FFD | TMM *(inferred mapping)* |
|---|---|---|
| Input: net receive, human/bot input, seeds; recorded | `drainPlatform` + `World.stepInput`; the `InputFrame` is recorded; lockstep closes per-seat frames; the seed is the tracked input | latch + `session.tick`'s input gathering; bots produce inputs; nothing recorded |
| Update: logic, AI | `World.stepUpdate`: fire, crew, bots, particles | `stepRound` (the rules) |
| Constraints: physics | `World.stepConstraints` ×N; projections only, no solver | not a phase: Jolt moves inline in Update, then `sync` |
| Output: render, net send | `view` → `Batcher` → `frameStep`; cues from deltas. Net send and receive both sit in `netAdvance`, "the pump as well as the step" (`game.kama:10330`) | per tick: events to audio/fx and `hostSend` (`game/src/netplay.kama:860`); per frame: draw |
| Parallel within a phase | no (single isolate, by rule) | no in kama; Jolt's pool inside its own calls |
| Per-component rates | one fixed tick; sub-rates by tick modulo | one fixed tick; sub-rates by timers; per-frame look and springs |

## 2. Determinism and replay

### FFD

- **A round is a seed plus a log of input frames.** `InputLog` has a fixed capacity, counts overflow, and holds ten
  minutes in 36,000 frames (`engine/src/phase/input.kama:34-38`). Record, replay, soak and network all call one
  `step`/`stepAll`, so "a divergence cannot hide in the difference between two of them" (`sim/src/world.kama:24-26`,
  `:2225-2233`).
- **Self-check at exit.** `replayCheck` replays the round "and says whether the world came out identical": most
  recently 7,986 ticks, reproduced exactly (`README.md:110-112`).
- **Replay file.** `--record-inputs` and `--replay-inputs` read and write `FFDREC\0`, a format byte, then the wire's
  own 24-byte big-endian frames: *"not a second serializer"*. It exists to film a played round at capture quality
  (FR-9, `game/src/game.kama:5432-5479`).
- **Literals are pinned, not just self-consistency.** The world hash after 600 ticks is identical on macOS/arm64,
  Linux/aarch64, wasm32, Windows/x64 and Linux x86_64 in Steam's sniper SDK (`docs/SPEC.md:2495-2501`); 25 full rounds
  (170,255 ticks) give byte-identical reports (`:2608-2615`). Changing the RNG stream "invalidates every recorded log"
  (`:1755-1759`). One log runs identically at a steady 60 fps and at alternating 240/20 fps (`:1744-1748`).
- **The deterministic path uses only correctly rounded float32 operations** (`+ - * /`, `sqrt`, compares, int↔float;
  no libm transcendentals). `-ffp-contract=off` sits in `sim/kama.json` alone, guarded by the startup tripwire
  `sim::fmaContractions` (`SPEC.md:1780-1808`); FMA contraction had made 10 of 64 triples differ between arm64 and
  wasm32 (`ENGINE_TODO.md:1854-1866`). Output code may use libm: "Do not 'fix' them."
- **Output never feeds the sim.** Audio cues come from diffing absolute world counters between ticks, gated by "600
  watched ticks hash identically to 600 unwatched" (`SPEC.md:1644-1680`). The `F` debug view is not a sim input,
  because every bound key is a bit of the hashed frame (`README.md:255-262`). A rebind cannot move the hash
  (`SPEC.md:2617-2640`).
- **Netcode is lockstep with a fixed input delay:** "Nobody predicts, nobody rolls back, and nobody snapshots". A late
  frame is dropped and that seat repeats its last one (`engine/src/net/lockstep.kama:15-18`, `:40-45`). Join-in-progress
  was sized, then deferred: a minute of play is a 374 KB log and 27 ms of catch-up (`docs/ROADMAP_DETAIL.md:925-950`).
  The snapshot codec is kept as "ROLLBACK's primitive" (`lockstep.kama:33-35`).
- **Captures are reproducible.** `--capture` steps exactly one tick per drawn frame and never reads the clock, so a
  frame is a function of `(seed, tick)`. Before that, three runs gave 305, 307 and 306 ticks
  (`game/src/game.kama:4121-4178`).

### TMM

- **The rules are bit-exact against a frozen JS prototype.** `sim::round` runs float64 with a bit-exact fdlibm port,
  `reproducible-float` and the prototype's mulberry32, with "no clock, no GPU, no files, no allocation per tick"
  (`the-mallow-man/sim/src/round/round.kama:1-4`). The parity gate passes 85 of 85 rounds, on every event and every
  once-a-second position (`docs/WORKING.md:465-477`). `Round` is plain data: "a determinism check is
  `Round copy = r;`" (`round.kama:17-18`).
- **Physics is not cross-platform deterministic.** `CROSS_PLATFORM_DETERMINISTIC` is off "because only the host
  simulates" (`docs/WORKING.md:77`). A gcc upgrade moved every seeded round's trajectories (`:137-146`). Whether two
  CPUs agree is an open item (`docs/ROADMAP.md:58`).
- **Netcode is host-authoritative and mirrors the whole state** (`docs/M3_PLAN.md:6-34`). The host sends the raw bytes
  of the 17.5 KB `Round`, XOR-delta coded against each client's acked baseline: no forgotten fields, host migration,
  and live tuning that reaches every client. A client predicts by rollback: copy the authoritative tick,
  `JoltWorld.rewindTo`, replay its unacked inputs through `stepRound` (`:53-66`). A layout fingerprint refuses
  mismatched builds (`:42`), and wasm "could never join" because `isize` is 4 bytes there (`:27-28`).
- **No input recording or replay file** exists (grep finds no `--record`, `--replay` or `InputLog`). Determinism is
  exercised by parity traces, seeded `--round-auto` runs, and byte-identical `--capture-audio`, which renders 1,600
  samples per 30 Hz tick with the device never opened (`game/src/audio.kama:615-619`). Particles and decals are seeded
  from the frame index or round events (`docs/NEXT.md:510-511`).
- **Worldgen.** A map is identified by `(seed, biome, kitHash)`, and hashes are pinned per seed. The code uses only
  `+ − × ÷`, `sqrt`, `floor` and a literal sine table (`docs/WORLDGEN.md:69-75`, `:98-104`).
- **Frame captures** repeat only on the same GPU and driver, so neither repo commits golden images
  (`the-mallow-man/docs/WORKING.md:81-83`, `:123-124`).

## 3. Component / entity model

Neither project has an ECS. The only mention of one is FFD's line that E-6 "is not an ECS"
(`friendly-fire-department/docs/ENGINE_TODO.md:1644`).

### FFD: one `World`, dense arrays, systems as ordered loops

- **`sim::World` is a `type resource`,** because it owns memory, so its fields are private and the phases are methods
  (`sim/src/world.kama:10-14`, `:180-208`). `TileMap` and `FireGrid` are `FixedArray`s of 12,596 cells, 4 floors ×
  67 × 47 (`docs/SPEC.md:1810-1816`). Crew, debris, refills and items are fixed-capacity `InlineArray` sets, and a
  crew index *is* a seat. Particles (2,048), the pathfinder and the ledger are heap `FixedArray`s, since inline they
  would put ~96 KB on a 64 KB wasm stack (`world.kama:195-208`).
- **Systems** are index-order `while` loops inside `stepUpdate`/`stepConstraints`, and the order is the RNG stream
  (`world.kama:1413-1440`).
- **The hash** folds field by field and never hashes struct bytes, because padding is not deterministic
  (`world.kama:2276-2290`).
- **No event lists in `World`,** because every field is hashed and serialized (`SPEC.md:1646-1650`).
- **What hurt:** big values on the 64 KB stack (§7); per-file visibility, which kept the round lifecycle in an
  11,108-line `game.kama` because "a `session.kama` would need ~25 accessor pairs" (`SPEC.md:2442`); and a renderer
  in module statics, forced until a compiler fix let methods resolve through a raw pointer's field
  (`SPEC.md:806-830`).

### TMM: one `Round` value, pooled arrays with counts

- **`sim::round::Round` is a `type value`** (`sim/src/round/round.kama:68-96`): tuning, layout, two `Mulberry32`s,
  the tick, the clock and the round's *game* phase (hike, camp, fire, song), plus `InlineArray<Player>#(5)`,
  `Projectile#(32)`, `Puddle#(16)`, `Item#(16)`, `Task#(8)` and `EventRec#(96)`, each with a count, and an `overflow`
  tally. Items, projectiles and puddles share one `nextId` (`:93`).
- **Presentation reads `const ref Round`** (`docs/M3_PLAN.md:20-21`). Animation reads rules state, never events,
  because "a frame can run several ticks" (`play/src/camperanim.kama:1-12`). A decal is "a pure function of a
  puddle", so a rollback cannot double one (`docs/RENDERING.md:306`).
- **Physics objects are handles.** `PhysicsWorld` owns every Jolt object; callers hold plain-data `BodyId` and
  `CharacterId`, "the one shape that cannot dangle" (`physics/src/world.kama:4-10`).
- **What hurt:** KM-29 (a big value costs its size in every frame it passes through by value) and KM-31 (`new T.make()`
  is not built in place). Together they produced a 205,880 B frame in `game::roundLoad` on Linux. The fix put state
  behind `Owned` and built it in place (`docs/KAMA_GAPS.md:46-47`).

## 4. Platform split: web and native

| Concern | FFD | TMM |
|---|---|---|
| Targets | macOS, Linux, Windows and **wasm32 in a browser**; "native is the reference" (`docs/ROADMAP.md:37-38`) | Steam on Windows, Linux/Deck and macOS; the engine "has never been built for the browser" (`docs/CHARACTER_TOOL.md:74-77`) |
| Window and input | `gfx/src/platform/ffd_platform.h`, 13 C-scalar functions: GLFW natively, `static inline` over `<emscripten/html5.h>` on web, in one header. kama's `std::gpu` has no input (KG-1) (`docs/SPEC.md:391-466`) | copied as `gfx/src/platform/tmm_platform.h:31-36`; the web half is present but unused |
| WebGPU | bindings generated by `wgpugen`, written in kama: 201 functions and 615 constants, checked against both headers. wgpu-native natively, emdawnwebgpu on web (`ENGINE_TODO.md:12`; `SPEC.md:578-582`) | same generator; wgpu-native only; WGSL in kama strings; a forward renderer in 4 quality tiers (`docs/RENDERING.md:7-27`) |
| Audio | a `type contract AudioSink` and two `@compileFor` `AudioDevice`s. Native: miniaudio's thread calls the kama synth. Web: a `--js-library` whose `pump()` calls the *identical* entry from the frame loop. AudioWorklet is deferred (`SPEC.md:1415-1445`; `ENGINE_TODO.md:1109-1114`) | `voice/` owns the one miniaudio device; `audio/` holds the synth and sample bank; "no wasm gates" (`docs/PROVENANCE.md:139`) |
| UI | a `type contract UiHost`. Natively, RmlUi runs through a *recording* render interface into the batcher. On web, the same `.rml` becomes real DOM over the canvas via `uidoc::rmlToHtml` (`SPEC.md:3121-3160`) | moved to the published `@kama/ui`, `@kama/rmlui` and `@kama/freetype` (`docs/UI_PACKAGES.md:1-20`); RmlUi drawn by `gfx/src/render/uipass.kama`; the DOM leg "kept for later" (`docs/E7_PLAN.md:178`); plus an MSDF debug HUD |
| Networking | browser `WsConnection` to a relay, native `TcpStream` with a length prefix; a headless `server` relay; encrypted (FR-32); Steam with host routing in progress (FR-35); WebTransport rejected (`SPEC.md:2320-2340`, `:2428-2445`) | a `Transport` contract over Steam Networking Messages, UDP or loopback, with one `Endpoint` and 5 channels; no web (`net/README.md:19-68`) |
| Assets | `engine/src/assets_native.kama` and `assets_web.kama`; one SVG baked to `.webp` (the browser decodes it) and `.pam` (kama decodes it) (`README.md:120-124`) | copied; plus a glTF loader (`engine::gltf`) and KTX2/BC7 |

**Where the seams sit.** FFD splits packages so that the headless `server` and the GPU-free `tests` never link GLFW,
wgpu, RmlUi or a C++ runtime (`docs/SPEC.md:355-389`):

- `engine` declares no dependencies.
- `sim` holds the rules.
- `audio`, `ui` and `gfx` are the device seams.
- `view` renders the game with no `gfx` dependency, so `tests` exercises drawing on all three legs.

Only C scalars cross into C: "kama polls, so there is no reentrancy" (`SPEC.md:402-403`). TMM keeps the split and adds
`physics` (Jolt via C++ joltc), `net`, `play` (glue between sim, physics and net), `voice`, `sfx` and `steam`
(`kama_workspace.json`; `play/kama.json`).

## 5. Human tools and visibility

### FFD

- **Capture and diff.** `tools/capture-frame` writes deterministic PPMs, with a flag per screen (`--title-card`,
  `--receipt-card`, `--vote-card`, `--lobby-card`, `--debug-view`). `tools/diff-ppm` writes a delta image, "black
  everywhere the frame did not move": "The ritual for any change that alters a picture" (`docs/WORKING.md:11-60`,
  `:826-869`).
- **Debug.** `F` shows the fire grid with fuel values; `--debug-view` makes it capturable. `engine::dev` compiles
  developer features out of release: "not a runtime flag, because Steam lets a player type launch options"
  (`docs/SPEC.md:2143-2170`).
- **Soak.** `soak/`, `tools/soak`, `soak-proto` and `soak-compare` run 1,000 seeded headless rounds against the
  prototype's distribution, with tolerances fixed before measuring (`SPEC.md:2513-2540`).
- **Tuning dials are code constants.** "Re-running `tools/soak` is how you see what a dial actually did"
  (`docs/ROADMAP_DETAIL.md:350-356`). There is no live-reload file: grep finds no reload or mtime code.
- **Network and browser checks.** `tools/check-net` drives real browser tabs, native binaries and a relay (328 checks).
  `tools/check-web` runs 168 browser checks (`docs/ROADMAP.md:66-70`).
- **Filming.** `tools/capture-video`, `gen-shots` and `gen-teaser` film a round played under `--record-inputs`
  (`docs/WORKING.md:870-930`).
- **Running.** `tools/run-game` enforces an RSS ceiling, because a runaway loop once reached 15.6 GB and panicked the
  machine (`SPEC.md:63-100`).
- **Device probes:** `check-pad`, `check-mic`, `check-audio`.

### TMM

- **Live tuning.** `tuning/round.json`, `input.json` and `camera.json` are polled by mtime once a second
  (`game/src/roundplay.kama:13-15`, `:783-830`). A bad file is "refused with a reason on the HUD and the last good one
  kept". Clients get the new numbers, because `tune` lives inside `Round`. There is no *code* hot reload (KM-3,
  `docs/KAMA_GAPS.md:32`).
- **Debug HUD and dev keys.** F1 shows debug lines; F2 skips to the next phase; F3 goos yourself; F4 fires the candle
  (`docs/WORKING.md:533`). Flags: `--round-auto` (a bot drives your seat), `--spike-log MS` (frames over budget, split
  by stage), `--bot-stuck-log`.
- **Gates.** `tools/gates <label>` runs the whole pre-commit gate, about 45 min, comparing captures and perf against a
  base (`docs/WORKING.md:48-62`).
- **Benchmarks.** `tools/bench` flies a deterministic camera path, reports per-pass p50/p95/p99, and exits 4 on a
  missed budget. `tools/bench-window` runs interleaved A/B; `tools/machine-state` logs power and RustDesk state
  (`docs/RENDERING.md:29-77`).
- **Suites and review.** `tools/check-frames` (§7), `check-sim`, `check-physics`, `check-net`, and `net-soak` across
  network profiles. `tools/review-frame`, `review-bot-paths` and `review-*-anim` write before/after PNGs and films to
  `out/review/` for Matt's verdicts; `capture-video` and `gen-teaser` film cut lists.
- **The character tool** is a local web app that walks a character "phase by phase, from a prompt to a rigged,
  animated character in the game", launched by `./dev` (`docs/CHARACTER_TOOL.md:1-40`).

## 6. Process and docs

### FFD

| File | Role | Pointer |
|---|---|---|
| `docs/ROADMAP.md` | "The order of work, and nothing else": permanent `FR-<n>` ids, a `Next id:` counter, three ordered goals | `docs/ROADMAP.md:1-50` |
| `docs/ROADMAP_DETAIL.md` | the why, one section per item, with a table of where a shipped item's record goes; then the item is deleted from both files | `docs/ROADMAP_DETAIL.md:1-30` |
| `docs/SPEC.md` | "what is implemented… Never speculative" | `docs/SPEC.md:1-4` |
| `docs/WORKING.md` | how to build it, and the traps that cost time | `docs/WORKING.md:1-9` |
| `docs/ENGINE_TODO.md` | `E-<n>` engine items "ours, not kama's", plus a "What X cost, and what it proved" section per slice | `docs/ENGINE_TODO.md:1-19` |
| `docs/KAMA_GAPS.md` | `KG-`/`KB-` BUG/GAP rows; status `open · worked-around · not kama's · wontfix`; no `fixed` status (a fixed row is deleted); "kama's maintainer reads it directly; nothing is filed as an issue" | `docs/KAMA_GAPS.md:1-12` |
| `design/DESIGN_SPEC.md`, `design/prototype/` | the design, and the JS prototype ported 1:1 | — |
| `docs/public/` → `site/` | player-voice Markdown for the website | `docs/WORKING.md:1021-1099` |

- **`tools/check-roadmap`** enforces a line ceiling, a per-row character ceiling (one 4,910-character row had slipped
  past the line ceiling), resolving anchors, and no orphaned sections (`docs/ROADMAP.md:7-17`).
- **Agent files.** `CLAUDE.md` is `@AGENTS.md`. `AGENTS.md` is kama's generated snippet with project-learned warnings
  spliced in, e.g. "an absent declaration is not evidence of absence — probe, do not infer" (`AGENTS.md:46-60`).
- **House style:** bold-caps ⚠️/✅ paragraphs, each correction kept beside what it corrects (e.g. `docs/SPEC.md:6-11`).

### TMM

| File | Role | Pointer |
|---|---|---|
| `docs/ROADMAP.md` | order only, permanent `E<n>`/`M<n>` ids; "Keep this file short… reasoning in the commit… or in the doc the item produces" (no DETAIL file); an *Open items* table whose *Needs* column says Matt, 4090 or build | `docs/ROADMAP.md:1-9`, `:40-48` |
| `docs/NEXT.md` | "**A new session starts here**": a dated update log with commit SHAs; §0, the plan; "What exists (don't rebuild it)"; "For Matt (proposals in effect until he says otherwise)"; "How work here has run" | `docs/NEXT.md:1-24`, `:413`, `:529`, `:835-858` |
| `docs/WORKING.md` | build, run and check; traps; per-subsystem how-tos | `docs/WORKING.md:1-166` |
| `docs/KAMA_GAPS.md` | `KM-<n>` with a **Next id**, in FFD's format, plus inherited FFD rows; open rows are re-checked at each pin bump | `docs/KAMA_GAPS.md:1-26` |
| Plans and topic docs | `M3_PLAN.md` and `E7_PLAN.md` (approved plans with slice tables); `RENDERING.md` (each technique with measured ms on named hardware); `WORLDGEN.md`, `NETTEST.md`, `STEAM.md`, `SOUNDS.md`; `net/README.md` (a 1,908-line subsystem log) | — |
| `docs/PROVENANCE.md` | every file copied from FFD, with its source SHA and what changed | `docs/PROVENANCE.md:1-13` |

- **Agent files.** `AGENTS.md` is kama's generated snippet, unmodified *(inferred: it matches the generated text)*.
  `CLAUDE.md` adds "Working with Matt": lead with the outcome; pipe long output to a log; read only the section you
  need; give subagents "narrow briefs: one slice each, the files they own" (`the-mallow-man/CLAUDE.md`).
- **House style** is plainer than FFD's. The compiler pin's bump log lives in `.kama-version:1-20`.

### "AI coordinates the project through docs"

Both projects coordinate through files in the repo. Neither has a database or wiki: grep finds none, apart from
external links in TMM's `WORLDGEN.md`.

- **TMM's `docs/NEXT.md:835-858`, "How work here has run":** "two background agents (net and audio) did the slices.
  The coordinating session verified, gated and committed each one." Each brief lists the files that agent owns; each
  agent "stops after each slice, reports, and waits". Mixed files are committed hunk by hunk, every build runs under
  `flock out/.build.lock`, and "Matt pushes."
- **Machines have roles:** the 880M box does engine work, the 4090 box character generation (`NEXT.md:359-379`).
- **Owner decisions are written inline as "(Matt, YYYY-MM-DD)"** in both repos (e.g. TMM `docs/ROADMAP.md:27`, FFD
  `docs/SPEC.md:3571`).
- **FFD writes its handoffs into ROADMAP_DETAIL sections** (e.g. `#fr26-next`, cited at `docs/ROADMAP.md:127`). It
  also learned to read a handoff that names a mechanism "as naming a *goal*" (`docs/ENGINE_TODO.md:2443-2446`).

## 7. Lessons relevant to a general-purpose engine

1. **An engine abstraction must pay for itself on the game.** FFD's scope rule is quoted in §1
   (`ENGINE_TODO.md:1643-1647`). TMM: "Engine work never runs ahead of what a milestone needs"
   (`the-mallow-man/docs/ROADMAP.md:24-25`).
2. **The tick is cheap; the frame is the renderer.** FFD's sim costs about 7.5 µs a tick (§1). TMM's physics costs
   about 0.1 ms a tick, renderer CPU about 0.9 ms a frame, and bots 3 µs a tick (`docs/RENDERING.md:592-594`;
   `docs/WORLDGEN.md:273`). TMM's budgets are a 16.6 ms p95 at Medium on the 880M and 25 ms at Low on the Deck
   (`RENDERING.md:29-40`). *(inferred)* Parallelism would pay in rendering and asset work, not in either tick.
3. **Isolates decide where state may live.** A thread kama did not create "sees every static at" its initialiser
   (`friendly-fire-department/game/src/game.kama:414-416`), so both games' audio callbacks reach state through the C
   `user` pointer (`the-mallow-man/game/src/audio.kama:230-233`). Shared state must be fields of one owner for
   `scope` to prove disjointness (`ENGINE_TODO.md:1580-1592`).
4. **Web threads are not free.** They need COOP/COEP, and a stray `-pthread` moved `main` off the canvas thread
   (`SPEC.md:1450-1458`). FFD made the audio seam a *pull*, so one implementation serves a thread natively and the frame
   loop on web (`ENGINE_TODO.md:1109-1114`).
5. **Frame size (the KM-29 family).**
   - FFD's 64 KB wasm stack overflowed from `World` locals and by-value `Font`s, and the crash "names the wrong file".
     At `-O0`, every branch's locals coexist. The budget was "deliberately not raised"; instead a 32 KB
     `-Wframe-larger-than` became a build error (`friendly-fire-department/docs/WORKING.md:1539-1595`; commit
     `f8a4265`).
   - TMM's frames reached 205 KB. The fix: keep big state behind `Owned`, pass big things by `const ref`, build them
     in a helper. `tools/check-frames` covers Windows, where the manifest guard is off
     (`the-mallow-man/docs/WORKING.md:148-166`).
   - FFD wants a computed worst-case stack per entry point (KG-41, `docs/KAMA_GAPS.md:775`).
6. **Determinism traps:** FMA contraction (`ENGINE_TODO.md:1854-1866`); libm's unspecified last bit
   (`SPEC.md:1782-1788`); a float literal is a double, so `float32 >= 0.45` failed at 0.45 (`ENGINE_TODO.md:1906-1912`);
   `-0.0` vs `0.0` in hashes (`SPEC.md:1761-1765`); `isize` is 32-bit only on wasm32 (`ENGINE_TODO.md:1818-1820`);
   signed overflow traps, so PRNG and hash code stays `uint64` (`SPEC.md:1750-1753`). "Two green legs out of three is
   what this class of bug looks like" (`ENGINE_TODO.md:1861-1863`).
7. **Keep presentation out of the sim.** "Nothing in a scene may read a wall clock"
   (`friendly-fire-department/docs/WORKING.md:862`); speech bubbles are Output and read no clock (`SPEC.md:3615`);
   ragdolls and animation never feed the rules (`the-mallow-man/docs/NEXT.md:472-474`).
8. **The frame loop must present or sleep on every path.** Reconfigure only on a real invalidation; `Occluded` is not
   an error. Breaking this "panicked a development machine twice" (`SPEC.md:63-100`).
9. **Netcode and physics determinism are coupled.** FFD's lockstep depends on bit-identical sims everywhere, and its
   "physics" is float32 clamping under the strict float rules. TMM chose host-authoritative snapshots ("Snapshot
   netcode is new. FFD is lockstep", `the-mallow-man/docs/ROADMAP.md:189`) and leaves Jolt's cross-platform
   determinism off "because only the host simulates". *(inferred)* Whether the Constraints/physics layer is
   deterministic decides whether lockstep is available at all. Mirroring raw struct bytes ended forgotten-field bugs,
   but it ties the wire to the native layout (`M3_PLAN.md:15-28`).
10. **Code sharing between games was by copy at first.** TMM copied with provenance because cross-workspace path
    dependencies were refused (`PROVENANCE.md:10-13`). The UI later moved to published packages that "never name
    these games" (`docs/UI_PACKAGES.md:1-40`).
11. **Language friction that shaped the structure:** per-file visibility, behind FFD's 11k-line `game.kama`
    (`SPEC.md:2442`); and in TMM (`the-mallow-man/docs/KAMA_GAPS.md:30-50`) no scoped `unsafe` (KM-26), no
    `const ref` locals (KM-23, KM-34), JSON silently ignoring unknown keys so a misspelt tuning key does nothing
    (KM-25), and no hot reload (KM-3).
12. **Measure under known conditions.** An attached RustDesk session cost 3.5–4 ms of p95, about 7× the box's drift, so
    budgets are held disconnected and only interleaved A/B runs are compared
    (`the-mallow-man/docs/RENDERING.md:61-77`). FFD: "A probe that proves a device is SEEN proves nothing about whether
    the game can be PLAYED with it" (`ENGINE_TODO.md:640-646`).
13. **Doc hygiene.** A confident justification is "a claim with an expiry date"; one cost three commits
    (`ENGINE_TODO.md:2590-2612`). "A deferral's reasons expire, and nothing marks them stale" (`:1123-1128`). "A
    shipped-work heading is a place live work goes to die" (`:2621-2631`). SPEC's own status header went two
    milestones stale (`SPEC.md:6-11`).
14. **Both games began from a playable JS prototype.** FFD's was 2D canvas; TMM's was three.js, frozen as the rules
    reference. Parity with it was the kama sim's first exit criterion (`friendly-fire-department/docs/SPEC.md:2513-2517`;
    `the-mallow-man/docs/ROADMAP.md:155-161`).
