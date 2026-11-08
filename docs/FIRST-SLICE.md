# The first slice — kickoff brief

The design spike (KYR-1) ended on 2026-11-07, and what it decided is in [SPIKE.md](SPIKE.md) § What the spike decided.
This brief starts the build. **The goal is the gate:** slice A (A1, the hello cube, then A2, the level) and slice B,
after which a game can start on kyoten ([ROADMAP.md](ROADMAP.md) § NEXT). **The first milestone is A1, the hello cube.**

The rule from the spike still holds: **no engine code is written before the decision it depends on is recorded.** Where
a step meets a question no doc answers, bring the options and a recommendation to the owner, and record the answer in
the design doc it settles before building on it.

## Where it stands (2026-11-08, end of day)

**The next session starts here:**

1. **Check `../kama`'s log and `kama --version`** first. Then run `tools/test.sh` and both packages' `tools/test.sh`
   on that binary.
2. **Build step 5** (KYR-7, the component model and the generator). Its seven questions were answered on 2026-11-08
   (§ Questions the owner answers), so nothing it needs is undecided. Each part is test-first: the test seen to fail,
   then the code, `tools/test.sh` green, and a commit on `main`.
   1. **`kyoten::world`:** `Transform` (a zone as `int32` per axis, `position`, `rotation` and `scale` on `std::math`;
      `rotateY(by:)`, `offsetTo(other:, zoneSize:)`, `place(zone:, position:)`), the 8-byte `Handle` (slot and
      generation), and the chunk-size rule (16 KiB, at most 128 rows). Tests in `engine/tests/`. **Built on
      2026-11-08** ([design/components.md](design/components.md) § Decided, the last entry): the zone is a `ZoneCoord`,
      and KY-40 and KY-41 were filed on the way.
   2. **`kyoten::records`:** the fixed record types, read with kama's `JsonDeserializer.strict`, with refusals that
      name the field (``unknown field `app.titel` ``).
   3. **The `kyoten` tool** (`tools/kyoten/`, package `@kyoten/cli`, built with `-o kyoten`): the generator's first
      pass, which writes what comes from records alone (`Actions`, `Prefabs`, the prefab types); the header rule for
      clearing stale generated files; and `generate`, `check`, `build`, `run` and `clean` (KY-28). Tested on fixture
      games under `tools/kyoten/tests/`, and `tools/test.sh` gains the generator's leg.
   4. **Signatures, passes and the world:** the generator asks `kama query` for each processor's parameters, and
      `--def` for each type's declaration until KY-39 is answered; the second pass writes the passes, with rate gating
      at the base rate, and a world that implements `kyoten::frame::World`. A fixture game with a spinning entity and
      no render is generated, built and stepped through `step`, natively (debug and release) and on wasm, and its
      rotation checked exactly, then mutations caught, as step 4's were.
   5. **The loader:** a zone's placements and the prefab values become rows at start, through `RecordSource`, with the
      engine's default records in `engine/content/` (declared in the engine's `preloadFiles` for wasm). Under node,
      run a wasm program from its build folder, where emscripten looks for the `.data` file.
   6. **Step 6, KYR-53's check,** reads the manifests and the code records.
   - **In scope:** what the hello cube touches. Parameters `ref C` and `const ref C`, `ref W` and `const ref W`,
     `Handle` and `const ref Time`, with every other decided parameter refused as not built yet; `Digital` actions in
     `kyoten::input`; required components added with their defaults; the module `static` refusal; and the 32 KiB
     frame guard on every target but Windows (**built on 2026-11-08,** in the engine's manifest alone, which reaches
     every game: [design/components.md](design/components.md) § Decided, the last entry).
   - **Left to later rows:** side stores, `Previous` and `Current`, the queues, random keys, world stores, more than
     one zone or layer, the footprint report, fusing a table's processors into one pass, `PARALLEL`, and `Mesh`,
     `Material`, `Camera` and `Light` (step 9). The generated `run` is step 7's.
   - **The probes behind the answers** sit in `.scratch/step5-main` (the fence's layout, and the generator's two
     passes), `.scratch/step5-content` (content natively, under node and in Edge) and `.scratch/step5-cli` (the tool's
     package). Each is quoted where its decision is recorded.
3. **Also in that session, a docs change** (the owner, 2026-11-08): give the **asset manager** its own roadmap row
   (KYR-66) and design doc, split out of KYR-29. In the owner's words, it is "something that kyoten games can use to
   deliver final asset bundles", while cosmic-forge handles most of the raw content creation. Today it is only the
   "delivery tool" clause in KYR-29. Gather what already bears on it: the 2026-11-05 direction
   ([SPIKE.md](SPIKE.md) § Standing direction, heavy assets never stored with the code), packs
   (project-database question 8), KYR-10's web bundling, KYR-21's release bundles, marketplace questions 1 and 2
   (content packs), and the proposal that a record refers to an asset by id and content hash. Write its open
   questions, decide nothing, and bring the name to the owner, since the docs say "delivery tool".
4. **Meanwhile, Track 1,** in a session of its own: first the stopgaps each package's `AGENTS.*.md` lists, since they
   change the API, each fix test-first. In `@kama/gpu`, WebGPU's two steps (an adapter, then a device from it) come
   first, since the format choice and the request methods follow from them. Then `@kama/window`'s web half (W2: html5
   callbacks on `#canvas`, ported from FFD's `ffd_platform.h`, with Pointer Events), `@kama/gpu`'s canvas surface and
   a run in Edge (G6), gamepads (W3), and the triangle's pipeline set. A page served from localhost to headless Edge
   prints its console to stderr (`msedge --headless=new --enable-logging=stderr --dump-dom <url>`), as step 5's
   content probe ran.

**Every recommendation is the production answer,** or says plainly that it is a stopgap and what replaces it.

- **Built so far:**
  - **Step 4, the frame core** (2026-11-08, `54d2985` to `019b7aa`): `tools/test.sh` and `engine/tests/`, 51 cases
    natively, debug and release, and on wasm under node; `kyoten::frame`'s `Time`, `Clock` (exact in integer
    nanoseconds, its `TimeScale` a ratio), the `World` contract, and `step` and `frame`, generic over `World`. Its
    details are in [design/frame-phases.md](design/frame-phases.md) § Decided, question 3's *Built on 2026-11-08*.
  - **Step 6's question** is answered: the simulation rule is a module fence in `importsOnly`, with `core::env` on its
    list ([design/ai-first-api.md](design/ai-first-api.md) § Decided, question 3, item 5). Its check lands with step
    5's code records.
- **kama:** step 4 was built on `0.9.876+g1a969a1e` (KR-283 step 2).
  - **The binary now reports `0.9.876+g7ce86d36`,** built at 06:06 on 2026-11-08. kama then committed `92ad3d15` (a
    test-harness fix) and, a minute after the build, `5a83d422`, 0.9.877 (KR-283 step 3: Android Studio's JDK, and
    `kama seed --kind app` writing an app on `std::app`). The binary probably holds that work; its version string
    lags, as it did on 2026-11-07.
  - **The rule:** never rebuild kama or edit `../kama`, and check `--version` before quoting one.
  - **`std::app` runs an owned `App`:** `run(app: Owned<App>)`, where an `App` has `tick()` and `lifecycle(event:)`
    (`Resumed`, `Suspended`, `SurfaceReady`, `SurfaceLost`, `FocusGained`, `FocusLost`, `LowMemory`). Every host says
    `Resumed`, then `SurfaceReady`, before the first tick, so portable code opens its window and creates surfaces on
    `SurfaceReady`. kama's notes of 2026-11-08 (`../kama-notes-for-kyoten.md`) give each event per host.
    `../kama-gpu`'s tests run as an `App`, and step 7's platform seam is built on the same lifecycle.
- **Green on `0.9.876+g7ce86d36` (2026-11-08):**
  - kyoten's `tools/test.sh`: the engine and its 51 tests, `examples/games/fps` (it prints `fps example, on kyoten`
    natively and on wasm), and `examples/games/vr`;
  - `@kama/window`'s gate, 20 cases;
  - `@kama/gpu`'s gate: its cases, the clear example's 60 frames, the xfail, and the wasm build.
- **kama reviewed the packages (2026-11-08),** in `../kama-notes-for-kyoten.md`. It found a real bug: `@kama/window`'s
  ring counted events into a trailing `Dropped` record after the reader had made room, so a key up could be lost.
  It was reproduced by a new test, fixed, and the test kept. Its other points are in each package's departures.
- **The examples sit under `examples/`, by kind** (the owner, 2026-11-08, [design/examples.md](design/examples.md)
  § Decided): the games are `examples/games/fps`
  ([kyoten-example-fps](https://github.com/cosmic-canopy/kyoten-example-fps)) and `examples/games/vr`
  ([kyoten-example-vr](https://github.com/cosmic-canopy/kyoten-example-vr)), each its own repository, git-ignored
  here, depending on `../../../engine` by path. Both were moved, committed and pushed to their `main` on 2026-11-08.
- **Pushed on 2026-11-08:** kyoten's `main` (its remote's default branch is now `main`), both package repositories'
  `main`, and both example games' `main`.
- **Neither package is published yet.** kama's floor for a first publish is the `tests/` gate green on every target the
  package claims, and neither has run on the web. `@kama/window` also vendors GLFW first, and both fix their
  stopgaps first, since those change the API. Publish `@kama/window` first, once its web half runs and GLFW is
  vendored; that also ends every consumer naming it beside `@kama/gpu`. Then `@kama/gpu`, once a canvas clears in a
  browser.
- **The packages are standalone, held to production grade, and kyoten drives them** (the owner, 2026-11-08; § Questions
  the owner answers, below). kama's § 8 designs are where each started. Where a package departs from its design, its
  `AGENTS.*.md` § Where this departs from kama's design says how and why: kept as the production answer, or a stopgap
  with the production answer to build. The owner relays the departures to kama. These are not gaps: a compiler or std
  gap goes in the package's own gap file, and neither has one (`KGPU-`, `KWIN-`).
- **Track 1, step by step (2026-11-07),** each repository's `tools/test.sh` the gate and its `AGENTS.*.md` § Where
  things stand the detail:
  - `../kama-gpu` (step 1): the bindings generated from both legs' headers and held to them; a device, buffers,
    textures, a clear pass and a polled readback (an offscreen clear reads back exactly, native debug and release; the
    wasm leg builds); a surface on a window with a typed acquire, which `examples/clear` presents every frame (Windows).
    Not yet: the triangle's pipeline set, and any run on the web.
  - `../kama-window` (step 2): a native window (Windows) and a headless one, one coalescing queue with `Dropped(n)`,
    physical keys as HID ids (33 cases natively, 17 under node). Not yet: the web window, gamepads, vendored GLFW.
  - `../kama-graphics` (step 3): the seeded placeholder.
- **The wgpu-native SDK** (v29.0.1.1, as the peer games pin) is fetched into `../kama-gpu/third_party/` (git-ignored),
  and `KAMA_WGPU_DIR` points there for a native build. A program on `@kama/gpu` sets `"webgpu": true` and, until
  `@kama/window` is published, names `@kama/window` beside it (kama allows a path dependency only at the top level).
- **Web builds** use emsdk 6.0.13. `emcc` is on the `PATH` only in an interactive UCRT64 shell (`bash -lic`).
- **Develop on `main`** (the owner, 2026-11-07: "you don't need to branch you can develop on main"). Pushing is the
  owner's call each session.

## A1, the hello cube: what "done" means

The code it runs is [REFERENCE.md](REFERENCE.md) § The hello cube: a two-line `main` in the app's root module that
imports the `run` generated beside it, one component and one processor in a simulation module (`src/cube/`), and three
record files. It lives in `kyoten-example-fps` (`examples/games/fps`) as slice A's first milestone (examples question
2), and `kyoten new` writes it later (KYR-30).

**Done when** (examples question 3), each held by CI where it can be:

1. at most **20 non-blank lines** across its files, and eight concepts (app, record, scene, prefab, component,
   processor, action, player);
2. at most **150 KB of code on the web**: wasm plus JS, release, brotli -q 11, without the page shell or assets
   (web-and-native question 4);
3. **the same game code on web and native**, with no platform flag in it (target-platforms question 3);
4. **a headless readback sees the cube**, as cosmic-forge's `render` measures coverage and mean colour.

Every number is a ratchet once measured: CI fails when it gets worse, and loosening it is a decision with its reason.
Measure the way [research/web-baseline.md](research/web-baseline.md) § Method does, so the next slice can repeat it.

## The order of work: two tracks, then the join

The libraries and the engine's core do not depend on each other, so two agents can build them in parallel (the
owner's parallel agents, examples question 2). Each step ends with something that runs on web and on native (Windows
here), committed with what it measured.

**Track 1, the libraries.** Each is a general kama package in its own repository, named for no engine. Commit there on
`main`.

1. **`@kama/gpu`** (KYR-52, `../kama-gpu`). It starts from kama's design, `../kama/docs/ROADMAP_DETAIL.md` § 8
   (`s8-gpu-wrapper`, KR-25), and is held to production grade. Start from cosmic-forge's `render/src/gpu` device
   and `wgpugen` ([research/harvest.md](research/harvest.md) §§ 4–5). **Done:** a cleared surface in a window and in a canvas, RAII
   handles with no hand-written release, and an offscreen readback. No raw destroy in the safe API, and check
   `webgpu.h`'s lifetime rules for a resource released while the GPU still uses it (ai-first-api question 3).
2. **`@kama/window`** (KYR-51, `../kama-window`). It starts from kama's design, § 8 (`s8-input`, KR-26), and is held to
   production grade. Start from FFD's web
   platform header and the-mallow-man's native one (harvest § 3). **A1 needs** one window or canvas, physical keys, a
   gamepad, and a headless window for tests.
3. **`@kama/graphics`** (KYR-9, `../kama-graphics`). Start from cosmic-forge's `render` (rendering question 1), with
   Three.js as the API's reference (SPIKE's standing direction, 2026-11-07). **A1 needs** a box mesh, the standard lit
   material, a camera, and a directional light with ambient light, drawn into the window. Shaders are WGSL, with WESL
   for imports (rendering, how shaders are written).

**Track 2, the engine's core** (`engine/`, the `kyoten` package).

4. **The frame core** (KYR-6): Input, Update, Constraints and Output; the fixed-step clock; the `Time` world component;
   serial; the root `tools/test.sh` and `engine/tests/` first. All decided (frame-phases § Decided, step 4 questions 1
   to 4, 2026-11-08). The world hash and the input log come with slice B. **Built on 2026-11-08** (§ Where it stands).
5. **The component model and the generator** (KYR-7): records read strictly from JSON; the generated world, tables and
   `Actions`; `Transform`. Generated files are never committed. Its questions were answered on 2026-11-08 (below), and
   the generated `run` moved to step 7.
   **KY-28 bites here:** until kama's KR-338, `kama check` fails on a fresh clone whose sources import generated code,
   so the generator runs before every kama command, behind a `kyoten` command.
6. **The import check** (KYR-53) lands with step 5's code records. **Decided on 2026-11-08:** the simulation rule
   (ai-first-api question 3) is a module fence in `importsOnly`, with `core::env` added. The check reads the manifests
   and the code records, covers games too, and reads source only for the OS-flag refusal.

**The join.**

7. **The platform seam** (KYR-8): the `Platform` contract, the open platforms chosen by `@compileFor`, on
   `@kama/window`, and the generated `run` a game's `main` calls (target-platforms question 2; moved from step 5 on
   2026-11-08). The web's single-threaded build first (web-and-native question 2).
8. **Input** (KYR-54): actions of every kind (step 5 builds `Digital`), bindings records, player 1 on the keyboard and
   the first gamepad, and the binding steps over values and over time.
9. **The render module** (KYR-9's kyoten half): Output extracts `Mesh`, `Material`, `Camera`, `Light` and
   `Environment` into `@kama/graphics` once a frame (rendering question 4), and the engine's default records supply the
   camera, the light and the material (rendering question 3).
10. **The hello cube in `kyoten-example-fps`** (KYR-14): its files as REFERENCE has them, and the four checks
    measured, then held in CI (KYR-13's first legs).

## Questions the owner answers when a step reaches them

- **Answered on 2026-11-07:** the generator is written in kama, a `kyoten` executable under `tools/` (components.md
  § Decided); and the reference machines are the owner's Steam Deck, Windows mini PC, Mac Mini, a mid-range laptop
  and Quest 3 (examples.md § Decided), each named beside the first numbers measured on it.
- **Answered on 2026-11-08, step 4's four questions** ([design/frame-phases.md](design/frame-phases.md) § Decided):
  1. **Where the frame tier lives:** each tier is a module, and the frame tier is `kyoten::frame`; a game imports
     `kyoten::frame::Time` and `kyoten::world::Transform`, since kama has no re-exports.
  2. **`Time`:** `float32 dt` and `int64 step`, the base clock's index; each processor gets its own rate's `dt`, and
     there is no elapsed-seconds float.
  3. **The clock:** exact in integer nanoseconds, at most 5 owed steps a frame with the discards counted, and pause,
     slow motion, fast forward and single stepping by scaling real time, so a step's `dt` never changes.
  4. **What step 4 builds:** the suite first (`tools/test.sh`, `engine/tests/`); then the `World` contract, the clock
     and a serial driver (`frame` and `step`) generic over `World`, with the world and the clock injected; and
     `reproducible-float` with musl's notice. Rate gating, `run`, Input's hand-off, waits, the RNG and `PARALLEL`
     wait for their own steps.
- **Answered on 2026-11-08, while step 4 was built: the time scale is a ratio** (`TimeScale`, `num/den`), so the
  clock stays exact at every scale. A `float64` was considered (frame-phases § Decided, question 3).
- **Answered on 2026-11-08, step 6's question** (KYR-53): the simulation rule moves into `importsOnly` as a module
  fence, and `core::env` joins the list ([design/ai-first-api.md](design/ai-first-api.md) § Decided, question 3,
  item 5).
- **Answered on 2026-11-08, step 5's seven questions** (KYR-7; the owner: "Everything sounds good so far with my notes
  above"). Each was probed on kama `0.9.876+g7ce86d36` and is recorded with its reason where it settles:
  1. **`main` sits in the app's root module, outside the simulation's fence,** with the generated `run` beside it
     (`src/<game>.generated.kama`, so `main` reads `import { run };`), and simulation code in module folders: the hello
     cube's in `src/cube/`. `<game>::generated` is fenced ([design/ai-first-api.md](design/ai-first-api.md) § Decided,
     question 3). The owner asked whether the generator could write `main` instead: nothing is wrong with it, but the
     game owns `main` and calls `run` (architecture question 4), so it was considered and set aside.
  2. **The generated `run` is built at step 7,** with the `Platform` contract; step 5 ends at a generated world that
     tests drive through `step` and `frame` ([design/components.md](design/components.md) § Decided, 2026-11-08).
  3. **Content reaches a running build through a `RecordSource`:** folders read from disk natively, kama's
     `preloadFiles` on wasm (one `.data` fetch, not counted as code), the engine's defaults in `engine/content/`, and
     packs when a game ships ([design/project-database.md](design/project-database.md) § Decided, 2026-11-08).
  4. **The fixed record types are one module, `kyoten::records`,** read by the loader and the tool alike (components
     § Decided).
  5. **The tool is the package `@kyoten/cli`, in `tools/kyoten/`, built as `kyoten`.** The owner asked why a package
     and not a module: it is a program with its own `main`, the engine is a library with none, and the tool imports
     the engine, never the reverse ([design/architecture.md](design/architecture.md) § Decided, 2026-11-08).
  6. **The action kinds are `Digital`, `Analog`, `Vector2`, `Vector3`, `Pose` and `Text`** (the table below), brought
     forward from step 8 because step 5 generates `Actions`; step 5 builds `Digital` (components § Decided).
  7. **The default budget is one chunk per (zone, layer, prefab),** reserved up front and refusing when full
     (components § Decided).
- **Step 8: the action kinds,** decided on 2026-11-08 as suggested (above, question 6). The owner had asked: "Button
  and Axis are ok to start I think... but I would prefer something maybe more general? If you have any suggestions."
  *Suggested* (2026-11-07), named for the value a processor reads rather than for a device, so one kind serves a key,
  a stick, a touch, a hand in VR, a UI button and an agent:

  | Kind | What a processor reads | Bound from, for example |
  |---|---|---|
  | `Digital` | on or off, with `held`, `pressed` and `released` | a key, a button, a trigger past a threshold, a UI button |
  | `Analog` | one number | a trigger, a mouse wheel, one axis of a stick, two keys as −1 and +1 |
  | `Vector2` | two numbers, a `Vec2` | a stick, the mouse's movement, WASD, a touch drag |
  | `Vector3` | three numbers, a `Vec3` | a 3D mouse, a device's motion sensor |
  | `Pose` | a position and a rotation | a tracked hand, controller or head |
  | `Text` | typed text | a keyboard, an on-screen keyboard, a UI field |

  OpenXR's action types are the same idea (`XR_ACTION_TYPE_BOOLEAN_INPUT`, `FLOAT_INPUT`, `VECTOR2F_INPUT`,
  `POSE_INPUT`; read in `openxr.h`, 2026-11-07), as are Bevy's leafwing-input-manager (`Button`, `Axis`, `DualAxis`,
  `TripleAxis`; read in its `lib.rs`) and, from memory, Unreal's Enhanced Input (Digital, Axis1D, Axis2D, Axis3D) and
  Steam Input's digital and analog actions. Adapters (KYR-54) turn one kind into another: four `Digital` keys into a
  `Vector2`, an `Analog` trigger into a `Digital` past a threshold. The hello cube's record says `"Digital"`.
- **Step 8, also: input over time, and a better word than "adapter".** The owner's direction (2026-11-07,
  [design/components.md](design/components.md) § Decided): gestures and presses over time (a tap, a double tap, a
  hold, a sequence, a swipe), values adapted (a `Digital` as a float from X to Y), and sensors normalized (the
  accelerometer). They run before Input's hand-off, timed by the events' own timestamps, and the hand-off records
  the action they produce. kama already has `type adapter`, so *suggested:* a **filter** reshapes each value and a
  **gesture** recognizes a pattern over time. The hello cube needs neither, so A1 does not wait on the words.
- **`@kama/gpu` and `@kama/window` are standalone packages held to production grade, and kyoten drives them.** The
  owner, 2026-11-08: "kama gpu and window are two official kama packages but they are stand alone like any package.
  The bar is production grade general solutions. In this case kyoten is the first consumer so you are able to help
  drive what production grade general solution means. I will relay to kama as well just in case."
  - kama's § 8 design is where each starts. A departure the production bar needs is made in the package, with its
    reason, in its `AGENTS.*.md`, and the owner relays it to kama.
  - Each stays general: it names no engine, and serves a tool or an editor as well as a game.
  - A compiler or std gap still goes in the package's own gap file, with its repro.

## kama gaps that touch the first slice

- **KY-28** (kama KR-338, "scheduled, design first"): generated code on a fresh clone. Step 5's wrapper covers it.
- **KY-6:** kama's wasm release does not run Closure. Until it does, measure the 150 KB with web-baseline's variant,
  `--closure=1` as an `ldflags` entry gated `ARCH_WASM32`, and record both numbers.
- **Fixed on 2026-11-07 and removed:** KY-37 (kama KR-344, `546dd54e`): a module's `importsOnly` now lists std's,
  `core`'s and other packages' modules too, and the command line and the environment moved to `core::env`. Step 6
  made the simulation rule a module fence on it (2026-11-08).
- **KY-38** (filed 2026-11-08, worked around): kama's `docs/targets.md` names only musl's licence as the notice
  `reproducible-float` brings, while the code it compiles in also carries Sun's and Arm's notices.
  `engine/THIRD-PARTY-NOTICES.md` carries all of them.
- **KY-2:** kama's `1e5099bb` (KR-283 step 1) builds an installable Android APK. It is not in this machine's binary,
  so re-check KY-2 on a build that has it. VR follows the gate.
- **Fixed on 2026-11-07 and removed:** KY-19, so `reproducible-float` now gives `std::math` the same bits natively and
  on wasm, which slice B's cross-platform hash needs; and KY-36.

## Practice

- **Read [REFERENCE.md](REFERENCE.md) first,** and use its words: a processor, a module, a tier, a scene's layer. Its
  § One way to do each thing is the API's rule.
- **Verify, don't trust.** Compile it, run it, read the emitted C, and record what was measured where it is decided.
- **kama runs in UCRT64:** `MSYSTEM=UCRT64 /c/msys64/usr/bin/bash.exe -lc '../kama/out/UCRT64-x86_64/kama.exe …'`, or
  `-lic` for `emcc`. **git runs from Git Bash.**
- **A decision goes in its design doc's *Decided*** with its reason, and the work it creates becomes a roadmap row.
- **Test-driven, with injected dependencies** (AGENTS.kyoten.md § Rules, the owner, 2026-11-08). The test comes
  first and is seen to fail, a bug's fix starts with the test that reproduces it, and the full suite passes before
  every commit. Code takes what it depends on as a parameter or a contract, so a test hands it a fake.
- **Commit each step on `main`,** with the Co-Authored-By line; push when the owner says.
