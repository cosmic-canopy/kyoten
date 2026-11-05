# The design spike — kickoff brief

kyoten was seeded on 2026-11-01 to be designed **with** its owner, not for its owner. This brief is for the session
that runs the walk-through.

## The goal

Turn every draft under [design/](design/) from questions into decisions, with their reasons, and leave a
[ROADMAP.md](ROADMAP.md) whose rows are the work those decisions create. **The output is decisions, not code.** A
throwaway prototype is fine wherever a measurement would settle a question. Build it under `.scratch/` (gitignored)
or in a temporary directory, and record what it measured in the design doc it settles.

## Where it stands (2026-11-05)

**Start here.** The walk-through (KYR-1) began on 2026-11-02. Two docs are decided, and components.md has begun. Every
answer is recorded in its doc's *Decided*:

- **[design/architecture.md](design/architecture.md), its spike questions.**
  - **Questions 1–4.** Generic up front; one `kyoten` package with modules, plus a package for anything standalone or
    gated; kyoten builds `@kama/window` and `@kama/gpu` (KYR-51, KYR-52); and the game's `main` calls `run`.
  - **The libraries.** Each system sits on a general-purpose library, and the graphics one is a standalone package
    shaped like Three.js, `@kama/graphics`, which kama ruled first-party (KR-309, 2026-11-04).
  - **Question 2's module rule** (2026-11-04). A system never imports another system, so data moves between systems
    through components, in phase order. kama's `importsOnly` (0.9.842) now holds it, and KYR-53 checks the lists. The
    layer names waited for frame-phases question 1 and components question 1, and both are now decided (*To raise*).
  - **Question 7.** The directories are `editor/`, `server/` and `tools/`. `@kama/<noun>` is for a package that can
    exist outside kyoten, and `@kyoten/<noun>` for what is kyoten's own.
- **[design/frame-phases.md](design/frame-phases.md), all ten** (2026-11-04):
  - Input → Update → Constraints → Output in that order. Output is read-only and may feed Input through the record,
    and each Constraints subsystem has its own iteration count.
  - **One simulation clock.** Its base is derived from the subsystems' rates or pinned by the game, and each subsystem
    is handed its step. The display, audio, headset, network and OS input are outside clocks that meet it at Input's
    hand-off and Output's read. The defaults are [research/rates.md](research/rates.md)'s (KYR-55), lowered by
    measurement.
  - **Interpolation.** A component declares how it interpolates, and Output blends two timestamped samples.
  - **Parallelism.**
    - It comes from stated access: relative order, a no-conflict rule, group iteration and a visible schedule.
    - **It is proven by the compiler,** with an explicit opt-out the schedule shows. So components question 1 was
      between options A and B.
    - **It is serial by default, and switched on per group by measurement.** CI holds serial and parallel runs to one
      hash. The build decides whether threads exist, and start-up decides how they are used.
    - **On the web, a build is single-threaded by default.**
  - **Waits.** A wait is a deadline in simulation steps, held in each waiting subsystem's own queue. Designers'
    sequences come later (KYR-36).
  - **The headset** is one more frame source behind `run`.
- **[design/components.md](design/components.md), question 1** (2026-11-05): B built on A.
  - Records generate the world as plain kama, and the game writes system bodies whose signatures are their access.
  - Storage is a table per (zone, prefab) of fixed-size value chunks, allocated when the zone loads, plus side stores
    (sparse sets) for components gained at run time.
  - The chunk is the unit of parallel work, of a snapshot and of a budget. The generator fuses the systems of one
    table that do not conflict into one pass per chunk, because kama refuses two tasks on one table.
  - It was checked against its precedents (Unity Entities, gecs, Bevy, ecst) and probed on kama 0.9.845 and 0.9.850.
- **[design/components.md](design/components.md), question 2** (2026-11-05): a component is a plain value, and all four
  kinds of data are on day one: fixed data, bounded lists, shared read-only assets by handle, and owned per-entity data.
  A prefab with owned data gets a resource chunk, which still splits across workers and is snapshotted by `copy`. Each
  list states whether it refuses or spills when full. World data (voxels, terrain, destruction) is not a component; it
  lives in world stores of cells, and the owner added question 9 for them, with procedural generation.
- **[design/components.md](design/components.md), question 3** (2026-11-05):
  - **The vocabulary:** "system" is a function plus its record, render or audio is an "engine module", and
    "subsystem" is retired. frame-phases.md and architecture.md were reworded to it the same day, apart from quotes.
  - **A system's parts:** its record holds phase, group, order, rate and iterations, its signature is its access, and
    any state it keeps between steps is a singleton in the world.
  - **Reading other entities:** a system declares the previous step (the default, always parallel) or this step
    (ordered after the writers, with its writes staged when parallel). The scheduler never changes what a system sees.
  - **Queued structural changes,** applied at the end of the phase, sorted by chunk.
  - **Engine modules** are written the way a game's systems are, so the engine never names a game's world.
  - **The layers:** frame, world, engine modules, the agent surface. This also decides architecture's layer names.
  - **The model in one read** is now [REFERENCE.md](REFERENCE.md), and AGENTS.kyoten.md points agents at it.
- **[design/components.md](design/components.md), question 4** (2026-11-05): the engine promises the order for every
  game. Only the order results are joined in is fixed, not the order threads run in, so the promise is close to free;
  the costly kind, cross-platform, stays replay question 1's. Removal is swap-and-pop, randomness is keyed by seed,
  step, handle and purpose, and a combined result folds in chunk order. A `Map`'s order was probed identical natively
  and on wasm.
- **[design/components.md](design/components.md) question 5 with
  [design/project-database.md](design/project-database.md) question 11** (2026-11-05):
  - **Records and components:** a component is a kama type plus its record, and a record's format is the type, one to
    one through serde. Prefabs of one archetype share generated code, so data alone can add a prefab.
  - **Layers:** sources patch fields (RFC 7396, kama's merge). The order is data, with named content layers each holding
    any number of sources by priority, and a source may be files, a pack, a database or a URI where the platform allows.
  - **Checks and history:** checks run per source, then over the stack. The stack's identity is in every save, replay
    and match.
  - **Probed** on 0.9.854, which found KY-21. Mods with code are roadmapped as KYR-60: "code is content".

**Next, in order:**

1. **[design/components.md](design/components.md), questions 6–9.**
   - Its *What the vision asks* carries the per-zone budgets (input to question 6) and every game type.
   - **KYR-58 is done** ([research/game-types.md](research/game-types.md), 2026-11-04). It ran thirteen kinds of game
     on paper, and found none the decided frame model cannot express. Its fourteen conditions, G1–G14, are summarized
     under components.md's *What already exists*, by question.
   - Question 1's *Decided* lists what it leaves to each later question.
2. Then the rest of the [narrowed table](#narrowed-2026-11-01). **37 questions remain:** components 4 (6–9; question 9
   was added as question 2 was decided), replay-and-determinism 5, project-database 7, web-and-native 7,
   target-platforms 4, rendering 4, ai-first-api 3, examples 3. A few are taken together, so about 35 separate
   decisions. The owner asked for the count of questions left each time one is put to them.

**To raise with the owner:**

- **KYR-58's G1, at components question 6.** The owner agreed (2026-11-04) that where machines simulate together, a
  simulation budget matches, negotiated at matchmaking if needed. Still to confirm there: Output's budgets vary per
  machine, and one authority (a server or single player) may choose its own.
- **Audio and networking in the first slice?** The owner expects much of the initial work to be engine systems:
  audio, graphics, networking, input (2026-11-03). Input and graphics are in the first slice (KYR-8, KYR-9), while
  audio (KYR-15) and netcode (KYR-18) sit after the gate. Ask whether either moves up. cosmic-forge has meanwhile
  started audio's slice 1, sound effects, with music and ambience next
  ([research/cosmic-forge.md](research/cosmic-forge.md), the note at the top).
- **The gaps for kama, for the owner to relay** ([KAMA_GAPS.md](KAMA_GAPS.md)). These were pushed on 2026-11-04 so
  another kama machine can act on them:
  - KY-12, the job pool: its priority, running borrowing work, and no heap allocation per call;
  - KY-5, raised with it;
  - KY-13 to KY-15, filed on 0.9.845, and KY-17 and KY-18, filed on 0.9.850.

  kama closed KY-9, KY-10 and KY-11 the same day, and KY-16 in 0.9.849.

  **The KR-3 audit, done 2026-11-05 (KYR-59, [research/kr3-audit.md](research/kr3-audit.md)), is the whole list to
  relay.** kama's KR-3 row was waiting on it. kama ruled KY-5, KY-12, KY-13 and KY-15 the same day. The audit answers
  KR-326 (both shapes) and KR-327 (a per-build setting), and adds KY-19 (`reproducible-float` does not cover
  `std::math`). It also maps what each open question leans on in kama, so the gaps that depend on an answer are known
  in advance.

  **kama ported the audit the same day** (`b6847d37`): KY-18 is now KR-329 and KY-19 is KR-328. **Still to relay:**
  KY-20 (a `parallel_for` body reading the container it splits), which is not in kama's roadmap yet, and KY-21 (an
  overfull list reported as a type mismatch).
- **The three package repositories are seeded** (2026-11-03), beside kyoten: `../kama-gpu` (KYR-52), `../kama-window`
  (KYR-51) and `../kama-graphics` (KYR-9). Each was made with `kama seed` on 0.9.831 and laid out like `kama-sodium`,
  with `AGENTS.<name>.md`, `KAMA_GAPS.md`, `CHANGELOG.md` and registry metadata. Each passes `kama check` and `kama
  publish --dry-run`, and nothing is built. Each is pushed to `cosmic-canopy/kama-<name>` (2026-11-03), so a session
  on another machine clones it beside kyoten. Commit there on `main`, and push when the owner asks.
- **Is `@kyoten` reserved in the registry?** kama ruled that a maintainer's scope is reserved in the registry project,
  not the compiler. That is not visible from here: there is no `gh`, and the registry repo is not checked out.

**Standing direction:**

- **Tooling (2026-11-03).** Tooling works for AI first and is visible to humans, and UX is done as well as we can as
  each tool is built. cosmic-forge's tools and its CLI are references, but its UX is not a pattern
  ([design/human-tools.md](design/human-tools.md)).
- **Given 2026-11-04** ([VISION.md](VISION.md)):
  - web-first tools in kama, as cosmic-forge's are, which become the window onto the workflow;
  - errors at compile time, threading errors above all;
  - every game type, and the best engine;
  - budgets per element and per zone, with allocation up front or at least very controlled;
  - Output per platform over one simulation, and input as an abstraction with universal rebinding.
- **Given 2026-11-05: kyoten writes its own systems as it goes.** In the owner's words: "ideally we would write our
  own constraints system and UI systems, etc." and "we are building something unique here and do not want to be limited
  by existing designs. I assume it should be fine to use them for now but build our own as we go?" So Jolt (the
  peers' physics) and RmlUi (under `@kama/ui`, natively) may serve first, and kyoten replaces each with its own. *Proposed
  the same day, to confirm:* each system's interface is kyoten's from the start, designed from the decided frame, so a
  borrowed library sits behind it and leaving it changes no game.
  - **UI is the largest case of it** (the owner, the same day): "everything should ideally leverage best in class native
    web tech for web and have counterparts we build natively. The UI system is a BIG part of that. The web ( html and
    CSS3 ) is the best UI platform out there today IMHO and it saves a TON on native web." So a game's UI is HTML and
    CSS, the browser's own on the web, and natively a counterpart kyoten builds, with RmlUi at most a stopgap.
    web-and-native question 3 keeps what is left: whether a game's UI is the same HTML on both, and how much of HTML and
    CSS the native counterpart covers, in what order.
- **Given 2026-11-05: heavy assets are never stored with the code.** The owner: "We don't have to solve the full
  pipeline now... I just want to make sure we don't store all of the heavy stuff with the code." Three things are kept
  and moved apart, as studios do:
  - **code and records,** light text in git (the engine's repository and each game's);
  - **source assets,** authored and managed through cosmic-forge, in whatever store a team uses (git LFS, Perforce, a
    custom store);
  - **built runtime assets,** produced by asset builds, hosted, and downloaded to developer machines and players by a
    delivery tool.

  Code and a built asset set must agree on the contract that reads them (a record's schema, an asset format's
  version), so the delivery tool fetches the asset build that matches the code. It bears on content-pipeline question
  1, project-database questions 2 and 8, and examples question 4, and its build is KYR-29's. *Proposed, to settle at
  those questions:* a record refers to an asset by id and content hash, never by embedding it.

- **The evidence rows are done.** Each was checked against its sources before it was committed, and the design docs
  they feed point at them under *What already exists*:
  - KYR-2, [research/harvest.md](research/harvest.md): what to take from FFD, the-mallow-man and cosmic-forge, and what
    each piece assumes.
  - KYR-3, [research/component-models.md](research/component-models.md): Unity's phases and its peers, probes of
    kama, and three options for components.md.
  - KYR-5, [research/web-baseline.md](research/web-baseline.md): the web build's size, and what a WebGPU call costs
    from wasm.
  - KYR-55, [research/rates.md](research/rates.md) (2026-11-04): each subsystem's floor, and a default for any game.
  - KYR-58, [research/game-types.md](research/game-types.md) (2026-11-04): thirteen kinds of game against the decided
    model. It marks each claim by how it was checked (read, a search excerpt, or secondary), and lists the rest under
    *Not verified*.
- **KYR-4 is the owner's**: a Quest prototype in its own project. Frame-phases question 10 leaves its measurements to
  it.
- **kama moves fast beside this work.**
  - **Earlier:**
    - It ruled that XR is kyoten's, not a kama package.
    - `@kama/gpu` and `@kama/window` stay first-party packages, and kyoten builds them (KR-25, KR-26).
    - It shipped the Android target in 0.9.830 (KR-280), so KY-2 is narrowed to the app the launcher starts (KR-283).
  - **On 2026-11-04:**
    - KR-309 ruled `@kama/graphics` first-party.
    - `importsOnly` landed (KR-308, 0.9.842).
    - The agent guidance's exit-status clause was fixed (0.9.840).
  - **Check kama's log at the start of each session.**
- **The work is on the branch `spike/roadmap`**, pushed to `origin` after each decision so other machines can pick it
  up, and not merged.

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
| architecture 4: the engine/game boundary, how a game starts | kama's Android ruling: `main` stays the entry on every target, with the lifecycle as events (target-platforms.md § What already exists) |
| frame-phases 1–3: the phases and their rates | harvest § 1 (FFD's `engine::phase`); component-models § 2 (flecs) and § Summary (rates) |
| frame-phases 5–7: parallelism | component-models § 4, probes 1–4, and KY-5; harvest *What this does not decide* 3 (the renderers' statics) |
| frame-phases 8, web-and-native 2: the web's threads | nothing measured yet (web-baseline § Not measured); recording costs land on whichever thread owns the device |
| components 1–8 | research/game-types.md (KYR-58, the game types); component-models § 5, one subsection per question, and § Options for the walk-through (A and B, after frame-phases question 6) |
| components 5, project-database 11: records and layers | component-models § Summary (overrides layer per property almost everywhere) and § 5.5 |
| replay 1, 2, 5 | KY-4 (fixed in kama 0.9.809); harvest *What this does not decide* 4, 6 and 8 (the input record, the ports' order, Jolt) |
| web-and-native 4: the size budget | web-baseline § What this means and § Candidate budgets. **The owner picks a number, a ratchet, or both** |
| web-and-native 3: UI | the `kama-ui` and `kama-rmlui` packages, each in its own repository beside the other `kama-` packages (clone them); the owner's UI direction (*Standing direction*, 2026-11-05) |
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
| [rendering.md](design/rendering.md) | 1–4 (with content-pipeline 5, forge's `render` package) | 5: KYR-22; 6: KYR-10; 7: KYR-26; 8: KYR-33; 9: KYR-49; 10: KYR-50 |
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
- **kama gaps go in [KAMA_GAPS.md](KAMA_GAPS.md)**, with a repro and the version. KY-2, KY-3, KY-5, KY-6, KY-12 to KY-15 and
  KY-17 to KY-21 are open there; take the next id from its counter.

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

- Seeded on kama **0.9.803** (`../kama`), last re-checked on **0.9.839** (2026-11-04). kama rebuilds often, so run
  `--version` before quoting one. On Windows, drive kama from msys2 UCRT64 (see kama's `docs/platforms/windows.md`).
  `kama` is not on that shell's `PATH`: use `../kama/out/UCRT64-x86_64/kama.exe`.
- **An Android build** (`--target aarch64-linux-android29`) needs the NDK, which this machine has at
  `C:\Users\Matt\AppData\Local\Android\Sdk\ndk\30.0.16248370`. In a UCRT64 shell started by an agent's tool,
  `USERPROFILE` is empty, so kama's search of Android Studio's default SDK misses it. Set `ANDROID_NDK_HOME` to that
  directory for the command. The Android emulator and its `kama34` device are kama's: don't start them while a kama
  session is busy.
- **Each example game is its own repository**, cloned as `games/<name>` (git-ignored here): `kyoten-fps` and
  `kyoten-vr`. With one present, `kama pkg install games/fps/kama.json` then `kama run games/fps/kama.json` prints
  `fps example, on kyoten`: everything is wired end to end, and nothing else is built.
- Two decisions are already made and recorded in [design/architecture.md](design/architecture.md) and
  [design/examples.md](design/examples.md): each example is its own repository, and the first two are the FPS and the
  VR (Meta Quest) examples.
- A web build needs emscripten. The Windows machine has emsdk 6.0.13 at `C:\Users\Matt\emsdk` (installed
  2026-11-01), and a kama program builds to wasm and runs under node there. Setting it up in a shell is in
  [../AGENTS.kyoten.md](../AGENTS.kyoten.md) § Build.
