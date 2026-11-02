# The design spike — kickoff brief

kyoten was seeded on 2026-11-01 to be designed **with** its owner, not for its owner. This brief is for the session
that runs the walk-through.

## The goal

Turn every draft under [design/](design/) from questions into decisions, with their reasons, and leave a
[ROADMAP.md](ROADMAP.md) whose rows are the work those decisions create. **The output is decisions, not code.** A
throwaway prototype is fine wherever a measurement would settle a question. Build it under `.scratch/` (gitignored)
or in a temporary directory, and record what it measured in the design doc it settles.

## Where it stands (2026-11-02)

**Start here.** The walk-through (KYR-1) has not begun. Open it at [design/architecture.md](design/architecture.md)
questions 1–4 and 7, and follow the [narrowed table](#narrowed-2026-11-01) from there. Nothing in the narrowed spike is
decided beyond what each doc's *Decided* already records.

- **The evidence rows are done** (2026-11-01). Each was checked against its sources before it was committed, and the
  design docs they feed point at them under *What already exists*:
  - KYR-2, [research/harvest.md](research/harvest.md): what to take from FFD, the-mallow-man and cosmic-forge, and what
    each piece assumes.
  - KYR-3, [research/component-models.md](research/component-models.md): Unity's phases and its peers, probes of
    kama, and three options for components.md.
  - KYR-5, [research/web-baseline.md](research/web-baseline.md): the web build's size, and what a WebGPU call costs
    from wasm.
  - Between them they filed KY-4 to KY-7 in [KAMA_GAPS.md](KAMA_GAPS.md).
- **KYR-4 is the owner's**: a Quest prototype in its own project. Nothing in the spike waits for it.
- **kama moved after the seeding.** It put Android for Quest (KR-280) in its NOW, and its Windows machine (this one)
  has claimed that and KR-279, KR-282 and KR-283 (kama `62322f93`, 2026-11-02). It ruled that XR is kyoten's, not a kama
  package, while `@kama/gpu` and `@kama/window` stay first-party packages that kyoten will be first to use
  ([design/architecture.md](design/architecture.md), [design/xr.md](design/xr.md) § Decided). Who builds those two is
  still architecture.md question 3.
- **The work is on the branch `spike/roadmap`**, not yet pushed or merged.

### What to read before each question

Each research doc ends in what it leaves open, naming the question it feeds. Read the evidence first, and re-check any
claim a recommendation rests on (each doc pins the commits and versions it read). Then bring the owner the options and
a recommendation, and record the answer in the doc's *Decided* as it is given. Commit once per doc, so a decision never
lives only in a conversation.

| Questions | Read first |
|---|---|
| architecture 1: how general, how soon | harvest § Summary; component-models § 1 (Unity grew by adding) and § 5.8 |
| architecture 2: the package split | harvest § The overview, and its *What this does not decide* 5 (copy, depend or publish) |
| architecture 3: kama's platform packages | harvest §§ 3–5 and *What this does not decide* 1; kama's `docs/ROADMAP_DETAIL.md` § 8 (`s8-gpu-wrapper`, `s8-input`) |
| frame-phases 1–3: the phases and their rates | harvest § 1 (FFD's `engine::phase`); component-models § 2 (flecs) and § Summary (rates) |
| frame-phases 5–7: parallelism | component-models § 4, probes 1–4, and KY-5; harvest *What this does not decide* 3 (the renderers' statics) |
| frame-phases 8, web-and-native 2: the web's threads | nothing measured yet (web-baseline § Not measured); recording costs land on whichever thread owns the device |
| components 1–8 | component-models § 5, one subsection per question, and § Options for the walk-through (A, B, C) |
| components 5, project-database 11: records and layers | component-models § Summary (overrides layer per property almost everywhere) and § 5.5 |
| replay 1, 2, 5 | KY-4; harvest *What this does not decide* 4, 6 and 8 (the input record, the ports' order, Jolt) |
| web-and-native 4: the size budget | web-baseline § What this means and § Candidate budgets. **The owner picks a number, a ratchet, or both** |
| web-and-native 6: the crossing cost | web-baseline § What this means, *For question 6* |
| target-platforms 1–4 | harvest § 3 (the peers' platform headers) |
| rendering 1: where it starts | harvest §§ 6–8 and *What this does not decide* 2 |
| rendering 2 and 5 | web-baseline § What this means, *For rendering.md* |
| rendering 3, ai-first-api 1: the hello cube | component-models § 2 (Three.js) and § 5.7 |
| examples 3: what "done" measures | web-baseline § Method, so a slice can repeat its measurements |

## Read first

1. [VISION.md](VISION.md): the owner's brief. Every design traces back to a line in it.
2. [research/peer-games.md](research/peer-games.md): what friendly-fire-department and the-mallow-man built,
   including **whether they used the Input / Update / Constraints / Output frame**, which is the owner's first
   question.
3. [research/kama-for-engines.md](research/kama-for-engines.md): what kama offers an engine today (threads,
   isolates, wasm, GPU and window packages, performance) and what kyoten has to build or wait for.
4. [research/cosmic-forge.md](research/cosmic-forge.md): the content-creation component kyoten consumes.
5. [research/harvest.md](research/harvest.md) (KYR-2), [research/component-models.md](research/component-models.md)
   (KYR-3) and [research/web-baseline.md](research/web-baseline.md) (KYR-5): the evidence gathered for the walk-through.
   The harvest corrects the earlier surveys where the code has moved (its § *Corrections*).

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

## Narrowed (2026-11-01)

**The owner, 2026-11-01: the spike decides only what the first slice needs. Every other question is roadmapped and
decided when its row comes up.** The reason: the first slice is what lets a game start on kyoten, and nothing else
blocks it; settling about 150 questions before any code would put the far-off ones (consoles, the DAW, the version
manager) ahead of the near ones. In the owner's words, the list "is likely a good place to start", and everything is
still roadmapped, so nothing is dropped ([ROADMAP.md](ROADMAP.md)).

**Widened the same day, by the owner: the design of the project database and wiki joins the spike**, though its build
stays after the first slice. A game that starts after slice B would otherwise be built before its wiki exists
([design/project-database.md](design/project-database.md) § Decided).

Walk the docs in this order. KYR-2, KYR-3 and KYR-5 gathered the evidence, KYR-4 is the owner's Quest prototype, and
KYR-1 is the walk-through itself.

| Doc | In the spike | The rest waits for |
|---|---|---|
| [architecture.md](design/architecture.md) | 1–4, 7 | 5–6: settled by the platform being a separate product (see its *Decided*); 8: KYR-37 |
| [frame-phases.md](design/frame-phases.md) | all, including 10 (a display clock the game does not own) | — |
| [components.md](design/components.md) | all, with 5 decided beside project-database.md | KYR-3 feeds it |
| [replay-and-determinism.md](design/replay-and-determinism.md) | 1–3, 5–6 | 4: KYR-27 |
| [project-database.md](design/project-database.md) | 1–6, 8, 11: the design (its build is KYR-24) | 7: KYR-26; 9: KYR-25; 10: KYR-29 |
| [web-and-native.md](design/web-and-native.md) | 1–6, 8 | 7: KYR-13 |
| [target-platforms.md](design/target-platforms.md) | 1–4, the extension model the platform seam is built on | 5–6: KYR-42; 7–9: KYR-43; 10: the roadmap's order; 11: KYR-13; 12–13: KYR-32, KYR-34 |
| [rendering.md](design/rendering.md) | 1–4 (with content-pipeline 5, forge's `render` package) | 5: KYR-22; 6: KYR-10; 7: KYR-26; 8: KYR-33; 9: KYR-49 |
| [ai-first-api.md](design/ai-first-api.md) | 1–3, because they shape the component API | 4: KYR-25; 5: KYR-23, KYR-41; 6: KYR-30; 7: KYR-14 |
| [examples.md](design/examples.md) | 1–3 | 4: KYR-29; 5: KYR-39, KYR-44; 6: KYR-40 |
| [xr.md](design/xr.md) | none decided here; the owner's Quest prototype, its own project, answers 1, 3 and 4 on a headset (KYR-4) | KYR-31 to KYR-33 |
| [networking.md](design/networking.md) | — | 1–4: KYR-18; 5–9: KYR-45 (the server) and KYR-44 |
| [human-tools.md](design/human-tools.md) | — | KYR-26, KYR-27 |
| [audio.md](design/audio.md) | — | 1–5, 7: KYR-15; 6: KYR-35 |
| [timeline.md](design/timeline.md) | — | KYR-36 |
| [content-pipeline.md](design/content-pipeline.md) | 5, with rendering 1 | the rest: KYR-29 |
| [version-manager.md](design/version-manager.md) | — | KYR-38 |
| [marketplace.md](design/marketplace.md) | — (the platform is a separate product, see its *Decided*) | 2, 3, 8: KYR-44; 1, 4–7: the platform product |
| [website.md](design/website.md) | — | KYR-39 |

## Ground rules

- **The owner decides.** Bring the options, the evidence and a recommendation, then ask. A question the
  walk-through does not reach stays a question; it is not quietly answered in code.
- **Record every decision in the doc it settles**, under its "Decided" heading, with the reason and the date. A
  decision that creates work becomes a `KYR-<n>` row in [ROADMAP.md](ROADMAP.md) (take the id from its
  `Next id` counter and bump it).
- **Evidence over assertion.** A claim about kama is checked against the compiler, and a claim about a peer
  against its code. [research/](research/) has pointers; follow them before relying on them.
- **kama gaps go in [KAMA_GAPS.md](KAMA_GAPS.md)**, with a repro and the version. KY-1 to KY-7 are there; take the
  next id from its counter.

## What the spike should leave behind

- Every question in the narrowed spike answered or explicitly deferred, with the reason. Every other question already
  has its roadmap row (above).
- A ROADMAP whose first rows are the **first vertical slice**: the smallest thing that proves the frame model and
  the platform seam together, running on web and native (see [design/examples.md](design/examples.md) for
  candidates). The AI-facing project database, designed in the spike, is built and joins it in slice C, and VR on Quest
  after it. *(Narrowed 2026-11-01:
  this asked for the project database in the first slice, and the roadmap now puts it in slice C, KYR-28.)*
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
- A web build needs emscripten. The Windows machine has emsdk 6.0.13 at `C:\Users\Matt\emsdk` (installed
  2026-11-01), and a kama program builds to wasm and runs under node there. Setting it up in a shell is in
  [../AGENTS.kyoten.md](../AGENTS.kyoten.md) § Build.
