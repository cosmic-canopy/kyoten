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
         empty.
       - **Considered:**
         - the refusal over a game's processor modules only, as first worded, which leaves a game's Output and app code
           free to name a platform;
         - building the refusal at step 7 with the platform types, so that it needs no exception. Until then, nothing
           would stop a second flag from arriving.
  9. **Question 4: features are packages too:** an interface kyoten defines, with backends in packages a game opts
     into. XR (OpenXR and WebXR, KYR-31); store services (achievements, leaderboards, cloud saves, presence), with a
     backend per store (Steam's is KYR-19; the consoles', Meta's and the web platform's); later, voice. A game that uses
     none never carries it.
  10. **Question 4: a game says a feature once.** Achievements are records, and "unlock `firstWin`" is an Output effect
      that each store's backend maps. A store's feature with no common interface (Steam Workshop, say) the game reaches
      by importing that package directly, in its own Input or Output code, behind a capability.
