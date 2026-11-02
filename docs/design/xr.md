# XR: VR on Meta Quest

**Status:** draft for the design spike. Four decisions are recorded; the rest are questions.

## What the vision asks

- **A VR example for Meta Quest** ([examples.md](examples.md)), as one of the first two examples.
- **Web first, native at parity** ([web-and-native.md](web-and-native.md)), and the same frame model everywhere
  ([frame-phases.md](frame-phases.md)).

## What already exists

- **Nothing for XR in kama or the peers.** kama has no WebXR or OpenXR binding, and neither peer game has any XR code.
  **kama filed one on 2026-11-01:** `@kama/xr` (KR-284, unprobed), which it recommends as a first-party package with
  one interface and an OpenXR and a WebXR backend chosen by target, since every engine on kama that wants XR needs the
  same binding. It would build OpenXR on Windows over Quest Link first, which needs no Android target (kama
  `docs/ROADMAP_DETAIL.md` § `@kama/xr`). That bears on question 2, and on [architecture.md](architecture.md)
  question 3.
- **kama's targets** (`kama/docs/targets.md` § Built-in targets): `MACOS`, `WINDOWS`, `LINUX`, `WASM`, `EMBEDDED`.
  **There is no Android target.** A custom triple with a per-target compiler is allowed, and the docs name "an NDK
  wrapper" as the kind of compiler that carries its triple in its name (`targets.md:540-553`). Building an Android
  `.so` that way is untested, and std's OS layer has no Android branch that anyone has exercised. Probed 2026-11-01 on
  0.9.803 ([../KAMA_GAPS.md](../KAMA_GAPS.md) KY-2): `--target ANDROID` is refused, and the triple
  `aarch64-linux-android` transpiles as `OS_LINUX` with `ABI_ANDROID`, so std treats it as Linux.
  **kama has since measured the native route** (kama `4f0ecbdc`, 2026-11-01, with NDK r30 on this machine; not
  re-checked from here): a `kama.json` target carrying `--target=aarch64-linux-android29` builds an executable and a
  `.so`, and every std fixture that applies links once `-lpthread` is dropped. Nothing has run on a device. kama moved
  the target (KR-280) to its NOW and filed KR-282 (an NDK wrapper is handed `-target`) and KR-283 (an installable APK).
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
4. **An Android target for kama.** The NDK's clang as the `cc`, a triple such as `aarch64-linux-android<api>`, bionic
   in kama's OS layer, a shared library loaded by a native activity, APK packaging and signing. Does kyoten build this,
   or ask kama for it (a `KAMA_GAPS.md` entry and a kama roadmap row)? Probe it before deciding.
5. **The frame under XR.** The headset drives the loop (`XRSession.requestAnimationFrame`, `xrWaitFrame`) with a
   predicted display time. Output renders for that time; head and controller poses are sampled as late as possible.
   How do the four phases and their rates fit a 72, 90 or 120 Hz display clock ([frame-phases.md](frame-phases.md))?
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
    target, but run nothing; see What already exists.)*
- **2026-11-01: the Android target is kama's to build; the platform package on it is kyoten's.** This answers question
  4. kyoten's rules already settle it: kyoten never edits kama, and the gap file is how kama hears about a gap
  ([../../AGENTS.kyoten.md](../../AGENTS.kyoten.md)). The owner expected the same ("some of that is KAMA_GAPS"). The
  target is KY-2, and kyoten's package on it is KYR-32. The probe (KYR-4) still runs, so that KY-2 gains a repro from a
  real build.
