# The frame: Input, Update, Constraints, Output

**Status:** in the walk-through (KYR-1). Questions 1 and 2 were decided on 2026-11-04 (see *Decided*). A draft answer to each
of the rest, for the owner, is in *A draft for the walk-through* (2026-11-04).

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
- **The engine systems are driven by components in the phases, each subsystem at its own rate** (the owner,
  2026-11-03). "Much of the initial work will be engine systems anyway. Cross platform Audio, graphics, networking,
  input, etc. Each are driven by components in each of the phased parallel processes. Input -> update -> Constraint ->
  output. Each sub system of a phase has its update frequency to compensate best with human perception and GPU/CPU
  performance and simulation correctness."
  - **What this sets for the questions below:** the rate belongs to a subsystem inside a phase. It is chosen against
    three things together: human perception, CPU and GPU cost, and simulation correctness (questions 2 and 3).
  - **What it leaves open:** whether those rates divide one fixed tick, as FFD's do, or run on clocks of their own
    (question 2).
- **What each phase is, in the owner's words** (2026-11-04): "The phases I came up with is what I believe every
  game/simulation has that requires input from the previous."
  - **Input:** "This is external inputs to the simulation. Random Seeds, Player Input, Networking, etc. These can be
    recorded for replay and determinism. it starts the process to feed the rest of the simulation phases."
  - **Update:** "This is where the meat of game logic happens. gameplay code in the form of components drives the
    experience. This leads to an ideal next frame which may [break] physical rules of the system and thus needs checked
    next."
  - **Constraints:** "This is a more general term than "physics" but that is one of the primary things that happens
    here. This is where logic that gates happens. Did something violate a rule and need corrected, etc. This allows the
    simulation to check rules like if a game relies on realistic physics we can check a bullet trajectory and determine
    if it contacts another object, if a player is hitting a wall, etc. constraint components help drive the rules of
    the system before an output frame or message to network is rendered."
  - **Output:** "This is the output of a complete simulation run. Rendering, Network sends, etc."
  - **Why there are phases at all,** said the same day about the module rule
    ([architecture.md](architecture.md) § Decided, 2026-11-04): "The goal is that each PHASE can be made parallel safely
    and efficiently to increase overall performance and utilization of CPU and GPU resources. It is also to make the
    engine easy to use correctly and hard to use incorrectly."
- **Output can differ per platform, over one simulation** (the owner, 2026-11-04; [../VISION.md](../VISION.md)).
  - A high-end box renders "super smooth looking graphics and shaders" and a low-end one "simpler scenes", with the same
    determinism.
  - Players can even play different games in the same simulation: iPad users as RTS "generals directing troops" while
    PC players play it as an FPS.
  - **What follows here:**
    - Output's being read-only (question 1) is what makes this possible.
    - Whatever affects fairness is simulated, not only drawn. If smoke hides a player on one box and is skipped on
      another, the second player sees through it, so concealment is a simulation rule and only its look is Output's.
    - The roles act differently, so Input's record holds semantic actions rather than device events
      ([replay-and-determinism.md](replay-and-determinism.md) question 2).

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
   from world deltas, and kept the net pump in one place. *Decided 2026-11-04: the four in order, with Output
   read-only, each Constraints subsystem's own iteration count, and idempotence a check a subsystem may claim.*
2. **Rates: one tick with sub-rates, or several clocks?** FFD derives every sub-rate from one fixed tick, which keeps
   replay trivial. The vision says components update "at different set frequencies". Is that tick-divided rates
   (60, 30, 20, 15 Hz…) on one clock, or independent clocks with their own accumulators? What does an input device
   sampled at 1000 Hz do? *Decided 2026-11-04: one simulation clock with its base derived from the subsystems' rates
   (or pinned), each subsystem handed its step, and input split across owed steps by timestamp.*
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

## A draft for the walk-through (2026-11-04)

**For the owner, not decided:** options and a recommendation per question, to bring and ask. The evidence is the
sections above and the research they cite. What rests on kama was re-checked on **0.9.839** (2026-11-04):

- `scope` still admits two systems on disjoint fields of a world, spawned from the world's own method, and refuses a
  store reached through an accessor ([../research/component-models.md](../research/component-models.md) § 4, probes
  1–3).
- Two readers of one store are still refused (KY-5, KR-288 open).
- A spawned store's element type must declare `implements Sendable`.
- No job pool exists yet: KR-3's next step is 7, and the pool is step 9.

**The thread through all ten:** one simulation clock, and every subsystem's rate stated against it. The clocks the
game does not own stay outside the simulation: the display, the audio device, the headset and the OS's input events.
They meet it only at Input's fold and at Output's read. That is how the owner's per-subsystem rates and a replayable
run can both hold.

1. **The phases.** *Decided 2026-11-04, with the owner's refinements (see Decided). The draft is kept as it was
   brought.*
   - **Options:** (a) the four as the vision words them; (b) the four with FFD's refinements; (c) finer phases as
     tags, as flecs splits Constraints into detecting and correcting.
   - **Recommended: (b), with one change.** Output reads and never writes, from day one, because enforcing it later
     breaks every renderer that writes back (component-models § 5.8, item 6; replay question 6).
   - **The change:** a Constraints subsystem runs a whole number of iterations per tick. FFD's count is the case where
     every subsystem runs the same N. Idempotence is something a projection may claim and a test checks, as FFD's
     suite does, not a rule of the phase, because a solver such as Jolt's is not idempotent.
   - **Where network and audio go:** network receive goes in Input, recorded. Network send and audio cues go in Output,
     derived from the settled tick, as FFD derives its cues from world deltas.
2. **Rates.** *Decided 2026-11-04, with a derived base (see Decided). The draft is kept as it was brought.*
   - **Options:**
     - (a) one fixed tick, with every simulation rate a divisor or a multiple of it, derived and not stored (FFD's
       modulo, flecs's `rate`);
     - (b) independent clocks, each with its own accumulator (flecs's `interval`, Unreal's `TickInterval`);
     - (c) (a) inside the simulation, plus the outside clocks named above, each an interface the engine reads.
   - **Recommended: (c).**
     - **Why:** a replay or a lockstep peer then needs only the tick count and the Input log. Under (b), every clock's
       steps are recorded or re-derived, and two machines must agree on each one.
     - **What it costs:** a rate that does not divide the tick, such as 50 Hz on a 60 Hz tick, means a faster tick or a
       rounded rate.
   - **A 1000 Hz device:** the platform takes events as they come, and Input folds everything since the last tick into
     that tick's record (the event queue and fold, harvest § 2).
     - **Edges wait for a tick,** as TMM's `InputState` holds them: "EDGES persist until a sim TICK consumes them". So
       "a frame that owes no fixed steps (a 240 Hz display against a 60 Hz sim) must not discard a keypress, and a
       frame that owes three must not apply one keypress three times"
       (`the-mallow-man/engine/src/input/state.kama:27-32`).
     - **Presentation-only reads,** such as camera look, take the newest sample each frame instead, because "a look
       that waits for the next tick is latency" (TMM, peer-games § 1).
     - **What the simulation sees** is the value the tick consumed, and the log records that value.
3. **Which rates for what.** Proposed defaults, each with the owner's reason that drives it:

   | Subsystem | Default | Driven by | A game changes it? |
   |---|---|---|---|
   | The simulation tick | 60 Hz (FFD; TMM's rules run at 30 and its free walk at 60) | correctness, CPU | yes |
   | Input's fold | once a tick; presentation reads once a frame | perception (latency) | no |
   | Update subsystems | every tick; slower AI on a divisor with a per-entity offset (FFD's bots) | CPU | yes, per subsystem |
   | Constraints | 1 iteration a tick | correctness | yes, per subsystem |
   | Rendering | the display's rate | perception, GPU | no: the display, rAF or the headset owns it |
   | Audio | the device's own clock and thread; cues each tick, the listener each frame (TMM) | perception | no |
   | Network send | each tick, or a divisor (TMM 30/30) | bandwidth, correctness | yes |

4. **Interpolation.**
   - **Options:** (a) the game interpolates by hand, as today: `alpha` reaches FFD's renderer, and nothing reads it;
     (b) a component declares how it is interpolated, and the engine keeps the previous tick's value only for those,
     so Output reads the previous value, the current value and `alpha`; (c) every component is double-buffered.
   - **Recommended: (b).** A transform defaults to linear for position and slerp for rotation, and anything undeclared
     snaps at the tick. How a component declares it waits for components question 2. How Output reads without
     stalling the next Update is rendering question 4, and (b) narrows it to the declared components.
5. **Parallelism inside a phase.**
   - **Options:** data-parallel (one system over a store), task-parallel (independent systems), or both. Built on
     `parallel_for` per call, on a pool kyoten writes, or on kama's pool (KR-3 step 9).
   - **The costs measured here** (kama-for-engines § 1, on 0.9.793): `parallel_for` costs 0.15–1.4 ms per call at
     1–16 workers, and 1.83 ms at 20. A pool kyoten writes costs about 250 µs a frame.
   - **Recommended:** both shapes in the API from day one, through access stated in signatures, but run serially until
     a measurement asks. Once access is stated, parallelism is a scheduler change (component-models § 5.8, *Later*).
     When a measurement does ask, build the pool as KR-3 step 9 in kama rather than as kyoten's own, by the rule that
     what can exist outside kyoten goes to kama. That last part is the owner's call.
6. **Proving it safe.**
   - **Recommended: yes, checked by the compiler.** Shape the component model so that a phase's parallel group is a
     `scope` over named store fields, which is components options A and B (component-models § Options).
   - **What the compiler then checks:** writes are disjoint. Two readers of one store wait for KR-288, or read a
     snapshot, which Output wants anyway (question 4).
   - **Under option C**, a run-time scheduler over type-erased columns, disjointness is kyoten's invariant rather than
     the compiler's. This waits for components question 1.
7. **When parallelism pays.**
   - **What the peers measured:** FFD's tick is about 7.5 µs. TMM's physics is about 0.1 ms a tick, its bots 3 µs, and
     its renderer about 0.9 ms of CPU a frame.
   - **Recommended:** parallel Update is a later, measured step, not a day-one feature. The trigger is a phase over its
     budget in a measured scene. The first parallel work worth having is likely in Output, recording render commands,
     and on the web that is bound to the device's thread (question 8).
8. **On the web.**
   - **Recommended:** single-threaded first, as FFD chose. Nothing measured needs threads yet (question 7), and threads
     cost COOP/COEP, which breaks a cross-origin WebSocket, and a `main` with no DOM.
   - **What keeps the door open:** the frame model never assumes threads, so a worker topology is a later change to the
     scheduler. The topology itself is web-and-native question 2.
9. **Game-logic waits.**
   - **Recommended:** a wait is a tick-counted deadline (FFD's `Countdown`, 85 lines, harvest § 1). An API may take
     seconds and convert them once, at the tick rate in force when the wait is made.
   - Fibers stay for I/O, because they park on the real clock, which a replay cannot reproduce.
10. **A display clock the game does not own.**
    - **Recommended: yes, it holds,** because Output is the only phase on the display clock.
    - **How a frame runs:** each frame, `run` asks the clock source how many ticks are owed and runs them. The clock
      source is rAF, vsync or the headset's predicted display time (architecture question 4 gave `run` the loop). Output
      then renders for that time.
    - **At headset rates:** at 72 Hz over a 60 Hz tick, some frames run no tick and some run one, and interpolation
      (question 4) covers both. FFD's clamp of five steps a frame still bounds a stall.
    - **Poses:** a pose is sampled late in Output, for presentation. A pose the simulation needs, such as a hand's grab,
      enters through Input at the tick, like any device.
    - **What settles it on a headset:** the owner's Quest prototype (KYR-4), measured against 120 Hz's 8.3 ms.

## Decided

- **2026-11-04, the owner: the four phases, in order, with Output read-only (question 1).**
  - **The phases:** Input → Update → Constraints → Output, always in that order, as the owner defines them in
    *What the vision asks*.
    - A system takes part in any phase by registering a subsystem there: net receives in Input and sends in Output.
    - Nothing reaches the simulation outside a phase.
  - **A phase has no rate; a subsystem does.** A phase is a place in the order.
    - Sometimes the simulation's subsystems owe several steps in one display frame: a 30 Hz display under 60 Hz
      physics, or a stalled frame. Then Input → Update → Constraints run once per owed step, and Output runs once.
    - How the steps are counted is question 2.
  - **Work runs at any time; it reaches the simulation only at its phase's hand-off.** In the owner's words: "phases can
    do work at any time to best utilize the hardware. So the network INPUT phase may still be gathering packets for the
    next Input "hand off" while the simulation is in a different phase. It just doesn't contribute to the simulation
    and/or finalize anything until the next Input phase."
    - **How:** outside its phase, a subsystem's work touches only its own staging state, or reads a settled snapshot.
      It writes the simulation only in its phase. At Input, the hand-off is what the log records. How much had arrived
      by then depends on timing, and recording the hand-off makes it a deterministic record.
    - **The cheap cases:** net gathering packets, the OS's input events, audio decoding, asset streaming.
    - **The case that crosses the simulation:** Output recording tick N while Update runs N+1. It needs a snapshot of
      N (question 4, [rendering.md](rendering.md) question 4). FFD warns it can cost a frame of latency, so it is
      questions 5 and 7's to measure.
  - **Output reads the simulation and never writes it, from day one.**
    - It keeps its own presentation state: render caches, audio voices, send buffers, a smoothed camera, screen shake.
    - **Why:** Output runs on the display's clock, so a write would make the result depend on the player's monitor. A
      replay, a test and a headless server run no Output, so each would get a different simulation. Enforcing the rule
      later would break every renderer that writes back
      ([../research/component-models.md](../research/component-models.md) § 5.8, item 6).
    - **What it costs:** anything gameplay depends on is computed in the simulation. Animation that affects gameplay
      (root motion, an animated hitbox) is evaluated in Update, and Output animates only what is cosmetic.
    - **Output may feed Input** (the owner): GPU picking, whether an enemy is on screen, a local in-process server.
      What Output feeds back enters through Input's record, so a replay reads it from the log. It lands on a later tick
      at the earliest. In lockstep it is sent to the peers like player input, since a peer cannot reproduce another
      player's screen.
  - **Constraints corrects, gates and records the simulation state that Update left in the tick.** It pushes a player
    out of a wall, holds a locked door, and records contacts, which Update reads on the next tick. A game's own rules
    are constraint components.
  - **Each Constraints subsystem runs a whole number of iterations per tick.**
    - The count is the subsystem's own, fixed as part of the simulation's definition like the tick rate, so a replay
      reproduces it.
    - The owner: "most physics solvers run some bound number of iterations to arrive at the "result" like cloth
      physics".
  - **Idempotence is a check a subsystem may claim, not a rule of the phase.**
    - **Why:** a physics step, a cloth solve and a bullet sweep are not idempotent, and the owner's Constraints holds
      all three.
    - **How:** kyoten offers FFD's test to any subsystem that claims idempotence: step at 1 iteration and at 5, and
      compare the hash.
    - **FFD:** "we want kyoten to be able to make any game so FFD should be possible to run in kyoten. FFD would just
      need to build the idempotence into it" (the owner). FFD's projections port as Constraints subsystems that claim
      it (KYR-46).
    - **Carried to question 5:** FFD repeats its whole phase (A, B, A, B), while per-subsystem counts run A, A and then
      B, B. For FFD the two agree, because its suite proves that 1 and 5 iterations hash alike. Solvers that must
      converge together may want a group that iterates jointly.
  - **Network and audio:**
    - net receive goes in Input, recorded, and net send in Output;
    - audio cues are decided by the settled tick, after Constraints, because Constraints can cancel what Update did (a
      blocked shot plays no hit sound);
    - Output plays the cues on the audio device's own clock.
  - **Order inside a phase is a priority** (the owner's term): what has the final say runs last, and its write stands.
    Its form (a number, relative edges, or bands) is question 5.
  - **Considered:**
    - FFD's idempotence as a rule of the phase, which moves every solver that integrates motion into Update;
    - Output writing some simulation state back, such as animation driven by rendering, which makes the result depend
      on the display rate;
    - named sub-phases fixed in advance, as flecs has. Order now goes to priority, question 5.
- **2026-11-04, the owner: one simulation clock, with each subsystem's rate stated against it (question 2).**
  - **The clock:** each simulation subsystem declares its rate in Hz and runs every *k* steps of one base clock.
    - The engine derives the base as the rates' least common multiple: 60 and 30 give 60, 120 and 60 give 120, and 60
      and 50 give 300. Above a cap, about 1,000 Hz, it warns and suggests the nearest rate that fits.
    - A game may pin the base instead, as FFD's port pins 60.
    - A step where nothing is due costs nothing, because the engine jumps to the next step that has work.
  - **Why**, in the owner's words: "It allows the subsystem granularity and solves the order problem of phases."
    - Under independent clocks, which subsystem steps first depends on how their accumulators interleave with frame
      timing. A replay then records every clock's steps, and lockstep peers must agree on each one.
    - Under one clock, the step count alone decides who runs when. A replay or a lockstep peer needs only the step
      count and the Input record.
  - **A subsystem never reads a clock. It is handed its step: its `dt` and its step index.**
    - A rate is then a configuration change, and the scheduler can change under the subsystems without touching their
      code. The owner: "you will always pass the dt to components so they should calculate any frame delta logic
      against the dt they are passed".
    - Code written against `dt` is rate-portable, not rate-identical. A jump integrated by simple Euler peaks at a
      different height at 30 Hz than at 60. A fixed `dt` keeps that from showing.
    - Output's subsystems already run on the display clock with the frame's `dt`, so one interface covers both.
  - **Other modes come later, opted into per game.** The owner: "We start with what we decided and it is probably the
    best simulation update anyway. but the abstraction allows flexibility and per game variation if needed later."
    - Independent clocks, or a variable `dt`, would be a scheduler mode a game opts into.
    - Under such a mode, each step's `dt` is recorded and the record names the mode. Lockstep between peers on
      different displays is not possible.
    - Only the derived or pinned base is built first.
  - **The clocks the game does not own stay outside:** the display, the audio device, the headset, the OS's input
    events and the network. Each is an interface the engine reads, and they meet the simulation only at Input's
    hand-off and Output's read.
    - **The counter is kama's.** `std::time::Instant` reads the best clock on each platform (kama
      `include/kama_time.h` and `lib/std/time/time.kama:282`, at `6cac55c7`):
      - `performance.now()` on wasm, whose resolution is 100 µs, or 5 µs when cross-origin isolated (MDN);
      - `QueryPerformanceCounter` on Windows;
      - `CLOCK_MONOTONIC` on Linux, Android, macOS and iOS.
    - **The engine's interface is the frame source,** which says when a frame will be shown: rAF on the web, vsync
      natively, and the headset's predicted display time under XR (question 10).
      - rAF is the web's display-synchronized wake-up, not its most frequent one. The audio worklet runs every 128
        samples on its own thread, and a worker loops on its own.
      - XR is another frame source ("XR is just another platform variation", the owner). It carries a predicted
        display time, a late pose, two views, and rates that change at run time.
  - **Input across several owed steps is split by timestamp.**
    - Events queue as they arrive. Each step's hand-off takes the events whose timestamps fall in its window, so a key
      pressed late in a frame lands in the later step.
    - Edges wait for a step that consumes them (the-mallow-man). Presentation reads, such as camera look, take the
      newest sample each frame.
    - **On the web, a gamepad is polled once a frame.** The Gamepad API is `[Exposed=Window]` and has no button
      events. The spec says to poll "as closely as possible to immediately before the animation callbacks are
      executed" (W3C Gamepad). A press and release that both fall between two polls is not seen. Natively, a gamepad
      can be polled faster.
  - **Cross-platform play is wanted** ([../VISION.md](../VISION.md), 2026-11-04). One clock is what makes it possible:
    every peer steps the same rates whatever its display, and a display changes only that peer's Output. Two things
    stay per game:
    - **The netcode model.** Lockstep needs the simulation bit-identical across wasm, x86 and ARM
      ([replay-and-determinism.md](replay-and-determinism.md) question 1), and server authority does not
      ([networking.md](networking.md) question 1).
    - **Input fidelity.** A web peer's gamepad is sampled once a frame.
  - **Carried:**
    - **To question 3, the rates' defaults.** The owner: "we should come up with the best universal rates for ANY".
      - Each subsystem's floor is set by what breaks below it: latency for net send, stability for physics, cost for
        AI.
      - Fast objects tunnelling is answered by sweeping in Constraints (continuous collision detection). The owner: "if
        you can sweep spheres for example you can determine if a bullet passed through a wall between simulation
        rounds". The rate still sets the stability of stacks, joints and springs.
    - **To [web-and-native.md](web-and-native.md) question 2 and networking (KYR-18): a hidden tab pauses rAF.** MDN:
      "requestAnimationFrame() calls are paused in most browsers when running in background tabs". A networked web
      game needs a policy: pause and resync, or simulate from another clock.
  - **Considered:**
    - a base the game must state, with every rate dividing or multiplying it, which is kept as the pinned option;
    - independent clocks per subsystem (Unreal's `TickInterval`, flecs's `interval`), which are kept as a later mode a
      game opts into.
