# Benchmarks: kyoten against other engines

**Status:** draft, deferred to KYR-74. These are questions, not decisions.

## What the owner asks

- **Benchmarks against other engines** (2026-11-11): "benchmarks for kyoten vs other engines."

## What already exists

- **kyoten measures itself.**
  - Every measured number is a ratchet on the reference machines (KYR-13; [examples.md](examples.md) § Decided,
    2026-11-07).
  - Each graphics feature has its web code size and GPU time ([rendering.md](rendering.md) § Decided, area 5).

  A benchmark against other engines asks something else: the same work done by each engine, and compared.
- **The reference machines:**
  - the Steam Deck;
  - the Windows mini PC with the Radeon 880M;
  - the Mac Mini;
  - a mid-range laptop's browsers;
  - Quest 3.

  Browsers are pinned in `~/browsers`, so a run can be reproduced.

## The questions

1. **What is measured.** Candidates:
   - CPU and GPU frame time, with their percentiles (p50, p99);
   - time from startup to the first frame, and load time;
   - memory;
   - the web download and the build's size;
   - power on the Steam Deck and Quest;
   - the simulation's step with many entities.
2. **Against which engines:**
   - on the web: three.js, Babylon.js and PlayCanvas, and Unity's and Unreal's web builds;
   - natively: Godot, Unity, Unreal and Bevy.
3. **Which scenes.** The same scenes, built in each engine. Candidates:
   - many cubes, for draw calls;
   - many lights;
   - many skinned characters;
   - a standard scene such as Sponza or Bistro;
   - many entities, with no rendering.

   The porting tools (KYR-73) could build some of them.
4. **Fairness.**
   - Each engine is set up its own best way, and someone fluent in it reviews the setup.
   - Each engine must draw the same image within a tolerance, so a faster engine is not simply drawing less.
   - Results are published with kyoten's losses as well as its wins.
   - The method, the raw data and the scenes' source are published, so anyone can reproduce a result or improve an
     engine's setup.
5. **Licenses and names.**
   - Some software licenses forbid publishing benchmarks without permission (a "DeWitt clause"). Each engine's terms
     are read for one before any number about it is published. None has been checked yet
     ([../research/graphics.md](../research/graphics.md) § 8).
   - The engines' names are used only to say what was measured.
6. **Where the results live, and how often.**
   - The results live on kyotenengine.com (KYR-39).
   - They are rerun at each release on the reference machines, not on every commit.

## Decided

- **2026-11-11, the owner: benchmarks against other engines are on the roadmap** (KYR-74). The questions above are
  decided when the row comes up.
