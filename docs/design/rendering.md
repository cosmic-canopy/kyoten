# Rendering: WebGPU first

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **WebGPU** on the web, the browser's own API, with native implementing the same interface.
- **High performance**, and **as quick to prototype in as Three.js**: a lit mesh on screen in a few lines.
- **Rendering is an Output-phase system**, running at the display's rate.

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

## Decided

*(nothing yet — filled in during the walk-through)*
