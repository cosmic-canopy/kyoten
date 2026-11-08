# The example games, and the first vertical slice

**Status:** questions 1–3, the spike's, are decided (2026-11-07), and 5 on 2026-11-01; 4 and 6 wait for
KYR-29 and KYR-40.

## What the vision asks

- **Example and test games built to consume the engine.** The engine is never hard-coded to a particular game; it is
  the driver for games.
- **Each example is its own repository**, so the engine manager can offer them one at a time as projects a developer
  downloads to start from ([version-manager.md](version-manager.md)).
- **The first two examples: an FPS, and a VR game for Meta Quest.**

## What exists

- **`kyoten-fps`** and **`kyoten-vr`**: two repositories, each checked out inside a kyoten checkout as `games/fps` and
  `games/vr` (git-ignored here). Each is a standalone kama project that depends on the engine by path
  (`../../engine`), and each prints its name and the engine version (kama 0.9.803). Nothing else is built.
- **The peers' starting point:** both began from a playable JS prototype (FFD in 2D canvas, the-mallow-man in
  Three.js), and parity with it was the kama simulation's first exit criterion
  ([../research/peer-games.md](../research/peer-games.md) § 7).

## The questions

1. **What does each example prove?** *(Decided 2026-11-07, below.)* An FPS exercises first-person input at high rates, a
   fixed simulation with interpolated rendering, hit detection (Constraints), audio, and naturally networking. VR on
   Quest exercises a headset's frame timing, stereo rendering, tracked poses and controllers, and a mobile GPU budget
   ([xr.md](xr.md)). What is each one's scope for its first version?
2. **What is the first vertical slice?** *(Decided 2026-11-07, below.)* The smallest end-to-end thing that proves the
   core ideas together. Candidates, smallest first:
   - **A.** The FPS's first-person camera and movement over a level, with keyboard and mouse, on web and native,
     through the platform seam ([web-and-native.md](web-and-native.md), [rendering.md](rendering.md)).
   - **B.** A plus all four phases at different rates (input at 120 Hz or more, simulation at 60 Hz, render at display
     rate), recorded and replayed bit-identically ([frame-phases.md](frame-phases.md),
     [replay-and-determinism.md](replay-and-determinism.md)).
   - **C.** B plus the project database: an agent builds and tunes the level and weapons through records, and a human
     watches and adjusts them in the tool surface ([project-database.md](project-database.md),
     [human-tools.md](human-tools.md)).
   - **VR:** the same slice in the headset, or a slice of its own after A? Quest is a separate platform path
     ([xr.md](xr.md)).
3. **What does "done" measure?** *(Decided 2026-11-07, below.)* For example: frame time per phase at each rate, web
   bundle size (the light-on-the-web promise), the lines of code each example needs (the Three.js promise),
   bit-identical replay, and holding the headset's frame rate on Quest.
4. **Shared content.** Do the examples share assets (from cosmic-forge, [content-pipeline.md](content-pipeline.md)),
   or does each carry its own, so that each download is self-contained?
5. **Examples as showcase.** The examples gallery on kyotenengine.com ([website.md](website.md)) and the first
   marketplace listings ([marketplace.md](marketplace.md)) could come from them. Is that a goal they are built to?
6. **Which examples come next?** A 2D game, a racing game and a networked arena are each a different shape, and each
   guards the engine against bending toward the first two.

## Decided

- **2026-11-01, the owner: each example game is its own repository**, so the engine manager can offer them one at a
  time as starting points. Inside a kyoten checkout, each is cloned to `games/<name>`, and kyoten's `.gitignore` leaves
  `games/` out, so examples take no space for anyone who only wants the engine. Layout and verification:
  [architecture.md](architecture.md) § Decided.
- **2026-11-01, the owner: the first examples are an FPS (`kyoten-fps`) and a VR game for Meta Quest (`kyoten-vr`).**
- **2026-11-01, the owner: the FPS example is expected to come first** ("may indeed be the first example"), so the
  first slice is planned in `kyoten-fps`. On the roadmap, slice A (KYR-11) and slice B (KYR-12) are the gate after
  which a game can start on kyoten, and slice C (KYR-28) follows with the project database. What each slice contains
  is still question 2's to decide, in the spike.
- **2026-11-01, the owner: the examples are built to showcase** (question 5). The owner wants as many games running
  on kyoten as possible to showcase when it is ready to host games. The ports of friendly-fire-department and
  the-mallow-man join the examples once each has shipped (KYR-46 to KYR-48). Each example still stays a different
  shape (question 6), so the showcase guards against bending the engine toward one game.
- **2026-11-07, the owner: questions 1–3, the last of the narrowed spike.** "All of this sounds good to me so far."
  1. **Question 1: kyoten-fps v1 is a playable single-player arena:** move, look and jump; a hitscan weapon whose hits
     resolve in Constraints; targets or simple bots (KYR-56's state machines); a HUD in HTML; and sound, on web and
     native from the same code (KYR-65). It proves the frame (input at a high rate, a fixed simulation, interpolated
     rendering), the records and the generator, the platform seam, and then the project database (slice C). Networked
     play (KYR-18) is its v2.
  2. **Question 1: kyoten-vr v1 is a room on Quest, natively:** the head and both hands tracked, controllers as actions,
     objects grabbed and thrown, stereo rendering, and the headset's rate held on a mobile GPU (KYR-33). It proves the
     XR package, the Android platform, and a frame driven by the headset's clock. It starts once the gate has passed
     and kama's installable Android app (KY-2) has landed; the owner's Quest prototype (KYR-4) informs it.
  3. **Question 1: neither bends the engine.** What they need arrives as a component or a pattern any game can use,
     by the rule in [../../AGENTS.kyoten.md](../../AGENTS.kyoten.md).
  4. **Question 2: the gate is slices A then B, in kyoten-fps, with the hello cube as A's first milestone.**
     - **A1, the hello cube** (KYR-14): a window, the GPU, records, the generator, one processor and input, on web and
       native, the smallest thing that passes through every tier.
     - **A2, the level** (KYR-11): a glTF level, flattened until KYR-62 brings the transform hierarchy; a first-person
       controller with simple collision against the level's boxes and ground (Jolt waits for KYR-17); keyboard, mouse
       and gamepad through actions.
     - **B** (KYR-12): the phases at their own rates, a session recorded and replayed bit-identically on every leg,
       the default rates measured, and parallel execution switched on group by group.
  5. **Question 2: slice C stays after the gate** (KYR-28): an agent builds and tunes the level through records while a
     human watches.
  6. **Question 2: VR has a slice of its own,** after the gate and KY-2: the hello cube in the headset first, then the
     room.
  7. **Question 2: audio and netcode stay out of the gate, and need not wait for it.** This answers the open question
     of the owner's 2026-11-03 expectation that much of the early work is engine modules. Netcode builds on slice B's
     determinism, so it starts once B's replay passes. Audio blocks nothing and waits on nothing, so another agent may
     build it in parallel at any time, as the project database's parallel agents do. "After the gate" says what the
     gate requires, not when work may start.
  8. **Question 3: each slice's "done" is a list of checks, held by CI where possible:**

     | Slice | Done when |
     |---|---|
     | A1, the hello cube (KYR-14) | at most 20 non-blank lines and eight concepts; at most 150 KB of code on the web (wasm plus JS, release, brotli); the same game code on web and native, with no platform flag in it; a headless readback sees the cube |
     | A2, the level (KYR-11) | the display's rate held on the reference machines, with frame time per phase reported; A1's numbers still hold |
     | B (KYR-12) | one world hash on every leg (three operating systems, wasm, the browser), with Output on and off; the parallel hash equal to the serial one; the default rates measured in its scene and recorded |
     | C (KYR-28) | an agent's record change visible in the running game within a second, with no rebuild (a starting gauge); a human's tuning landing in the same records |
     | VR (KYR-33) | the headset's rate held, with no dropped frame over a five-minute session in its reference scene |

  9. **Question 3: every number is a ratchet.** It is measured once, CI then fails when it gets worse, and loosening it
     is a decision recorded with its reason, as the hello cube's lines and the web's size already are. Measurements
     follow [../research/web-baseline.md](../research/web-baseline.md) § Method, so a slice repeats them.
  10. **Question 3: the reference machines:** a Steam Deck as the low-end native gauge, since the-mallow-man measured
      its quality tiers from there; a mid-range laptop's browsers (Chrome or Edge, Firefox, Safari) for the web; and the
      owner's Quest for VR. *(Named the same day, below: the owner has each, and Quest 3 is the target.)*
- **2026-11-07, the owner: the reference machines, named.** "I have a Steam Deck, This mini PC, Mac Mini, a few
  different mid rang laptops, Quest 3 ( and Quest 2 but probably better to target Quest 3? ). At some point it would be
  good to look into consoles as well."
  - **Native, the low-end gauge:** the Steam Deck, which is also the Linux leg (SteamOS).
  - **Windows:** the development machine, an Acer RB102 mini PC with an AMD Ryzen AI 9 465 and its integrated Radeon
    880M (read from Windows, 2026-11-07).
  - **macOS:** the owner's Mac Mini, which also runs Safari for the web leg.
  - **The web:** one of the owner's mid-range laptops, named with its model when A2 first measures, in Chrome or Edge
    and Firefox, with Safari on the Mac Mini.
  - **VR: Quest 3 is the target** (KYR-33). The Quest 2 is an older headset; whether a game also holds its rate there
    is a later check, not the bar.
  - **Each machine's model, CPU and GPU are written beside the first numbers measured on it,** so a ratchet always
    names its machine. Consoles stay KYR-42, which the owner wants looked into at some point.
