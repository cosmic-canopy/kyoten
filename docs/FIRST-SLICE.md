# The first slice — kickoff brief

The design spike (KYR-1) ended on 2026-11-07, and what it decided is in [SPIKE.md](SPIKE.md) § What the spike decided.
This brief starts the build. **The goal is the gate:** slice A (A1, the hello cube, then A2, the level) and slice B,
after which a game can start on kyoten ([ROADMAP.md](ROADMAP.md) § NEXT). **The first milestone is A1, the hello cube.**

The rule from the spike still holds: **no engine code is written before the decision it depends on is recorded.** Where
a step meets a question no doc answers, bring the options and a recommendation to the owner, and record the answer in
the design doc it settles before building on it.

## Where it stands (2026-11-07)

- **kama:** this machine's binary is `0.9.873+g7c0a6bd0`, and kama's HEAD is `1e5099bb`. Never rebuild kama or edit
  `../kama`; check `--version` before quoting one.
- **Everything checks clean on it:** `engine/` (one placeholder, `version()`), `games/fps` (prints `fps example, on
  kyoten`), `games/vr`, and the three package repositories, `../kama-gpu`, `../kama-window` and `../kama-graphics`, each
  a seeded placeholder with nothing built.
- **Web builds** use emsdk 6.0.13. `emcc` is on the `PATH` only in an interactive UCRT64 shell (`bash -lic`).
- **Develop on `main`** (the owner, 2026-11-07: "you don't need to branch you can develop on main"). The local `main`
  was fast-forwarded to `spike/roadmap`, which holds the spike's history. The remote has only `spike/roadmap` so
  far, and pushing is the owner's call.

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

1. **`@kama/gpu`** (KYR-52, `../kama-gpu`). The design is kama's: `../kama/docs/ROADMAP_DETAIL.md` § 8
   (`s8-gpu-wrapper`, KR-25). Start from cosmic-forge's `render/src/gpu` device and `wgpugen`
   ([research/harvest.md](research/harvest.md) §§ 4–5). **Done:** a cleared surface in a window and in a canvas, RAII
   handles with no hand-written release, and an offscreen readback. No raw destroy in the safe API, and check
   `webgpu.h`'s lifetime rules for a resource released while the GPU still uses it (ai-first-api question 3).
2. **`@kama/window`** (KYR-51, `../kama-window`). The design is kama's: § 8 (`s8-input`, KR-26). Start from FFD's web
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
   question 3), since `importsOnly` does not reach std (KY-37).

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
- **Any conflict with kama's own designs** for `@kama/gpu` and `@kama/window` is kama's to rule: a gap goes in
  [KAMA_GAPS.md](KAMA_GAPS.md), and the design is not changed from here.

## kama gaps that touch the first slice

- **KY-28** (kama KR-338, "scheduled, design first"): generated code on a fresh clone. Step 5's wrapper covers it.
- **KY-6:** kama's wasm release does not run Closure. Until it does, measure the 150 KB with web-baseline's variant,
  `--closure=1` as an `ldflags` entry gated `ARCH_WASM32`, and record both numbers.
- **KY-37:** a module cannot be kept from std's modules, so kyoten's import check holds the simulation rule (step 6).
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
