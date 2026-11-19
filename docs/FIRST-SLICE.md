# The first slice — kickoff brief

The design spike (KYR-1) ended on 2026-11-07, and what it decided is in [SPIKE.md](SPIKE.md) § What the spike decided.
This brief starts the build. **The goal is the gate:** slice A (A1, the hello cube, then A2, the level) and slice B,
after which a game can start on kyoten ([ROADMAP.md](ROADMAP.md) § NEXT). **The first milestone is A1, the hello cube.**

The rule from the spike still holds: **no engine code is written before the decision it depends on is recorded.** Where
a step meets a question no doc answers, bring the options and a recommendation to the owner, and record the answer in
the design doc it settles before building on it.

## Where it stands (2026-11-18, the thirty-sixth session)

**Track 2 is built through step 6** (KYR-6, KYR-7 and KYR-53):
- records generate the world, and the loader reads content into it;
- the tool checks both at build;
- the tool holds every module's list to the simulation's fence, the engine's tiers and the platform rule.

**Track 1 is under way, and each package keeps its own order** (`SPEC.md`, `ROADMAP.md`, its detail, and for
`@kama/gpu` `COVERAGE.md`, 96 of webgpu.h's 206 functions called):
- GPU-1, GPU-2 and GPU-13, WIN-1, WIN-2 and WIN-16 are built (the ninth to eleventh sessions, below);
- WIN-3 is built, the web leg's first row: a window on the page's canvas, and Pointer Events on every backend (the
  twelfth session, below);
- **GPU-3 is built, so both packages run in a browser** (the thirteenth session, below): `@kama/gpu`'s tests and its
  clear example run in headless Chrome for Testing and Edge on a canvas, where WebGPU ran here for the first time, and
  WIN-20, a window's size through its handle, was built for it;
- **WIN-21 is built** (the fourteenth session, below): under `sizedByPage`, `open` refuses a canvas the page sizes on
  neither axis;
- **WIN-4 is built** (the fifteenth session, below): gamepads, through the browser's Gamepad API on the web and SDL3,
  vendored, natively on Windows;
- **WIN-18 is built** (the sixteenth session, below): both packages' browser legs run under `kama run --target WASM` in
  Edge and Firefox 160, and through each package's driver in the pinned Chrome for Testing, which keeps every case;
- **GPU-4 is decided and under way, and GPU-14 is built** (the seventeenth session, below): its questions answered,
  shader modules and their compilation messages built as its first part, and Firefox's three differences from Dawn
  fixed once headless Firefox was given WebGPU;
- **GPU-4's second part is built** (the eighteenth session, below), with four more decisions: typed flag sets, buffers
  and samplers by description, layouts, bind groups and `writeBuffer`. **Nothing a program passes to `@kama/gpu` ends
  it any more** (decision 9): every misuse is a validation error on both legs. `@kama/window`'s scale cases run under
  `kama run`.
- **GPU-4's third part is built** (the nineteenth session, below): render pipelines both ways, from WebGPU's
  description, drawn and read back, the asynchronous ones compiled natively on the package's own isolates;
  `DeviceOptions.printErrors`; and, found by its probe, a texture format whose feature the device lacks refused
  everywhere. Question 10, what wgpu-native takes that WebGPU refuses, is decided and built (decision 10), and Firefox
  runs every case in the gate since the pin moved to 0.9.940 with KY-54's fix.
- **GPU-4's fourth part is built** (the twentieth session, below):
  - its probe found that every pass error lands at `finish`, and that emdawnwebgpu's NaN depth clear value ends a web
    program;
  - the owner decided questions 11 to 14 as recommended;
  - textures, views and the pass by description are built, and the pass's eight commands.
- **GPU-4 is built** (the twenty-first session, below): its fifth and last part, `examples/triangle`, draws through a
  vertex buffer, an index buffer and a bind group on every leg, and reads its last frame back from its window, as the
  owner decided (decision 15).
- **GPU-15 is built** (the twenty-second session, below): the fallback adapter, a software GPU on every leg that has
  one, for `@kama/graphics`' byte-for-byte goldens. Found on the way and fixed: natively a lost device's next submit or
  map no longer ends the program.
- **`queue.writeTexture` is built** (the thirtieth session, below; kama-gpu `27760aa`, its AGENTS.gpu.md item 14), brought
  forward from GPU-8 at the owner's word for `@kama/graphics`' DFG table, by WebGPU's full description.
- **GPU-16, DXC natively on Windows, is built** (the thirty-fifth session, below; kama-gpu `b123a03`, its item 16):
  Microsoft's `dxcompiler.dll`, fetched pinned by `tools/fetch-dxc.sh` and never committed, and one line printed when
  Direct3D 12 falls back to FXC.

  No question is open in either package.
- **`@kama/image` is seeded** (the twenty-second session, `../kama-image`, KYR-77): image codecs, PNG first, a package
  of its own, as the owner decided for `@kama/graphics`' goldens, pushed to `cosmic-canopy/kama-image` once the owner
  added it. **Its five design questions are measured** (the twenty-third session, its `RESEARCH.md`, kama-image
  `ffcbb22`). Four are decided (its `AGENTS.image.md` § Decided, `3c8a8b8`), and its `ROADMAP.md` is written, PNG
  decoding first (IMG-1). The first was confirmed the same day: kama's PNG codec on every leg (kama-image `fc1d108`).
  **IMG-1, PNG decoding, is built** (kama-image `2f0e87c` to `a18a3f3`, the twenty-third session):
  - the `Image` type, with `convert(to:)`;
  - every colour type and bit depth, an APNG's default image, and the colour chunks by the PNG Third Edition's
    precedence;
  - `keepGrey` and `partial`;
  - held to libpng on PngSuite and 28 crafted files, 470 cases natively and on wasm;
  - a flip-and-cut sweep of 1.3 million decodes in its gate.

  **IMG-2, PNG encoding, is built, so PNG is whole** (kama-image `9f704e9` to `8575bb8`, the twenty-fourth session):
  - `encode` with `standard()` and `archival()`, libpng's adaptive filter and the five fixed ones, and IDAT chunks of
    65,536 bytes;
  - the colour chunks, written so a file decodes back to the image's colour space with everything it carries;
  - the same bytes on every leg, held by the gate, and `archival()`'s written down;
  - libpng reads all 254 files it writes from the fixtures with no warning;
  - 1,401 cases natively and on wasm.

  Its six details were settled under the owner's word on decision 4 (kama-image's `AGENTS.image.md` § Decided 4).
  Reading libpng's writer found two places the decoder kept chunks other than as libpng does, now fixed.
- **Audio started on the Mac Mini** (the nineteenth session): `@kama/audio`, seeded in `../kama-audio` and pushed, is
  designed and built there in parallel, from its `AGENTS.audio.md` ([design/audio.md](design/audio.md) § Decided).

**The join waits on Track 1. Where the work is:**

1. **At a session's start, run the suites on kyoten's pin, `0.9.978+g5e542c55`** (`.kama-pin/`, through `tools/kama`;
   AGENTS.kyoten.md § Build): `tools/test.sh`, then the packages' `tools/test.sh` with `KAMA` set to the pin: `@kama/window`'s,
   `@kama/gpu`'s, `@kama/image`'s and `@kama/graphics`'. Their browser legs run under `kama run` in Edge, the pinned
   Firefox 160 and, in `@kama/gpu` and `@kama/graphics`, the pinned Chrome for Testing 157.0.8103.50 with its own flags;
   `@kama/window`'s runs that one through its driver (`~/browsers`, its `README.md`). **Every leg runs a debug build and a
   release build** since the thirty-second session (rendering.md § Decided, 2026-11-17), so each count below is held
   twice on each leg. The closing counts, on 0.9.978:
   - tools/test.sh: engine 164 native and on wasm, each debug and release; the frame guard, on wasm in both builds;
     the tool's 211; kyoten check; fps native, and on wasm in both builds; vr checked;
   - `@kama/window`'s: 249, 163 under node, 253 in Edge and Firefox, 264 through the driver;
   - `@kama/gpu`'s: 340 natively, debug, release and once without DXC; 313 in Edge, 316 in Firefox and Chrome for
     Testing; both examples on every leg;
   - `@kama/image`'s: 1,401 natively and on wasm, the sweep's 197;
   - `@kama/graphics`': 322 cases natively, in Firefox and in Chrome for Testing, 309 in Edge, since part 5's step 1
     (the thirty-sixth session); 288 and 278 at its start. Its gate also asks Edge for WARP, which it does not offer, and
     holds the run to failing cleanly.
   - **Natively on Windows both GPU packages' gates need DXC:** `@kama/gpu`'s `tools/fetch-dxc.sh` fills
     `third_party/dxc/<platform>/` (git-ignored, as wgpu-native's SDK is), and `@kama/graphics`' `tools/legs.sh` finds it
     in `../kama-gpu`. A fresh machine runs it once, as it runs kama's `fetch-webgpu.sh`.
   - **The release legs cost the five gates 39 % more time, not double** (measured with kama quiet, the thirty-third
     session; rendering.md § Decided): 17.2 minutes before, 23.8 with them, from +13 % for kyoten's to +63 % for
     `@kama/window`'s. Building and the native legs were already debug and release.
   - **Start a suite or a driver in msys2's bash, never in Git Bash** (the Bash tool):
     `MSYSTEM=UCRT64 /c/msys64/usr/bin/bash.exe -lic '…'`. A `bash -lic` from Git Bash is Git Bash's own login shell,
     with no `emcc` or `node`, and `MSYSTEM=MINGW64`, so `@kama/gpu` looks for its SDK in the wrong folder. Every gate
     then fails within seconds.
   - Suites and builds may run while kama works on this machine; only measurements wait until it is quiet. Since
     0.9.948 two native `kama run`s at once no longer break each other (KY-56, fixed and removed), so a probe may run
     beside a suite.
   - **A mutation driver started from Python gets no `emcc`,** even inside `bash -lic`: `.scratch/s32/mutate.py` exports
     emsdk's paths itself, and reports a run that skipped a web leg as INVALID. Read one run's log before a batch counts.
   - **Read `../kama`'s log since `5e542c55`,** kyoten's pin, every commit in the range. First check that the pin is
     still on kama's history: `git -C ../kama merge-base --is-ancestor 5e542c55 HEAD`. kama rebases at times. If the
     pin has left its history, the commit with the same message may not be its twin: on 2026-11-14 the rebase put
     0.9.950 to 0.9.954 below the old pin's message. Compare the trees (`git diff --stat`) before rebuilding at one.
     By the thirty-sixth session the range held 16 commits, to 0.9.983 (`00707b6f`), none that kyoten needs:
     0.9.979, an Android app's loop fibers (KR-411); 0.9.980, `spawn` may name a method (KR-337); 0.9.981, Linux's
     io_uring watcher (KR-412); 0.9.982, a `static` or `comptime` of a value type holding a fixed array of values
     (`Mat3`) builds; 0.9.983, the emitter's pruning keeps a runtime macro line, so a `comptime` fixed array of values
     compiles. kama rebased its last commit during the session (`3e8591b8`, KR-397's brief, is now `dc0a8a1f`); the pin
     is still on its history. A bump is optional until something kyoten needs lands.
   - **The pin is on 0.9.978** (`5e542c55`) since the thirty-fifth session's start (`.kama-version`), at the owner's
     word ("All as recommended"), every suite green on it at 0.9.966's counts. Every manifest passed `kama check` on the
     staged pin first, so KR-405 refuses nothing kyoten writes. **0.9.967's KR-378 is on it, so `@kama/window`'s WIN-24
     can be built.** Before it, 0.9.966 since the thirty-second session. `.kama-version` says what moved:
     - **0.9.958:** `run(app:, pace:)` takes a required `Pace`; the five calls say `Pace::EveryRefresh`, as they ran
       (kama-gpu `542789b`, kama-window `dfe07c4`, kama-graphics `5f494fa`), their manifests needing 0.9.958. A window
       package may install its own wait for an app on demand (`setEventWait`), which `@kama/window` does not do yet; it
       matters once a program runs on demand, as an editor would.
     - **0.9.960 to 0.9.964: KY-59, KY-60, KY-61 and KY-62 fixed and removed,** so typed nodes take named nodes as
       operands, a chain of operators frees what it makes, and an operator's result needs no import of its type.
     - **0.9.965: kama's KR-332:** a `--release` build is `-O3` on every target, wasm included; `release.optimize` says
       `"size"`; an `-O` in a manifest's flags is refused by name.
     - **0.9.966: kama's KR-289, a wasm `--release` runs Closure** unless the root manifest says
       `"release": { "closure": false }`, and `--closure` in a flag key is refused. KY-6 is fixed and removed: kama's
       webgpu triangle's JS is 8,677 bytes of brotli where it was 15,440. **No gate had built a wasm release,** so the
       bump was green without Closure ever running on the packages' glue. A probe found two breakages, now fixed:
       `@kama/gpu`'s glue would not link under Closure (`GPUTextureUsage`), and `@kama/window`'s keyboard read every key
       as Unknown. That is why every leg now runs in both builds.
   - **The Mac's pin is on 0.9.978 (`5e542c55`) too** (kyoten `9c7704b`, 2026-11-18), rebuilt from a clean clone at the
     owner's word, its `tools/test.sh` green with Windows's counts, every wasm leg in both builds. KY-3 is narrowed
     there: a program builds for `aarch64-ios17.0-simulator` with Xcode 27.2. A probe of `@kama/audio`'s that calls
     `run` needs `pace:`; its committed code has none.
   - **Still open with kama:**
     - KY-45 and KY-40;
     - KY-58, filed 2026-11-14, kama's KR-395 since 2026-11-15: an object held in a `Shared` cannot reach its own handle,
       worked around in GFX-1's part 2.
2. **Track 1 continues, by each package's `ROADMAP.md`,** in the order the owner decided on 2026-11-10
   ([design/architecture.md](design/architecture.md) § Decided, how the libraries grow). Each row is test-first, its
   questions asked in full in the chat:
   1. **`@kama/graphics`' first slice, GFX-1, a lit cube, on both legs.** Its four questions were measured and then
      decided by the owner on 2026-11-14, each as recommended ([design/rendering.md](design/rendering.md) § Decided,
      GFX-1's four questions; [research/graphics.md](research/graphics.md) § 9; `.scratch/gfx1-probe/FINDINGS.md`):
      reversed depth always; typed nodes with a public node contract, so a program's own nodes are checked as the
      library's are; software goldens per software GPU, compared byte for byte; FLIP against them on the reference
      machines, and goldens as PNGs in the library's repository. **Its parts are laid out, and part 1's three questions
      decided** (the same day, rendering § Decided, GFX-1's part 1): a `Renderer` gets its GPU both ways
      (`make(window:, options:)` requesting its own, `withDevice(...)`); the goldens' PNGs through `@kama/image`; each
      leg names its software GPU (`--golden warp`, `--golden swiftshader`), and only `tools/update-goldens.sh` writes a
      golden, from the base64 lines the tests print. The parts, depth-first:
      1. the gate and the golden harness, and a `Renderer` with no window that clears and reads back, with its golden;
      2. the scene graph on the flat core, `BoxGeometry`, `PerspectiveCamera` with reversed depth: an unlit box;
      3. typed nodes compiled to WGSL, `MeshStandardMaterial`, the sun and ambient light: the lit box. Its question:
         how the library's own shader modules are linked when a material compiles at run time (WESL);
      4. the frame: the depth prepass, 4x MSAA, the 16-bit float target and AgX;
      5. pipelines compiled off the frame, and the quality presets;
      6. `examples/cube` in a window on both legs, FLIP, the 150 KB measurement, FEATURES.md's rows and the SPEC.
      - **GFX-1's part 1 is built** (kama-graphics `3ac9c79` and `9afdbee`, the twenty-fifth session):
        - **the gate and the golden harness:** each leg names its software GPU, every frame is held to
          `tests/goldens/<test>/<gpu>.png`, and `tools/update-goldens.sh` writes what the legs print;
        - **a `Renderer` with no window** that clears a render target and reads it back as an `@kama/image` `Image`,
          shaped by part 1's questions 4 to 6 (rendering § Decided, the owner the same day): a camera names its target,
          the default 8-bit sRGB target holds what the window would show, and a read hands back an `Image`.
      - **GFX-1's part 2 is built** (kama-graphics `bc845db`, the twenty-sixth session), its questions 1 to 3 decided by
        the owner that day (rendering § Decided, GFX-1's part 2):
        - **the scene graph on the flat core:** `Scene`, `Group`, `Mesh` and `PerspectiveCamera` behind `Object3D`;
          change marks, so an unchanged scene costs nothing to walk; each mesh's record in its scene's storage buffer;
        - **rotation both ways,** `Euler` with its five safeguards and a std::math `Quat`;
        - **`BoxGeometry` as three.js's, `MeshBasicMaterial`** (its WGSL by hand until part 3), **reversed depth,**
          `Renderer.render(scene:, camera:)` and `info()`; every shared object a `Shared<T>` made with `new`;
        - **its golden,** two boxes crossing in depth; 82 cases on each golden leg, 77 in Edge; 49 of 51 mutations
          caught, the other two only slower.
      - **Part 2's question 4 is built** (kama-graphics `faafb92`, the twenty-seventh session; rendering § Decided,
        GFX-1's part 2, item 4; SPEC § Misuse): a camera naming no target on a renderer with no window draws nothing,
        its error recorded for `renderer.takeErrors()` and printed unless `printErrorsMut()` turns it off; a node added
        under itself or one of its children is refused, printed, and `add` says `false`, with `isAncestorOf(object:)` to
        ask first. 95 cases on each golden leg, 90 in Edge.
      - **Part 3's question is decided** (the owner, 2026-11-15, "Yes I take your recommendation"; rendering § Decided,
        GFX-1's part 3; measured in [research/graphics.md](research/graphics.md) § 10, `.scratch/gfx1-part3/`): the
        library's shader functions are typed-node functions in kama, emitted into a material's WGSL once where it
        reaches them, with a `let` for a node used twice; a WGSL function as text with its includes is the escape; no
        WESL linker at run time.
      - **Part 3's first part is built** (kama-graphics `ad29352`, the twenty-eighth session; rendering § Decided,
        GFX-1's part 3):
        - typed nodes, typed functions and the material compiler;
        - `MeshBasicMaterial` rebuilt on them, `boxes/<gpu>.png` matched byte for byte;
        - 142 cases on each golden leg, 137 in Edge, and 65 of 65 mutations caught.
      - **Part 3's second part's question 1 is decided** (the owner, 2026-11-15, "Sounds like A is the best solution";
        rendering § Decided): each mesh's record carries its normal matrix, computed on the CPU when it moves, the record
        growing from 64 bytes to 112.
      - **The mirrored mesh is fixed** (kama-graphics `2d3b043`, the same session): part 2's renderer drew a mesh with a
        negative determinant inside out, where three.js flips its winding. A camera inside a mirrored box now sees the
        backdrop, with a clockwise pipeline per material for such a mesh.
      - **Part 3's second part, step 1, is built** (kama-graphics `f2e2ec7`, the same session): the record's normal
        matrix, the vertex's normal at location 1, `normalLocal()`, `modelNormalMatrix()`, `normalWorld()` and
        `positionWorld()`, held by a box under a shear and a mirrored shear; 18 of 18 mutations caught.
      - **Part 3's second part's question 2 is decided** (the owner, 2026-11-15, "A: graphVersion() (Recommended)";
        rendering § Decided): the `Material` contract gains `graphVersion()` beside `version()`, moved when a
        material's nodes change, and a renderer compiles a material again before its next draw once it moves.
      - **Part 3's second part, step 2, is built** (kama-graphics `7843e3c`, the twenty-ninth session):
        `MeshStandardMaterial`'s five values with three.js r187's defaults, its 48-byte settings, `emissiveNode`, and
        `graphVersion()`. With no light it draws its emissive alone, as three.js's does. 166 cases on each golden leg, 161
        in Edge; 26 of 26 mutations caught. `colorNode`, `roughnessNode` and `metalnessNode` moved to the third part,
        with the lights that read them, since nothing could hold them before.
      - **Part 3's third part's three questions are decided** (the owner, 2026-11-16, "I assume your recommendations
        are the best production answer for kyoten and I will take them", each (A); rendering § Decided, kyoten
        `e52c870`, kama-graphics `9aa00f8`):
        1. the scene's lights reach a shader as data: a storage buffer of directional lights of any length in the
           frame's group and the ambient lights' sum, so a light's change compiles nothing and nothing is capped;
        2. the direct light reads three.js r187's DFG table through a texture-sample node, and kama-graphics carries
           three.js's MIT notice for it;
        3. a `DirectionalLight` points from its world position to `target()`, a world-space point, its default
           position (0, 1, 0).
      - **`@kama/gpu`'s `writeTexture` brought forward from GPU-8** (the owner, 2026-11-16, "A: writeTexture now";
        rendering § Decided): the table needed a texture filled from the CPU, which the package could not do.
      - **Part 3's third part, step 1, is built** (kama-graphics `b039404`, the thirtieth session; SPEC § Typed nodes
        and § The compiler): `dfgTable()`, three.js r187's 512 half floats, written once a renderer into an RG16Float texture
        bound in group 0 with a linear, clamped sampler; `dfg(roughness:, dotNV:)`, r187's `DFGLUT`, a typed function
        that samples it; `Vec2Node`; and the compiler declaring the table only where it is read, refusing a sample in the
        vertex stage. THIRD-PARTY-NOTICES.md carries three.js's MIT notice. 177 cases on each golden leg, 172 in Edge;
        23 of 23 mutations caught.
      - **How a material's shader reads the lights is decided** (the owner, 2026-11-16, at the thirty-first session's
        start, "(A) LightingModel (Recommended)"; rendering § Decided, kyoten `94c2b52`): a public `LightingModel`
        contract, as three.js r187's `LightingModel` and Godot's `light()`, which the compiler writes once inside a loop
        over the scene's directional lights. The step's tests needed a shader to read the lights back, and no node could.
      - **Part 3's third part, step 2, is built** (kama-graphics `dfcdc71`, the thirty-first session; SPEC § The renderer,
        § Misuse, § The scene graph, § Typed nodes and § The compiler):
        - `DirectionalLight` and `AmbientLight` as scene nodes with three.js r187's defaults, the sun's `target()` a
          world-space point; each light's slot in its scene's lights table; the directional lights' storage buffer at
          group 0's binding 4, and the frame block's ambient sum and count (80 bytes);
        - `LightingModel`, `ReflectedLight` and `lit(model:)`; the compiler's one loop a stage, in either stage, with what
          depends on no light a let before it;
        - `GraphicsErrorKind::Light`, for a sun at its own target, which lights nothing.

        240 cases on each golden leg, 235 in Edge. 67 of 67 mutations caught, and a 68th shown equivalent.
      - **Part 3's third part, step 3, is built** (kama-graphics `c3ff5ed`, the thirty-second session; rendering § Decided,
        under the `LightingModel` decision; SPEC § The renderer, § Materials, § Typed nodes and § The compiler):
        - the frame block carries the camera's position in world space (`cameraPosition()`), 96 bytes;
        - r187's BSDFs and `getRoughness` as typed functions, and `PhysicalLightingModel` on the contract;
        - `MeshStandardMaterial` lit by it, with `colorNode`, `roughnessNode` and `metalnessNode`.

        A lit box's centre texel is held within a step to r187's formulas in float64, in five lightings, and the ambient
        term amplified 128 times against its float64 value. 259 cases natively and on each golden leg, 254 in Edge, each
        debug and release; 35 of 35 mutations caught, five after the tests were sharpened. r187's geometry roughness
        waits for the first geometry whose normals vary (GFX-2), since on a flat face it is 0; settled and reported.
      - **Part 3's third part, step 4, is built, and so part 3** (kama-graphics `ef418f2` and `126ac07`, the thirty-third
        session; rendering § Decided, under the `LightingModel` decision; SPEC § Tests):
        - the lit goldens `light-directional`, `light-ambient` and `material-standard` on WARP and SwiftShader, one per
          feature the part built, named as FEATURES.md names their tests (settled and reported);
        - on every leg, every face they show held within a step to r187's formulas in float64.

        WARP draws the same lit bytes natively and in Firefox. 266 cases on each golden leg, 258 in Edge, each debug and
        release; 7 of 7 mutations caught. Found and fixed first: a leg whose device never opened panicked.
      - **Part 4, the frame, is built** (the depth prepass, 4x MSAA, the 16-bit float target and AgX). Its three
        questions were decided at the thirty-third session's end (rendering § Decided): 4x MSAA resolves by a ladder, a
        tone-mapped resolve best; AgX is both, Blender's the default; exposure is on each camera in EV100. The
        thirty-fourth session added three decisions, each the owner's (A) (rendering § Decided): tone mapping is on each
        camera too; Blender's AgX is a table the renderer makes from the formulas, sampled as OpenColorIO does, its
        generator credited and a licence asked for; and `@kama/gpu` compiles with DXC natively. The thirty-fifth settled
        how: Microsoft's own release, fetched, as wgpu and Bevy have a game ship it (rendering § Decided, 2026-11-18).
        - **Its two checks:** `@invariant` holds on every Windows leg (a prepass and an Equal pass shade exactly one
          pass's texels); Blender's formulas reproduce all 185,193 of its table's entries, but Blender shows the table
          interpolated, up to 22 steps from the formulas, hence the table (`.scratch/s34/FINDINGS.md`).
        - **Step 1, the depth prepass, is built** (kama-graphics `43bd19a`): 267 cases, 259 in Edge; 12 of 13
          mutations caught, the 13th (GreaterEqual for Equal) equivalent.
        - **Step 2, the HDR frame, is built** (kama-graphics `81c3127`): the 16-bit float scene and the output pass,
          exposure in EV100 and pre-exposed, `max(0)`, `RenderTarget.withFormat`; 279 cases, 271 in Edge; 13 of 13
          caught. The lit goldens were written again, half floats moving 2 to 44 texels a step.
        - **Step 3, tone mapping, is built** (kama-graphics `3899adb`): `ToneMapping::BlenderAgX`, the default,
          and r187's `AgX`; 285 cases natively, in Firefox and in Chrome for Testing, 276 in Edge; 17 of 17 caught.
        - **r187's golden, `tone-mapping-agx`, is written** (kama-graphics `61c5661`), once `@kama/gpu` shipped DXC
          (kama-gpu `b123a03`): the native legs put its `dxcompiler.dll` on the PATH, and WARP's two legs agree.
        - **Step 4, 4x MSAA resolved by the GPU, is built** (kama-graphics `c1a9f51`): on by default, the count the
          renderer's, no public switch yet; the four goldens with edges written again; 288 cases, 278 in Edge; 6 of 7
          caught, the seventh (the samples stored) equivalent.
        - **How a program chooses the method is decided** (the owner, 2026-11-18, "A (Recommended)"; rendering §
          Decided, kyoten `a2c9c41`): one list of whole methods on the renderer, `Antialiasing`, the tone-mapped resolve
          the default; later methods (8x natively, TAA, SMAA, FXAA) join the same list.
        - **Step 5 is built, and so part 4** (kama-graphics `dad8fe2`): `Msaa4ToneMapped`, `Msaa4` and `None`, set by
          `antialiasingMut()` and taking effect at the next render; the tone-mapped resolve, a pass of its own reading
          the stored samples, with two guards (a sample stored as infinity, a negative clear colour), the second found
          while writing its case; the older tests kept on the GPU's resolve, so no golden moved; three goldens, one a
          method; 299 cases, 286 in Edge; 24 of 24 mutations caught.
      - **Part 5, pipelines compiled off the frame and the quality presets, is under way:**
        - **Its three questions are decided** (the owner, 2026-11-18, "all sounds good now as revised
          recommendations"; rendering § Decided, kyoten `6dc5e44`), each (A) as revised after the owner asked for the
          ubershader and pre-compiling as approaches too: every way a draw takes while its pipeline compiles, the
          program's choice (`General`, the material's general form, by default, then `Skip`; `StandIn`; `Wait`), and
          `compile(scene:, camera:)` ahead; presets a value the game owns, the library's four only starting points;
          question 11 (KYR-78) scope, decided at its row.
        - **Step 1 is built** (kama-graphics `ee90ef7`): pipelines compiled off the frame, `General` (skipping until
          step 2), `Skip` and `Wait`, `compile`, `info()`'s misses; a material the device refuses is skipped alone,
          where its frame drew nothing before; 322 cases, 309 in Edge; 27 of 28 mutations caught.
        - **Next, step 2: the general form** for the cull flip, a mirrored mesh's; then step 3, `StandIn` and the
          per-material override; step 4, `Quality`, `applyQuality` and the device's features; then part 6,
          `examples/cube`. Read the code for any public-API question before building, and ask it in full.
      - **Part 4's evidence** is machine-local:
        - `.scratch/s33/part4-sources/` and `part4/`: the survey's pinned sources and its measurements;
        - `.scratch/s34/`: `FINDINGS.md`; `invariant/`, check 1's probe; `agx/`, Blender 5.3's config and tables, the
          generator at `ab7415e`, colour-science 0.4.3, and the port and its comparisons in `agx/tools/`;
          `agx/licence-request.md`, the request for EaryChow, not posted; `dxc/`, the FXC-against-DXC probes and DXC
          v1.9.2609's release, read for its licence; `kg-tools/`, the runners (`native.sh`, `native-m.sh`, `native-b.sh`,
          `native-dxc.sh`, `warp2.sh`, `gate*.sh`), `mutate.py` and `list1.py` to `list3.py`. The worktrees
          `../kama-graphics-s34b` and `-s34m` are removed (`kg-tools/unlink_worktree.py`).
        - `.scratch/s35/`: `suites.sh` and `bump.sh` (the start and the bump); `dxc/FINDINGS.md`, the clang build's probe
          and why it needs patches, with DXC's source and build; `dxc/probe2/modes.c`, which compiler wgpu-native uses
          and when it loads the DLL; `gpu/` (GPU-16's runners, `mutate.py`, `list1.py`) and `kg/` (`native.sh`,
          `native-m.sh`, `mutate.py`, `mutate-m.py`, `list1.py`, `list2.py`); `unlink_worktree.py`. Every session
          worktree is removed.
        - `.scratch/s36/`: `suites.sh` (the start's run and its logs); `k1.py`, the one-sample texel worked exactly;
          `kg/`: `native.sh`, `native-m.sh`, `mutate.py` and `mutate-m.py` (which now take paired replacements, a tuple
          for `old` and `new`), `list1.py` (step 5's 25), `mutations1.out`, `gate.log`, `update-goldens.log` and the
          goldens enlarged 8x; the edit scripts; `unlink_worktree.py`. Both session worktrees are removed.
      - **Since KY-57's fix, Chromium under `kama run` can take SwiftShader** (measured on 0.9.956 with `@kama/graphics`'
        tests).
        - **The settings:** Edge needs `--enable-unsafe-webgpu`. The pinned Chrome for Testing needs that,
          `--enable-unsafe-swiftshader` and `--disable-features=NetworkServiceSandbox`, and with them it loads a page
          under `kama run` for the first time. Each matched both SwiftShader goldens.
        - **Decided by the owner at the twenty-sixth session's start, as recommended** (rendering § Decided, the
          drivers retired): `@kama/gpu`'s and `@kama/graphics`' DevTools drivers are retired (kama-gpu `fba6beb`,
          kama-graphics `80aa861`). The pinned Chrome for Testing runs under `kama run` with its flags on its own command
          line, the web's SwiftShader leg, and Edge runs as a player's does, on its real GPU, with no flag and no golden.
          `@kama/window`'s keeps its driver for KR-378.
      - **`@kama/gpu`'s GPU-15, the fallback adapter, is built** (the twenty-second session, kama-gpu `b294d66`, its
        AGENTS.gpu.md item 13): WARP natively and in Firefox, SwiftShader in Chromium through the driver, each the same
        bytes twice. Since the drivers' retirement, Chrome for Testing runs its fallback cases under `kama run`, and Edge
        holds that none is offered (`--no-fallback-adapter`).
        **Found on the way and fixed** (kama-gpu `c490c01`): natively a lost device's next submit or map ended the
        process. On wgpu-native v29's D3D12, a read-only depth pass loses the device when the depth texture's usage is
        RenderAttachment alone (`.scratch/warp-lost/`), so GFX-1's depth textures also take TextureBinding.
      - `examples/triangle`'s read back (kama-gpu's `examples/triangle/src/check.kama`) is the first form of the golden
        harness's frame capture, and the node sketch (`.scratch/gfx1-nodes-947/`, a number on either side since KY-55's
        fix) the first form of the node builder.
      - The runners are in `.scratch/gpu15/tools/` (its README): native, Edge, Firefox, Chrome for Testing and Edge
        through the driver, and the mutation driver with `--runner`, which starts any browser runner in a UCRT64 login
        shell. The probe's page runner, which works in every browser, is `.scratch/gfx1-probe/run.mjs`. **For
        `@kama/graphics`, `.scratch/gfx1-part2/tools/`** (its README): the same driver pointed there, with runners that
        hold a mutation to the gate's own checks, and part 2's mutation list; part 1's are in `.scratch/gfx1-part1/tools/`.
   2. `@kama/window`'s WIN-24, the drivers retired, now that kama gives trusted input (KR-378, built in 0.9.967 and on the
      pin since 0.9.978). Since 0.9.956 the pinned Chrome for Testing loads a page under `kama run`, given
      `--chromium-arg --disable-features=NetworkServiceSandbox`, which was WIN-24's other condition. The device scale
      moved to `kama run --scale 1.5` in the eighteenth session.
   - **Reached kama on 2026-11-14:**
     - `@kama/image` is ruled first-party (kama `74784471`, docs/packages.md, beside every `@kama/*` package);
     - KY-57 is fixed (0.9.956);
     - `@kama/image`'s KIMG-1 is in kama's KR-332, measured on std's own inflate, with a speed level for one package.
   - **Waiting on the owner:** posting two requests for a permissive licence, which every AgX's lineage lacks
     (rendering § Decided): `.scratch/s34/agx/licence-request.md` on EaryChow/AgX_LUT_Gen, and
     `licence-request-sobotka.md` on Troy Sobotka's AgX or SB2383-Configuration-Generation. `@kama/graphics`' first
     publish waits on the answers. A comment on wgpu-native PR #630 with the probe's results (research/graphics.md § 6),
     drafted in the fourteenth session's chat. Nothing has been posted to gfx-rs. An issue for gfx-rs/wgpu, drafted in
     the nineteenth session (`.scratch/gpu4-part3/wgpu-issue.md`, on this machine): wgpu takes alpha to coverage at
     one sample, natively and in Firefox, where WebGPU refuses it. Another, drafted in the twenty-second session
     (`.scratch/warp-lost/wgpu-issue.md`, with its C repro): on D3D12 a read-only depth pass loses the device when the
     depth texture's usage is RenderAttachment alone. And, optionally, two reports to Dawn, each worked
     around by the package:
     - emdawnwebgpu's use-after-free on a second `getCompilationInfo` (kama-gpu's SPEC § Shader modules);
     - emdawnwebgpu passing a depth attachment's NaN "no clear value" to Chrome, which throws, so every C program that
       loads depth through it ends (`.scratch/gpu4-part4/FINDINGS.md`).

     - emdawnwebgpu converting `draw`'s and `drawIndexed`'s counts as 31-bit numbers, so a count of 2^31 or more
       reaches a browser negative and it throws, though WebGPU takes it (the package refuses it on the web alone).

     And, optionally, two reports to Firefox:
     - Firefox 160 takes a colour attachment's depth slice of 2^32 - 2 on a 2D view, where it refuses a slice of 0
       there, and WebGPU refuses both (kama-gpu's `--unchecked-depth-slice`);
     - Firefox 160 delivers no second uncaptured validation error whose words repeat an earlier one's.
3. **Then the join.** Step 7, the platform seam, builds:
   - the generated `run`, on the `Platform` contract and `@kama/window`. `run` calls `openContent`, `readContent`,
     `loadPrefabs` and `placeFirstScene`;
   - `engine/content/`'s first records;
   - the `Platform`'s content folder, so that `kyoten::content`'s `folderFor` and its exception in the platform-flag
     check are removed, and the check's exception list is empty (target-platforms § Decided, question 3, item 8).

**The thirty-sixth session** (2026-11-18). Nothing new on any origin at the start, and kama's range held nothing kyoten
needs, so no bump.
- **Every suite was green on 0.9.978 at the start,** at the thirty-fifth session's counts.
- **One question in plan mode, answered "A (Recommended)":** how a program chooses its anti-aliasing. Reading the code
  for step 5 found that step 4 had left the sample count a private 4, and nothing had decided how a program names the
  method. Recorded as its own commit (kyoten `a2c9c41`) before the build.
- **Built:** part 4's step 5 (kama-graphics `dad8fe2`), test-first and mutated, in a worktree with a second for the
  mutations; so part 4 is built. Found on the way: the tone-mapped resolve rounds to half floats twice, so it is held
  within two steps where the others hold one (WARP measured 1.1); WARP stores a finite overflow as 65504, so the
  infinity guard needed a shader that makes a real infinity (10^30 squared); and the undoing of the weight needed the
  floor the weight has, or a negative clear colour came back over 1.25.
- **Part 5's three questions, asked in full after part 4 was built,** the owner continuing the session. The first
  draft said Godot's ubershader could not serve a node material and that waiting could exist only natively; the owner
  asked for the ubershader and pre-compiling as approaches ("recall that before shaders the fixed function pipeline
  was basically an 'uber shader'") and how far a game shapes its presets. Both claims were wrong, as Godot 4.7.2's
  source showed (its general form is each material's own shader, specializations as push constants), and the
  questions were laid out again; answered "all sounds good now as revised recommendations" (kyoten `6dc5e44`).
- **Built:** part 5's step 1 (kama-graphics `ee90ef7`), test-first and mutated. Found on the way: under the
  synchronous call a refused material's pipeline invalidated its whole frame; each leg words the refusal its own way,
  and Firefox passes on only wgpu's first line.

**The thirty-fifth session** (2026-11-17 and 18). Nothing came from the Mac for kyoten; `@kama/audio`'s AUD-2 slot table
was pulled into this machine's clone.
- **Every suite was green on 0.9.966 at the start,** at the thirty-fourth session's counts.
- **Two questions in plan mode, answered "All as recommended":** the bump, and DXC built with msys2's clang, which
  reading Firefox's DLL had shown to be the only build route shipping none of Microsoft's runtime.
- **The bump to 0.9.978** (kyoten `f4d545c`), probed first with `kama check` on every manifest, then every suite green
  at the same counts.
- **The clang route needed patches** (`.scratch/s35/dxc/FINDINGS.md`: DXC's Windows path is MSVC's and ATL's alone).
  The owner asked "How do others do this? Direct X is meant to be used... why are we trying to work around things?";
  answered from wgpu's, Bevy's, Firefox's, Chrome's and Godot's practice, the owner took Microsoft's own release,
  fetched (rendering § Decided, 2026-11-18). Then: "Who said we should compile shaders while the game runs? shouldn't
  that be a choice for the game?": nobody had decided it, so it is KYR-78 and rendering question 11, questions only;
  on the web the browser always compiles, and natively wgpu-native v29 cannot yet take DXIL. Steam's common
  redistributables do not include DXC.
- **Built:** `@kama/gpu`'s GPU-16 (kama-gpu `b123a03`), after a fix found on the way, the gate installing dependencies
  before its bindings check, as a fresh clone needs (kama-gpu `06a0946`, proved in a fresh worktree); r187's golden
  (kama-graphics `61c5661`); part 4's step 4, 4x MSAA (kama-graphics `c1a9f51`). Each test-first and mutated.
- **The owner asked how far the lit cube and the FPS demo are.** The answer, from the pace so far: the cube about 7 to
  11 sessions (GFX-1's step 5, parts 5 and 6, then the join's steps 7 to 10); slice A2 and slice B some 10 to 20 after
  it; the playable FPS v1 (KYR-65) beyond those, with audio, UI, physics and bots. Two ways to bring the cube closer,
  offered and not yet decided: the join's steps 7 and 8 in parallel (they need `@kama/window`, which is built), on the
  Mac or a second track; or GFX-1's part 5 after the cube, since A1's checks do not depend on it.
- **Pushed at the owner's word** ("yes you can push and get things ready for the next session"), nothing new on any
  origin: kyoten, kama-gpu and kama-graphics. kama-window and kama-image did not change.

**The thirty-fourth session** (2026-11-17). kama's range since the pin held three docs commits (KR-378 ruled and claimed
by this machine, KR-397 filed), so no bump. The Mac pushed `@kama/audio`'s decisions 32 to 35 and AUD-1's ring and
backlog, and nothing to kyoten.
- **Every suite was green on 0.9.966 at the start,** at the thirty-third session's counts.
- **One question asked in plan mode and decided at once:** tone mapping on each camera (A).
- **Part 4's two checks ran first:** `@invariant` passed; Blender's AgX against its table failed as worded, and the
  owner took a table the renderer makes (A), its unlicensed generator credited and a licence asked for (A), after asking
  "I find it hard to believe we must rely on an unlicenced repo to make this work?". The answer: what is taken is the
  method, our own code written from it, and only Blender's GPL file could not be shipped.
- **Steps 1 to 3 built** in worktrees, each test-first and mutated, and committed one by one.
- **Two questions mid-build:** WARP's two legs disagreed on r187's ramp, FXC natively against Firefox's DXC; the owner
  took DXC natively (A), then, once Microsoft's prebuilt binaries were found to carry Microsoft's distribution terms
  (corrected and asked again), DXC built from source as Firefox does (A), and step 3 committed before it (A).
- **The owner asked once more at the end** whether there was another way than EaryChow's unlicensed repository, and
  whether we could build our own: answered and recorded under the AgX decision (nothing from it ships; our code is
  written from its method; each alternative loses Blender's image or its licence; publishing on the credit alone stays
  the owner's to choose).
- **Pushed at the owner's word** ("Yes push what you need. and get ready for next session"): kyoten, rebased onto the
  Mac's pin commit (`69697c8`), and kama-graphics, nothing new on its origin. kama-window, kama-gpu and kama-image did
  not change.

**The thirty-third session** (2026-11-17). kama's range since the pin held one commit, `cf04df19` (docs), so no bump.
Nothing came from the Mac for kyoten. Its `@kama/audio` work is on its origin, which this machine's clone has not pulled.
- **Every suite was green on 0.9.966 at the start,** at the thirty-second session's counts.
- **Each gate was timed against the commit before its release legs,** with kama quiet: 17.2 minutes before, 23.8 with
  them (+39 %), recorded in rendering.md § Decided. The first launch ran in Git Bash and measured nothing (item 1).
- **Found and fixed first, test-first** (kama-graphics `ef418f2`): step 3 left the tests' no-device path pointing at its
  new stage, so a leg whose device never opened panicked (Edge asked for WARP, status 134). The finishing stage is one
  named constant, and the gate holds the path.
- **Step 4 built** (kama-graphics `126ac07`): the lit goldens, red first ("no golden yet"), written by update-goldens
  with WARP's two legs agreeing. Their face checks were green first and proved by the same 7 mutations as the goldens.
  **Part 3 is built.**
- **Part 4 prepared:**
  - a survey of three.js r187's output path, Bevy, Godot, Filament, Unity HDRP and the WebGPU spec, its claims checked
    against the downloaded sources;
  - r187's AgX against Blender's, as Godot 4.7 approximates it: up to 45 steps apart on saturated colours, and 10 at
    mid-grey;
  - an HDR edge texel through each resolve.

  Its three questions were asked in full at the end and decided at once, each (A), the owner asking whether they were
  the production answers: they are, with the two checks above to make while building.
- **Pushed at the owner's word** ("push anything you need"): kyoten and kama-graphics, each a fast-forward with nothing
  new on its origin. kama-window, kama-gpu and kama-image did not change. Part 4 starts in the next session, in plan
  mode, with its two checks.

**The thirty-second session** (2026-11-17). Every suite was green on the 0.9.965 pin at the start, at the
thirty-first session's counts. Nothing came from the Mac.
- **The pin bumped to 0.9.966** at the owner's word ("Yes you can bump kama"; kyoten `38ac701`), every suite green on it at
  the same counts with nothing else changed, and KY-6 fixed and removed.
- **One question, asked in plan mode and decided at once:** no gate built a wasm release, so the bump would pass without
  Closure ever running on the packages' glue. The owner took (A), every wasm leg in both builds (kyoten `c35f08b`). A
  probe on the staged pin had already found the two breakages:
  - `@kama/gpu`'s glue would not link under Closure: `GPUTextureUsage` is undeclared to it;
  - `@kama/window`'s DOM-code table was renamed, so every key read as Unknown.
- **The release legs, built test-first, red on 0.9.966 where Closure broke something:**
  - `@kama/window` (kama-window `b719ab2`): 11 of 11 mutations caught. Quoting the table was not enough, since emscripten
    rewrites a library object's keys unquoted, so a function makes the table. The release legs also found a pad's
    `effects` and the driver's acknowledgement renamed;
  - `@kama/gpu` (kama-gpu `5f400be`): 9 of 10 caught, one equivalent. Its gate now runs from a fresh clone;
  - `@kama/image` (kama-image `a860c6b`): 2 of 2 caught;
  - `@kama/graphics` (kama-graphics `9bc2e64`): 4 of 4 caught;
  - kyoten (`2fdd8ff`): 5 of 5 caught. The frame guard's release leg needed a fixture whose big frame is in the release
    build alone, so the leg can tell its build.

  `tools/closure-names.mjs` holds each JS file's names to its release build, and it caught the one renaming no case
  could see: `effects` unquoted on both sides of the test's fake pad.
- **Step 3 built** (kama-graphics `c3ff5ed`) in a second worktree while the release legs were mutated, then put onto
  them. Its first mutation run found five gaps in the tests, now closed: Fresnel at a grazing angle, F90 other than 1, an
  off-axis camera for the view direction, and the ambient's multiple scattering, amplified past the 8-bit step.
- **Pushed at the owner's word** ("yes you can push and get things ready for next session"): kyoten, kama-window,
  kama-gpu, kama-image and kama-graphics, each a fast-forward with nothing new on its origin.

**The thirty-first session** (2026-11-16). Every suite was green on the 0.9.965 pin at the start, at the thirtieth
session's counts. Nothing came from the Mac. kama's range since the pin held a CI guard (`d817de00`) and a job-pool
benchmark (`b7800cbd`), with the compiler unchanged, so no bump.
- **One question, asked in plan mode and decided at once:** reading the code for step 2 found that its tests must read
  the lights back in a shader, and that nothing could: the compiler wrote no loop. The owner took (A), a `LightingModel`
  contract (kyoten `94c2b52`), so the contract and the loop came into step 2 from step 3.
- **Step 2 built** in a worktree (`../kama-graphics-s31`), in two halves: the lights as scene nodes with their table and
  buffer, then the contract and the loop. Mutations ran in a second worktree (`../kama-graphics-s31m`) while the second
  half was built.
  - **Red first:** the lights' half against a stub with its defaults, marks, refusal and reserved names taken out, 8
    of its 20 cases and the gate's printed-refusal check failing; the lighting half against a `lit()` that drops what
    `direct()` gives, 36 of its 40 failing.
  - **The mutations found four gaps in the tests, now closed:** no let inside the loop, no vertex-only value read in a
    vertex-stage loop, and no typed function with a let called from inside the loop. A fifth, a model reading an
    earlier `lit()`'s result, looked like a bug, but the tests showed the old code refused it too, by another path. It
    is recorded as equivalent, and the refusal is now made in the loop's body, in words that say why.
  - **Settled under part 2's question 4 and reported:** a directional light at its own target lights nothing, and is
    reported as `GraphicsErrorKind::Light`, once a change.
  - **Committed as one commit, not one per half as planned:** the halves share the compiler and the test file, so
    splitting them would have meant rebuilding the first half's state by hand and running the gate again.

**The thirtieth session** (2026-11-16). Every suite was green on the 0.9.964 pin at the start, at the twenty-ninth
session's counts. Nothing came from the Mac. kama had committed two things since the pin: 0.9.965 (KR-332) and a
benchmark.
- **The pin bumped to 0.9.965** at the owner's word ("Yes, bump first"; kyoten `ab76ced`), every suite green on it at the
  same counts with nothing else changed.
- **Step 1 of the lights met a gap:** `@kama/gpu` could not fill a texture from the CPU, `writeTexture` having been left
  in GPU-8. The owner asked whether bringing it forward was a stopgap; it is not, since kama lacked nothing and the
  package had not wrapped WebGPU's call, and the owner took (A), "writeTexture now".
- **`writeTexture` built in `@kama/gpu`** (kama-gpu `27760aa`, AGENTS.gpu.md item 14), probed first:
  - natively every misuse is a validation error inside the call, and only a null pointer with a size ends the process,
    which a `ConstView` never hands it (`.scratch/s30/wt-probe/`); emdawnwebgpu reads every 32-bit field unsigned, so on
    the web only an offset past 2^53 - 1 would throw, which the package clamps;
  - **found in Firefox 160:** every write from past the end of its data is worded alike, so with its dropping of a
    repeated error only one such case is seen;
  - red first 17 of 29; 18 of 19 mutations caught, the nineteenth (a stride of 2^32 - 1 unclamped) equivalent.
- **Step 1 built in `@kama/graphics`** (kama-graphics `b039404`): the DFG table, the texture-sample node and `dfg()`, red first
  3 of 10 against a stubbed `dfg()`; 23 of 23 mutations caught.
- Built in worktrees (`../kama-gpu-s30`, `../kama-graphics-s30`) while the suites held the packages at their HEADs.
- **KYR-66's direction was decided at the session's end** ([design/content-delivery-tool.md](design/content-delivery-tool.md)
  § Decided, questions 3 to 8 and 10 in part). The owner asked whether each asset should be built and hashed, so that
  only what changed is built, and whether development and the shipped game should differ, then said "all sounds good to
  me":
  - each asset is keyed by a SHA-256 of its inputs, with a shared cache;
  - a file per asset in development, and asset packs of what loads together when a game ships;
  - an asset manifest that the game's lock names and the stack's identity covers;
  - fetched when needed on the web, every hash checked at load.

  KYR-10, the first slice's assets, reads by it.

**The twenty-ninth session** (2026-11-15 and 16). Every suite was green on the 0.9.962 pin at the start, at the
twenty-eighth session's counts. Nothing came from the Mac. kama had committed four things since the pin.
- **The pin bumped to 0.9.964** at the owner's word ("Yes, bump first"; kyoten `59e21c4`): kama `52032a3b` fixed
  KY-61 and KY-62 the day they were filed. Their repros build and run on it and are refused on 0.9.962, and both
  entries are removed. Every suite is green on it at the same counts. KR-332 was ruled (a wasm `--release` at `-O3`,
  to be built).
- **Part 3's second part's question 2 asked and decided:** (A), `graphVersion()` on the `Material` contract.
- **Step 2 built** (kama-graphics `7843e3c`) in a worktree beside the packages, while both suite batches held
  kama-graphics at its HEAD. Red first against a stub, 12 of 15 new cases; 26 of 26 mutations caught after the drawn
  cases were sharpened to hold alpha.
  - **Settled and reported:** `colorNode`, `roughnessNode` and `metalnessNode` move to the lights' part, since with no
    light they change neither a pixel nor the WGSL, so no test could hold them now.
  - **Found for part 4:** three.js clamps every node material's output with `max(0)`, which only a float target shows.
- **The lights' part prepared:** three.js r187 recompiles every lit material when a light is added or removed (each
  light's id is in its cache key); Bevy and Godot keep a fixed number of directional lights in one uniform with a count
  (10 and 8). r187's direct light reads a 16x16 RG16F DFG table, which r170's analytic fit misses by up to 0.41 in its
  scale term (`.scratch/gfx1-part3/lights/dfg_compare.py`). A directional light's target must be added to the scene
  before moving it does anything.
- **The lights' three questions asked in full at its end, and decided the next morning,** each as recommended. Pushed
  at the owner's word: kyoten and kama-graphics.

**The twenty-eighth session** (2026-11-15). Every suite was green on the 0.9.960 pin at the start, at the
twenty-seventh session's counts. kama had committed nothing since the pin, and nothing came from the Mac.
- **KY-60 found from kama's working tree and filed:** an uncommitted fix there said a chained operator's left operand
  was never freed. `.scratch/ky60/` made 11 values and freed 9 on the pin, and freed all 11 on `../kama`'s working
  binary.
- **GFX-1's part 3, its first part, built** in kama-graphics: typed nodes, typed functions, the material compiler, and
  `MeshBasicMaterial` on them, its golden matched byte for byte.
  - A sketch on the pin came first (`.scratch/gfx1-part3/sketch/`). kama has no generic methods, so `param` is a free
    function. A node's identity is its expression's address. Programs write nodes in safe kama.
  - **Every float32 swept** (`.scratch/gfx1-part3/numbers/`, six processes): one value, `7.038531e-26`, is read through
    a float64, as WGSL compilers read literals, as its neighbour. The compiler writes that one with its float64
    digits.
  - **Mutations:** 65 of 65 caught, after `pow`'s case was sharpened.
  - **Found and fixed:** a material's settings were visible to the fragment stage alone.
  - **Found and filed:** KY-61, an operator's result across packages untyped unless its type is imported.
  - **Found and fixed:** a mirrored mesh drew inside out (3 of 3 mutations caught).
- **Part 3's second part's question 1 asked and decided:** normals under a non-uniform scale, (A), the normal matrix
  in the record. The prior art was read in its source (`.scratch/gfx1-part3/prior-art/`): three.js's
  `modelNormalMatrix`, Bevy's record, Godot's flag.
- **The pin bumped to 0.9.962** at the owner's word ("bump"), after kama fixed KY-60 within hours of its filing. Every
  suite is green on it at the same counts. KY-60's repro frees all 11 values on it, and the entry is removed.
- **Part 3's second part, step 1, built** (kama-graphics `f2e2ec7`): the record's normal matrix, held by a box under a
  shear, every texel to S⁻¹ R n in float64. A test turning the box alone could not tell the plain matrix from the inverse
  transpose; red first against the plain 3x3 (279 texels wrong). 18 of 18 mutations caught. **Found and filed:** KY-62,
  a generic's type argument inferred from `a * b` is `a`'s type.
- **At the end:** the Mac's four commits (audio's design pass closed, its pin rebuilt at 0.9.960) were fetched and this
  session's rebased onto them; kama had committed one roadmap commit since the pin (`e0936930`, KR-332's brief), and its
  tree holds 0.9.963 (Android's `Pace`, proved on the emulator), which touches nothing of kyoten's. Pushed at the
  owner's word ("go ahead and push and get things ready for the next session"): kyoten and kama-graphics.

**The twenty-seventh session** (2026-11-15). Every suite was green on the 0.9.956 pin at the start, at the twenty-sixth
session's counts; kama had not moved past 0.9.959 and its roadmap claim, and nothing came from the Mac.
- **Part 2's question 4 built** test-first (kama-graphics `faafb92`): red first against a stub, 5 of 11 new cases;
  the gate counts each leg's printed lines from outside the program, browsers included. How the printing is turned off
  was settled under the owner's word and reported: the renderer's `printErrors` property pair, and `isAncestorOf` to
  ask before an `add`. 20 of 21 mutations caught, five by the gate's printed-line count alone and one as a hang; the 21st is equivalent (`.scratch/gfx1-q4/`).
- **Part 3's question measured, asked and decided** (research/graphics.md § 10): the same lit material with its five
  library functions held as typed nodes and as WGSL text, both compiled with no message in Dawn and naga and giving the
  same values; (A) typed adds 3.9 KB of web code and about 42 µs a material, (B) text 2.0 KB and 6 µs, (C) a WESL linker
  at run time a WGSL parser (wesl-js is 39 KB gzip). The owner took (A) with (B) the escape and no (C).
- **KY-59 found and filed:** the probe's typed nodes crashed, then emitted WGSL from freed nodes. An overloaded operator
  is handed a by-value node bitwise, with no copy ctor, and both it and the caller release it (`.scratch/ky59/`, the
  emitted C quoted in the entry).
- **The pin bumped to 0.9.960** at the owner's word (kyoten `7164a9c`): KY-59's fix landed upstream within the hour
  (kama `f2c8b31b`), found by reading kama's log before pushing. Every suite green on it at the same counts, with the
  five `run(app:, pace:)` calls ported in the packages; KY-59's repro passes on the pin and fails on 0.9.956, and the
  entry is removed.
- **A mutation that makes the tree a loop hangs the test program,** and the driver's timeout cannot end it while the
  program holds the run's pipes: `.scratch/gfx1-q4/tools/watchdog.ps1` stops a mutant program past 180 s.

**The twenty-sixth session** (2026-11-14/15). Every suite was green on the 0.9.956 pin at the start, at the
twenty-fifth session's counts, and kama had not moved; the Mac rebuilt its pin at 0.9.956 too (kyoten `7caa18c`).
- **The drivers retired** (the owner's choice at the start, "A"; rendering § Decided): the pinned Chrome for Testing runs
  under `kama run` in `@kama/gpu` (kama-gpu `fba6beb`) and `@kama/graphics` (kama-graphics `80aa861`), its flags on its
  own command line, and Edge as a player's, on its GPU. Each leg's role follows its browser's kind, so a missing flag
  fails rather than skips: 11 of 12 mutations caught, the twelfth caught by `@kama/gpu`'s gate in the same file.
- **GFX-1's part 2 measured, asked, decided and built** (kama-graphics `2480686` and `bc845db`):
  - a sketch on 0.9.956 (`.scratch/gfx1-part2/sketch/`) found kama's shapes first: a `ref` handed out must point into
    `this`, so the transform is inline; a contract cannot be a field, so a mesh holds `Shared<Geometry>`; and nothing
    reaches the `Shared` holding `this` (KY-58, filed);
  - the owner's three answers ("I take the recommendations"), after asking whether Euler's traps can be closed (five
    safeguards) and whether `Shared<T>` costs speed (measured: no; `.scratch/gfx1-part2/bench/`, with change marks an
    unchanged scene of 10,100 meshes walks in 0 µs);
  - built test-first, its golden viewed on both GPUs, and the tests sharpened twice by mutation.
- **Decided at its end:** part 2's question 4, what a misuse does ("A": refused and reported, never ending the
  program), to be built first at the next session. Pushed at the owner's word ("you can push").

**The twenty-fifth session** (2026-11-14). Every suite was green on the 0.9.949 pin at the start, at the twenty-fourth
session's counts, and kama had not moved. It ended with the pin bumped to 0.9.956 at the owner's word (kyoten `c6ed657`):
- **The rebase:** kama had rebased, and the old pin's commit had left its history.
- **The suites:** every one, kyoten's and four packages', was green on 0.9.956 at the same counts.
- **The gaps:** KY-57 is fixed and removed, and KY-40 and KY-45 are unchanged.

GFX-1's part 1 was built in `../kama-graphics`, test-first:

- **The gate and the golden harness** (kama-graphics `3ac9c79`):
  - **The tests program, and `tools/test.sh`,** natively debug and release, under `kama run` in Edge and Firefox, and
    through the driver in Chrome for Testing. The legs are defined once, in `tools/legs.sh`.
  - **Each leg names its software GPU:** `--golden warp` natively and in Firefox, `--golden swiftshader` through the
    driver. Edge under `kama run` names none (KY-57). The adapter is held to what it can say about itself.
  - **The comparison takes the golden's bytes as a parameter,** decodes it with `@kama/image` and compares byte for byte.
    A frame that differs, or has no golden yet, prints as one `golden-png` line at `archival()`. `tools/update-goldens.sh`
    writes those, refusing when the legs of one GPU disagree.
  - **The gate holds each leg that names a GPU** to declaring and matching every golden it has.
  - **The harness's own scene is two triangles at 4x MSAA, 37x23.** WARP draws 381 texels and SwiftShader 382, so each
    has its own golden. WARP draws the same bytes natively and in Firefox.
  - **17 cases on each golden leg, 14 in Edge.** 29 of 29 mutations were caught, and a broken golden was written back
    byte for byte by the updater.
- **The `Renderer`'s three questions, decided by the owner as recommended** ("I will take your recommendation on all 3
  yes"; rendering § Decided, GFX-1's part 1, questions 4 to 6):
  - a camera names the target it draws into, and with none the window;
  - a target's format decides what it holds, the default 8-bit sRGB target what the window would show;
  - a read hands back an `@kama/image` `Image`, so the library depends on `@kama/image`.
- **The `Renderer`, built test-first** (kama-graphics `9afdbee`):
  - **The API:** `Renderer.withDevice(device:, queue:)`, a clear colour written in sRGB and held linear (`Color`),
    `clear(target:)`, and `readRenderTargetPixels(target:)`, a read polled until it hands back an `Image`.
  - **The tests:** `#336699` reads back `0x33 0x66 0x99` on every leg, hardware included, and against its golden on WARP
    and SwiftShader. Also covered: an alpha of 0.4 is 102, a copy of a target clears the target, a target never cleared
    reads 0, a read dropped while pending is safe, and two renderers share one device.
  - **The counts:** 32 cases on each golden leg, 28 in Edge.
  - **The proof:** 30 of 31 mutations caught, after the gate was sharpened twice. Every leg must now run its GPU cases
    to the end, and natively a run naming SwiftShader on WARP must print no frame. The one not caught drops a verdict
    only a device that never opens reaches.
  - **SPEC.md now describes what is built,** since it said nothing was.

**The twenty-fourth session** (2026-11-14). Every suite was green on the 0.9.949 pin at the start (kama had reached
0.9.950, `std::fs::Watcher`, nothing kyoten uses). Each part was test-first and committed with every suite green:

- **The decoder fixed first** (kama-image `9f704e9`). Reading libpng 1.6.50's writer for IMG-2 found two places the
  decoder kept chunks other than as libpng does:
  - it kept a cICP whose matrix is not 0, which `png_set_cICP` drops and the PNG Third Edition forbids;
  - it counted a broken colour chunk as seen, so it dropped a good one after it.

  Ten crafted fixtures, held to libpng, were red first. 11 of 11 mutations were caught.
- **IMG-2 built** in three parts:
  - **The encoder** (`a6baa14`):
    - the image as it is held, but an opaque image without its alpha;
    - `Adaptive` as libpng's `png_write_find_filter`, with its one-row and one-column rules, held to libpng's choice for
      every row of every fixture;
    - IDAT chunks of 65,536 bytes;
    - the refusals.

    The decoder's shared helpers moved to `image::png::detail`, which only `image::png` reaches. 30 of 31 mutations
    were caught. The 31st, the guard on a width past 2³¹ − 1, needs a 2 GiB image to reach.
  - **The colour chunks** (`9831d5c`). What the image carries is written back, and its colour space is written where
    that does not give it. The check is the decoder's own precedence, so a contradiction is refused as the new
    `Metadata` kind. 34 of 34 mutations were caught, two after their cases were sharpened.
  - **The promise** (`8575bb8`):
    - `archival()`'s bytes are written down for a fixed set;
    - the gate holds every leg's bytes to the others';
    - `tools/reference/encoded.sh` has libpng read every file written from the fixtures, with no warning and with its
      answer unchanged from the fixture's.

    The gate's own new check, proved by mutation, had a `diff | head` that `pipefail` cut short; it was fixed.
- **Settled under the owner's word on decision 4** ("I will defer to your production answer"), and reported at the
  session's end: the colour type written, what is refused, the colour chunks for each colour space, what is written
  back, the IDAT size, and `Adaptive` as libpng's.

**The twenty-third session** (2026-11-14):

- **The pin bumped to 0.9.949** (`9f1fdaef`, kyoten `55ca3ac`), the owner's choice at the session's start, for KY-56's
  fix. Its repro failed 0 of 20 runs on 0.9.949 and 15 of 20 on 0.9.947 the same hour, and the entry is removed. Every
  suite was green with nothing else changed, at the twenty-second session's closing counts, and kyoten's and
  `@kama/gpu`'s suites ran at once.
- **`@kama/image`'s five questions measured** (kama-image `RESEARCH.md`, `ffcbb22`; probes in its `.scratch/img-probe-*/`).
  The probes compared PngSuite and ten crafted files against libpng's pixels, in Edge, Chrome for Testing and Firefox:
  - 8-bit PNGs are exact through a WebGPU or WebGL copy in every browser.
  - No browser keeps 16 bits: Chromium truncates and Firefox rounds.
  - Chromium decodes a bad Adler-32, and Firefox also decodes a broken CRC and a truncated stream.
  - The browsers' encoders write different bytes and lose straight alpha.
  - A kama PNG codec adds 12.9 KB brotli to a page.
  - std's deflate wrote the same bytes on native debug and release and on wasm.
  - kama's `-Oz` wasm release makes a codec 3 to 3.5 times slower than `-O3`: KIMG-1, evidence for kama's KR-332.

  The questions were asked in full in the chat. The owner decided questions 2 to 5 as recommended (kama-image
  `3c8a8b8`): the image type, strict decoding within limits, every format roadmapped with PNG now, and the encoder's
  `standard()` and `archival()`. Question 1 drew four follow-ups, each answered in its `AGENTS.image.md`. A request's
  check each frame costs 1 ns natively and 0.6 ns on wasm (kama-image's `.scratch/img-probe-poll/`). Question 1 waits
  on the owner's confirmation. The leftover `kama-run-35448.exe`, idle since 2026-11-12, was stopped at the owner's
  word.
- **Question 1 confirmed** ("sounds good to me", kama-image `fc1d108`): every design question is decided.
- **IMG-1's first part built** (kama-image `2f0e87c`, `32120bc`), test-first:
  - `Image`, with its samples in typed `FixedArray`s handed out through view mints (`bytes()`, and the package's own
    `samples8/16/F32` contracts), `ImageError`, `DecodeOptions` and `DecodeLimits`;
  - `image::png::decode`;
  - `tests/`: every PngSuite file and 13 crafted cases held to libpng 1.6.59's answer (generated by
    `tools/reference/run.sh`, reproduced byte for byte), and 33 hand-built refusals;
  - 219 cases natively, debug and release, and on wasm under node.

  It was red first: 186 of 186 failed against a decoder that refused everything. 41 of 42 mutations were caught. The
  42nd, a Paeth tie broken the other way, is shown equivalent. Four that were missed at first sharpened the tests.
- **IMG-1 finished** (kama-image `010dbba` to `a18a3f3`), each part test-first with every mutation caught:
  - **the colour chunks** (40 mutations), as libpng 1.6.50's source keeps them. An ICC profile is never matched to
    sRGB, as libpng no longer does. A gAMA of 0 is dropped, where libpng 1.6.59 reads it as 1.0;
  - **the flip-and-cut sweep in the gate.** A flip's chunk CRC is put right first, as libpng's OSS-Fuzz harness does,
    so the flip reaches the inflate and the filters. Debug builds compile the package at the release level
    (`debug.optimize`) and keep kama's traps, so a leg takes 24 s where `-O0` took 405;
  - `keepGrey` (7 mutations), `convert(to:)` (15) and `partial` (8);
  - an APNG's default image.

**The twenty-second session** (2026-11-14). Test-first, with every suite green and every mutation caught before each
commit:

- **The pin bumped to 0.9.947** (`f919c10e`, kyoten `e81a3c7`), once the owner said KY-55 was fixed: its repro refused
  on 0.9.943 and right on 0.9.947, and every suite green with nothing else changed, at the twenty-first session's
  counts. The node sketch takes a number on either side of an operator.
- **KY-56 filed:** two native `kama run`s at once break each other's builds, since each writes its generated C into the
  shared temp folder under the same names (11 and 13 of 20 runs failed, four at once). It turned six of the tool's cases
  red at the session's start, while a sketch ran beside the suite.
- **GPU-15 built** (kama-gpu `b294d66`): `AdapterOptions.forceFallbackAdapter(on:)`, its shape by GPU-4's decision 1.
  WARP natively and in Firefox (452 texels drawn), SwiftShader in Chrome for Testing and Edge through the driver (453),
  each the same bytes twice. Chromium gives WebGPU SwiftShader only when asked on its command line (Edge:
  `--enable-unsafe-webgpu`; Chrome for Testing: that and `--enable-unsafe-swiftshader`, measured one flag at a time), so
  Chromium under `kama run` passes `--no-fallback-adapter` (KY-57 filed), a flag that fails a run offered one. 9 of 9
  mutations caught.
- **Found on the way and fixed** (kama-gpu `c490c01`): with every case on WARP, a read-only depth pass lost the device
  and the next map ended the process. A C probe (`.scratch/warp-lost/`) showed wgpu-native v29's D3D12 loses the device
  there, on WARP and the AMD GPU alike, unless the depth texture can also be bound, and that a submit to a lost or
  destroyed device panics. Natively the seam now finishes an empty encoder quietly before every submit, skipping the
  submit and failing the map when the device can take no work, so `device.lost()` answers, as in a browser. Two facts
  pin it, and 7 of 8 mutations were caught, the eighth equivalent. A gfx-rs/wgpu issue is drafted.
- **GFX-1's parts laid out, and part 1's three questions decided by the owner** ("Yes both I take your
  recommendation"; "If it makes sense to have a separate image package I'm good with that"; "yes I take your
  recommendations"). The owner asked what a golden is; it was explained in plain words (a saved picture, compared on a
  software GPU because real GPUs cover edges a little differently) before the third answer. `@kama/image` was seeded
  (`../kama-image`, `992942c`).

**The twenty-first session** (2026-11-13). Test-first, with every suite green and every mutation caught before the
commit:

- **Every suite was green on 0.9.943 at the start,** at the twentieth session's counts: kyoten's (the engine's 164 natively
  and on wasm, the tool's 192), `@kama/gpu`'s (301 natively, 278 in Edge, Firefox and Chrome for Testing) and
  `@kama/window`'s. kama stood at 0.9.945 (`c474b5e9`) all session, with the pin on its history and nothing kyoten waits
  on, so there was no bump.
- **Question 15, decided by the owner** ("B, as recommended"): `examples/triangle` reads its own window back, since
  "60 frames with no WebGPU error" is also what a frame with nothing drawn gives.
- **GPU-4 part 5 built, and with it GPU-4** (kama-gpu `e100084`): `examples/triangle`, a triangle spun in a window
  through a vertex buffer, an index buffer and a bind group whose uniform is written each frame, with its group's layout
  written out and nothing released by hand. Under `--frames 60` it copies its last frame out of the window and holds
  three texels: the centre, a point towards the red corner at the frame's angle, and the clear colour. The gate runs it
  natively, in Edge and Firefox under `kama run`, and in Chrome for Testing through the driver.
  - Red first twice: the gate's step before the example, then the example without its draw, which presented 60 frames
    with no WebGPU error and read back the clear colour.
  - The point towards the red corner came after a first run: with the centre and a corner alone, a spin never written
    passed. The window is 600 wide so that a copy's rows need padding, which 640 hid.
  - COVERAGE.md stays at 95 of 206: the uncalled rows of the render path's sections are the `SetLabel`s, which GPU-8
    holds, and compute's, GPU-5's.
  - 21 of 21 mutations caught: 16 natively, four in Edge, and a raw handle taken in the example, caught by the gate's
    grep alone. Six of the drawing's mutations leave WebGPU silent, so only the read back catches them.
- **GFX-1's four questions, measured, then asked** after the owner said to go on to them (research/graphics.md § 9):
  - reversed depth resolves 5 cm at 5 km on depth32float, where the standard convention gets every pixel wrong or tied;
  - a typed node builder reads close to TSL in kama and refuses a float in a colour slot at compile time, but a type
    cannot overload one operator for both itself and a number on the right, filed as KY-55;
  - SwiftShader runs WebGPU in Edge and the pinned Chrome for Testing, and WARP natively and as Firefox's fallback, each
    the same bytes on every run, and every hardware leg here the same bytes as the others;
  - Chrome for Testing loads a page it was started on with its network service unsandboxed, for WIN-24 to weigh.
- **GFX-1's four questions, decided by the owner the next morning** (2026-11-14), each as recommended: "I will take your
  recommendation" (1 and 3), "I will take your recommendations as well" (4), and for 2, "It sounds like typed is the
  production answer. We lean that way typically." The owner asked whether node types are a bound list and whether
  custom ones are possible; measured in the sketch: custom nodes come three ways (a kama function, a wrapped WGSL
  function, and a program's own node type through the public node contract), each checked as the library's are. The
  contract being public from GFX-1 was proposed with that answer, for the owner to object to. `@kama/gpu` gained
  GPU-15, the fallback adapter, which GFX-1 pulls first.
- **Found on the way, and fixed in a kama-gpu commit of its own (`08d12e8`):** two of GPU-4 part 3's cases counted the compile
  isolates before each had started, and failed once natively in debug ("1 run, not 2"). Holding each isolate after the
  first 300 ms reproduced it every time. Both now wait by the clock and then hold the count exactly, so a pool one short
  or one over still fails.

**The twentieth session** (2026-11-13). Test-first, with every suite green and every mutation caught before each
commit:

- **Every suite was green on 0.9.940 at the start,** at the nineteenth session's counts.
- **The pin bumped to 0.9.943**, as the owner asked first thing, with every suite green at the same counts and nothing
  else changed. It brings KR-386 and KR-387 for the Mac's `@kama/audio`. The Mac had bumped to the same commit and
  pushed first (`01c1eae`), so Windows's results joined its `.kama-version` entry (`0892565`) when this session pushed.
- **GPU-4 part 4's probe** (`.scratch/gpu4-part4/FINDINGS.md`) ran 149 misuses of textures, views, passes and their
  commands, natively and in Edge:
  - every pass error lands at `encoder.finish()` on both legs;
  - a browser throws on NaN clear colours, blend constants and viewports, on numbers at 2^31 or above (which
    emdawnwebgpu hands JavaScript negative in a release build), and on a gated view format;
  - emdawnwebgpu passes webgpu.h's NaN "no clear value" for a depth attachment, so loading depth ends a web program;
  - natively, an unbind and a count of 0 end the process;
  - wgpu-native takes stencil ops on a depth-only format, and a view usage the texture lacks.
- **Questions 11 to 14, decided by the owner** ("I will take your recommendation on all 4 questions"): all eight pass
  commands with no unbind, views by description, the depth-stencil attachment typed per aspect, and a refusal inside
  a pass reported at `finish`. They were first asked mid-turn and lost in the scroll; the owner asked that a question
  always come last in a turn.
- **Built in four commits** (kama-gpu `ce9b492`, `2e1b8e4`, `6158db2` and `3122d2f`):
  - **textures by description:** `TextureDescriptor` and WebGPU's `GPUTexture` attributes, brought forward to prove
    each field reaches the backend, with a view format's feature refused. Red first, 13 of 17. 25 of 25 mutations
    caught, one in Edge;
  - **views by description:** `TextureViewDescriptor` with `mips(first:, count:)`, since kama reserves `base`. It
    refuses a count of 0, a gated format, and a usage beyond the texture's. A texture, and a surface's frame, now hold
    their device, so a refusal reaches its channel. Red first, 12 of 15. 21 of 21 mutations caught, one in Edge;
  - **the pass by description,** after the owner said to go on once both repositories were pushed: colour
    attachments with load and store ops, a resolve target, a depth slice and empty ones, and the depth-stencil
    attachment typed per aspect. A refusal inside a pass rides a carrier set as vertex buffer 0, measured first: an
    invalid carrier is reported ahead of an earlier error natively, and a valid one made for copies alone keeps
    WebGPU's order on both legs. It refuses non-finite clear values and ops on an aspect the view's format lacks. Its
    cases catch two of part 3's carried mutations, the depth bias slope and both stencil faces. Red first, 25 of 28.
    36 of 36 mutations caught, one in Edge, and part 3's carried slope and both faces with them;
  - **the pass's eight commands,** after the owner said to go on again: vertex and index buffers over a
    `BufferBinding`, bind groups with and without dynamic offsets, the blend constant, `drawIndexed`, the viewport, the
    scissor and the stencil reference, drawn and read back. A slot, group index or scissor value at 2^31 or above and
    an offset or size past 2^53 - 1 are clamped; a non-finite blend constant or viewport is refused at `finish`. A draw
    count of 2^31 or more is refused on the web alone, since emdawnwebgpu converts the counts as 31-bit numbers, and
    passed on natively, which can draw it. The instanced case catches part 3's last carried mutation, the step mode.
    Red first, 27 of 28. 46 of 46 mutations caught, five in Edge.
  - **Fixed on the way:** a mapped read asked for its bytes twice answered nothing the second time on the web, a bug
    since GPU-3, since the seam asked emdawnwebgpu for the range again and a browser refuses a second range over the
    first.
  - wgpu-native v29's errors for a view never name its label, where Dawn's and Firefox's do; and its pass errors never
    name the pass, nor do Firefox's (`--unnamed-pass-errors`). Firefox 160 takes a depth slice of 2^32 - 2 on a 2D view
    (`--unchecked-depth-slice`). Firefox 160 delivers no second uncaptured error whose words repeat an earlier one's.
  - `tests/` is 301 cases natively and 278 in each browser. COVERAGE.md: 95 of 206.
- **Asked by the owner:** how many sessions to the lit cube. About 7 to 9 for GFX-1 done, at a part a session: the
  rest of GPU-4, then GFX-1's renderer, scene graph, node-graph material, depth prepass, MSAA, HDR and golden harness.
  kyoten's hello cube also needs the join.

**The nineteenth session** (2026-11-13). Test-first, with every suite green and every mutation caught or explained
before each commit:

- **Every suite was green on 0.9.938 at the start,** at the eighteenth session's counts. kama moved one commit past the
  pin, `3fe52f50`, CI only, so there was no bump.
- **GPU-4 part 3's probe** (`.scratch/gpu4-part3/FINDINGS.md`) ran 63 misuses of a pipeline's description natively and
  in Edge.
  - Natively, a depth write to a format with no depth ends the process.
  - On the web, these throw: a non-finite depth bias or pipeline constant, a stride past 2^53 - 1, a `Src1` blend
    factor without its feature, and **any texture format whose feature the device lacks, `createTexture` included**,
    which part 2's "nothing a program passes ends it" had missed.
  - wgpu-native takes three descriptions WebGPU refuses: question 10, asked in the chat.
- **Built in four commits** (kama-gpu `b2e16af`, `2a832e9`, `99eaf80` and `88d4a0b`):
  - **the feature-gated formats refused** in `createTexture` and storage layouts, with `TextureFormat.requiredFeature()`
    generated by wgpugen; 19 of 19 mutations caught. A test bug found on the way: the binding cases ran after the case
    that drops their queue, so their flush did nothing;
  - **the description types and `createRenderPipeline`,** with `VertexState` and `FragmentState` as types of their own
    (decision 1's rule; the owner to object), `ColorWriteMask` with `None`, `VertexFormat` generated, and
    `setPipeline`/`draw` brought forward from part 4, since only a draw read back proves the defaults; 56 of 59
    mutations caught, part 1's leftover among them, and three carried to part 4;
  - **`DeviceOptions.printErrors`,** held from outside the program by `tools/test.sh`; 12 of 12;
  - **`createRenderPipelineAsync`:** one request on both legs. Natively the package's own compile isolates take a deep
    copy of the description, with an overflow in the seam so asking never waits, and a pending request keeps its
    device's isolates. Fact 29 pins wgpu-native's abort. On the way: natively a test tick takes no time, so the
    asynchronous cases wait by the clock.
- **Firefox with WebGPU runs every case** once `ffrun.sh`'s wrapper was fixed for 0.9.938's runner, and found a fourth
  difference from Dawn: a buffer of 2^53 - 256 bytes is an OutOfMemory error there (`--huge-buffer-out-of-memory`).
  Firefox's asynchronous rejection also drops its cause's words.
- **Audio, the owner's ask:** `@kama/audio` is its own package (`../kama-audio`, seeded with `kama seed`, pushed), for
  the Mac Mini to design and build in parallel, recorded in [design/audio.md](design/audio.md) § Decided.
- **Then, once the owner had pushed and the Mac had begun audio's design:**
  - **The pin bumped to 0.9.940** (`da9e64e`), as the owner asked once kama fixed KY-54 (`fa9e13c3`), with every suite
    green and nothing else changed. `@kama/gpu`'s Firefox leg then found an adapter and ran all 185 cases. KY-54 was
    removed, and Firefox's whole leg joined `@kama/gpu`'s gate (`f48d42a`): every case, the printErrors check and the
    clear, with only its three measured differences passed.
  - **Question 10, decided** (the owner: "I will take your recommendation A as revised", having said "I would prefer
    not to nerf native unless it is something that isn't needed"). Re-measured first: wgpu-native refuses 9 vertex
    buffers that carry attributes, and leaves only the slots with none uncounted (40 taken, past the adapter's 16).
    None of the three is a capability, so decision 10 (kama-gpu `b6020af`, built in `87379de`) refuses empty
    slots past the device's `maxVertexBuffers` and alpha to coverage at one sample on both legs, and pins the
    unwritten target as fact 30. A device that needs more vertex buffers asks for them in `DeviceOptions.limits`.
    Measured on every leg: Firefox's later wgpu refuses the unwritten target and counts the slots, so only alpha to
    coverage is still wgpu's, and the draft issue for the owner says so. 9 of 9 mutations caught, and fact 30's own.

**The eighteenth session** (2026-11-12). Test-first, with every suite green and every mutation caught or explained
before each commit:

- **Every suite was green on 0.9.928 at the start,** at the seventeenth session's counts. kama had not moved since
  `94365be5`.
- **The pin bumped to 0.9.938** (`3f27d2e`), as the owner decided, with every suite green and nothing else changed.
  KY-52 and KY-53 passed their repros and were removed (`4f07576`). KY-52's fix is `kama run --scale`, giving 1.5 in
  Edge and Firefox. Under KY-53's fix, Chrome for Testing is named after 62 s, quoting its own "Network service
  crashed".
- **`@kama/window`'s scale cases run under `kama run --scale 1.5`** (kama-window `c8387b1`), as WIN-18's decision 3
  said: 253 cases in Edge and in Firefox, up from 245, and 264 through the driver. The run without the driver now
  reaches the one-axis hold, held to 30 frames, and fails itself if it ever stops short. 7 of 8 mutations were caught;
  the eighth (the scale always 1.5) is equivalent, since every run is at 1.5. One mutation showed the hold case passed
  after 12 frames, so it was sharpened. WIN-24 is narrowed to trusted input and Chrome for Testing.
- **GPU-4 part 2's probe** (`.scratch/gpu4-part2/FINDINGS.md`) ran each misuse natively and in Edge. These end the
  program on one leg:
  - a `writeBuffer` of a byte count not a multiple of 4 (the web throws);
  - any 64-bit size or offset past 2^53 - 1 (the web throws; natively a `minBindingSize` of `UINT64_MAX` aborts);
  - an empty buffer binding (natively);
  - a non-finite LOD clamp or clear colour (the web throws, and natively a NaN is taken silently).

  It also found that natively a write is not seen by a map until the next submit.
- **Five questions, asked in full in the chat, each answered as recommended:**
  - 1, the pin bump;
  - 2, typed flag sets (`BufferUsage`, `TextureUsage`, `ShaderStage`, and `ColorWriteMask` in part 3), since
    `TextureUsage::CopyDst`, `BufferUsage::MapWrite` and `ShaderStage::Fragment` were the same `uint64`;
  - 3, buffers by description, with a label;
  - 4, the sampler's description, by decision 1's rule;
  - 5, after the probe, decision 9: **nothing a program passes ends it.** Every misuse is a validation error on both
    legs, reported where WebGPU reports one, and the handle comes back invalid. The owner asked what that meant before
    answering, "yes to A".

  These are kama-gpu AGENTS.gpu.md item 12's decisions 6 to 9 (`0952720`, `89f11d2`).
- **GPU-4 part 2 built in five steps** (kama-gpu `d5c474b`, `623ba00`, `c6002a5`, `f41d5d7` and `766fd29`):
  - the flag sets, with an xfail held to its four refusals;
  - buffers by description, a size past 2^53 - 1 clamped to 2^53 - 256;
  - samplers;
  - layouts, pipeline layouts and bind groups;
  - `queue.writeBuffer`, natively flushed before a map.

  Decision 9's plumbing is in the seam:
  - the refusal rides a carrier call on both legs: a 4-byte buffer with no usage, labelled `kama-gpu-refusal:<n>`,
    whose words `report_of` swaps for the package's, so it lands in the same scope and order as a real error;
  - a quiet section drops a substitute call's error, the substitute making the invalid handle a refusal hands back.

  `tests/` went from 109 cases natively and 88 in each browser to 141 and 118, with 21 in Firefox, mostly from the new
  `tests/src/bindings.kama`, a step a tick on both legs. Mutations: 12, 6, 12, 17 and 11, each caught, two of them
  only once a case was sharpened: a `has` of two flags, and a map after the queue's last copy is dropped.
- **For part 3:** today's `beginRenderPass(clear:)` ends a web program on a NaN colour (measured); part 4's pass by
  description refuses it.
- **A process from the seventeenth session was left running** (its compile-isolate sketch, hung by design), and could
  not be stopped from here: the classifier refused `Stop-Process`. The owner was told.

**The seventeenth session** (2026-11-12). Test-first, with every suite green and every mutation caught or explained
before each commit:

- **Every suite was green on the pin, 0.9.928, at the start,** at the sixteenth session's counts. kama had not moved
  since `addd14cd`.
- **A visible Firefox 160 gives WebGPU here, and so does a headless one with one pref,** `layers.gpu-process.allow-headless`
  (`.scratch/ff-webgpu-visible/`, `.scratch/ff-webgpu-headless/`). `kama run` does not set it: **KY-54** (`5ef8a4a`).
  A slip on the way: a hand-run copy of kama's runner, given `--headless` where it takes `1`, opened a visible Firefox
  on the owner's desktop for a moment; it was closed and the owner told.
- **GPU-4 measured on both legs** (`.scratch/gpu4-pipelines/FINDINGS.md`): wgpu-native ends the process on
  `GetCompilationInfo` and on `CreateRenderPipelineAsync`, and reports a WGSL error inside `createShaderModule` with
  its place in characters; Dawn reports it a task later in UTF-16 units; a pipeline made on another thread works
  natively; a zero-filled sample mask draws nothing, silently, on both legs. A kama sketch of the descriptors and one of
  a compile isolate compiled (fields drop in reverse declaration order, or the isolate's join hangs).
- **Six questions, asked in full in the chat, each answered as recommended** (the owner asked that 3 to 5 be explained,
  and that the API be "easy to use correctly and hard to use incorrectly"): WebGPU's dictionaries as kama types;
  pipelines both ways, natively on the package's own compile isolates; a shader's errors part of the API, hard to miss
  (a failed pipeline carries its shaders' messages, `printErrors` on by default, `compilationInfo()` in UTF-8 bytes);
  `writeBuffer` forward from GPU-8; the pass and textures by description; Firefox's leg in the gate headless once
  KY-54 lands, and its differences fixed first (kama-gpu AGENTS.gpu.md items 11 and 12, `851a5f4`).
- **GPU-14 built** (kama-gpu `40e4eca`): Firefox with WebGPU found three differences from Dawn. A surface now lists only
  the canvas formats its browser takes (Firefox refuses an RGBA16Float canvas by throwing), a configure the browser
  throws on is refused, `--no-immediates` pins Firefox's missing `maxImmediateSize` to 0, and the web-timing error
  cases make each error distinct (Firefox reports a repeated message once). `tests/` passes all 75 cases in Firefox
  with the pref; 6 of 7 mutations caught, the seventh equivalent.
- **GPU-4 part 1 built** (kama-gpu `c50b115`): shader modules and their compilation messages, placed in UTF-8 bytes on
  both legs; naga's place format and the sixth abort held in `tests/facts`. It found **emdawnwebgpu freeing a module's
  cached compilation info on a second ask** (a use-after-free in its `webgpu.cpp`), so the package asks once per
  module. Firefox with WebGPU, run by hand, showed its compiler is naga too: a message's words are now one line on
  every leg, and `--no-shader-warnings` pins Firefox's lack of warnings. `tests/` is 109 cases natively and 88 in each
  browser; 13 of 14 mutations caught, the fourteenth (a copy without its `AddRef`) waiting for part 3's pipelines to
  make it visible. COVERAGE.md: 59 of 206.
- **kama moved four commits during the session** (to `94365be5`), answering KY-52 and KY-53 (above); the pin stayed.

**The sixteenth session** (2026-11-12). Test-first, with every suite green and every mutation caught or explained before
each commit:

- **Every suite was green on the pin, 0.9.911, at the start,** at the fifteenth session's counts.
- **Five minutes with pads, at the start** (the owner; `.scratch/win4-gamepads/FINDINGS.md`, runs 8 and 9; kama-window
  `2c249b2`): **GameInput's device id follows a pad to another USB port** (the 360 pad, moved between two USB-A
  ports); **a pad's labels follow the mode its firmware chose**, not what is printed on it (the 8BitDo, Nintendo's
  print, labelled as an Xbox pad); and **Steam takes the guide button**, so a program may never receive it. The Series
  pad enumerates only on the mini PC's USB-C port.
- **The pin bumped to 0.9.928** (`59fe835`), as decided, once kama fixed KWIN-1 (KR-379) and KY-51 (KR-380), both of
  which landed during the pad work. Every suite was green with the one port, kama-gpu's clear to
  `Parseable::<int32>.parse(text:)` (`6abd4cd`; its floor 0.9.915, `8ddcf04`). Both workarounds were retired test-first:
  KY-51's `./` (`f626a33`; the tool's tests failed 163 of 175 built on 0.9.911 with the variable set, none on 0.9.928)
  and KWIN-1's copies element by element (kama-window `b16e21c`, 6 mutations caught, a seventh equivalent and
  removed).
- **WIN-18 measured** (`.scratch/win18-kamarun/`; kama-window AGENTS.window.md item 10, kama-gpu AGENTS.gpu.md item 11):
  under `kama run`, Firefox 160 runs kama-window's browser cases as Chromium does, and what fails in all three browsers
  is trusted input (kama's KR-378) and a device scale `kama run` cannot set. WebGPU needs no flag in headless Chromium.
  Headless Firefox gives WebGPU no adapter, and `canvas.getContext('webgpu')` answers null there. An unzipped Chrome for
  Testing never loads a page under `kama run`: its sandboxed network service crashes at start-up, even after its folder
  was given the four grants an installed Edge's carries (`~/browsers/README.md`).
- **Five questions, each answered as recommended:** `kama run` for every case it runs and no BiDi client; the Chrome
  for Testing folder's permissions (done, not enough); KY-52 filed; Chromium-only WebGPU, Firefox reporting its missing
  adapter; the drivers kept for the pinned Chrome for Testing alone (kama-window `38db04f`, kama-gpu `fa10461`).
- **Built** (kama-gpu `47aa9ca`, kama-window `a5e46b5`):
  - in `@kama/gpu`: `Surface.make` refuses a canvas the browser gives no WebGPU context, asking the page first
    (`js/gpuseam.js`), where emdawnwebgpu's assertion ended a debug build; `GpuError::NoAdapter` for webgpu.h's
    `Unavailable`; `--adapter-optional` for Firefox's leg alone; the too-wide case independent of the scale;
  - in `@kama/window`: `--driver`, the 7 scale cases and the trusted-input steps skipped by name without it, and the
    driver's run failed if it skips one;
  - in both: `tools/browsers.mjs` and the legs in `tools/test.sh`. kama-gpu's `tests/` is 75 cases in Edge and Chrome
    for Testing and 18 in Firefox; kama-window's is 245 in Edge and Firefox, and 264 through the driver. Mutations:
    6 of 6 in each package, each caught in the browser it belongs to.
- **Filed in kyoten:** KY-52 and KY-53; KY-50 and KY-51 were fixed and removed (`39c347d`, `f626a33`).
- **kama moved nine commits after the pin** (to `addd14cd`): refinements of the browser runner, then macOS and iOS
  work (`kama run`'s `.dSYM` on macOS, Apple's entropy source, a kama static library linked into a C host, KR-381, and
  a UIKit app around one on the iPad). No row needs them yet; the macOS ones matter once kyoten runs on the Mac Mini.

**The fifteenth session** (2026-11-12). The fourteenth session's record was committed and all four repositories
pushed at its start (the owner's choice). Then WIN-4, test-first, with every suite green and every mutation caught or
explained before each commit:

- **Every suite was green on the pin at the start.** `../kama` had moved one commit, KR-377's brief, then two more
  during the session (above); the pin stayed on its history, and no row needed a bump.
- **Measured first, with the owner's pads** (`.scratch/win4-gamepads/`, its `FINDINGS.md`): a wired Xbox 360 pad, a
  wired Xbox Series pad and an 8BitDo Ultimate. A native C probe over GLFW 3.5.1 and SDL3, the probe page in visible
  Edge 157 and Firefox 160, every press made with another window focused unless stated:
  - **GLFW duplicates a replugged pad through DirectInput, its right trigger reading fully pulled,** in 9 of 20
    replugs, both Xbox pads; SDL3, run alone beside a GLFW window as Godot 4.5 does, never on one backend;
  - **a pad reports in the background** through XInput, GLFW and SDL; Windows.Gaming.Input gives none unfocused;
  - **GameInput** needs Microsoft's runtime (Windows 11 ships 0.2309, API 0): with the redistributable installed (the
    owner's go-ahead) it read all three pads in the background, played every motor of both Xbox pads (the owner felt
    each, distinct), named each pad's maker and model, and kept each pad's id across replugs and runs. With GameInput
    and XInput both on, SDL 3.4.18 adds a replugged pad twice; SDL's main branch has the fix, no release yet;
  - **the browsers:** Edge exposes every pad on one press and gives no input unfocused or hidden, with dual and trigger
    rumble; Firefox exposes each pad on its own, gives input while visible, and has no rumble;
  - the 8BitDo came up for 2.9 s as a Switch Pro pad through SDL's own driver (gyroscope, player lights, Nintendo's
    labels) before its firmware chose Xbox mode; Bluetooth is off on this machine (the owner: "it was leaking").
- **Nine questions asked in full, each answered as recommended** (kama-window `1d65eac`): SDL3 natively and the Gamepad
  API alone on the web (the owner: "as lean as possible on the web"); events and state; dead zones, drift and curves in
  KYR-54's bindings (2a); the W3C layout with face buttons by place, a raw view and SDL's database shipped and
  updatable; slots, a returning pad's player being kyoten's; background reads off by default; the focus release
  extended; rumble in the row; tests through the one read function; and GameInput where its runtime is present, XInput
  otherwise, the duplicate's stopgap until SDL releases its fix (WIN-23). WIN-22 (a pad's sensors and lights) filed.
- **Built in five parts** (kama-window `bf20ce5` to `b2dde88`; its AGENTS.window.md item 9): the ring's pads; SDL 3.4.18
  vendored by `tools/vendor-sdl.sh` (237 sources, 452 files, Windows only, never in a web build) with the native
  backend and `padInfo`; rumble; SDL_GameControllerDB's Windows lines, `addPadMappings` and a raw view; and the web's
  Gamepad API. `tests/` went from 140 cases natively, 103 under node and 189 in each browser to 249, 163 and 264. The
  run reads no real pad but where a case asks for one, so it never depends on, or rumbles, the pads plugged in; SDL's
  own path is tested through SDL's virtual pads, the web's through a `getGamepads` of the tests' own. Mutations: 33,
  21, 15, 15 and 14, each caught but three explained: the stopgap (needs a physical replug), SDL's background hint
  (inert with no SDL window), and kept mapping text SDL took nothing from.
- **Found in kama:** KWIN-1, kama-window's first gap: writing an `extern value`'s `InlineArray` field passes `kama check`
  and fails in C. Worked around; its repro is in kama-window's `KAMA_GAPS.md`, for the owner to relay.
- **Found in kama at the session's end: KY-51,** a bug. kyoten's suite failed 163 of the tool's cases when run from a
  shell carrying `NoDefaultCurrentDirectoryInExePath=1`, which this session's PowerShell did: kama's `std::process`
  leaves Windows to search for a program, and a relative path written with `/` is searched for as a bare name, out of
  the current directory. Reproduced alone (`.scratch/ky51-spawn/`); `tools/test.sh` now hands the tool's tests
  `./tools/kyoten/out/kyoten.exe`, and the suite passes with the variable set and without it.
- **Filed in kyoten:** KYR-75, offering GameInput's redistributable in a Windows build, and the engine's notices for
  SDL, its database and GameInput's header once it links `@kama/window`. KYR-54 holds 2a and the returning pad.
- **Not measured:** whether GameInput's device id follows a pad to another USB port, and the owner's other Switch pads;
  both at the next session with pads.

**The fourteenth session** (2026-11-11). Test-first, with every suite green and every mutation caught before each
commit:

- **Every suite was green on the pin at the start,** with the thirteenth session's counts. `../kama` had not moved
  (`db6147f8`, 0.9.923), with the pin still on its history, so the pin stayed.
- **WIN-21 was measured before it was built** (`.scratch/win21-sizing/`, its `FINDINGS.md`):
  - Edge 157 matches Chrome for Testing 157 on every shape the investigation measured;
  - a canvas the page sizes by its height alone holds, as a width-only one does;
  - **the `aspect-ratio` canvas seen rewritten 15 times in 30 frames is not a bug.** Alone it holds, 1 write in 60
    frames, in 48 runs: both browsers, ratios 1.25 to 2, fractional offsets, both forms of the property, and 19 million
    pixels down the page. On the investigation's page, the runaway above it moved it every frame.
- **WIN-21 built** (kama-window `caba1f2`): under `sizedByPage`, `open` changes the canvas's pixels once, reads its
  layout and puts them back, then refuses in words naming the fix when both axes followed, before anything of the
  canvas is touched. 9 new cases in each browser (189), and 9 of 9 mutations caught. `@kama/gpu`'s suite stayed green on
  it, its `#flat` canvas (not displayed) still opening (kama-gpu `8c1c5e1`, a docs touch).
- **The graphics design pass (KYR-68) was done.** Its research came first ([research/graphics.md](research/graphics.md)):
  Three.js's features, the engines' state of the art, what lies beyond WebGPU (wgpu-native's and Dawn's headers read
  locally), and how renderers without a garbage collector hold their objects. Then its five areas were asked in the
  chat in full, and each was answered by the owner as recommended ([design/rendering.md](design/rendering.md)
  § Decided, 2026-11-11):
  1. the object model (`1840bb8`): a flat core of packed instances and a scene graph on it, assets as shared handles,
     nodes through `Shared` with a `Weak` parent;
  2. the names (`c6ed162`): Three.js's type names, `make` with Three.js's defaults, `x()`/`xMut()` pairs, units in
     the labels;
  3. the renderer's core (`5fece61`, `7e59ee5`): clustered forward with a depth prepass and 4× MSAA, typed material
     presets over node materials, pipelines compiled off the frame, a per-object buffer with automatic instancing,
     linear HDR with AgX;
  4. beyond WebGPU (`cdb531d`): techniques as ladders of methods, hardware ray tracing by helping land wgpu-native
     PR #630, virtualized geometry natively first, the library's own upscaler, WebGPU as the web's only backend;
  5. the feature map: `FEATURES.md`, the order by example, budgets that never limit what is built (the owner's
     condition), goldens on a software GPU, and the library's scope. The owner asked whether naming the engines is a
     legal issue; answered in the record (research § 8).
- **The probes behind it** (`.scratch/kyr68-*/`, git-ignored):
  - a lit pipeline takes about 24 ms on one thread, and wgpu-native compiled 48 in parallel 4.7× faster on 8 threads;
    its asynchronous call is `unimplemented!()`;
  - **PR #630 was built and run, with the owner's OK** (`4602c91`): over Vulkan on the Radeon 880M, ray queries
    matched the CPU on every ray, about 1 G coherent rays a second against half a million triangles, and a task and
    mesh pipeline drew its target pixel for pixel;
  - WARP, Windows' software GPU, is reachable through wgpu-native v29 for golden images (`b4b30c1`).
- **Written from it** (kama-graphics `1bb903e`, then `3dbf89e` for LF line endings): `ROADMAP.md` (GFX-1 to GFX-18)
  with its detail, `FEATURES.md` (162 features, all planned), `SPEC.md` (empty until GFX-1 lands), and their guards
  `tools/check-roadmap.sh` and `tools/check-features.sh`, the second seen to fail on each of 13 mutations.
  `AGENTS.graphics.md` carries each area as it was decided (`be2cb67` to `fe2b0cd`). `@kama/gpu`'s GPU-4 got the
  pipeline measurement (`8693712`), and GPU-10 the answer for native features (`82bf863`).
- **Two rows were added at the owner's request:** porting tools from other engines, three.js and Unity first (KYR-73,
  [design/porting.md](design/porting.md)), and benchmarks against other engines (KYR-74,
  [design/benchmarks.md](design/benchmarks.md)). Each is a draft of questions, decided when its row comes up.
- **kyoten's suite did not change:** nothing in kyoten uses the packages yet.

**The thirteenth session** (2026-11-11). Test-first, with every suite green and every mutation caught or explained before
each commit:

- **Every suite was green on the pin at the start,** with the twelfth session's counts. `../kama` had moved to 0.9.922
  (`49089044`, Android ABIs) with the pin still on its history, so the pin stayed.
- **A probe came first** (`.scratch/gpu3-web/`, its `FINDINGS.md`): plain WebGPU pages and a kama program on both
  packages, in headless Edge 157, then Chrome for Testing and Brave, and natively.
  - **Headless Chromium has WebGPU on this machine's GPU** (AMD RDNA 3, not a fallback adapter);
  - **an adapter gives one device on the web**, where wgpu-native grants many;
  - **an uncaptured error waits while nothing is queued,** and arrives a tick after any queue use;
  - **two writers of a canvas's pixels:** emdawnwebgpu's configure wrote its size into the canvas behind the window;
  - `maxImmediateSize`'s default is 64 (the spec), where the package said 0;
  - `@kama/window`'s `sizedByPage` runs away on a canvas the page does not size (WIN-21);
  - `examples/clear` could not run on the web: it waited in a loop inside `main`.
- **Five questions were asked in the chat and answered by the owner,** each as recommended (`../kama-gpu/AGENTS.gpu.md`
  item 10). The owner asked whether one device per adapter nerfs native (no: measured, two adapters give a device each),
  whether a configure without a size touches offscreen rendering (no: only the frames presented), and whether the
  browser runner is best in kama (yes: `kama run` on Android is the same job, and kama's own suite already needs one):
  1. one device per adapter on every leg, `GpuError::Consumed`;
  2. `surface.configure(device:, config:)` sized by its window, the window the one writer;
  3. `sizedByPage` investigated first (WIN-21);
  4. running wasm in a browser is kama's (KY-50), each package's driver a stopgap;
  5. the browser legs on pinned browsers, every one present: **Chrome for Testing 157.0.8103.50 and Firefox 160.0 were
     downloaded and verified into `~/browsers`** (its `README.md`), with the owner's leave.
- **Built** (kama-gpu `746b857` the decisions, then `4176e9a`, `ca77fc0`, `56fc5a6`, `fc7b789` and `bed7022`;
  kama-window `54bdf9f` the rows, then `ebeeb2f` WIN-20, `37c92b1`, `89278da` and `32b9797`):
  - `@kama/gpu`'s browser leg, one device per adapter, a configure sized by its window (`NoWindow` for an adopted
    surface, decided in the building), the surface cases and the clear example in a browser, and a device's errors on
    the web's timing; `tests/` is 96 cases natively and 74 in each browser;
  - `@kama/window`'s WIN-20, `NativeWindow.framebufferSize()`, and its browser leg in every browser present; its tests
    are 140 natively, 103 under node and 180 in each browser;
  - the mutations: 7 of 8 (one device per adapter), 4 of 4 (WIN-20), 4 of 5 (a configure sized by its window) and 6
    of 6 (the seam's web half), each not caught explained in its package's record.
- **WIN-21 was investigated** (a survey of eight engines and libraries, verified against learn-wgpu and Unity's
  tracker, and a layout probe at two pixel ratios), and **decided at the session's end, as recommended:** `open`
  refuses a canvas the page sizes on neither axis. The owner asked first whether it is the production answer: yes, it
  refuses at the mistake on every screen; it refuses CSS that arrives after `open` and `max-width` alone, and does not
  catch a page that removes the size after `open`.
- **On the roadmap, from the owner:** KYR-69 (QA bug reports from a running build, with marker strokes over the frame),
  KYR-70 (promo shots and videos from captures and replays), KYR-71 (animation, first version) and KYR-72 (NVIDIA
  MotionBricks on it).
- **kyoten's suite did not change:** nothing in kyoten uses the packages yet.

**The twelfth session** (2026-11-11). Test-first, with every suite green and every mutation caught or explained before
each commit:

- **Every suite was green on the pin at the start,** with the eleventh session's counts. `../kama` had not moved
  (0.9.917, `f113270e`), so the pin stayed. By the session's end kama was at 0.9.921 (`9751c609`).
- **A probe came first** (`.scratch/win3-web/`, its `FINDINGS.md`): headless Edge 157 driven over the DevTools protocol
  from node 24, with trusted input, on a plain page and on a kama program whose dependency ships a JS library. It
  overturned none of the drafts, and found two things the roadmap had assumed: emsdk's `html5.h` has no Pointer
  Events, ResizeObserver or pixel-ratio change, so the package ships a JS library; and `--dump-dom` cannot run a test
  program.
- **WIN-3's ten questions were answered by the owner in the chat, each as recommended,** and an eleventh was found on
  the way (`../kama-window/AGENTS.window.md` item 8):
  1. one JS library, its listeners queueing records that `pump()` pulls: no call into the program from outside, so
     nothing can abort a page after `quit`. The owner asked whether this is like networking: it is kama's own
     `std::net::web` model ("no callbacks into wasm");
  2. Pointer Events replace `MouseMove` and `MouseButton` on every backend: a `Pointer` value, every button its own
     down and up, a touch or pen contact cancelled at a focus change, moves coalescing per pointer, `PointerButton`
     numbered as the W3C's, and every pointer sample later (WIN-19);
  3. the canvas is the page's, refused rather than created, and `title` is the page's;
  4. focus is the canvas's, not the page's;
  5. the window takes the defaults of the keys it names, a pointer down, the context menu and the wheel, and sets
     `touch-action: none`;
  6. `open` sets the canvas's CSS size unless `WindowOptions.sizedByPage`, and the pixels follow the device's;
  7. pointer lock waits for the next click, and the browser giving it back sets the mode to `Normal`;
  8. no `CloseRequested` on the web;
  9. `Scroll` carries its unit, `Lines` or `Pixels`;
  10. the browser leg in headless Edge, and Firefox as a row before the first publish (WIN-18);
  11. **found on the way:** a `type value` cannot hold a `string` in kama, so a canvas is named by a ctor of its own,
      `Window.openIn(canvas:, title:, width:, height:, options:)`, as `std::net` spells an address; natively the
      selector goes unused.
- **WIN-3 built, in three parts** (kama-window `8997644` and `557b7f0`, the decisions; `0b531ca`, `251dd33` and
  `e4fdf50`, the build):
  - Pointer Events on both backends: 33 of 33 mutations caught;
  - the browser leg, `tools/webtest.mjs`, proven on the headless cases before the web window existed, each of its red
    paths run;
  - the web window: 48 of 50 mutations caught, one more removing code the browser made redundant and one equivalent;
  - `tests/` is 134 cases natively, 100 under node and 175 in headless Edge.
- **Measured in the building:**
  - a click focuses the canvas before its down;
  - a drag released outside the canvas still ends in its up (pointer capture);
  - a touch drag is the program's with `touch-action: none`;
  - Escape gives the lock back unseen;
  - a key pressed in the page's field and let go on the canvas has its up dropped, WIN-2's first open reading.

  A change of the device pixel ratio could not be made headless, so what follows the browser's report is tested
  in-process. The harness needed a larger window, focus with `preventScroll`, and a drag's held button named.
- **`@kama/gpu`'s suite stayed green on each part** (83 cases, 60 frames, the wasm build), and its GPU-3 detail no
  longer suggests `--dump-dom` (`25baa47`). Nothing in kyoten uses the packages yet, so kyoten's suite did not change.

**The eleventh session** (2026-11-10 and 11). Test-first, with every suite green and every mutation caught before the
commit:

- **Every suite was green on the pin at the start,** with the tenth session's counts. `../kama` had moved to 0.9.915
  (`6960ec1c`, a clean tree), with the pin still on its history, so the pin stayed. By the session's end kama was at
  0.9.917 (`f113270e`).
- **WIN-2's seven questions were answered by the owner, each as recommended** (`../kama-window/AGENTS.window.md`
  item 5).
  - **How they were asked:** they were first put in the session's plan with "approving this plan answers all seven". The
    owner approved it, then said "I didn't realize there were questions to approve". They were laid out again in full
    in the chat, and answered there before anything was built.
  - **The answers:**
    1. one pairing rule, kept by the ring for every backend: an up for what is not held is dropped, the window says
       what a repeat is, and a second button down is dropped;
    2. `Key::Unknown` is never held;
    3. the release goes buttons first, then keys by HID id, so the modifiers go last, each up carrying the modifiers
       still held after it;
    4. room is kept for an up of everything held;
    5. a `post`ed event moves the held set;
    6. GLFW's own releases are dropped by the same rule;
    7. `Window.releaseHeld()`.
  - **Asked on the way:**
    - **several keyboards and mice are not pursued** (the owner: "Controllers are the natural split screen solve"),
      since a browser cannot tell them apart;
    - **focus handling is not configurable,** and whether a program reads pads while unfocused is WIN-4's question;
    - **kyoten will handle locale and localization,** so `@kama/window` gains WIN-17: keyboards beyond the US layout,
      their keys named and each key's label in the player's layout.
  - **The owner also asked** why most applications leave keys stuck, why input belongs to the window, and whether the
    window's made-up ups could leave a weird state. The answers are in item 5.
- **A probe overturned none of them** (`.scratch/win2-focus/`). It sent Win32 messages to a hidden window over MSYS2's
  GLFW 3.5.1, so GLFW's own paths ran while the window never took the focus. It measured:
  - GLFW releases after its focus callback, with mods 0, and only on a loss;
  - it filters key ups, but no button event;
  - it reports a key it has no token for (Henkan) as a press every time and never releases it;
  - **its mouse capture stays set after its focus release,** so the suite's native case covers keys only.
- **WIN-2 built** (kama-window `cd8b02f`, the decisions, and `762876c`, the build):
  - one path in the C seam, `take()`, for GLFW's callbacks and `post` alike;
  - 36 new cases: 97 natively and 69 under node, 3 of them on a hidden system window driven by Win32 messages;
  - 31 of 31 mutations caught, one after the case it showed missing was added.
- **One detail decided in the building, within decision 4:** while the ring overflows, an up it owes goes before the
  trailing `Dropped` record, which stays last.
- **`@kama/gpu`'s suite stayed green on it** (83 cases, 60 frames). Nothing in kyoten uses the packages yet, so
  kyoten's suite did not change.

**The tenth session** (2026-11-10). Each part was test-first, with its suites green and mutations caught before its
commit:

- **Every suite was green on the pin at the start,** with the ninth session's counts. `../kama` had not moved
  (`c0b6887d`, a clean tree, the pin on its history), so the pin stayed.
- **WIN-1's four questions were decided, each as recommended** (the owner, 2026-11-10, approving the session's plan;
  `../kama-window/AGENTS.window.md` item 6), after a probe overturned none of them:
  - `NativeWindow` holds the count, not a `Copyable` `Window`, since a `Window` is its event queue;
  - dropping the `Window` closes it at once (hidden, no more events), the HWND goes with its last holder, and a
    surface on a closed window refuses with `Closed`;
  - one record and one count for the headless window and the canvas;
  - Android's `SurfaceLost` closes the window's current record, built with WIN-13.

  The probe (`.scratch/win1-window/`, wgpu-native over GLFW) measured a configure on a surface whose window was
  destroyed aborting the process, and a hidden window's surface working as a shown one's.
- **WIN-1 built** (kama-window `0aa6497`): 18 new cases (56 natively, 33 under node), 8 of 9 mutations caught, and the
  ninth equivalent. The stopgap's own behaviour turns two cases red.
- **GPU-2 built** (kama-gpu `435f184`): a surface, adapter options made with one, and a frame each hold the window.
  9 new cases (78), 6 of 7 mutations caught, and the seventh equivalent natively. The mutations corrected the record:
  with the window held, a closed window is hidden and valid, so `Closed` is the package's rule, not an abort guard.
- **Both packages' tests opened their windows unfocused** (the owner, 2026-11-10: "it fights for focus"), at first
  through GLFW's hints in `tests/` alone. The probe's exit 127 at process end came in 9 of 50 runs while its windows
  took the focus, and in none of 50 unfocused; the cause was not found. **A lead:** GPU-13's reproduction, a wgpu-native
  panic, also ended with 127 under bash, and with Windows' fail-fast status (`0xC0000409`) under python, so the probe's
  127s were likely aborts of that kind, not a command bash could not find.
- **Found on the way:** an acquire on a surface never configured aborts wgpu-native, measured 3 of 3.
- **The two questions those findings raised were decided at the session's end, and built** (the owner, 2026-11-10):
  - **WIN-16, a window opened without taking the focus** ("yes b sounds better": an options value over a separate
    `openUnfocused`; kama-window `e67878f` and `1fd9893`). kama's own rule names it (its SPEC § Construction, KR-367):
    `Window.openWith(title:, width:, height:, options:)` beside an unchanged `open`, with `WindowOptions.make()` and
    `focused`, true by default. Every open sets both GLFW hints, both ways, since GLFW keeps a hint until it
    terminates. The tests open through it and never take the focus even when the package is wrong: the cases that need
    a window that would take it read `FOCUS_ON_SHOW` on hidden windows, and a window is shown only after they pass.
    5 new cases (61 natively, 36 under node), and 5 of 5 mutations caught with no window shown. `@kama/gpu`'s tests
    use it too, and `examples/clear --frames` leaves the focus where it is (kama-gpu `3113d4d`).
  - **GPU-13, an acquire before a configure refused** (as recommended: a new `SurfaceError::NotConfigured` over
    `Outdated`; kama-gpu `a3908d4` and `c7d9968`). The surface answers it without asking WebGPU, from the state every
    copy shares, and an adopted surface is taken as configured by its maker. 5 new cases (83), and 5 of 5 mutations
    caught.
- **Nothing in kyoten uses the packages yet,** so kyoten's suite did not change.

**The ninth session** (2026-11-10). Each part was test-first, with its suites green and mutations caught before its
commit:

- **Every suite was green on the pin at the start,** with the eighth session's counts. `../kama` had not moved
  (`d0835250`, a clean tree, the pin on its history), so the pin stayed.
- **GPU-1's details were decided, six as recommended** (the owner, 2026-11-10, approving the session's plan;
  `../kama-gpu/AGENTS.gpu.md` item 2). Reading the code refined four of the five proposed:
  - `GpuErrorKind`, since `ErrorKind` is `std::io`'s;
  - a ring of 64 reports with each message whole;
  - what an unpopped scope caught goes to the channel;
  - each abort matched by its panic's words.

  It also found a sixth, then measured it. **A child reports to its device's callback after the device's last
  release** (a new probe case, `childafterrelease`, in `.scratch/item2-errors/`), so every handle made from a device
  holds the device's state, not the device's copies alone.
- **GPU-1 built in `../kama-gpu`, in four parts:**
  - `a772ed0`: the decisions, and `tools/check-facts.sh`, 22 facts of wgpu-native's held in the gate, 10 of 10
    mutations caught;
  - `cf2dc25`: the channel and the state's holders, 11 of 11 caught;
  - `44d9691`: the error scopes, kept by the seam natively, 7 of 8 caught. The eighth needs a device on two threads,
    which only `raw()` allows, since a `Device` is not `Sendable`;
  - `ebca0cb`: a failed `finish` never submitted natively, 4 of 4 caught;
  - `9ceb3de`: GPU-1's record, and its row retired.

  `uncapturedErrors()`, `lastErrorMessage()` and `lostDevices()` are gone. `@kama/gpu`'s tests are 69 cases (51
  without a display), and COVERAGE.md is 55 of 206.
- **Nothing in kyoten uses `@kama/gpu` yet,** so kyoten's suite did not change.

**The eighth session** (2026-11-10). Each part was test-first, with its suites green and mutations caught before its
commit:

- **The pin moved to 0.9.911** (`cfd632a`), carrying KR-367, kama's constructor naming rule:
  - the port was 2 `IoError.of` calls here and 1 `parse::<int32>` in `@kama/gpu`'s example;
  - every suite was green on 0.9.909 that morning and on 0.9.911 with the port alone, with the same counts;
  - kama then rebased, so the pin was rebuilt at the rebased twin, `238198b3`.
- **Nine questions were answered,** each as recommended: four for step 1 (architecture.md § Decided, the eighth
  session's entry) and five for `@kama/gpu` item 2. Its probe found five ways wgpu-native aborts the process where
  webgpu.h promises an error, and a device that never reports its loss (`.scratch/item2-errors/`).
- **`@kama/gpu`'s `COVERAGE.md`** (kama-gpu `0988fec`):
  - `tools/wgpugen --coverage` writes it from kama's `--refs` answers, the seam's C and the three headers;
  - `tools/check-bindings.sh` holds it, and its counts are a ratchet;
  - the counting rules are held on a fixture package, with 9 of 9 mutations caught.
- **Both packages' constructors follow kama's rule** (kama-gpu `2272999` and `085279e`, kama-window `948a65c`):
  - `Instance.make()`, `Surface.make(…)`, `FeatureSet.empty()`, `SurfaceCapabilities.make(…)` and
    `AdapterOptions.withSurface(…)`;
  - `Color.of`, `Size.of` and `NativeWindow.of`, each by `@generate(of)`;
  - `TextureFormat::fromValue(value:)`.
- **Each package's `SPEC.md`, `ROADMAP.md` and `ROADMAP_DETAIL.md`, after kama's and FFD's pattern** (kama-gpu
  `33198e1`, kama-window `d52472a`). Each package also has a `tools/check-roadmap.sh` in its gate, with 7 of 7 kinds of
  damage caught.
- **Counts on the pin:**
  - kyoten: the engine's 164 cases and the tool's 192, unchanged;
  - `@kama/window`: 38 cases natively and 22 under node (2 new);
  - `@kama/gpu`: 45 cases, 60 frames, the xfail, and the wasm build.

**The seventh session** (2026-11-10). Each part was built test-first, with its suites green and mutations caught before
its commit:

- **Every suite was green on the pin at the start,** with the sixth session's counts. kama had one docs commit past the
  pin (`25e16d16`), so the pin stayed.
- **`@kama/gpu` item 8's five questions were answered** (the owner, 2026-11-10: "All of this sounds great"), each as
  recommended, after a probe measured what this machine's surface answers (`.scratch/item8-caps/`):
  - RGBA8UnormSrgb first, Immediate before Fifo, and Opaque only;
  - **every invalid surface configure aborts the process natively,** a 0×0 size included (a minimised window).

  The draft had assumed a validation error. The answers, and each leg's measured or read facts, are in
  `../kama-gpu/AGENTS.gpu.md` item 8.
- **Item 8 built** (kama-gpu `18df59e`):
  - `surface.capabilities(adapter:)`, `SurfaceCapabilities` and `preferred()`;
  - `configure(device:, config:, width:, height:)`, which refuses in a `ConfigureError` (`NoArea`, `TooLarge`,
    `NotOffered`) what wgpu-native would abort on;
  - `PresentMode` and `AlphaMode`;
  - sRGB through a view format by default, shared by a surface's copies;
  - `TextureFormat` for all 101 of webgpu.h's formats, generated by `tools/wgpugen`.

  44 cases natively with a display, and 29 of 30 mutations caught. The other is equivalent on wgpu-native, which
  accepts a usage the surface does not report.
- **Item 7 built** (kama-gpu `92a2f5a`): `SurfaceError::OutOfMemory` is gone. The package's tests are 45 cases.
- **Nothing in kyoten uses `@kama/gpu` yet,** so neither change reached kyoten's suite.

**The sixth session** (2026-11-10). Each part was built test-first, with its suites green and mutations caught before
its commit:

- **The pin moved to `0.9.909+g64f011de`** (`4589796`), carrying KR-364's rename, the one change "nothing else
  changed" could not hold off: 12 `JsonDeserializer.strict(src: x)` calls became `make(src: x, strict: true)`, and 3
  `deserializeJsonBuffer` calls, which were lenient, state `strict: false`. Every suite was green on 0.9.899 that
  morning and on 0.9.909 with the port alone, with the same counts.
- **KY-48 closed** (`f147132`): the loader reads each subtree through the parsed tree's own reader,
  `JsonValue.reader(strict: true)`, with nothing written back to text. `mergeTree` and `readTree` in
  `kyoten::content`, 6 cases (two of them for a gap the mutations found), 10 mutations caught. The engine's tests are
  164 cases.
- **KY-49 closed** (`6dad66c`; the owner, 2026-11-10, components § Decided): the tool's query names every module
  but the game's root with `--modules`, 0.09 times the whole package's cost on `spin`, measured relative only. A
  `static` in a game's root is the app's own; a processor or component there is refused, pointing to a module folder;
  a library's root is exempt. 5 mutations caught. The tool's tests are 192 cases with the wasm legs.
- **`@kama/gpu`'s two steps** (kama-gpu `c7e00a3`; the owner's three answers of 2026-11-10 in its AGENTS.gpu.md):
  `requestAdapter`, `AdapterInfo`, `Limits`, `FeatureSet` and `DeviceOptions`, and `adapter.requestDevice(options:)`.
  12 cases natively over Vulkan, 9 of 11 mutations caught (the other 2 equivalent on wgpu-native). wgpu-native was
  measured reporting `maxBindGroupsPlusVertexBuffers` as 0 and not listing `CoreFeaturesAndLimits`; the tests hold
  each per leg.
- **The owner asked** whether the highest-resolution timers per platform are kyoten's or kama's. They are kama's
  (`std::time`: `QueryPerformanceCounter`, `CLOCK_MONOTONIC`, `performance.now()`, and a high-resolution waitable timer
  for `sleep` on Windows; frame-phases § Decided already says so). kyoten owns the frame source and the `Clock`, which
  is handed each frame's time.

**The fifth session** (2026-11-09). Each part was built test-first, with `tools/test.sh` green and mutations caught
before its commit:

- **The suites ran green on the pin, and the harness fix landed** (`db6c785`).
  - The tool's tests' `check` gives "failed, and nothing was said" for an empty reason, and the engine's content
    tests' `all()` gives "no refusals".
  - Both were verified as mutations that passed before the fix and fail after it.
  - No case was hiding a failure.
- **Step 6's four questions were answered** (`d549947`; the owner, 2026-11-09; § Questions, below). They were
  explained in full in the chat, each with an example, after the first asking was hard to read.
- **The generated world, its tables and its passes moved into the root module** (`fa9c2ff`). `src/generated/` keeps
  `Actions` and the prefab types.
- **KYR-53's check** (`eaaf802`, `tools/kyoten/src/fence.kama`):
  - the simulation's fence, as an allow-list across packages;
  - the engine's tiers, from a `tier` in each module's records file, `kyoten::records`' new `Tier`;
  - the platform flags, with `folderFor` the one stopgap exception.

  `kyoten generate` holds a game's lists and source. `kyoten check engine/kama.json` holds the engine's, and
  `tools/test.sh` runs it. Its `--json` became KYR-67. Each part's details are in its design doc's *Built* entry of
  2026-11-09: ai-first-api, target-platforms, architecture and components.

**The fourth session** (2026-11-09), each part test-first, `tools/test.sh` green and mutations caught before its
commit:

- **The pin moved to `0.9.899+gf32373ea`** (`e3e6164`), and kama's fixes were taken (`0c6f9fe`, `14abe9a`):
  - `ChunkSize` counts in `isize` (KR-357);
  - the tool reads each parameter's `path` and the `default ctor` mark (KR-360), so `imports.kama` and `ctorIsDefault`
    are gone, and a component its module does not export is refused by name;
  - a key written twice is refused (KR-359);
  - ids compare directly (KR-358);
  - a bounded list is one size on every target (KY-47).

  KY-39, KY-41 to KY-44, KY-46 and KY-47 are removed from `docs/KAMA_GAPS.md`.
- **`std::asset` was probed, and `preloadFiles` kept for development** (`7bf10bd`; the owner, 2026-11-09;
  project-database § Decided). A dependency cannot ship assets, so the engine's content could not arrive that way.
  `std::asset` becomes the shipped and Quest source behind `RecordSource`, with KYR-66's packs.
- **`kyoten::content`, the loader's engine half** (`482e6b5`):
  - `RecordSource`, `FolderSource` and `LayerStack`;
  - the content and zone file shapes;
  - `readContent`, `layOver`, `readWhole` and KY-48's `subtreeText`.

  A game whose manifest does not preload its `content/` is refused.
- **The loader's game-shaped half** (`4b718d6`): `src/<game>.generated.kama` with `openContent`,
  `loadPrefabs` and `placeFirstScene`, `Prefabs.of`, and the first scene's zones checked at build in the loader's
  words. The details of each are in [design/components.md](design/components.md) § Decided, the built entries of
  2026-11-09.
- **The loader's analysis cost accepted for now, and KY-49 filed** (the owner, 2026-11-09; components § Decided). The
  tool's one query takes about 2.8 times as long on `spin` with the loader, since it analyzes the whole game. kama is
  asked for a `--search` scoped to modules.

**Step 5's parts, each with its details in components § Decided:**

1. **`kyoten::world`** (2026-11-08, `bea9ce5`):
   - `Transform`: a `ZoneCoord` and a `float32` offset, on `std::math`;
   - the 8-byte `Handle`;
   - `ChunkSize::rowsFor(rowBytes:)`, run at compile time from `sizeof`.
2. **`kyoten::records`** (2026-11-08, `d8cfd92`): every record kind whose shape is the engine's, read with `mergeFrom`
   through `JsonDeserializer.strict`.
3. **The `kyoten` tool's first pass** (2026-11-09, `86fbdf4`, `3ab910e`): `@kyoten/cli`'s `generate`, `check`,
   `build`, `run` and `clean`, which write `Actions`, the prefab types and ids and `Prefabs`. It finds components by
   asking kama, and each dependency's answer is cached.
4. **Signatures, passes and the world** (2026-11-09, `043f75a`, `72ce358`): `Store::World`, `Rate`, `Lookup`, and the
   tool's `tables.kama`, `passes.kama` and `world.kama`.
5. **Required components and the module `static` refusal** (2026-11-09, `dc785f3`).
6. **The loader** (2026-11-09, `482e6b5` and `4b718d6`): `kyoten::content`, the generated half, and the zone checks.
7. **Step 6, KYR-53's check,** built in the fifth session (above), on step 5's code records.

- **In scope, and built:** what the hello cube touches.
  - Parameters `ref C` and `const ref C`, `ref W` and `const ref W`, `Handle`, and `const ref Time`, with every other
    decided parameter refused as not built yet.
  - `Digital` actions in `kyoten::input`, and required components added with their defaults.
  - The module `static` refusal.
  - The 32 KiB frame guard on every target but Windows.
  - Content loaded from one layer, into one zone and the layer `main`.
- **Left to later rows:**
  - side stores, `Previous` and `Current`, the queues, random keys and world stores;
  - more than one zone, layer or group (KYR-61), and `scene.records.json`;
  - placed names mapped to handles;
  - the footprint report, fusing a table's processors into one pass, and `PARALLEL`;
  - `Mesh`, `Material`, `Camera` and `Light` (step 9);
  - the generated `run` (step 7).
- **The probes behind the answers** sit in `.scratch/`:
  - `step5-main`: the fence's layout, and the generator's two passes;
  - `step5-content`: content natively, under node and in Edge;
  - `step5-cli`: the tool's package;
  - `step5-tool`: step 5.3's, with the gap repros;
  - `step55-loader`: the loader's questions;
  - `step55-asset`: `std::asset`.

  Each is quoted where its decision is recorded.

**Every recommendation is the production answer,** or says plainly that it is a stopgap and what replaces it.

- **Built so far:**
  - **Step 4, the frame core** (2026-11-08, `54d2985` to `019b7aa`): `tools/test.sh` and `engine/tests/`, 51 cases
    natively, debug and release, and on wasm under node; `kyoten::frame`'s `Time`, `Clock` (exact in integer
    nanoseconds, its `TimeScale` a ratio), the `World` contract, and `step` and `frame`, generic over `World`. Its
    details are in [design/frame-phases.md](design/frame-phases.md) § Decided, question 3's *Built on 2026-11-08*.
  - **Step 5.1, `kyoten::world`** (2026-11-08, `bea9ce5`): 27 cases. Its zone type, `ZoneCoord`, and `offsetTo`'s
    `zoneSize:` were the owner's answers that morning.
  - **The 32 KiB frame guard** (2026-11-08, `9286a7d`): in the engine's manifest alone, gated on `!OS_WINDOWS`, since a
    dependency's `cflags` reach every game. `tools/fixtures/frame-guard`, a game with a 40 KB frame, holds it.
  - **Step 5.2, `kyoten::records`** (2026-11-08, `d8cfd92`): 18 cases. The engine's tests are 96 cases in all.
  - **Step 5.3, the `kyoten` tool's first pass** (2026-11-09, `86fbdf4` and `3ab910e`): `kyoten::input::Digital`,
    3 cases, so the engine's tests are 99; and `@kyoten/cli`, 43 cases on its fixture games natively and 2 on wasm.
    Its four questions were answered that morning (components § Decided, 2026-11-09).
  - **Step 5.4, the second pass** (2026-11-09, `043f75a` and `72ce358`): `Store::World`, `Rate` and
    `Lookup` in the engine, 15 cases, so the engine's tests are 114; and the tool's tables, passes and world, so its
    tests are 101 cases with the wasm legs, on the `spin`, `schedule` and `processors` fixtures. Its two questions
    were answered the same day (components § Decided, 2026-11-09).
  - **Step 5.5's first part, required components and the module `static` refusal** (2026-11-09, `dc785f3`): the
    tool alone, on a new `requires` fixture and refusals in `components` and `processors`, so its tests are 117 cases
    with the wasm legs. Its four questions were answered the same session (components § Decided, 2026-11-09).
  - **Step 5.5's last part, the loader** (2026-11-09, `482e6b5` and `4b718d6`), on the `0.9.899` pin:
    `kyoten::content` in the engine, 41 cases, so the engine's tests are 155. The tool generates the loader's game-shaped
    half and checks the first scene's zones; its tests are 158 cases with the wasm legs, on a new `zones` fixture
    and `nopreload`. Its four questions were answered on 2026-11-09, and the third again after `std::asset` was probed.
  - **Step 6, KYR-53's check** (2026-11-09, `fa9c2ff` and `eaaf802`), on the `0.9.899` pin:
    - the simulation's fence, the engine's tiers and the platform flags, in `tools/kyoten/src/fence.kama`;
    - the generated world moved out of the fence;
    - `kyoten::records`' `Tier`, with 3 cases, so the engine's tests are 158;
    - the engine's first code records.

    The tool's tests are 188 cases with the wasm legs, on the new `fence`, `flags` and `tiers` fixtures and the
    engine itself. Its four questions were answered the same day.
  - **KYR-66, the content delivery tool** (2026-11-08, `dea3db1`): its row and doc, twelve questions. Its name was
    question 1, answered the same day; the other eleven wait for KYR-66's turn, and nothing in the first slice needs
    them.
  - **Step 6's question** is answered: the simulation rule is a module fence in `importsOnly`, with `core::env` on its
    list ([design/ai-first-api.md](design/ai-first-api.md) § Decided, question 3, item 5). Its check lands with step
    5's code records.
- **kama:** kyoten's pin is `0.9.911+g238198b3` (`.kama-version`, 2026-11-10; `0.9.909+g64f011de`, `0.9.899+gf32373ea` and
  `0.9.886+g2159ce21` before it), built from a clean clone; step 4 was built on `0.9.876+g1a969a1e`, and steps 5.1 and
  5.2 on `../kama`'s working binary, `0.9.881+g4267d2ec`.
  - **That binary was built at 09:59 on 2026-11-08** from kama's working tree, which held uncommitted changes to its
    emitter and driver. kama had committed 0.9.878 to 0.9.881 that morning: `kama run` on Android over adb, every std
    module building on bare metal or refused by name, and a board's clocks declared in kama.
  - **Filed on the way:** KY-40 (std::math has no integer vectors; beside kama's KR-343) and KY-41 (kama does not
    evaluate an `isize` local at compile time, so `ChunkSize` counts in `usize` until it does). On 2026-11-09, at step
    5.3: KY-43 (the strict JSON reader takes a repeated key), KY-44 (a query result says neither whether a symbol is
    exported nor which ctor is the default), KY-45 (`--search` does not reach a dependency, so the tool caches each
    dependency's answer) and KY-46 (`==` with a `T.default()` operand is refused).
  - **`../kama` had no commits past the pin** on the morning of 2026-11-09 (its HEAD was `2159ce21`). By the second
    session it held `59fcda4d` (0.9.887, KR-354: `Atomic` on an Xtensa core masks interrupts) and a roadmap brief
    (`3d0bac8c`); nothing kyoten builds on changed, and none of KY-39 or KY-43 to KY-47 was answered, so the pin was
    not bumped.
  - **Filed at step 5.4:** KY-47 (an `InlineDynamicArray`'s `isize` length makes a component holding a bounded list a
    different size natively and on wasm, so its chunk's row count can differ).
  - **Filed at step 5.5:** KY-48 (no `Deserializer` over a parsed `JsonValue`, so a record held as a tree is laid
    over a value by writing its subtree back to text and reading it again).
  - **`../kama` at the session's end** (2026-11-09) was at `64c7e2d2`: 0.9.888 (a wasm program that spawns compiles its
    `csources` with `-pthread`), 0.9.889 (`parallel_for` on kama's job pool, KR-3 step 2), the roadmap rows above and
    KY-38's fix. kyoten uses neither feature yet, and the fixes it waits for are not committed, so the pin stays at
    0.9.886 until they are. It was still there, with a clean tree, at the third session's start.
  - **The rule:** kyoten builds with its own pin, `.kama-pin/`, made from a clean clone at `.kama-version`'s commit
    (the owner, 2026-11-08), because `../kama`'s binary is rebuilt as kama develops on this machine. Never rebuild
    or edit `../kama`, and check `--version` before quoting one.
  - **`std::app` runs an owned `App`:** `run(app: Owned<App>)`, where an `App` has `tick()` and `lifecycle(event:)`
    (`Resumed`, `Suspended`, `SurfaceReady`, `SurfaceLost`, `FocusGained`, `FocusLost`, `LowMemory`). Every host says
    `Resumed`, then `SurfaceReady`, before the first tick, so portable code opens its window and creates surfaces on
    `SurfaceReady`. kama's notes of 2026-11-08 (`../kama-notes-for-kyoten.md`) give each event per host.
    `../kama-gpu`'s tests run as an `App`, and step 7's platform seam is built on the same lifecycle.
- **Green on the pin, `0.9.911+g238198b3` (2026-11-10, the eighth and ninth sessions),** as before on `0.9.909+g64f011de`,
  `0.9.899+gf32373ea`, `0.9.886+g2159ce21`, `0.9.881+g4267d2ec` and `0.9.884+g88a0054c`:
  - kyoten's `tools/test.sh`:
    - the engine and its 164 tests;
    - the frame guard;
    - the `kyoten` tool's 192 cases;
    - `kyoten check engine/kama.json`;
    - `examples/games/fps`, which prints `fps example, on kyoten` natively and on wasm;
    - `examples/games/vr`;
  - `@kama/window`'s gate: its roadmap, 38 cases natively and 22 under node (36 and 20 before the eighth session);
  - `@kama/gpu`'s gate: its roadmap, the bindings, `TextureFormat` and `COVERAGE.md` with the coverage fixture,
    wgpu-native's 22 facts, its 69 cases (45 before GPU-1), the clear example's 60 frames, the xfail, and the wasm
    build.
- **kama reviewed the packages (2026-11-08),** in `../kama-notes-for-kyoten.md`. It found a real bug: `@kama/window`'s
  ring counted events into a trailing `Dropped` record after the reader had made room, so a key up could be lost.
  It was reproduced by a new test, fixed, and the test kept. Its other points are in each package's departures.
- **The examples sit under `examples/`, by kind** (the owner, 2026-11-08, [design/examples.md](design/examples.md)
  § Decided): the games are `examples/games/fps`
  ([kyoten-example-fps](https://github.com/cosmic-canopy/kyoten-example-fps)) and `examples/games/vr`
  ([kyoten-example-vr](https://github.com/cosmic-canopy/kyoten-example-vr)), each its own repository, git-ignored
  here, depending on `../../../engine` by path. Both were moved, committed and pushed to their `main` on 2026-11-08.
- **Pushed on 2026-11-08:** kyoten's `main` (its remote's default branch is now `main`), both package repositories'
  `main`, and both example games' `main`. The second session's commits (`bea9ce5` onward) are on the local `main`;
  pushing is the owner's call.
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
3. **`@kama/graphics`** (KYR-9, `../kama-graphics`). Start from cosmic-forge's `render` (rendering question 1). Its
   design pass (KYR-68) writes its spec and roadmap before any code. Three.js is the reference for ease of use only,
   never a limit: the bar is the state of the art (the owner, 2026-11-10, rendering § Decided). **A1 needs** a box mesh,
   the standard lit material, a camera, and a directional light with ambient light, drawn into the window. Shaders are
   WGSL, with WESL for imports (rendering, how shaders are written).

**Within Track 1, the order the owner decided on 2026-11-10** ([design/architecture.md](design/architecture.md)
§ Decided, how the libraries grow): each package's spec and roadmap, then the stopgaps that change an API, then the
web leg brought forward (`@kama/window`'s WIN-3 and `@kama/gpu`'s GPU-3), with the graphics design pass alongside. Then gamepads, `@kama/gpu`'s render
pipeline set, and `@kama/graphics`' first slice. Each library's whole architecture is decided first, then built
depth-first through the cube.

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
- **Answered on 2026-11-09, step 5.3's four questions** ([design/components.md](design/components.md) § Decided):
  1. **The generator finds each component a prefab names by asking the compiler,** after a first pass that writes
     the generated names, and caches each dependency's answer by a hash of its sources, so no record has to list a
     component. The owner asked whether listing them would touch every new module and duplicate the code (it would),
     and whether the query's cost grows ("if that can grow that is not good"): the dependency's query is the part that
     grows, so it is the part cached, and KY-45 asks kama for one query.
  2. **A component with defaults elects a `default ctor`,** and a record is laid over it; one without, such as
     `Actions`, is listed in every prefab that has it. REFERENCE's `Spin` elects one, on its one line.
  3. **`Actions.player` is an `int32`, numbered from 1.**
  4. **The tool finds kama from `--kama`, then `$KAMA`, then `kama` on PATH.** The owner: "I guess we can also pass the
     path of kama to the tool as well… that is typical".
- **Answered on 2026-11-09, step 5.4's two questions** ([design/components.md](design/components.md) § Decided): a
  processor parameter's type is resolved through its own file's imports until kama answers KY-39; and a world
  component is declared by its component record, `"store": "World"`.
- **Answered on 2026-11-09, step 5.5's four questions, required components** (components § Decided), each as
  recommended:
  1. **A requirement adds, never overwrites:** a required component a prefab lists keeps the prefab's values.
  2. **A variant that drops a component its others still require is refused,** naming what requires it.
  3. **A requirement names only the component,** never values; a prefab that wants other values lists it.
  4. **The tool reads a ctor's source line for `default ctor` until kama's KR-360 marks it** (KY-44's stopgap).
- **Answered on 2026-11-09, the loader's four questions** (components § Decided). The owner asked whether the first
  two were the production answer before choosing them:
  1. **The loader is `kyoten::content`,** a new engine module outside the simulation's fence, with the game-shaped part
     generated into the root module beside `run`.
  2. **A record is laid over a component as a subtree, with `mergeFrom`, in layer order;** re-serializing each subtree
     is KY-48's stopgap, one function.
  3. **A game whose manifest does not preload its `content/` is refused,** naming the line.
  4. **The tool checks the first scene's zone files at build time too,** and the loader refuses the same later.
- **Answered on 2026-11-09, step 6's four questions** (KYR-53), each as recommended. They were explained in full, each
  with an example, after the owner found the first asking hard to read ("can you give more context here as well in
  full"):
  1. **The generated world, its tables and its passes leave the fence** for the app's root module, one set per game.
     `src/generated/` keeps `Actions` and the prefab types ([design/components.md](design/components.md) § Decided).
  2. **The check accepts an entry on a simulation module's list only when it is known safe:** one of std's pure
     modules, `core`, or a fenced module of any package. The owner asked whether kama had `importsOnly` wrong: it does
     not, and the fix is kyoten's ([design/ai-first-api.md](design/ai-first-api.md) § Decided, question 3, item 5).
  3. **The platform-flag refusal covers all engine and game source,** with `folderFor` the one stopgap exception, which
     step 7 removes ([design/target-platforms.md](design/target-platforms.md) § Decided, question 3, item 8).
  4. **The tier table is a `tier` in each engine module's records file**
     ([design/architecture.md](design/architecture.md) § Decided, question 2).
- **Answered on 2026-11-08, KYR-66's name:** the asset manager is the **content delivery tool**, for now. The owner:
  "Content Delivery Tool is probably fine for now?" ([design/content-delivery-tool.md](design/content-delivery-tool.md)
  § Decided).
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
- **Answered on 2026-11-10, how the libraries grow toward complete** (five, each as recommended), after the owner asked
  what remains for the hello cube ([design/architecture.md](design/architecture.md) § Decided):
  1. each library's whole architecture is decided first, then built depth-first through the cube;
  2. `@kama/graphics` gets a design pass, with a feature map, before any code (KYR-68), and each package repository has
     its own `SPEC.md` and `ROADMAP.md`. The owner made the bar plain: "I DO NOT want us to be limited by any decisions
     Three.js has made or anything it can not do... we need to be able to do the state of the art in graphics."
     Three.js is a reference for ease of use only ([design/rendering.md](design/rendering.md) § Decided);
  3. `@kama/gpu` covers every call in webgpu.h before 1.0, tracked by a coverage report `tools/wgpugen` prints;
  4. the browser's platform APIs are `@kama/window`'s checklist, native at parity;
  5. the order: the stopgaps, then the web leg brought forward, with the graphics design pass alongside (§ Where it
     stands).

## kama gaps that touch the first slice

- **KY-28** (kama KR-338, "scheduled, design first"): generated code on a fresh clone. Step 5's wrapper covers it.
- **KY-6, fixed in 0.9.966 and removed:** a wasm release runs Closure, and `--closure` in a flag key is refused. Measure
  the 150 KB on the release build as kama makes it.
- **Fixed on 2026-11-07 and removed:** KY-37 (kama KR-344, `546dd54e`): a module's `importsOnly` now lists std's,
  `core`'s and other packages' modules too, and the command line and the environment moved to `core::env`. Step 6
  made the simulation rule a module fence on it (2026-11-08).
- **Fixed on 2026-11-09 and removed:** KY-38 (kama `64c7e2d2`): `docs/targets.md` now names musl's, Sun's and Arm's
  notices, all three of which `engine/THIRD-PARTY-NOTICES.md` already carries.
- **KY-2:** kama's `1e5099bb` (KR-283 step 1) builds an installable Android APK. It is not in this machine's binary,
  so re-check KY-2 on a build that has it. VR follows the gate.
- **Fixed on 2026-11-07 and removed:** KY-19, so `reproducible-float` now gives `std::math` the same bits natively and
  on wasm, which slice B's cross-platform hash needs; and KY-36.

## Practice

- **Read [REFERENCE.md](REFERENCE.md) first,** and use its words: a processor, a module, a tier, a scene's layer. Its
  § One way to do each thing is the API's rule.
- **Verify, don't trust.** Compile it, run it, read the emitted C, and record what was measured where it is decided.
- **kama runs in UCRT64, through the pin:** `MSYSTEM=UCRT64 /c/msys64/usr/bin/bash.exe -lc 'tools/kama …'` from the
  repository's root, or `-lic` for `emcc`. **git runs from Git Bash.**
- **A decision goes in its design doc's *Decided*** with its reason, and the work it creates becomes a roadmap row.
- **Test-driven, with injected dependencies** (AGENTS.kyoten.md § Rules, the owner, 2026-11-08). The test comes
  first and is seen to fail, a bug's fix starts with the test that reproduces it, and the full suite passes before
  every commit. Code takes what it depends on as a parameter or a contract, so a test hands it a fake.
- **Commit each step on `main`,** with the Co-Authored-By line; push when the owner says.
