# The example games, and the first vertical slice

**Status:** draft for the design spike. Four decisions are recorded; the rest are questions.

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

1. **What does each example prove?** An FPS exercises first-person input at high rates, a fixed simulation with
   interpolated rendering, hit detection (Constraints), audio, and naturally networking. VR on Quest exercises a
   headset's frame timing, stereo rendering, tracked poses and controllers, and a mobile GPU budget ([xr.md](xr.md)).
   What is each one's scope for its first version?
2. **What is the first vertical slice?** The smallest end-to-end thing that proves the core ideas together.
   Candidates, smallest first:
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
3. **What does "done" measure?** For example: frame time per phase at each rate, web bundle size (the light-on-the-web
   promise), the lines of code each example needs (the Three.js promise), bit-identical replay, and holding the
   headset's frame rate on Quest.
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
