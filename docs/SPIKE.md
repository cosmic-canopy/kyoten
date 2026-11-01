# The design spike — kickoff brief

kyoten was seeded on 2026-11-01 to be designed **with** its owner, not for him. This brief is for the session
that runs the walk-through.

## The goal

Turn every draft under [design/](design/) from questions into decisions, with their reasons, and leave a
[ROADMAP.md](ROADMAP.md) whose rows are the work those decisions create. **The output is decisions, not code.** A
throwaway prototype is fine wherever a measurement would settle a question. Build it under `.scratch/` (gitignored)
or in a temporary directory, and record what it measured in the design doc it settles.

## Read first

1. [VISION.md](VISION.md): the owner's brief. Every design traces back to a line in it.
2. [research/peer-games.md](research/peer-games.md): what friendly-fire-department and the-mallow-man built,
   including **whether they used the Input / Update / Constraints / Output frame**, which is the owner's first
   question.
3. [research/kama-for-engines.md](research/kama-for-engines.md): what kama offers an engine today (threads,
   isolates, wasm, GPU and window packages, performance) and what kyoten has to build or wait for.
4. [research/cosmic-forge.md](research/cosmic-forge.md): the content-creation component kyoten consumes.

## The walk-through, in order

Each doc ends in numbered questions. Take them in this order, because the later ones lean on the earlier
ones:

| # | Doc | Why it comes here |
|---|---|---|
| 1 | [design/architecture.md](design/architecture.md) | the package split and the engine/game boundary shape every other doc |
| 2 | [design/frame-phases.md](design/frame-phases.md) | Input / Update / Constraints / Output, parallelism, per-component rates |
| 3 | [design/components.md](design/components.md) | how a game expresses state and behaviour |
| 4 | [design/replay-and-determinism.md](design/replay-and-determinism.md) | recorded inputs, which the Input phase owes |
| 5 | [design/web-and-native.md](design/web-and-native.md) | web first, native at parity: the seam everything renders, sounds and listens through |
| 6 | [design/target-platforms.md](design/target-platforms.md) | N platforms, extensible: platforms as packages, consoles under NDA, Roblox and UEFN as export targets |
| 7 | [design/xr.md](design/xr.md) | VR: OpenXR natively, WebXR on the web, perhaps as a package; Quest first |
| 7 | [design/networking.md](design/networking.md) | netcode in the Input and Output phases, and the hosted game backend |
| 8 | [design/project-database.md](design/project-database.md) | the AI-coordinated database and wiki: how a game is generated |
| 9 | [design/human-tools.md](design/human-tools.md) | visibility and tuning: the editor surface, the DAW, timelines |
| 10 | [design/rendering.md](design/rendering.md) | WebGPU first |
| 11 | [design/audio.md](design/audio.md) | Web Audio first, and the DAW tool on top |
| 12 | [design/timeline.md](design/timeline.md) | timeline and cinematic tools |
| 13 | [design/content-pipeline.md](design/content-pipeline.md) | consuming cosmic-forge |
| 14 | [design/ai-first-api.md](design/ai-first-api.md) | easy for AI from day one, as quick as Three.js to prototype in |
| 15 | [design/version-manager.md](design/version-manager.md) | several engine versions on one machine, and example projects to start from |
| 16 | [design/marketplace.md](design/marketplace.md) | the developer platform: build, deploy and sell games and content |
| 17 | [design/website.md](design/website.md) | kyotenengine.com: the site, subdomains, provisioning, deployment |
| 18 | [design/examples.md](design/examples.md) | the FPS and VR examples, and the first vertical slice they prove |

The marketplace comes late in the order because the engine is its first product, not because it matters less: it
decides what a "game" and a "content package" are when they are built, deployed and sold, and the engine's
packaging should be checked against it before it settles.

## Ground rules

- **The owner decides.** Bring the options, the evidence and a recommendation, then ask. A question the
  walk-through does not reach stays a question; it is not quietly answered in code.
- **Record every decision in the doc it settles**, under its "Decided" heading, with the reason and the date. A
  decision that creates work becomes a `KYR-<n>` row in [ROADMAP.md](ROADMAP.md) (take the id from its
  `Next id` counter and bump it).
- **Evidence over assertion.** A claim about kama is checked against the compiler, and a claim about a peer
  against its code. [research/](research/) has pointers; follow them before relying on them.
- **kama gaps go in [KAMA_GAPS.md](KAMA_GAPS.md)**, with a repro and the version. KY-1 is already there.

## What the spike should leave behind

- Every design doc's questions answered or explicitly deferred, with the reason.
- A ROADMAP whose first rows are the **first vertical slice**: the smallest thing that proves the frame model,
  the platform seam and the AI-facing project database together, running on web and native (see
  [design/examples.md](design/examples.md) for candidates), and where VR on Quest joins it.
- A decision on how the engine is split into packages, reflected in `kama_workspace.json`.

## Practicalities

- Built against kama **0.9.803** (`../kama`). On Windows, drive kama from msys2 UCRT64 (see kama's
  `docs/platforms/windows.md`).
- **Each example game is its own repository**, cloned as `games/<name>` (git-ignored here): `kyoten-fps` and
  `kyoten-vr`. With one present, `kama pkg install games/fps/kama.json` then `kama run games/fps/kama.json` prints
  `fps example, on kyoten`: everything is wired end to end, and nothing else is built.
- Two decisions are already made and recorded in [design/architecture.md](design/architecture.md) and
  [design/examples.md](design/examples.md): each example is its own repository, and the first two are the FPS and the
  VR (Meta Quest) examples.
- A web build needs emscripten. Whether this machine has it is in
  [research/kama-for-engines.md](research/kama-for-engines.md).
