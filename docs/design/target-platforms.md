# Target platforms: N platforms, extensible

**Status:** draft for the design spike. Questions 1–4, the extension model, are decided (2026-11-07); 5–13
stay outside the spike, with their roadmap rows.

## What the vision asks

- **The engine supports N platforms and must be extensible**: adding a platform must not change the engine for the
  others.
- **Named so far:** the web (wasm), Windows PC, Linux, Mac, Steam Deck; **eventually consoles**: Nintendo Switch 2,
  Xbox, PlayStation and others. **XR** on each through OpenXR natively and WebXR on the web, perhaps as a package
  ([xr.md](xr.md)).
- **Roblox and UEFN** (Unreal Editor for Fortnite) may be good targets too.
- **iOS** (added at the first roadmap review, 2026-11-01). **Android** is needed for Quest's native route
  ([xr.md](xr.md)).
- **Web first, native at parity** ([web-and-native.md](web-and-native.md)): each engine interface is designed against
  the browser's API, and every other platform implements the same interface.

## What already exists

- **kama compiles to C**, which is the most portable thing a console toolchain accepts. Its built-in targets are
  `MACOS`, `WINDOWS`, `LINUX`, `WASM` and `EMBEDDED`, and a project may name any other triple with its own compiler
  (`kama/docs/targets.md` § Built-in targets, § Getting a cross toolchain). Per-platform code is chosen by
  `@compileFor`, which gates whole declarations (so a platform's differences live in per-platform *types*), or by a
  `csources` entry's `compileFor` gate. See [../research/kama-for-engines.md](../research/kama-for-engines.md).
- **kama's platform packages are designed as packages, not std** (`@kama/gpu`, `@kama/window`), decided 2026-10-16:
  the same "a platform capability is a package" shape this draft asks about.
- **The peers ship on Windows, Linux, macOS and the web, and both ship on Steam** (Steam runtime, depots, notarized
  Mac builds), with their own GLFW and emscripten platform layers
  ([../research/peer-games.md](../research/peer-games.md) § 4).
- **Steam Deck runs SteamOS (Linux)**, so a Linux build plus controller input is its baseline *(to verify the details:
  Steam Input, the Deck's display and performance profile)*.
- **kama's Android target shipped** (KR-280, 0.9.830; re-checked here on 0.9.839, 2026-11-04). It is
  `aarch64-linux-android29`, with the NDK found by kama itself. The app the launcher starts (an APK) is still to come,
  as kama's KR-283 ([../KAMA_GAPS.md](../KAMA_GAPS.md) KY-2, narrowed to it). iOS is unchanged (KY-3).
- **kama had neither an Android nor an iOS target** (probed 2026-11-01 on 0.9.803, [../KAMA_GAPS.md](../KAMA_GAPS.md)
  KY-2 and KY-3). Both triples transpile. `aarch64-linux-android` is treated as Linux, and `aarch64-ios-none` derives
  `OS_IOS`, which std's macOS declarations do not cover. Apple's own spelling, `arm64-apple-ios`, derives neither
  `ARCH_AARCH64` nor `OS_IOS`. Each also needs an app entry the OS owns, its own packaging and signing, and, for iOS, a
  Mac to build on.
- **kama ruled Android for production** (kama `1c1f165f`, 2026-11-02; KY-2): kama finds the NDK itself,
  `kama build` makes the signed APK, and **`main` stays the entry on every target, with the activity's lifecycle
  (pause, resume, a lost surface) delivered as events.** So a platform package on Android receives the lifecycle as
  events rather than owning an entry point of its own, which bears on questions 1–2 and on
  [architecture.md](architecture.md) question 4 *(inferred)*.
- **The peers' platform layers** ([../research/harvest.md](../research/harvest.md) § 3): one C header per game, its web
  half over emscripten's `html5.h` and its native half over GLFW, with one window held in file-static C state.
- **Decided in [architecture.md](architecture.md) (2026-11-02), bearing on questions 1–4:**
  - **The game picks the platform.** The game's `main` builds the app and calls `run`, and the engine cannot import a
    private platform package.
  - **A gated part is its own package**, a console's platform under NDA among them.
  - **kyoten builds `@kama/window` and `@kama/gpu`** (KYR-51, KYR-52).

## The questions

### The extension model

1. **What is a platform, in code?** *(Decided 2026-11-07, below.)* A package that implements the engine's platform
   interfaces (window and events, GPU, audio, input devices, files, networking, threads, the app loop), selected per
   build target. Is each platform its own package (`kyoten-platform-web`, `-windows`, …), or are the open ones in the
   engine and only the closed ones outside?
2. **The interface.** *(Decided 2026-11-07, below.)* Defined as kama contracts the engine calls through, with one
   implementation per platform chosen at build time, so there is no dispatch cost (monomorphized, as kama's contract
   bounds are)? How does a game reach a platform-specific capability (a console's achievements, Steam Input) without the
   engine naming that platform?
3. **Capabilities, not platform names.** *(Decided 2026-11-07, below.)* Does the engine ask "is there a pointer lock, a
   gamepad, threads, a file system?" rather than "is this the web?", so that a new platform slots in by declaring what
   it has?
   - *Noted 2026-11-05 at [project-database.md](project-database.md) question 11:* a remote record source (a URI for
     dynamic data updates) is one such capability. The owner: "This is typically restricted on many consoles and such
     but possible on web, etc."
4. **Packages for features as well as platforms.** *(Decided 2026-11-07, below.)* XR (OpenXR and WebXR backends behind
   one interface), Steamworks, console services: the same package mechanism?

### Consoles

5. **Closed platforms in an open engine.** Console SDKs are under NDA, so their platform packages cannot live in the
   public MIT/Apache repository. The extension model must let a **private** package implement the public interfaces,
   built by those who hold the SDK. Who builds and holds those packages: kyoten, or each licensed developer?
6. **Toolchains and certification.** Each console has its own compiler toolchain (generally clang-based, *to verify per
   console*), its own certification rules, and its own constraints (memory, no JIT, threads, file I/O). What must the
   engine avoid now so a console port is not a rewrite later?

### Roblox and UEFN: a different kind of target

7. **What does "targeting" them mean?** Roblox runs Luau scripts inside its own engine; UEFN runs Verse inside
   Unreal. Neither runs native code from outside, so kyoten cannot run there. Targeting them means **exporting**: a
   kyoten project's content and design, from its project database ([project-database.md](project-database.md)),
   turned into a Roblox place or a UEFN project, with the game logic regenerated in Luau or Verse. Is that the idea?
8. **How much can be exported?** Content (meshes, materials, audio, levels) is the tractable part. Logic is the hard
   part: written in kama, it does not translate to Luau or Verse. Is it regenerated by agents from the project
   database's design records, or authored in a form designed to translate (a constrained logic layer)? This could make
   the project database the single source of truth across engines.
9. **Why these two?** Reach (each has a large audience and creator economy) and the marketplace
   ([marketplace.md](marketplace.md)): selling to Roblox and UEFN creators, or publishing kyoten games there.

### Order

10. **Which platforms, in what order?** The web and desktop first, then Steam Deck and XR (OpenXR, WebXR), then
    consoles and the export targets? What must exist before the first console (a published engine, a stable platform
    interface)?
11. **CI across N platforms.** Which platforms are built and tested on every commit, which nightly, and which only by
    whoever holds the SDK?

### Mobile

12. **iOS: native, the web, or both?** Natively it needs kama's iOS target (KY-3), a GPU route to Metal (wgpu-native's,
    *to verify*), and builds on a Mac. On the web it is Safari, and whether Safari on iOS runs WebGPU *(to verify)*
    decides whether the web route reaches it at all.
13. **Android beyond Quest.** Quest needs Android for its native route (KY-2). Are Android phones and tablets a target
    too, once the target exists?

## Decided

- **2026-11-01, the owner: iOS joins the platforms, and Android is needed for Quest.** kama has neither target, so both
  are kama gaps (KY-2, KY-3). kyoten's platform packages on them are KYR-32 and KYR-34.
- **2026-11-07, the owner: questions 1–4, the extension model.** "All of this sounds great. I like the abstraction idea
  here for sure and that is the point of compilefor in kama."
  - **The probe** (kama 0.9.873, `0.9.873+g7c0a6bd0`, Windows 11, msys2 UCRT64), three packages:
    - `eng` declares `type contract Platform for value { fn string name(); fn bool hasPointerLock(); }`, an open
      platform `Open` implementing it, and `fn uint8 run<P: Platform>(P platform)`;
    - `platx`, standing in for a private console package, depends on `eng` and declares `ConsoleX implements Platform`;
    - `game` declares a select group, `"PLATFORM": { "OPEN": { "default": true }, "CONSOLE_X": {} }`, and depends on
      `platx` only through `"compileFor": ["CONSOLE_X"]`, with one `main` per configuration in files gated
      `file @compileFor(!CONSOLE_X)` and `file @compileFor(CONSOLE_X)`.
    - `kama check` reported *"OK (2 configurations, 4 units analyzed)"*. `kama run` printed `running on open`, and with
      `--select PLATFORM=CONSOLE_X` printed `running on console x, a private package`. The emitted C specializes `run`
      as `eng__run__kama_of__platx__ConsoleX__kama_end`, which calls `platx__ConsoleX__name(...)` directly, with no
      vtable.
  1. **Question 1: a platform is one kama type implementing kyoten's `Platform` contract:** the loop and its frame
     source, the lifecycle, capabilities, files and paths, and the window, GPU, audio, input devices and network that
     the libraries provide.
  2. **Question 1: the open platforms live in kyoten and its libraries,** each picked per build target by kama's
     `@compileFor`: the web, Windows, Linux, macOS, Android (Quest), and iOS once kama has it (KY-3). Steam Deck is
     Linux with its controller. There is no package per open platform, so building for any of them needs no setup.
  3. **Question 1: a closed platform is a private package** with a type implementing the same contract, built by
     whoever holds the SDK. Who that is is question 5's, outside the spike.
  4. **Question 2: calls are resolved at compile time.** `run` is generic over the platform, so kama writes a copy for
     each and calls it directly, as the probe shows.
  5. **Question 2: the game picks a private platform, and the engine never names it.**
     - **Its manifest** depends on the private package only for that configuration, through `compileFor` and a select
       group, as kama's own `CONSOLE` example has it (kama `docs/SPEC.md` § Conditional compilation).
     - **Its records** name the platform per configuration, and the generator writes the `run` the game's `main` calls,
       passing the generated world and the build's platform to the engine.
     - **So the hello cube's `main` stays two lines,** importing `run` from its generated module rather than from
       kyoten. *(Since 2026-11-08, `run` is generated beside `main` in the app's root module, outside the
       simulation's fence, and built at the first slice's step 7: ai-first-api.md § Decided, question 3.)* That
       closes a gap in the sketch: `kyoten::run()` without arguments could not reach a game's generated world,
       since the engine never imports a game and reaches the world through the `World` contract
       ([components.md](components.md)).
  6. **Question 2: under a console, the GPU's interface stays WebGPU's shape.** Whether a console supplies it as a C
     library behind `webgpu.h`, as Dawn and wgpu-native do on desktop, or as a kama type, is left to the first console
     port.
  7. **Question 3: capabilities, not platform names.** The engine and games ask what a platform has (pointer lock,
     touch, gamepads, threads, files, remote record sources, haptics, XR, whether mods are allowed, a store's
     services), never which one it is. Some are fixed for a build (no threads in the single-threaded web build) and
     some change while running (a gamepad plugged in, pointer lock granted). Both are read the same way, in Input and
     Output only ([web-and-native.md](web-and-native.md) question 5).
  8. **Question 3: OS and target flags stay in the libraries and the platform types.** A check refuses
     `@compileFor(OS_WINDOWS)` and its kind in an engine module and in a game's processors (KYR-53's), so a new platform
     slots in by declaring its capabilities, and nothing else changes.
     - **2026-11-09, the owner: the check covers all engine and game source, and `folderFor` is its one stopgap
       exception** (the first slice's step 6, KYR-53, question 3 of 4; the others are in components, ai-first-api and
       architecture § Decided). The owner, once it was clear this is kyoten's rule and not kama's (kama allows
       `@compileFor` anywhere): "Keeping platform specifics isolated is kyoten's rule... yes that is a good rule. So
       basically we just need a stopgap for now until Step 7 and then we are back on design?"
       - **What is refused:** an `@compileFor`, or a file-level `file @compileFor`, whose expression names one of
         kama's platform flags: `OS_*`, `ARCH_*` or `ABI_*`. `BUILD_TYPE` and the flags a package declares (a
         `PARALLEL`, a console's select group) are not platform flags and stay allowed. Comments are not read.
       - **Where:** every source file of a game, generated files included, and every source file of the engine.
         "A game's processors" became the whole game, so the hello cube's check, "the same game code on web and native,
         with no platform flag in it", is held by the check rather than by review.
       - **The one exception, a stopgap:** `kyoten::content`'s `folderFor` chooses the web's preloaded `/<game>/content`
         or the native folder with `@compileFor(ARCH_WASM32)`. Where the files are is a platform fact: the `Platform`
         contract's "files and paths" (question 1, above). Step 7 (KYR-8) builds the contract, the platform supplies the
         content folder, and `folderFor` and its exception are removed. Step 7's test is that the exception list is
         empty. *(Since 2026-11-20 (below), the platform types are one engine module marked as such, the one place a
         library may name a platform flag, and the check keeps no named exception.)*
       - **Considered:**
         - the refusal over a game's processor modules only, as first worded, which leaves a game's Output and app code
           free to name a platform;
         - building the refusal at step 7 with the platform types, so that it needs no exception. Until then, nothing
           would stop a second flag from arriving.
     - **2026-11-09, built** (step 6, KYR-53; `tools/kyoten/src/fence.kama`, with the fence in ai-first-api § Decided),
       test-first on kyoten's pin, `0.9.899+gf32373ea`.
       - **What is read:** every `.kama` file under a package's `src/`, with each `//` comment removed and every line
         kept, so a refusal names `file:line`. A `//` inside a string is not a comment.
       - **What is refused:** an `@compileFor` or `file @compileFor` whose expression names `OS_*`, `ARCH_*` or
         `ABI_*`, or `HOSTED`. kama derives `HOSTED` from the target as it does the others (its docs/SPEC.md
         § Conditional compilation, read on the pin), so it is the same kind of flag.
       - **Where it runs:** `kyoten generate` holds a game's source, and `kyoten check` the engine's.
       - **The exception:** package `kyoten`, `src/content/source.kama`, the declarations of `folderFor`.
       - **Tested** by the tool's `flags` fixture.
         - Refused: `ARCH_WASM32` in the app's root module, `OS_WINDOWS` in an Output module, a file gated on
           `ABI_GNU`, and `HOSTED`.
         - Not refused: `RELEASE`, a declared `PARALLEL`, and a comment naming `OS_WINDOWS`.
         - The `tiers` library's `OS_LINUX` is refused, and the engine passes with its one exception.
       - **Mutations caught:** the exception dropped (the engine's check turns red), comments read as code, and
         `ABI_` not matched.
  9. **Question 4: features are packages too:** an interface kyoten defines, with backends in packages a game opts
     into. XR (OpenXR and WebXR, KYR-31); store services (achievements, leaderboards, cloud saves, presence), with a
     backend per store (Steam's is KYR-19; the consoles', Meta's and the web platform's); later, voice. A game that uses
     none never carries it.
  10. **Question 4: a game says a feature once.** Achievements are records, and "unlock `firstWin`" is an Output effect
      that each store's backend maps. A store's feature with no common interface (Steam Workshop, say) the game reaches
      by importing that package directly, in its own Input or Output code, behind a capability.
- **2026-11-20, the owner: where the open platforms' target flags live (the first slice's step 7, KYR-8), (A).** The
  owner: "I think A sounds good from what I can understand of your proposal." Asked in full at the forty-third session's
  readying, after a stand-in on the pin ([../FIRST-SLICE.md](../FIRST-SLICE.md) § Where it stands, item 3;
  `.scratch/s43/step7/`, machine-local).
  - **The question:** question 3's item 8 puts target flags in "the libraries and the platform types", and question 1
    puts the open platforms in kyoten. The check of 2026-11-09 refuses a platform flag anywhere in the engine's source,
    with `folderFor` its one stopgap, and step 7's test was an empty exception list. A platform type in the engine names
    a target: the stand-in's `OpenPlatform` is two declarations of one type, gated `ARCH_WASM32` and its negation, for
    the content folder and for the web's ending by `quit`, since there `run` never returns. So the two could not both
    hold as worded.
  - **Decided:** the open platforms are one engine module, `kyoten::platform`, whose records file marks it as a platform
    module (its key settled at step 7).
    - The check lets a platform flag (`OS_*`, `ARCH_*`, `ABI_*` or `HOSTED`) appear only in a library's module so
      marked. It refuses the mark in a game, which asks for capabilities and names no target, and it keeps no named
      exception, so `folderFor` and its exception go.
    - A private platform package marks its own module the same way.
    - Step 7's test: the check's exception list is gone, a platform flag outside a marked module of a library is
      refused, and a game that marks a module is refused.
  - **Why:** both decisions hold as worded. The platform types hold the flags, and the open platforms live in kyoten
    with no package per open platform, so building for any of them needs no setup. The check stays a rule with no
    stopgap. Godot's layout is the same: its core names no platform, and each platform's folder under `platform/` holds
    its differences.
  - **Settled with it by the rules, to report:** `kyoten::platform` is tier `Module`, outside the simulation's fence, as
    `kyoten::content` is. `kyoten::frame` must stay fenced, since a game's simulation modules import its `Time`, and a
    `Frame`-tier module names no other engine module, while the loop names `kyoten::frame`'s `World`, `Clock` and
    `frame`. REFERENCE's tier picture moves `run` there when it is built.
  - **Considered:**
    - (B) the open platforms as a package of their own, which the engine's check never reads, at the cost of question
      1's "no package per open platform" and a dependency line in every game;
    - (C) no flag in kyoten, each difference moved into kama's libraries first (a content folder at one path on every
      target, `std::app` ending a web program when its loop stops): two kama gaps, with a stopgap until they land.
- **2026-11-20, the owner: how a game's run ends, runs without a window and steps at a fixed rate (the first slice's
  step 7, KYR-8), (A).** The owner: "A (Recommended)". Asked in full at the forty-fourth session's start, found while
  reading the code for step 7's plan.
  - **The question:** a game's `main` calls the generated `run()` with no arguments, and the loop ends when the window
    closes. Step 7 runs the `spin` fixture through that `run` natively and under node, debug and release, and as laid
    out it could not: nothing ends a test's run, and a test never takes the focus; under node `@kama/window` refuses a
    window with no page, so the run would end with 1 at once; and natively a tick with nothing to present takes no
    time, so 30 frames by the real clock owe almost no steps, and a test could not hold what the world did. The hello
    cube's check in CI (the first slice's step 10) and CI itself (KYR-13) meet the same.
  - **Decided:** the open platforms read three options from the command line, Godot's, which every game gets with no
    code; on the web from the page's query and under node from its arguments, as kama's `args()` gives them:
    - `--headless`: a headless window of the app's size (`@kama/window`'s `Window.headless`), so no system window, no
      page and no focus; Output runs as usual;
    - `--quit-after N`: the run ends after N frames with status 0, and a window it opens takes no focus;
    - `--fixed-fps F`: each frame's timestamp moves by exactly 1/F second instead of reading the clock, so N frames
      owe an exact count of steps.
  - **Why:** the generated `run` and the open platforms are then run in a test on every leg, as a player runs them:
    the content folder on the web, the window, the web's ending. A game needs no test `main`, so the hello cube's
    two-line `main` is the one CI runs. Godot's names are known to its users, and a movie written frame by frame
    (Godot's `--write-movie`) is built on the same two.
  - **What the peers do,** read on their docs on 2026-11-20:
    - Godot 4.7's command line: `--headless`, "Enable headless mode (`--display-driver headless --audio-driver
      Dummy`). Useful for servers and with `--script`."; `--quit-after`, "Quit after the given number of iterations.
      Set to 0 to disable."; `--fixed-fps <fps>`, "Force a fixed number of frames per second. This setting disables
      real-time synchronization."
    - Unity 6's player: `-batchmode`, "the application doesn't display anything or accept user input"; `-nographics`,
      no graphics device. A built player has no option that quits after some frames.
    - Bevy drives an app by hand in a test: `ScheduleRunnerPlugin`'s `run_once` and `run_loop`, and
      `TimeUpdateStrategy::ManualDuration`, "Time will be incremented by the specified Duration each frame."
    - `@kama/graphics`' `examples/cube`: `--frames N` draws N frames and exits, opening without the focus, and on the
      web the page passes it.
  - **Settled with it, to report:** the platform reads only its three options and leaves the rest of the command line
    to the game; a malformed value (`--quit-after x`) is printed and ends the run with 2 before the loop; the hello
    cube's readback in CI uses `--quit-after` with a real window, unfocused, in a headless browser, as `examples/cube`
    does, never `--headless`.
  - **Considered:**
    - (B) no options, the loop tested only through a fake platform: the generated `run` and the open platforms would
      never run in a test, and the hello cube's check in CI would need a test `main` of its own;
    - (C) environment variables, as `@kama/window`'s tests' `KAMA_WINDOW_NO_DISPLAY`: a browser page cannot set one,
      so the web leg would have no way.
- **2026-11-20, built: the platform seam, the first slice's step 7 (KYR-8),** in five commits (`fd8a130`, `4b32cd0`,
  `820b887`, `6556102` and `c8334bb`), test-first on kyoten's pin, `0.9.978+g5e542c55`, each gated by `tools/test.sh`.
  - **The platform mark:** a module's records file says `"platform": true` (kyoten::records' `ModuleRecord`). The
    check holds a platform flag (`OS_*`, `ARCH_*`, `ABI_*`, `HOSTED`) everywhere but a library's marked module and the
    folders below it, refuses a game's mark (which grants nothing), and keeps no named exception: `folderFor` and its
    exception are gone, and the engine's flags are all in `kyoten::platform`.
  - **`Clock.resetBaseline()`:** the next timestamp owes nothing however far it is, a part of a step already owed
    kept, the steps settled going on.
  - **`kyoten::platform`,** tier `Module`, marked, outside the fence, naming `kyoten::frame` alone of the engine:
    - the `Platform` contract as far as step 7 needs it: `contentFolder(package:, native:)`, `arguments()`,
      `openWindow(title:, width:, height:, headless:, focused:)`, `pumped()`, `now()` and `ended(code:)`;
    - `Play<W, P>`, a std::app `App`: the window asked for once on `SurfaceReady`; `Resumed` after `Suspended`
      resetting the clock's baseline; a tick that pumps the window, ends with 0 when it closes, and runs
      kyoten::frame's `frame` on the platform's timestamp or, under `--fixed-fps F`, frame k's at k / F seconds
      rounded up; a refused window ending the run with 1 at the first tick; `--quit-after N` ending it with 0;
    - `play(world:, platform:, hz:, title:, width:, height:)`: the options read first (`RunOptions.fromArguments`), a
      malformed one ending the run with 2 before the loop; natively the status returned, held in an `Ending` the loop
      and `play` share, with no module `static`;
    - `OpenPlatform`, two declarations gated `ARCH_WASM32` and its negation: a package's content folder (natively the
      generator's, on the web `/<package>/content`), the command line through kama's `args()` (on the web the page's
      query), `@kama/window`'s window (a system window, the page's `#canvas`, or under `--headless` a headless one),
      `std::time`'s monotonic clock read at the tick, and on the web std::app's `quit` at the end.
  - **The engine's content:** `engine/content/app.records.json`, the window's size, 1280 x 720; the engine's manifest
    packs it for the web (`"preloadFiles": ["content@/kyoten/content"]`), which reaches every program on the engine, as
    probed on the pin (`.scratch/s44/probe-preload/`). The app record gains `window` (`width`, `height`), and each
    layer's app record is laid over the one below, field by field; a size below 1 is refused, naming its file.
  - **The generated `run`,** beside `main` in `src/<game>.generated.kama`: `OpenPlatform.make()`; `openContent`, now
    generic over the platform, opening the engine's folder, then the game's, at the platform's folders; the content
    read, the prefabs loaded and the first scene placed, a refusal printed (`kyoten: refused at load: …`) and the run
    ending with 1; then `play` with the generated world's base rate and the app record's window, its title the game's
    `app.title` else its name. The generated `contentFolder()` is gone.
  - **The spin fixture runs through it,** `main` ending `return run();`, natively and under node, debug and release,
    under `--headless --fixed-fps 60 --quit-after 30`: 30 frames of Output, three cubes each, and the last frame's
    rotations after exactly 29 steps, bit for bit with `turn` by hand. Also held: a malformed option ending the run
    with 2 (natively and under node), a refusal at load ending it with 1 before the loop, the engine's layer opened
    below the game's, and under node with no `--headless` the window refused for want of a page and the run ended
    with 1 from inside the loop by the platform's `quit`.
  - **Counts:** the engine's tests 218 cases (164 at the start), the tool's 228 (211), on every leg.
  - **Mutations:** 6 of 6 (the mark), 2 of 2 and the no-op stub (the reset), 20 of 20 (the loop and the options; the
    unsplit timestamp traps on kama's overflow check in a debug build and fails by name in a release build), 8 of 8
    (the open platform's folder and the app record's window; the first layer's title winning was caught only once the
    case's lower layer named a title too), and 8 of 8 (the generated `run`, held on spin's legs; a case for the
    web's ending by `quit` was added while planning them, since nothing held it).
  - **Found on the way:** the gate's first run of the fourth commit failed its node legs, since every program on the
    engine now has a `.data` (the engine's content) and emscripten's loader finds it in node's working directory, so
    `tools/test.sh` runs node from the build's folder for the engine's tests and the fps example, as spin's legs did.
  - **Settled and reported, for the owner to object to:**
    1. the mark's key, `"platform"`, beside `"tier"`;
    2. the window asked for once, on `SurfaceReady`, where the stand-in asked on the first tick (std::app's docs:
       portable code opens its window there); Android's `SurfaceLost` and a second `SurfaceReady` come with its
       platform (KYR-34);
    3. `--quit-after` and `--fixed-fps` applied by the loop, read through the platform's `arguments()`, so a private
       platform takes them with no code; `--headless` handed to the platform with the window;
    4. an option written with `=` refused, naming the two-argument form; `--fixed-fps` from 1 to 1,000,000; and
       frame k's fixed timestamp rounded up, so at the base rate each frame after the first owes exactly one step;
    5. the run's status in a `Shared<Ending>`, since the rules allow no module `static`, where the stand-in kept one;
    6. the engine's path dependency on `@kama/window` admitted by listing `../kama-window` in kyoten's
       `kama_workspace.json`, kama's rule for a path dependency below the top level, where `@kama/graphics`' tests
       repeat each path in their own manifest; it goes when the packages publish;
    7. the window's default size, 1280 x 720, Bevy's; its title the game's name when no record names one, as Godot
       and Unity title a window with the project's name;
    8. the engine's layer named `kyoten/content` in a refusal, the game's `content`;
    9. nothing of the lifecycle reaches the world yet: a game saves on `Suspended`, never in a destructor (on the web
       the world is never dropped), which comes with saves.
  - **Not held by a case yet:** the system window's path (natively a window, on the web the page's canvas) and its
    close ending the run with 0, which no headless run reaches and no test may open with the focus; the hello cube's
    readback in CI (the first slice's step 10) runs it in a headless browser with `--quit-after`. And the run's guard
    on a window size of 0, which only a missing engine content reaches.
