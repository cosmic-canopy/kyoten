# The frame: Input, Update, Constraints, Output

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **Four phases:** **Input** (network receive, bot and human input, random seeds; *recorded*, so a run can be
  replayed), **Update** (game logic, bot and AI state machines), **Constraints** (physics), **Output** (rendering,
  network sends).
- **Each phase can run its work in parallel.**
- **Components within a phase update at different fixed frequencies**, each chosen for human perception.
- **Clean patterns each game uses, not hard-coded systems.** It should be easy to use correctly and high
  performance.
- **Strong abstractions for the systems and phases, up front** (the owner, 2026-11-02;
  [architecture.md](architecture.md) question 1), with "each phase has its own components that can be written"
  ([components.md](components.md)).

## What already exists

From [../research/peer-games.md](../research/peer-games.md) § 1:

- **friendly-fire-department built exactly this model, under these names** (item E-6, landed 2026-09-02; `docs/SPEC.md`
  § "The four-phase harness"). The shipping client runs `drainPlatform` (Input) → `stepWorld` (Update, then
  Constraints N times, for each 60 Hz tick it owes) → `frameStep` (Output, at display rate). Its pieces live in
  `engine/src/phase/`: a fixed-step `PhaseClock` (owed steps plus `alpha`, at most 5 steps a frame, the excess dropped and
  counted), `Rng`, `Hasher`, `InputFrame`/`InputLog`.
- **FFD changed the model in four ways, each with a reason worth weighing:**
  - **Constraints is an iteration count per tick, not a rate of its own**, and it must be *idempotent*: the suite
    steps one world at 1 iteration and one at 5 and demands the same hash. A bounce is not a projection, so it lives in
    Update.
  - **The phases never overlap across threads.** Overlapping Output for frame N with Input for N+1 "buys throughput at a
    frame of latency and destroys the data flow… The parallelism worth having is inside a phase."
  - **Sub-rates are tick arithmetic inside the one fixed tick**, never separate clocks: fire spreads every 27 ticks, and
    bots re-decide when `(tick + seat*37) % PERIOD == 0` ("derived, not stored").
  - **It stays single-isolate "until a measurement asks otherwise"**, and none has: a tick costs about 7.5 µs in release.
  `alpha` reaches the renderer and nothing reads it yet.
- **the-mallow-man has no named phases:** a 30 Hz fixed tick with frame interpolation, and Jolt physics called inline
  from the rules (no separate Constraints step).
- **Neither game runs any phase in parallel.** The only extra threads are audio, speech recognition and Jolt's own
  pool. FFD's web build is deliberately single-threaded.
- **FFD's design notes on parallelism in kama** (`ENGINE_TODO.md:1580-1602`): module statics are per isolate, so phase
  state must hang off one owner and be passed as `ref` field borrows for `scope` to prove two spawns disjoint;
  `parallel_for` needs a contiguous container; and it binds the element but not its index, so a neighbour-reading
  stencil does not fit it as shipped.
- **kama's parallel machinery** ([../research/kama-for-engines.md](../research/kama-for-engines.md) § 1 and the fibers
  addendum): `scope`, `spawn`, `parallel_for` (which starts and joins K threads on every call: 1.3–1.8 ms here, far
  too slow for a per-phase barrier), channels, and `Locked`/`ReadWriteLocked`. **The job pool kama has designed for CPU
  work (KR-3 step 9) is not built**; a channel-fed pool kyoten could write costs about 250 µs a frame. Fibers are for
  I/O, not for this.
- **On the web, threads move `main` to a worker** (COOP/COEP required, no DOM or canvas there). See
  [web-and-native.md](web-and-native.md).
- **Gathered since** ([../research/component-models.md](../research/component-models.md), KYR-3;
  [../research/harvest.md](../research/harvest.md), KYR-2):
  - **Phases and rates (questions 1–3).** flecs's built-in pipeline maps onto the four phases almost one to one.
    Unreal, flecs and Unity Entities give each unit its own rate; MonoBehaviour, Bevy and Godot run one fixed rate.
  - **Parallelism (questions 5–6).** On kama 0.9.803, `scope` accepts two systems on disjoint fields of a world when
    the world's own method spawns them. It refuses a store reached through a `ref`-returning accessor, and two
    read-only children of one place ([../KAMA_GAPS.md](../KAMA_GAPS.md) KY-5). Probes 1–4 of its § 4.
  - **The donors' renderers keep their state in module statics** (FFD 16, the-mallow-man 63), which are per isolate;
    forge's `render` keeps none (harvest § Summary and its *What this does not decide* 3).
- **The loop is the engine's** ([architecture.md](architecture.md) question 4, 2026-11-02): the game's `main` calls
  `run`, which owns the loop on every target. That covers rAF on the web, the headset's frame under XR (question 10)
  and the lifecycle's events. The parts stay public, so a test or a replay can step a world without it.

## The questions

1. **The phases themselves.** Keep the owner's four, with FFD's refinements (Constraints as iterations; Output
   reading, never writing, the simulation)? Where do network *send* and audio cues go: FFD put cues in Output, derived
   from world deltas, and kept the net pump in one place.
2. **Rates: one tick with sub-rates, or several clocks?** FFD derives every sub-rate from one fixed tick, which keeps
   replay trivial. The vision says components update "at different set frequencies". Is that tick-divided rates
   (60, 30, 20, 15 Hz…) on one clock, or independent clocks with their own accumulators? What does an input device
   sampled at 1000 Hz do?
3. **Which rates for what?** The vision ties rates to human perception: input latency, animation smoothness, audio's
   own clock, network send rates. Write down the defaults, and which ones a game changes.
4. **Interpolation.** Output at display rate between fixed ticks: who reads `alpha`, and how does a component say how it
   is interpolated (or that it is not)?
5. **Parallelism inside a phase.** Over what: components of one type (data-parallel), independent systems
   (task-parallel), or both? Built on what, given that kama's job pool is not built yet and `parallel_for` is too slow
   to call per phase? Does kyoten build the pool now, contribute it to kama as KR-3 step 9, or wait?
6. **Proving it safe.** kama's `scope` proves disjointness of `ref` field borrows. Can the component model
   ([components.md](components.md)) be shaped so a phase's parallel work is checked by the compiler, not by convention?
7. **When does parallelism pay?** Both peers' ticks are microseconds; their frame cost is the renderer (TMM: renderer
   CPU about 0.9 ms a frame). Is parallel Update a day-one feature or a measured later step, and is parallel *Output*
   (render command recording) the first one worth having?
8. **On the web.** Single-threaded first (as FFD chose), or workers from the start? This depends on the thread
   topology in [web-and-native.md](web-and-native.md).
9. **Game-logic waits** ("in two seconds, open the door"). Tick-counted deadlines, as FFD's `Countdown`; coroutines on
   fibers would park on the real clock, which a replay cannot reproduce.
10. **A display clock the game does not own.** In VR the headset drives the loop at 72, 90 or 120 Hz with a predicted
    display time, and poses are sampled as late as possible ([xr.md](xr.md)). Does the frame model hold when Output's
    rate is dictated from outside?

## Decided

*(nothing yet — filled in during the walk-through)*
