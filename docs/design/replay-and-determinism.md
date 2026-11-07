# Replay and determinism

**Status:** the spike's questions (1–3, 5 and 6) are decided, on 2026-11-07; question 4 waits for KYR-27.

## What the vision asks

- **Input-phase data is recorded**: networking, bot and human input, random seeds. The recording **can feed the
  simulation again for replay**, and more.
- **Input is an abstraction with universal rebinding, so AI drives the same inputs as humans** (the owner,
  2026-11-04; [../VISION.md](../VISION.md), [../ROADMAP.md](../ROADMAP.md) KYR-54).
  - **What it points to for question 2:** the record holds semantic actions ("fire", "move squad to X"), not device
    events.
  - **Why:**
    - A rebind then cannot move the hash. FFD already works this way: "every bound key is a bit of the hashed frame"
      ([../research/peer-games.md](../research/peer-games.md), FFD `SPEC.md:2617-2640`).
    - An iPad tap and a PC click enter as the same order, which players in different roles of one simulation need
      ([frame-phases.md](frame-phases.md) § What the vision asks).

## What already exists

From [../research/peer-games.md](../research/peer-games.md) § 2 and § 7:

- **friendly-fire-department: a round is a seed plus a log of input frames.** Record, replay, soak and network all call
  one `step`, so "a divergence cannot hide in the difference between two of them". A world hash after 600 ticks is
  identical on macOS/arm64, Linux/aarch64, wasm32, Windows/x64 and Linux x86_64; 25 full rounds give byte-identical
  reports. It replays itself at exit to check. Its replay file is the wire's own frames, not a second serializer.
  Captures step one tick per drawn frame and never read the clock.
- **How FFD stays deterministic:** only correctly rounded float32 operations on the deterministic path (no libm
  transcendentals), `-ffp-contract=off` in the sim package with a startup tripwire, hashing field by field (never struct
  bytes, because padding is not deterministic), PRNG and hash arithmetic in `uint64`, and **output never feeds the
  simulation** (gated by "600 watched ticks hash identically to 600 unwatched").
- **the-mallow-man is bit-exact against a frozen JS prototype** (a float64 fdlibm port, `reproducible-float`), but its
  physics (Jolt) is **not** cross-platform deterministic, because only the host simulates. It has no input recording.
- **The traps they hit:** FMA contraction, libm's last bit, a float literal being a double, `-0.0` versus `0.0` in
  hashes, `isize` being 32-bit on wasm32, signed overflow trapping. "Two green legs out of three is what this class of
  bug looks like."
- **kama helps:** `reproducible-float` in the manifest (no fused multiply-add), explicit integer widths, and traps on
  signed overflow ([../research/kama-for-engines.md](../research/kama-for-engines.md) § 4).
- **Found since:**
  - **A world reloaded from a snapshot does not step like the world that was saved** when its stores are kama
    `SlotMap`s, because a reloaded one reuses slots in a different order ([../KAMA_GAPS.md](../KAMA_GAPS.md) KY-4,
    [../research/component-models.md](../research/component-models.md) § 4). **Fixed in kama 0.9.809** (KR-287): the
    free list is written to the wire, so a reloaded map reuses the slot the live one would. Re-checked here on 0.9.810,
    and KY-4 was removed on 2026-11-02.
  - **FFD's input record is FFD's controller.** Its clock, RNG and hasher move nearly verbatim, but `InputFrame` and
    the four-phase driver are game-shaped ([../research/harvest.md](../research/harvest.md) § 1).
  - **Whether the ports fix the order.** KYR-46 needs FFD's RNG stream and hash order bit for bit, and Jolt is built
    without its cross-platform determinism (harvest's *What this does not decide* 6 and 8).

## The questions

1. **Is the simulation deterministic across platforms, by contract?** *(Decided 2026-11-07, below.)* FFD's answer (yes: strict float rules,
   cross-platform hashes in CI) makes lockstep netcode, replays and bug reports from a seed plus a log possible. It
   constrains physics ([networking.md](networking.md) and the Constraints phase in [frame-phases.md](frame-phases.md)):
   a third-party physics engine may not be deterministic across CPUs. Is determinism a promise the engine makes, or a
   pattern a game opts into?
   - *Narrowed 2026-11-05 at [components.md](components.md) question 4:* on one platform, the engine promises the order
     to every game, with no opt-in. This question keeps the cross-platform guarantee: floats, libm (KY-19) and physics. Jolt's
     cross-platform build is "approximately 8% slower". The owner asked whether any game should opt in, and this
     guarantee is where a reason could turn up.
   - *Learned the same day (kama KR-328's brief, `8813060d`):* the guarantee is wider than platforms. One Windows executable
     gives different `std::math` bits with UCRT's FMA3 paths on and off, so two PCs can disagree, and kama says *"a
     program that never targets wasm still needs one implementation compiled in"*. musl compiled in gives wasm's bits
     on all 28 functions at risk.
2. **What is recorded?** *(Decided 2026-11-07, below.)* Every Input-phase source (devices, network receive, seeds, time where a game reads it) as one
   ordered log per tick? What about inputs that do not fit a tick (text input, file drops, asset loads)? And the
   content layers loaded, since one id can resolve differently under another stack
   ([project-database.md](project-database.md) question 11)?
   - *Settled in part 2026-11-05 at project-database question 11:* the stack's identity (each source's id, version and
     content hash, in order) is in every save, replay and match. A recording carries any unpublished source, and a
     source that changes while running applies at a step boundary as a recorded input.
3. **The log format.** *(Decided 2026-11-07, below.)* Shared with the network wire, as FFD's is, so there is one serializer? Versioned, so a recording
   survives an engine update, or explicitly tied to a build?
   - *Noted 2026-11-07 ([components.md](components.md) question 9, round 3):* a save's file format joins this one,
     so there is one serializer. A save holds each loaded zone's changeable layers and changed sections, and the
     identity: the stack, the engine's version, the world generator's version and the seed.
4. **What does replay give humans?** Scrubbing, stepping, comparing two runs, reproducing a bug from a recording, and
   filming at capture quality ([human-tools.md](human-tools.md)). What does it give agents: tests from recordings, a
   regression suite of play sessions?
5. **The tripwires.** *(Decided 2026-11-07, below.)* FFD's world hash, its replay-at-exit check and its cross-platform hash CI. Which become engine
   features every game gets?
6. **Presentation versus simulation.** *(Decided 2026-11-07, below.)* Enforce "Output never feeds the simulation" in the engine's structure (the
   Output phase gets only a read-only view of the state), rather than by discipline?

## Decided

- **2026-11-07, the owner: questions 1, 2, 3, 5 and 6, the spike's five.** Question 1: "I think I agree for the most
  part", with two questions answered below; questions 2, 3, 5 and 6: "sounds good so far". Question 4 waits for
  KYR-27.
  - **The evidence, probed on kama 0.9.867:**
    - **Generation is bit-identical natively and on wasm under `reproducible-float`** (components question 9, round
      2): a terrain generator's hashes matched in four builds, and a million scattered `sin`, `cos` and `exp` matched
      with the key (1290205407 on both) and differed without it (native 1405493178).
    - **The key reaches a program from a dependency.** A game whose own manifest leaves it out, depending on a package
      that declares it, got musl's bits (1290205407). kama's `docs/targets.md`: the key "propagates from a dependency",
      and "It is one-way: a dependency's `false` takes nothing from a consumer".
    - **kama has three binary formats** beside JSON (`lib/std/serialization/binary/kbin`): named (`KBIN`,
      self-describing), numbered (`KNUM`, protobuf's shape: "an UNKNOWN id can be skipped" and "a stream survives
      REORDERING") and positional (`POS`: "The six-field frame KBIN puts at 91 bytes lands at 24 here", and both ends
      "must be built from the same declarations").
  - **Question 1: determinism across platforms is a promise to every game.** The same inputs give the same world hash
    in the browser and natively, in debug and release, on every CPU.
    - **How:** kyoten's own manifest declares `"reproducible-float": true`, so every game gets it and none can turn it
      off, with nothing to forget.
    - **What leans on it:** world generators (each machine generates its own zones), saves that keep only changed
      sections, lockstep, replays and bug reports carried between machines, agents testing on one platform for all, and
      web and native players in one match.
    - **What it costs** (kama's measurements): the 28 affected functions sum to about the same, unevenly (`log10` about
      2× slower, `cbrt` 2× faster); no fused multiply-add; and musl's MIT notice travels with every game, in the
      engine's notices.
    - **With it:** the simulation never runs on the GPU, and the physics backend runs in its cross-platform mode (Jolt's
      is about 8% slower; KYR-17).
    - **No opt-out, for now.** The owner: "Some games do not care as much about determinism so I am curious if they
      should be able to opt out? the cost is probably not enough to warrant it right now though." A slice B measurement
      (KYR-12) is what would reopen it. If an opt-out comes, the engine stops declaring the key and the generator writes
      it into each game's manifest, where a game may remove it, giving up cross-machine replays, lockstep, generated
      worlds each machine builds, and saves of changed sections only. On one machine the order stays promised either
      way (components question 4).
    - **GPU compute, the owner's other question,** "becoming increasingly interesting for parallel work". *Proposed, a
      direction for later (KYR-64):*
      - **Output may use the GPU freely:** particles, cosmetic cloth and fluids, culling, skinning.
      - **The simulation stays on the CPU by contract,** because GPU floating point is not the same bits across vendors
        and drivers, and a reduction across workgroups has no fixed order unless one is imposed. *Checked 2026-11-07
        in the WGSL specification (§ 15.7):* "No rounding mode is specified", `sin` and `cos` have an "Absolute
        error at most 2⁻¹¹ when x is in the interval [-π, π]", and "An implementation may reassociate operations"
        and "may fuse operations". Integer arithmetic is exact: an overflow is "modulo 2^bitwidth" (§ 6.2.3).
      - **A simulation kernel could run on the GPU later in two ways:** integer or fixed-point arithmetic with a fixed
        reduction order, which WGSL defines exactly, proved by a cross-GPU hash in CI (a falling-sand world store is the
        natural first case); or as an outside computation whose result enters at Input's hand-off, recorded, like an
        LLM's answer, so a replay needs no GPU. Either way the result is ready by the step that uses it, as a zone is.
  - **Question 2: what is recorded is one ordered log of Input's hand-off per step.**
    - **Recorded:** each player's actions after adapters (never device events), network receives, outside clocks a game
      reads (the audio position, VR poses; G12), what Output feeds back through Input (GPU picking), every I/O result (a
      dropped file, an LLM's answer, a web response, a non-deterministic world generation), and a content source
      changing while running. Typed text and dropped files are events with their payload at the next hand-off.
    - **The header:** the stack, the engine's version, the game build's identity, the world generator's version and the
      seed.
    - **Not recorded,** being deterministic or fixed by the stack's identity: world generator output, random keys,
      derived data, asset contents, and when a zone finishes loading (G8).
    - **The simulation never reads the wall clock;** a daily event's date enters as recorded input.
    - **Always on:** every session records into a ring buffer of its last minutes, so a bug report carries its replay;
      keeping a whole session is a setting.
  - **Question 3: one serializer, kama's serde, and one set of types in three forms.**
    - Records are JSON (components question 8 part b), saves `KNUM`, and the replay log and the network wire `POS`, a
      frame per step: lockstep sends the frames the log keeps, so there is one path, as in FFD.
    - **Saves are state,** versioned, and migrate across engine and game updates (components question 8 part a's
      promise). **A replay is inputs to code,** so it is tied to the build that recorded it; an update makes old
      replays unplayable unless the old build is kept. `POS` refusing a shape mismatch as "malformed" is the honest
      failure.
  - **Question 5: the tripwires every game gets.**
    - **A world hash every step** over simulated, changeable state: chunks hash directly, since equal lists are equal
      bytes, and read-only layers are skipped. A release build may hash less often.
    - **Replay at exit, in development** (FFD's): the session replays itself from its log and compares hashes, and a
      divergence names the first step and the store that differs, so hashes are kept per store.
    - **Serial against parallel** (frame-phases question 7) and **watched against unwatched** (FFD's 600 ticks: with
      Output and without it, the same hashes; question 6's alarm).
    - **Across platforms:** `kyoten test --replay` runs a recorded scene on every leg (native on three OSes, wasm in a
      browser) and compares hashes. The examples' CI uses it (KYR-12, KYR-13), and a game's CI can.
  - **Question 6: Output's read-only rule is enforced by structure** (frame-phases question 1 decided the rule).
    - The generator gives an Output processor only `const ref` parameters, reading the last step's snapshot, and
      refuses `ref` of a simulation component, any queue and `Current<C>`.
    - **Output's own state** (a smoothed camera, render caches, screen shake) lives in components or world components
      whose record says `"output": true`: only Output writes them, the generator refuses a simulation processor that
      reads one, and they are never saved or hashed.
    - Output feeds back only through Input's record, and kama's `const ref` makes a write a compile error.
