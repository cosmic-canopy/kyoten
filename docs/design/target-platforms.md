# Target platforms: N platforms, extensible

**Status:** draft for the design spike. One decision is recorded; the rest are questions.

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
- **kama has neither an Android nor an iOS target** (probed 2026-11-01 on 0.9.803, [../KAMA_GAPS.md](../KAMA_GAPS.md)
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

## The questions

### The extension model

1. **What is a platform, in code?** A package that implements the engine's platform interfaces (window and events,
   GPU, audio, input devices, files, networking, threads, the app loop), selected per build target. Is each platform
   its own package (`kyoten-platform-web`, `-windows`, …), or are the open ones in the engine and only the closed
   ones outside?
2. **The interface.** Defined as kama contracts the engine calls through, with one implementation per platform chosen
   at build time, so there is no dispatch cost (monomorphized, as kama's contract bounds are)? How does a game reach a
   platform-specific capability (a console's achievements, Steam Input) without the engine naming that platform?
3. **Capabilities, not platform names.** Does the engine ask "is there a pointer lock, a gamepad, threads, a file
   system?" rather than "is this the web?", so that a new platform slots in by declaring what it has?
4. **Packages for features as well as platforms.** XR (OpenXR and WebXR backends behind one interface), Steamworks,
   console services: the same package mechanism?

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
