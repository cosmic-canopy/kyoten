# Replay and determinism

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **Input-phase data is recorded**: networking, bot and human input, random seeds. The recording **can feed the
  simulation again for replay**, and more.

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

1. **Is the simulation deterministic across platforms, by contract?** FFD's answer (yes: strict float rules,
   cross-platform hashes in CI) makes lockstep netcode, replays and bug reports from a seed plus a log possible. It
   constrains physics ([networking.md](networking.md) and the Constraints phase in [frame-phases.md](frame-phases.md)):
   a third-party physics engine may not be deterministic across CPUs. Is determinism a promise the engine makes, or a
   pattern a game opts into?
2. **What is recorded?** Every Input-phase source (devices, network receive, seeds, time where a game reads it) as one
   ordered log per tick? What about inputs that do not fit a tick (text input, file drops, asset loads)? And the
   content layers loaded, since one id can resolve differently under another stack
   ([project-database.md](project-database.md) question 11)?
3. **The log format.** Shared with the network wire, as FFD's is, so there is one serializer? Versioned, so a recording
   survives an engine update, or explicitly tied to a build?
4. **What does replay give humans?** Scrubbing, stepping, comparing two runs, reproducing a bug from a recording, and
   filming at capture quality ([human-tools.md](human-tools.md)). What does it give agents: tests from recordings, a
   regression suite of play sessions?
5. **The tripwires.** FFD's world hash, its replay-at-exit check and its cross-platform hash CI. Which become engine
   features every game gets?
6. **Presentation versus simulation.** Enforce "Output never feeds the simulation" in the engine's structure (the
   Output phase gets only a read-only view of the state), rather than by discipline?

## Decided

*(nothing yet — filled in during the walk-through)*
