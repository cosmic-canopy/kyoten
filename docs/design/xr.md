# XR: VR on Meta Quest

**Status:** draft for the design spike. Four decisions are recorded; the rest are questions.

## What the vision asks

- **A VR example for Meta Quest** ([examples.md](examples.md)), as one of the first two examples.
- **Web first, native at parity** ([web-and-native.md](web-and-native.md)), and the same frame model everywhere
  ([frame-phases.md](frame-phases.md)).

## What already exists

- **Nothing for XR in kama or the peers.** kama has no WebXR or OpenXR binding, and neither peer game has any XR code.
  kama will not build one: XR is kyoten's (see *Decided*). kama's survey of the routes, made for kyoten, opens its
  `docs/ROADMAP_DETAIL.md` § 8 (kama `62322f93`):
  - **Native:** Quest's loader is Khronos's `openxr_loader_for_android` AAR (Meta supports 1.0.34 and later),
    initialized with the activity's `JavaVM` and `jobject`. On Windows it is `openxr_loader.dll`, with Quest Link as
    the runtime.
  - **Web:** WebXR is reached through `jsLibraries`, with an `expose fn` as the per-frame callback. It exists only on
    the page thread, and a threaded wasm build runs `main` on a worker. It renders through WebGL2, since WebGPU in
    WebXR is behind a flag in the Quest browser.
- **The Android target shipped** (kama KR-280, 0.9.830, 2026-11-03; re-checked here on 0.9.839, 2026-11-04,
  [../KAMA_GAPS.md](../KAMA_GAPS.md) KY-2).
  - **What it is:** `aarch64-linux-android29` is the one spelling, and kama finds the NDK itself.
  - **What was built here:** a hello, to an aarch64 executable "for Android 29, built by NDK r30". It has not been run
    on a device from here.
  - **What Quest still needs from kama** is the installable app, KR-283 (an APK the launcher starts). Its next step is a
    ruling on `kama.json`'s shape (kama `6cac55c7`).
  - The history below is how it got there.
- **kama's targets** (`kama/docs/targets.md` § Built-in targets): `MACOS`, `WINDOWS`, `LINUX`, `WASM`, `EMBEDDED`.
  **There was no Android target until 0.9.830** (above). A custom triple with a per-target compiler is allowed, and
  the docs name "an NDK wrapper" as the kind of compiler that carries its triple in its name (`targets.md:540-553`).
  Building an Android `.so` that way is untested, and std's OS layer has no Android branch that anyone has exercised.
  Probed 2026-11-01 on
  0.9.803 ([../KAMA_GAPS.md](../KAMA_GAPS.md) KY-2): `--target ANDROID` is refused, and the triple
  `aarch64-linux-android` transpiles as `OS_LINUX` with `ABI_ANDROID`, so std treats it as Linux.
  **kama has since measured the native route** (kama `4f0ecbdc`, 2026-11-01, with NDK r30 on this machine; not
  re-checked from here): a `kama.json` target carrying `--target=aarch64-linux-android29` builds an executable and a
  `.so`, and all 135 std fixtures that apply link once `-lpthread` is dropped. kama moved the target (KR-280) to its NOW
  and filed KR-282 (an NDK wrapper is handed `-target`) and KR-283 (an installable APK). On 2026-11-02 its Windows
  machine, which is this one, claimed all three, with KR-279 (kama `62322f93`).
- **Developing without the headset** (kama `a23f1da2`, 2026-11-02, `docs/ROADMAP_DETAIL.md` § Android; not re-checked
  from here). The SDK's emulator runs on this machine: an API 34 x86_64 image (the `kama34` virtual device) boots
  headless in about 35 s under the Windows Hypervisor Platform, and runs arm64 executables through Google's
  `ndk_translation`, so Quest's own ABI is tested too. **110 of the 135 fixtures pass, on arm64 and x86_64 alike.** 16
  are unmeasured (a test helper the probe did not supply), and 9 fail and are tracked under KR-280. kama's
  `./dev test android` leg will run on the emulator by default and on the Quest when one is attached. CI could run it
  too, since GitHub's Linux runners expose KVM to the emulator (untried).
  - **Quest Link is optional.** It renders on the PC, and this machine's GPU is an integrated Radeon 880M, so
    Quest-native and WebXR, which render on the headset, come first.
  - **The headset is the last mile:** Horizon OS specifics, the VR launch path, and OpenXR itself.
  - **Leads, none tried with kama** (question 8): the Meta XR Simulator, an OpenXR runtime on Windows; the Immersive
    Web Emulator extension, WebXR in desktop Chrome; and Google's Android XR emulator images
    (`system-images;android-34;google-xr`), which the SDK lists, though whether they run OpenXR apps is unchecked.
- **kama's hot-reload notes** already mention Quest: "Android/Quest only via a pushed `.so`"
  (`kama/docs/ROADMAP_DETAIL.md` § the hot-reload library).
- **Quest facts to verify before relying on them** *(to verify)*: the Quest browser runs WebXR `immersive-vr`
  sessions; native Quest apps use OpenXR on Android with Vulkan (or OpenGL ES); headsets run at 72, 90 or 120 Hz on a
  mobile GPU with a tight thermal budget. **Whether the Quest browser supports WebGPU, and WebXR with WebGPU layers,
  is the question the web route depends on.** WebXR has traditionally been bound to WebGL.
- **WebGPU in WebXR on Quest is experimental and behind a flag** *(to verify on a headset)*. A web search of Meta's
  Quest Browser release notes (`developers.meta.com/horizon/release-notes/web/`, 2026-11-01) reports: 146.0 (April
  2026) enabled experimental WebGPU in WebXR, behind `chrome://flags` "webxr experiments"; 149.1 added WebGPU
  space-warp layers; 150.1 experimental foveation for WebGPU in WebXR; 152.1 (October 2026) composition layers for it.
  A January 2026 forum thread reported the WebGPU samples failing on a Quest 3S. The pages render by script, so they
  were not read directly. **So the web route can render with WebGPU for development, but not yet for players** who
  have not set a flag.

## The questions

1. **Which route ships first for the Quest example?** Both are decided (see *Decided*): WebXR in the Quest browser
   fits web first and needs no store, since a game is a URL (`play.` on the platform, [website.md](website.md));
   OpenXR natively gives full performance and store distribution (Meta Horizon Store). Which comes first?
2. **XR as a package** (the owner's proposal): one XR interface (session, frame timing, views, poses, input sources)
   with an OpenXR backend and a WebXR backend, shipped as its own package, so a flat-screen game never carries it.
   It is the same shape as the platform packages in [target-platforms.md](target-platforms.md). What is in the
   interface, and does it cover headsets beyond Quest (anything OpenXR runs on) from the start?
3. **Graphics on each route.** On the web: does WebXR work with WebGPU on the Quest browser, or would the web route
   force WebGL, against the WebGPU-first rule ([rendering.md](rendering.md))? Natively: Vulkan through wgpu-native
   needs the device created with the extensions OpenXR asks for, which is a known integration point to probe early.
   *Since (kama § 8, 2026-11-02):* the swapchain is Vulkan or GLES on Quest, and whether wgpu-native exposes either is
   unprobed. With XR now kyoten's, that probe is kyoten's too, and it comes before the XR renderer is designed.
4. **An Android target for kama.** The NDK's clang as the `cc`, a triple such as `aarch64-linux-android<api>`, bionic
   in kama's OS layer, a shared library loaded by a native activity, APK packaging and signing. Does kyoten build this,
   or ask kama for it (a `KAMA_GAPS.md` entry and a kama roadmap row)? Probe it before deciding.
5. **The frame under XR.** The headset drives the loop (`XRSession.requestAnimationFrame`, `xrWaitFrame`) with a
   predicted display time. Output renders for that time; head and controller poses are sampled as late as possible.
   How do the four phases and their rates fit a 72, 90 or 120 Hz display clock ([frame-phases.md](frame-phases.md))?
   *Narrowed 2026-11-04* (frame-phases § Decided, question 10): the headset is one more frame source behind `run`;
   Output renders for its predicted display time, and poses are read late for drawing and enter Input at the step when
   the simulation needs them. What is left is measured on a headset (KYR-4).
6. **Input.** Head pose, tracked controllers and hands are Input-phase sources, recorded like any input, so a VR session
   replays ([replay-and-determinism.md](replay-and-determinism.md)). At what rate, and with what prediction?
7. **Rendering budget.** Stereo (multiview), foveated rendering, and holding the display rate on a mobile GPU. What does
   the example hold itself to, and how is it measured?
8. **Developing without a headset.** A simulator or an emulator (a WebXR emulator in a desktop browser, Meta's XR
   simulator natively), and a desktop mode for the example, so that agents and CI can exercise the VR path.
9. **Distribution.** A URL on kyoten's platform, a store listing, or sideloading for development. Who signs the APK
   (the signing question kama records as KR-135 applies)?
10. **The first Quest game.** The owner will likely make it as a new project of its own (see *Decided*). Is it built on
    kyoten, so that it drives KYR-31 to KYR-33, or on an engine of its own, as FFD and the-mallow-man were? *Answered
    2026-11-01: on its own, as a prototype kyoten references (see Decided).*

## Decided

- **2026-11-01, the owner: native XR is OpenXR.** OpenXR is the cross-vendor standard Quest and other headsets
  implement, so one native backend reaches them.
- **2026-11-01, the owner: XR on the web is WebXR.** The owner's expectation ("likely"), and the web has no other
  standard XR API to weigh against it. Whether the Quest browser runs it with WebGPU (question 3) decides how it
  renders, not whether it is WebXR.
- **2026-11-01, the owner: the first Quest game starts as its own project, now**, as friendly-fire-department and
  the-mallow-man did, unless it fits here in a reasonable time. The owner has not built for Quest before and wants a
  prototype to reference as soon as possible, without holding kyoten up or bending kyoten toward one game, since kyoten
  is open-ended and general purpose. It sits beside the `kyoten-vr` example, which stays an example of the engine.
  - **Assessed the same day: it does not fit here in a reasonable time.** kyoten has no frame, platform seam or
    renderer yet, so a Quest game here would wait for the gate (KYR-12), then the XR package (KYR-31) and Android
    (KYR-32). Meanwhile it would be the one game kyoten's early design bends toward, which is what the owner wants to
    avoid.
  - **What kyoten gets from it:** what FFD and the-mallow-man gave, a donor and a reference. It answers KYR-4's
    questions on real hardware, its findings come back here as research, and its kama findings go to the gap files
    (KY-2 first).
  - **Its quickest start** (a suggestion; the route is the game's own call): the web route needs no new kama target,
    since kama builds wasm today, and renders with WebGPU behind the Quest browser's flag or with WebGL without it. The
    native route meets KY-2 at once, though a `kama.json` target entry naming the NDK's clang (kama `docs/targets.md`
    § "You already have a cross toolchain") may carry it. That is untested. *(kama has since built through such a
    target and run its std fixtures on the SDK's emulator; see What already exists.)*
- **2026-11-01: the Android target is kama's to build; the platform package on it is kyoten's.** This answers question
  4. kyoten's rules already settle it: kyoten never edits kama, and the gap file is how kama hears about a gap
  ([../../AGENTS.kyoten.md](../../AGENTS.kyoten.md)). The owner expected the same ("some of that is KAMA_GAPS"). The
  target is KY-2, and kyoten's package on it is KYR-32. The probe (KYR-4) still runs, so that KY-2 gains a repro from a
  real build.
- **2026-11-02, the owner, ruling in kama: XR is kyoten's, not kama's** (kama `62322f93`, `docs/ROADMAP_DETAIL.md`
  § 8). kama's rule puts a capability in the language or std if it belongs there, in a first-party package if it
  stands alone, and otherwise in the engine.
  - **Why XR is the engine's:** its one consumer is an engine, and its hard half is engine design: the swapchain
    handed to the renderer, and on the web the frame loop `XRSession.requestAnimationFrame` owns. One interface over
    OpenXR and WebXR is an engine abstraction, as Godot's `XRServer` is.
  - **Considered:** a first-party `@kama/xr` (KR-284), filed 2026-11-01 and retired. A bare OpenXR binding could
    stand alone, as Rust's `openxr` crate does, so kyoten may publish one later.
  - **What follows:** question 2's package is kyoten's to build (KYR-31). What kama owes XR is the Android target
    (KR-280, KR-283); a gap kyoten meets past that goes to [../KAMA_GAPS.md](../KAMA_GAPS.md).
