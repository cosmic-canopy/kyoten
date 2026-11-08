# The first slice — kickoff brief

The design spike (KYR-1) ended on 2026-11-07, and what it decided is in [SPIKE.md](SPIKE.md) § What the spike decided.
This brief starts the build. **The goal is the gate:** slice A (A1, the hello cube, then A2, the level) and slice B,
after which a game can start on kyoten ([ROADMAP.md](ROADMAP.md) § NEXT). **The first milestone is A1, the hello cube.**

The rule from the spike still holds: **no engine code is written before the decision it depends on is recorded.** Where
a step meets a question no doc answers, bring the options and a recommendation to the owner, and record the answer in
the design doc it settles before building on it.

## Where it stands (2026-11-08)

**The next session starts here:**

1. **Check `../kama`'s log and `kama --version`** first: kama's working tree is changing `std::app` (below).
2. **Ask step 4's question 3 of 4,** then 4, one at a time, each with how many remain (§ Questions the owner answers,
   below), and record each answer in [design/frame-phases.md](design/frame-phases.md) § Decided. Step 4's code starts
   once all four are recorded (the owner, 2026-11-07). Questions 1 and 2 were decided on 2026-11-08: each tier is a
   module, the frame tier `kyoten::frame`; and `Time` is `float32 dt` and `int64 step`, each processor getting its own
   rate's `dt`. **Every recommendation is the production answer,** or says plainly that it is not (the owner asks).
3. **Meanwhile, Track 1:** first the stopgaps each package's `AGENTS.*.md` lists, since they change the API. Then
   `@kama/window`'s web half (W2: html5 callbacks on `#canvas`, ported from FFD's `ffd_platform.h`), `@kama/gpu`'s
   canvas surface and a run in Edge (G6), gamepads (W3), and the triangle's pipeline set.

- **kama:** this machine's binary reports `0.9.876+g546dd54e`. kama's HEAD is `546dd54e` (0.9.875, KR-344), and the
  binary was built from kama's working tree, which holds uncommitted KR-283 work. Never rebuild kama or edit
  `../kama`; check `--version` before quoting one.
  - **That work replaces `std::app`'s loop.** `run(tick:, state:)` and `TickFn` give way to `run(app: Owned<App>)`,
    where an `App` has `tick()` and `lifecycle(event:)`: `Resumed`, `Suspended`, `SurfaceReady`, `SurfaceLost`,
    `FocusGained`, `FocusLost`, `LowMemory`.
  - On this binary, `../kama-gpu`'s test program no longer compiles. It passed on 0.9.874, and stays on the
    committed API until kama commits the change. **When it lands:** port `kama-gpu/tests`, and build step 7's
    platform seam and the GPU surface's lifetime on the `App` lifecycle (a surface is dropped on `SurfaceLost`).
- **Checks clean on 0.9.876 (2026-11-08):** `engine/` (one placeholder, `version()`), `games/fps` (prints `fps
  example, on kyoten`), `games/vr`, and `@kama/window`'s gate. `@kama/gpu`'s gate passes everything except its test
  program (above): the bindings, the 60-frame window and the xfail.
- **Pushed on 2026-11-08:** kyoten's `main` and both package repositories' `main`. The remote's default branch is still
  `spike/roadmap`; making it `main` is the owner's change on GitHub.
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
- **Develop on `main`** (the owner, 2026-11-07: "you don't need to branch you can develop on main"). The local `main`
  was fast-forwarded to `spike/roadmap`, which holds the spike's history. Pushing is the owner's call each session.

## A1, the hello cube: what "done" means

The code it runs is [REFERENCE.md](REFERENCE.md) § The hello cube: a two-line `main` that imports `run` from the game's
generated module, one component and one processor, and three record files. It lives in `kyoten-fps` (`games/fps`) as
slice A's first milestone (examples question 2), and `kyoten new` writes it later (KYR-30).

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
   serial. The world hash and the input log come with slice B.
5. **The component model and the generator** (KYR-7): records read strictly from JSON; the generated world, tables and
   `Actions`; `Transform`; and the generated `run` (target-platforms question 2). Generated files are never committed.
   **KY-28 bites here:** until kama's KR-338, `kama check` fails on a fresh clone whose sources import generated code,
   so the generator runs before every kama command, behind a `kyoten` command.
6. **The import check** (KYR-53) lands when the engine has a second module, with the simulation-files rule (ai-first-api
   question 3). KY-37 was fixed on 2026-11-07 (kama KR-344): `importsOnly` now reaches std, `core` and other
   packages, so whether that rule moves from kyoten's per-file check into the modules' manifests is asked when this
   step starts.

**The join.**

7. **The platform seam** (KYR-8): the `Platform` contract, the open platforms chosen by `@compileFor`, on
   `@kama/window`. The web's single-threaded build first (web-and-native question 2).
8. **Input** (KYR-54): actions, bindings records, player 1 on the keyboard and the first gamepad.
9. **The render module** (KYR-9's kyoten half): Output extracts `Mesh`, `Material`, `Camera`, `Light` and
   `Environment` into `@kama/graphics` once a frame (rendering question 4), and the engine's default records supply the
   camera, the light and the material (rendering question 3).
10. **The hello cube in `kyoten-fps`** (KYR-14): its files as REFERENCE has them, and the four checks measured, then
    held in CI (KYR-13's first legs).

## Questions the owner answers when a step reaches them

- **Answered on 2026-11-07:** the generator is written in kama, a `kyoten` executable under `tools/` (components.md
  § Decided); and the reference machines are the owner's Steam Deck, Windows mini PC, Mac Mini, a mid-range laptop
  and Quest 3 (examples.md § Decided), each named beside the first numbers measured on it.
- **Step 4: the frame core's four questions,** asked one at a time from 2026-11-07, each recorded in
  [design/frame-phases.md](design/frame-phases.md) § Decided. **1, where the frame tier lives:** decided on
  2026-11-08, each tier a module and the frame tier `kyoten::frame`. **2, `Time`'s shape:** decided on 2026-11-08,
  `float32 dt` and `int64 step`, the base clock's index, with each processor getting its own rate's `dt`.
  *Recommended* for the two left, each the production answer, for the owner to decide:
  3. **The clock:** kyoten's own, after FFD's `PhaseClock` (`engine/src/phase/clock.kama`, credited), which keeps a
     `float64` seconds accumulator and an `isize` tick. Changed for production:
     - **Exact, in integers.** It takes the frame source's time as an `int64` count of nanoseconds (rAF, vsync and
       XR's predicted display time each supply one), and its accumulator counts nanoseconds times the base rate. A
       step is then exactly 1/rate seconds, the clock never drifts, and a test that feeds it nanoseconds gets exact
       step counts. FFD's tick is an `isize`, 32 bits on wasm; this one is `Time`'s `int64` step.
     - **It owes nothing for time that runs backwards or stands still** (FFD's rule: an NTP step, a resumed laptop).
     - **The cap stays at 5 owed steps a frame** (FFD's `maxStepsPerAdvance`): the excess is discarded and counted in
       an `int64`, the engine's default, and an App record field when a game needs another.
     - **Pause and a time scale:** real time is scaled before it is owed, and a scale of 0 pauses. A step's `dt`
       never changes, so slow motion stays deterministic and a replay is unaffected. Unity's `timeScale` and Bevy's
       virtual time (`pause`, `relative_speed`) work the same way.
     - **It returns** the owed base steps and the render time, the last step plus a fraction, for Output's blend.
     - **The base rate is an input:** the least common multiple the generator derives, or a pinned base (step 5).
     - **It stays off the deterministic path:** a replay or a test drives steps directly and builds no clock, as in
       FFD.
  4. **Step 4's scope:**
     - the `World` contract's four phase calls, each taking `const ref Time`;
     - rate gating and Constraints' iterations inside the generated passes (step 5), so the frame core only orders
       the phases;
     - a public serial `stepFrame` for tests and a headless server, with the loop-owning `run` at step 7 (on
       `std::app`'s `App` once kama commits it);
     - `"reproducible-float": true` and musl's notice now;
     - waits, the RNG world component and the `PARALLEL` flag when something needs them, and Input's hand-off an
       empty call until step 8.
- **Step 8: the action kinds.** The owner: "Button and Axis are ok to start I think... but I would prefer something
  maybe more general? If you have any suggestions." *Suggested* (2026-11-07), named for the value a processor reads
  rather than for a device, so one kind serves a key, a stick, a touch, a hand in VR, a UI button and an agent:

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
  `Vector2`, an `Analog` trigger into a `Digital` past a threshold. The owner chooses these names or Button and Axis
  when step 8 starts; the hello cube's record says `"Button"` until then.
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
  asks what that changes for the simulation rule.
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
- **Commit each step on `main`,** with the Co-Authored-By line; push when the owner says.
