# Rendering: WebGPU first

**Status:** draft for the design spike. One decision is recorded; the rest are questions.

## What the vision asks

- **WebGPU** on the web, the browser's own API, with native implementing the same interface.
- **High performance**, and **as quick to prototype in as Three.js**: a lit mesh on screen in a few lines.
- **Rendering is an Output-phase system**, running at the display's rate.
- **2D as layers** (the owner, 2026-11-01): a 2D game can render onto a screen layer over a 3D scene, or into a
  texture, and so on.

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

## The questions

1. **Where does it start?** From forge's `render` package, from the-mallow-man's `gfx`, from the WebGPU example, or
   fresh on `@kama/gpu`? Which repository owns the result?
2. **The layers.** Raw WebGPU (safe handles), a render graph or frame graph, and a scene layer (meshes, materials,
   lights, cameras) that a prototype uses in a few lines. Which layers does the engine provide, and which does a
   game write?
3. **The Three.js bar.** What does "a lit, spinning mesh in N lines" look like in kyoten, and what defaults make it
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
