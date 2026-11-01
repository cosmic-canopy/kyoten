# XR: VR on Meta Quest

**Status:** draft for the design spike. Two decisions are recorded; the rest are questions.

## What the vision asks

- **A VR example for Meta Quest** ([examples.md](examples.md)), as one of the first two examples.
- **Web first, native at parity** ([web-and-native.md](web-and-native.md)), and the same frame model everywhere
  ([frame-phases.md](frame-phases.md)).

## What already exists

- **Nothing for XR in kama or the peers.** kama has no WebXR or OpenXR binding, and neither peer game has any XR code.
- **kama's targets** (`kama/docs/targets.md` § Built-in targets): `MACOS`, `WINDOWS`, `LINUX`, `WASM`, `EMBEDDED`.
  **There is no Android target.** A custom triple with a per-target compiler is allowed, and the docs name "an NDK
  wrapper" as the kind of compiler that carries its triple in its name (`targets.md:540-553`). Building an Android
  `.so` that way is untested, and std's OS layer has no Android branch that anyone has exercised.
- **kama's hot-reload notes** already mention Quest: "Android/Quest only via a pushed `.so`"
  (`kama/docs/ROADMAP_DETAIL.md` § the hot-reload library).
- **Quest facts to verify before relying on them** *(to verify)*: the Quest browser runs WebXR `immersive-vr`
  sessions; native Quest apps use OpenXR on Android with Vulkan (or OpenGL ES); headsets run at 72, 90 or 120 Hz on a
  mobile GPU with a tight thermal budget. **Whether the Quest browser supports WebGPU, and WebXR with WebGPU layers,
  is the question the web route depends on.** WebXR has traditionally been bound to WebGL.

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

## Decided

- **2026-11-01, the owner: native XR is OpenXR.** OpenXR is the cross-vendor standard Quest and other headsets
  implement, so one native backend reaches them.
- **2026-11-01, the owner: XR on the web is WebXR.** The owner's expectation ("likely"), and the web has no other
  standard XR API to weigh against it. Whether the Quest browser runs it with WebGPU (question 3) decides how it
  renders, not whether it is WebXR.
