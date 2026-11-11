# The first slice — kickoff brief

The design spike (KYR-1) ended on 2026-11-07, and what it decided is in [SPIKE.md](SPIKE.md) § What the spike decided.
This brief starts the build. **The goal is the gate:** slice A (A1, the hello cube, then A2, the level) and slice B,
after which a game can start on kyoten ([ROADMAP.md](ROADMAP.md) § NEXT). **The first milestone is A1, the hello cube.**

The rule from the spike still holds: **no engine code is written before the decision it depends on is recorded.** Where
a step meets a question no doc answers, bring the options and a recommendation to the owner, and record the answer in
the design doc it settles before building on it.

## Where it stands (2026-11-11, end of the eleventh session)

**Track 2 is built through step 6** (KYR-6, KYR-7 and KYR-53):
- records generate the world, and the loader reads content into it;
- the tool checks both at build;
- the tool holds every module's list to the simulation's fence, the engine's tiers and the platform rule.

**Track 1 is under way, and each package now keeps its own order:**
- `@kama/gpu` has a `SPEC.md`, a `ROADMAP.md` (rows `GPU-<n>`), its detail, and `COVERAGE.md`: 55 of webgpu.h's 206
  functions called;
- `@kama/window` has the same three documents (rows `WIN-<n>`);
- GPU-1 is built (errors per device, and error scopes; the ninth session, below);
- WIN-1 and GPU-2 are built (a window's native record counted, and a surface holding its window; the tenth session,
  below), and so are the two rows its questions made: GPU-13 (an acquire before a configure refused) and WIN-16 (a
  window opened without taking the focus);
- **WIN-2 is built, the last stopgap** (the eleventh session, below): the window keeps what is held, and releases it on
  a focus change. The next rows are the web leg's.

**The join waits on Track 1. The next session starts here:**

1. **Run the suites on kyoten's pin, `0.9.911+g238198b3`** (`.kama-pin/`, through `tools/kama`; AGENTS.kyoten.md
   § Build): `tools/test.sh`, then both packages' `tools/test.sh` with `KAMA` set to the pin.
   - Suites and builds may run while kama works on this machine; only measurements wait until it is quiet (the owner,
     2026-11-10).
   - **Read `../kama`'s log since `f113270e`,** its HEAD at the eleventh session's end (0.9.917, a clean tree). First
     check that the pin is still on kama's history: `git -C ../kama merge-base --is-ancestor 238198b3 HEAD`. kama
     rebased its `dev` twice on 2026-11-10, and a pin is rebuilt from a clean clone at its commit.
   - **kama is six versions past the pin, and the next bump carries a port.**
     - 0.9.912 (`c065dcea`) fixes a lost cross-isolate wake on Linux.
     - 0.9.913 (`f19742f6`) refuses `int32.parse(text: t)` again.
     - **0.9.915 (`637df517`, KR-370) retires `parse::<T>(text:)` as well:** an adapter's member is reached only where
       its contract is named. So the one use on this side, `../kama-gpu`'s `examples/clear`, ports from
       `int32.parse(text: v)` to `Parseable::<int32>.parse(text: v)`.
     - 0.9.914 checks adapters onto a generic contract, 0.9.916 lets a fiber park switch straight to the next one, and
       0.9.917 makes `Instant` count only the time the system is awake on Apple.

     None is needed for the web leg's first row, so bump only when one is.
   - **Still open with kama:** KY-45 (KR-361, not started) and KY-40 (no integer vectors), both re-run on 0.9.911.
2. **Track 1 continues, by each package's `ROADMAP.md`,** in the order the owner decided on 2026-11-10
   ([design/architecture.md](design/architecture.md) § Decided, how the libraries grow). Each row is test-first.
   **Its questions are asked in full in the chat, and answered there,** never folded into a plan's approval (the
   eleventh session, below).
   1. **The web leg, brought forward:** WIN-3 (the web half, from FFD's `ffd_platform.h`, with Pointer Events), then
      GPU-3 (a canvas surface, and the tests run in Edge, where the web is measured for the first time).
      - WIN-3's html5 callbacks reach the ring through WIN-2's `take()`. What a browser sends around a focus change is
        measured there: a `keyup` for a key pressed before the page had the focus, and a held key's repeat after a
        focus gain as `repeat: true`.
      - GPU-3 also runs GPU-1's web half, whose error cases run natively only so far, and measures two facts read and
        not run (its ROADMAP_DETAIL § GPU-3).
   2. **Alongside 1, the graphics design pass** (KYR-68; [design/rendering.md](design/rendering.md) § Decided,
      2026-11-10): `@kama/graphics`' `SPEC.md`, `ROADMAP.md` (rows `GFX-<n>`) and feature map, before any of its code.
      Three.js is a reference for ease of use, never a limit, and the bar is the state of the art, as Unreal, Unity and
      Godot reach it. The owner held it for a session of its own (2026-11-10).
   3. **Then the rest of the libraries' share of the cube:**
      - gamepads (WIN-4), which now asks whether a program reads pads while unfocused (the owner, 2026-11-10);
      - `@kama/gpu`'s render pipeline set (GPU-4, shaped by the design pass);
      - `@kama/graphics`' first slice, on both legs.

   A page served from localhost to headless Edge prints its console to stderr
   (`msedge --headless=new --enable-logging=stderr --dump-dom <url>`), as step 5's content probe ran.
3. **Then the join.** Step 7, the platform seam, builds:
   - the generated `run`, on the `Platform` contract and `@kama/window`. `run` calls `openContent`, `readContent`,
     `loadPrefabs` and `placeFirstScene`;
   - `engine/content/`'s first records;
   - the `Platform`'s content folder, so that `kyoten::content`'s `folderFor` and its exception in the platform-flag
     check are removed, and the check's exception list is empty (target-platforms § Decided, question 3, item 8).

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
- **KY-6:** kama's wasm release does not run Closure. Until it does, measure the 150 KB with web-baseline's variant,
  `--closure=1` as an `ldflags` entry gated `ARCH_WASM32`, and record both numbers.
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
