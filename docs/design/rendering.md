# Rendering: WebGPU first

**Status:** draft for the design spike. Two decisions are recorded, the latest closing question 3; the rest are
questions.

## What the vision asks

- **WebGPU** on the web, the browser's own API, with native implementing the same interface.
- **High performance**, and **as quick to prototype in as Three.js**: a lit mesh on screen in a few lines.
- **Rendering is an Output-phase system**, running at the display's rate.
- **2D as layers** (the owner, 2026-11-01): a 2D game can render onto a screen layer over a 3D scene, or into a
  texture, and so on.
- **Output differs per platform, over one simulation** (the owner, 2026-11-04; [../VISION.md](../VISION.md)).
  - A high-end box renders "super smooth looking graphics and shaders", and a low-end one "simpler scenes".
  - One simulation can even be seen as two different games: an RTS on an iPad, an FPS on a PC.
  - Because Output never writes the simulation, this keeps determinism ([frame-phases.md](frame-phases.md) § Decided).
    Anything that affects fairness, such as smoke that hides a player, is simulated, and only its look is the
    renderer's.

## What already exists

- **kama's WebGPU state** ([../research/kama-for-engines.md](../research/kama-for-engines.md) § 3): `examples/webgpu`
  draws a triangle in pure kama over `webgpu.h`, through a four-function platform seam, with known faults (manual
  releases, leaks, a hardcoded size, no input). `@kama/gpu` (RAII handles, a typed `acquire`) is designed and unbuilt.
  The `webgpu.h` of the web port and of wgpu-native share 199 functions and differ elsewhere.
- **The peers' renderers:** the-mallow-man's `gfx` package (3D, glTF) and friendly-fire-department's renderer. See
  [../research/peer-games.md](../research/peer-games.md).
- **cosmic-forge's `render` package** (WebGPU, glTF, PBR, orbit camera, web leg built) is "shaped as kyoten's render
  package would be", in forge's own words. See [../research/cosmic-forge.md](../research/cosmic-forge.md) and
  [content-pipeline.md](content-pipeline.md).
- `std::math` has vectors, matrices and quaternions with WebGPU's depth convention.
- **FFD's 2D renderer already renders to textures.** `gfx::render` gained three passes and two offscreen targets on
  2026-09-14 (`friendly-fire-department/docs/ROADMAP_DETAIL.md` § "The offscreen render target"), proved by four
  byte-identical captures, and it serves both larger-than-screen captures and a screen-space heat haze.
- **Gathered since:**
  - **For question 1,** [../research/harvest.md](../research/harvest.md) §§ 6–8 compares the donors' renderers.
    forge's `render` is library-shaped, web only, and keeps no module statics. the-mallow-man's is feature-rich,
    native only, shaped like its one scene, and holds 63 statics. FFD's 2D renderer holds 16.
  - **For questions 2 and 5,** [../research/web-baseline.md](../research/web-baseline.md) measured what a draw costs
    from wasm. A few thousand draws a frame need no batching; ten thousand do.
- **Decided in [architecture.md](architecture.md) (2026-11-02), bearing on questions 1–3:**
  - **The layers:** a standalone, Three.js-shaped graphics library is its own package on `@kama/gpu`, which kyoten
    builds (KYR-52). It names no engine concept, so tools and non-game products can use it, and kyoten's render module
    binds components to it (KYR-9).
  - **It is a `@kama` package** (architecture question 7, 2026-11-03): "If it can exist outside of kyoten it probably
    will be in kama for now". Its name is `@kama/graphics` (the owner, 2026-11-03), and kama ruled it a first-party
    package on 2026-11-04 (kama KR-309, closing KY-9), with its design in `cosmic-canopy/kama-graphics`.
  - **Still open here:** where its code starts (question 1).

## The questions

1. **Where does it start?** From forge's `render` package, from the-mallow-man's `gfx`, from the WebGPU example, or
   fresh on `@kama/gpu`? Which repository owns the result?
2. **The layers.** Raw WebGPU (safe handles), a render graph or frame graph, and a scene layer (meshes, materials,
   lights, cameras) that a prototype uses in a few lines. Which layers does the engine provide, and which does a
   game write?
3. **The Three.js bar.** *(Decided 2026-11-05 with components question 7, below.)* What does "a lit, spinning mesh in N lines" look like in kyoten, and what defaults make it
   short (a default camera, light and material)?
4. **Rendering in the frame.** The Output phase reads the simulation's state, at the display's rate, and interpolates
   between simulation steps ([frame-phases.md](frame-phases.md)). How does it read state without stalling the next
   Update: double-buffered state, a snapshot, or extraction into render-only data?
5. **Command recording in parallel.** WebGPU encoders can be recorded on several threads natively; on the web, only
   where the device lives (see the thread topology in [web-and-native.md](web-and-native.md)). How is that kept
   portable?
6. **Assets.** glTF/GLB first (forge's output), texture formats (KTX2 and Basis for the web's size budget), shaders in
   WGSL, and hot reload of all three.
7. **Debug and tuning views** for humans ([human-tools.md](human-tools.md)): wireframe, overdraw, GPU timings per pass.
8. **Stereo and a mobile GPU.** The VR example on Meta Quest needs stereo (multiview), foveation and a hard 72–120 Hz
   budget, and its web route depends on whether WebXR works with WebGPU in the Quest browser ([xr.md](xr.md)).

9. **2D layers, in detail** (see *Decided*). The order and blending of screen layers; which layer receives input (a
   click on a 2D overlay versus the 3D scene behind it); how a 2D layer rendered to a texture is placed in 3D (a screen
   in the world, a panel in a headset, where OpenXR's and WebXR's own quad layers may keep text sharper,
   [xr.md](xr.md)); and how HTML/CSS UI relates to it. On the web, is the DOM simply the topmost layer?
   - *Noted 2026-11-06:* a scene now has layers of its own ([components.md](components.md) § Decided). A HUD or a 2D
     canvas is a non-spatial, drawn-only scene layer, and a view (a camera drawing into a target) loads what is drawn.
     How a drawn-only scene layer reaches a screen layer is this question's, and the shared word is components
     question 8's.
10. **Generative worlds, later** (KYR-50; the owner, 2026-11-02: traditional engines "for a while… especially on
    current hardware… but generative games are likely the future"). Wizard (Yuzhe Wu, Zijun Lin and Yeying Jin;
    Tencent, NUS and NTU; arXiv 2610.40339, 2026-10-29; <https://wyzardwu.github.io/wizard/>, code "soon") splits a
    game the way kyoten's frame does. Agents keep the explicit state (scene geometry, an articulated skeleton per
    character, the fight's rules), and a video model renders it: Wan2.2-TI2V-5B with two denoising steps, at 24 FPS on
    hardware the project page does not state. In kyoten's terms that is another renderer in the Output phase, reading
    the same simulation state, with agents changing the world through the project database *(inferred)*. What should
    the engine keep true until then so that one can be added: state explicit enough to condition a model on, and an
    Output phase that a renderer other than the rasterizer can fill?

## Decided

- **2026-11-01, the owner: 2D is a layer.** A 2D scene renders onto a screen layer, over a 3D scene or alone, or into
  a texture that something else uses. So 2D is not a separate engine mode, and a 2D game, a HUD, and a game on a screen
  inside a 3D world are one mechanism. The renderer designed in the spike (questions 2 and 4) leaves room for layers
  and render targets; 2D itself is KYR-49, and the details are question 9.

- **2026-11-05, the owner: question 3, the defaults that keep the hello cube short, decided with components question 7
  and ai-first-api question 1.** "All in all I think I agree on all."
  - **The default makeup of a world:** unless a record says otherwise, one window or canvas, a camera looking at the
    origin, a directional light with ambient light, a lit default material, and a start zone. *(Revised 2026-11-06:
    the app's first scene, with one zone and one layer, replaces the start zone, and one player bound to the local
    keyboard and first gamepad joins the defaults; [components.md](components.md) § Decided.)*
  - **Each default is an engine record** in the engine's content layer, which a game patches field by field
    ([project-database.md](project-database.md) question 11). kama has no default parameters, so defaults live in data.
  - **A mesh requires a transform and a material** *(confirmed at components question 8, 2026-11-06)*, so a prefab
    that lists only a mesh is drawn.
  - **Left to question 2:** which scene-layer types carry these defaults. The sketch and the reasons are in
    [components.md](components.md) § Decided, question 7.
