# Rendering: WebGPU first

**Status:** draft for the design spike. Questions 1–4 are decided (3 on 2026-11-05, 1, 2 and 4 on 2026-11-07);
5–10 stay outside the spike, with their roadmap rows.

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

1. **Where does it start?** *(Decided 2026-11-07, below.)* From forge's `render` package, from the-mallow-man's `gfx`,
   from the WebGPU example, or fresh on `@kama/gpu`? Which repository owns the result?
2. **The layers.** *(Decided 2026-11-07, below.)* Raw WebGPU (safe handles), a render graph or frame graph, and a scene
   layer (meshes, materials, lights, cameras) that a prototype uses in a few lines. Which layers does the engine
   provide, and which does a game write?
   - *Noted 2026-11-07 ([components.md](components.md) question 8 part b):* a bare "layer" now means a scene's
     layer, and levels of code are tiers, so these are the render module's tiers, and the "scene layer" here needs
     another word.
   - *Named 2026-11-07 at [components.md](components.md) question 8:* the day-one render components are `Mesh`,
     `Material`, `Camera`, `Light` and the world component `Environment`. Their fields are this question's.
3. **The Three.js bar.** *(Decided 2026-11-05 with components question 7, below.)* What does "a lit, spinning mesh in N lines" look like in kyoten, and what defaults make it
   short (a default camera, light and material)?
4. **Rendering in the frame.** *(Decided 2026-11-07, below.)* The Output phase reads the simulation's state, at the
   display's rate, and interpolates between simulation steps ([frame-phases.md](frame-phases.md)). How does it read
   state without stalling the next Update: double-buffered state, a snapshot, or extraction into render-only data?
   - *Noted 2026-11-07 ([components.md](components.md) question 9):* a position is a zone and a `float32` offset,
     so Output draws relative to the camera's zone and the GPU sees small floats.
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
     question 8's. *(Named 2026-11-07: a bare "layer" is a scene's layer, and a screen layer is always called so.)*
10. **Generative worlds, later** (KYR-50; the owner, 2026-11-02: traditional engines "for a while… especially on
    current hardware… but generative games are likely the future"). Wizard (Yuzhe Wu, Zijun Lin and Yeying Jin;
    Tencent, NUS and NTU; arXiv 2610.40339, 2026-10-29; <https://wyzardwu.github.io/wizard/>, code "soon") splits a
    game the way kyoten's frame does. Agents keep the explicit state (scene geometry, an articulated skeleton per
    character, the fight's rules), and a video model renders it: Wan2.2-TI2V-5B with two denoising steps, at 24 FPS on
    hardware the project page does not state. In kyoten's terms that is another renderer in the Output phase, reading
    the same simulation state, with agents changing the world through the project database *(inferred)*. What should
    the engine keep true until then so that one can be added: state explicit enough to condition a model on, and an
    Output phase that a renderer other than the rasterizer can fill?
11. **When shaders are compiled is the game's choice** (KYR-78; the owner, 2026-11-18: "Who said we should compile
    shaders while the game runs? shouldn't that be a choice for the game? Pre-compiling shaders is pretty typical and I
    would say probably the most common unless you have dynamic shader needs?"). The direction is the owner's; how is
    this question's.
    - **Where it stands:** GFX-1's part 3 (2026-11-15) took a material as a typed node graph compiled at run time,
      three.js's model, and its decision 3 compiles pipelines off the frame, `renderer.compile(scene:)` ahead and a
      pipeline cache on disk later natively. Whether a game may ship its shaders built was never asked. Part 5
      (2026-11-18, § Decided) builds compiling at load and leaves the rest to this row.
    - **What limits it today:** on the web a page hands WGSL to the browser, which always compiles it, so a game can
      build its WGSL ahead but never its DXIL. Natively, wgpu-native v29 takes WGSL or SPIR-V and compiles them itself
      (naga to HLSL, then DXC or FXC on D3D12); its feature that takes a backend's own shader, DXIL on D3D12, is
      commented out in its header (`WGPUNativeFeature_PassthroughShaders`), and its pipeline cache is Vulkan's alone
      (DX12 and Metal unimplemented). So until wgpu-native passes DXIL through, a game on `@kama/gpu` needs DXC (or FXC)
      beside it on Windows even if it builds every material ahead. The driver's own compile, from DXIL to the GPU's
      code, happens at run time either way, which is why Unreal precaches pipelines too.
    - **To decide when the row comes up:** how a game says which (its manifest, or per material); what is built ahead
      (WGSL from its material records by the `kyoten` tool; DXIL once wgpu-native passes it through, DXC then running on
      the developer's machine); what a dynamic need keeps at run time (hot reload, modding, an editor, the kama builder);
      the pipeline cache on disk natively; and how the goldens hold both paths to the same pixels.

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

- **2026-11-07, the owner: questions 1, 2 and 4.** "All of this sounds good to me so far." And the bar they set with
  it: *"Three.js has become THE primary prototype for AI development due to th ease of use and ability to run on browser
  seamlessly... we want kama graphics to be the same ease of use but cross platform. It also must be production grade
  for kyoten to compete with Unreal, Unity, GoDot, etc."* and *"We need kyoten to be competitive in graphics so it must
  be able to do amazing shaders and visuals. We will build as we go."*
  - **The bar is two at once:** Three.js's ease of use (a lit mesh in a few lines, in any browser) on every platform,
    and production-grade visuals and shaders that compete with Unreal, Unity and Godot. Three.js, and the other engines
    below, are the references for the library's API.
  - **The donors, re-checked the same day at the owner's request:** friendly-fire-department and the-mallow-man have no
    commits since the harvest. cosmic-forge has 58, none in `render`: they are its asset pipeline, with LODs by a budget
    the game sets, baked normal maps, glass as an alpha map, and metallic-roughness maps. Its `render` already reads
    glTF's core material (base colour, metallic-roughness, normal, occlusion and emissive textures; alpha opaque, mask
    and blend) with Khronos PBR Neutral tone mapping, and has no shadows, no instancing and no native leg.
  - **The references, read the same day by a research agent and checked here at their source:**
    - **three.js r187** (2026-10-30): `WebGPURenderer` *"can automatically fall back to using a WebGL 2 backend"*, and
      *"The renderer itself is still in an experimental state although its maturity level has been greatly improved
      in the last years"*. Its shaders are TSL, node expressions in JavaScript that are *"transpiled to WGSL or GLSL
      depending on the available backend"*; post-processing is `RenderPipeline` (renamed from `PostProcessing` in
      r183), which *"replaces the previous instance of `EffectComposer`"*. Its manual's lit spinning cube is 35
      non-blank lines, on `WebGLRenderer`.
    - **Render graphs are split:** Bevy removed its render graph in 0.19 (*"The RenderGraph API has been removed.
      Render passes are now systems that run in Core3d or Core2d schedules"*); Babylon.js 9.0 made its Frame Graph a
      v1 feature; Unity 6.4 removed URP's compatibility mode for custom passes in favour of its render graph.
    - **Shaders:** WGSL has no imports (*"A WGSL program is composed of a single WGSL module"*). Bevy 0.20 writes its
      shaders in WESL, which adds `import` and `@if` and is translated to plain WGSL (*"WESL support is always enabled.
      GLSL support has also been removed"*), and naga_oil, its predecessor, is archived.
    - **glTF's lights** (KHR_lights_punctual, ratified): point and spot *"use luminous intensity in candela (lm/sr)
      while `directional` lights use illuminance in lux"*.
  1. **Question 1: `@kama/graphics` starts from cosmic-forge's `render`:** the only donor shaped as a library, with no
     module statics, glTF's core material with skins and clips, and an offscreen readback a headless check can measure.
     It lacks a native leg, shadows, instancing, more than one light and post-processing.
  2. **Question 1: the-mallow-man's techniques come over one at a time,** each when a measurement or an example asks
     for it (shadows first; instancing as draws near 10⁴), with its costs per technique on a Steam Deck as the bar.
     Its game-shaped frame uniform and its 63 statics stay behind. friendly-fire-department's batcher and MSDF text
     become the 2D screen layer later (KYR-49).
  3. **Question 1: one renderer, two consumers.** cosmic-forge depends on `@kama/graphics` in place of its own copy,
     which answers [content-pipeline.md](content-pipeline.md) question 5: shared, not forked. `@kama/gpu` (KYR-52) is
     built first, and the library on it.
  4. **Question 2: three tiers, named by their packages,** so the old "scene layer" needs no new word: **`@kama/gpu`**,
     safe WebGPU handles; **`@kama/graphics`**, meshes, materials, lights, cameras, render targets and passes, naming
     no engine concept; and **kyoten's render module**, the Output processors that read render components and drive
     the library, with views, screen layers and quality per machine.
  5. **Question 2: no general render graph at first.** Each view runs a fixed list of passes (shadows, opaque,
     transparent, post-processing, then the screen layers composed), with render targets first-class, since 2D as a
     layer needs them. A frame graph comes when the number of passes asks for one; the references above go both ways.
  6. **Question 2: what a game writes:** records for everything the defaults cover; custom shaders as WGSL assets a
     `Material` names (KYR-10); and anything else in its own Output processor on `@kama/graphics`, the escape hatch
     of [web-and-native.md](web-and-native.md) question 1.
  7. **Question 2: the day-one render components' fields, a first cut KYR-9 refines:**

     | Component | Fields (default) |
     |---|---|
     | `Mesh` | `shape`, `Box`, `Sphere`, `Plane` or `Cylinder`, or `asset`, a mesh from a glTF file; `castShadows` (true) |
     | `Material` | `color` (white), `metallic` (0), `roughness` (0.5), `emissive` (black), `texture` (none), `transparent` (false), `shader`, a WGSL asset (none: the standard lit material) |
     | `Camera` | `projection`, `Perspective` or `Orthographic`; `fov`, vertical, in degrees (60); `near` (0.1 m), `far` (1000 m); `target`, the view it draws into (the screen) |
     | `Light` | `kind`, `Directional`, `Point` or `Spot`; `color` (white); `intensity`, in glTF's units, lux for a directional light and candela for a point or spot; `range`; `cone` (a spot's); `castShadows` |
     | `Environment`, a world component | `ambient`, a colour and an intensity; `background`, a colour or a sky image; `fog` (none) |

  8. **Question 4: Output extracts, and the GPU work reads only what was extracted.** The render module's Output
     processors read the settled world and write what is drawn into the library's buffers: one per-object buffer,
     written once a frame ([web-and-native.md](web-and-native.md) question 6). Interpolation, each component's `blend`
     at the frame's time, happens in this pass, and so does the camera-relative position (a zone and an offset), which
     keeps the GPU's floats small.
  9. **Question 4: serial by default:** the due steps, then extraction, then recording, on one thread. Only what is
     drawn is copied, nothing adds latency, and it is the single-threaded web build's only shape.
  10. **Question 4: pipelined when measured.** With threads on, recording and submitting frame N may overlap the next
      steps, since it reads only extracted data. It costs up to a frame of latency (friendly-fire-department's
      warning), so it is a switch a game turns on by measurement, like the job pool.
  11. **Question 4: no double-buffered world,** which would copy every column each step. The `history` a component's
      record asks for already keeps the previous values interpolation needs.

- **2026-11-07, the owner: how shaders are written,** proposed for the bar's "amazing shaders and visuals" and filling
  in question 2's item 6. "All sounds good to me so far."
  - **The evidence,** besides the references in the entry above: WESL's Rust implementation has a C library, `wesl-c`,
    and a command-line tool, `wesl-cli`, among its crates (`webgpu-tools/wesl-rs`, read 2026-11-07), and its site says
    *"C bindings are available in the Rust implementation"*. three.js's `WebGPURenderer` does not support
    `ShaderMaterial`, `RawShaderMaterial` or `onBeforeCompile`, so its custom shaders are TSL. Unity's Shader Graph,
    Unreal's Material Editor, Godot's visual shaders, Babylon.js's Node Material Editor and three.js's TSL each pair a
    shader language with a graph of nodes for materials.
  1. **WGSL is the shader language, with WESL for imports.** WGSL is what the browser runs, and Dawn and wgpu-native
     take it natively, so a shader is never translated between languages. kyoten's tools translate WESL's `import`
     and `@if` to plain WGSL at build, and again on save in development so a shader hot-reloads, through `wesl-c` or
     `wesl-cli`; nothing extra ships. The engine's own shaders (the standard lit material, shadows, post-processing)
     are WESL modules a game imports.
  2. **Materials are node graphs, kept as records.** The standard lit material has slots (base colour, normal,
     metallic, roughness, emissive, opacity, a vertex offset), and a material fills any of them with an expression of
     nodes: textures, noise, time, mixes, a fresnel. That is TSL's model and the node editors'. In kyoten the graph is
     data, so an agent writes it, the editor draws it, and it hot-reloads, layers and is checked like any record. The
     graphics library compiles a graph to WGSL, and a kama builder API makes the same graph from code, as TSL does in
     JavaScript.
  3. **Full WGSL when nodes are not enough.** A material may replace a slot, or a whole vertex or fragment stage, with a
     WGSL or WESL function that imports the engine's modules, as a Bevy material does. Nodes never cap what a shader
     can do.
  4. **Compute shaders for visuals:** GPU particles, post effects and culling, written the same way and run in Output.
     Never the simulation, which stays on the CPU because WGSL's floats are not reproducible
     ([replay-and-determinism.md](replay-and-determinism.md) question 1, KYR-64).
  - **The production features grow as the examples ask,** with the-mallow-man's measured techniques as the reference:
    shadows, instancing, a post-processing stack (tone mapping, bloom, anti-aliasing), many lights, then global
    illumination and the rest. Their order is not decided here.

- **2026-11-10, the owner: Three.js is a reference for ease of use, never a limit; the bar is the state of the art.**
  "I only reference Three.js as I noticed it is being used very successfully by AI today. I DO NOT want us to be
  limited by any decisions Three.js has made or anything it can not do. We need to be able to do what Unreal and Unity
  and Godot can do graphics wise as well. AKA we need to be able to do the state of the art in graphics." Of the
  library: "a fully featured and easy to use library for general graphics applications much like how Three.js has
  become that for the web." Decided with how the libraries grow ([architecture.md](architecture.md) § Decided,
  2026-11-10).
  - **The bar, restated:** ease of use like Three.js's (a lit mesh in a few lines, in any browser and natively), and
    capability at the state of the art as Unreal, Unity and Godot reach it.
    - Where Three.js and the state of the art differ, the state of the art wins, and the ease of use is kept on top.
    - This sharpens the 2026-11-07 bar: Three.js is a reference for how easy the library is to start with, never for
      what it can do.
  - **A design pass before any graphics code** (KYR-68), its questions asked in full like the spike's:
    - **the object model in kama's terms:** no garbage collector, no inheritance, and RAII, so nothing is disposed by
      hand, as Three.js's `dispose()` asks;
    - how close its names sit to Three.js's;
    - **the renderer's core:** the decided fixed pass list, pipeline and bind group caches, the per-object buffer, the
      node-material compiler with WESL, and a linear-light workflow with HDR and tone mapping;
    - **beyond WebGPU:** where the state of the art needs what WebGPU does not have yet (hardware ray tracing, mesh
      shaders), and wgpu-native's native extensions (its `wgpu.h` lists ray queries), how a feature beyond the web is
      offered without breaking "web first, native at parity";
    - **the feature map:** every feature of Three.js and of the engines, each with its status, the example that needs
      it, and its test and budget. Among them:
      - geometry, materials and PBR with image-based lighting, lights, shadows and cameras;
      - textures and loaders, and animation;
      - post-processing, instancing, picking, helpers and text;
      - 2D, XR multiview, and the state of the art beyond Three.js (global illumination among it).

    The pass writes the package's `SPEC.md` and `ROADMAP.md`.
  - **Every example is a test:** a headless readback and a golden image with a tolerance, on web and native.
  - **Pay for what you use:** a feature a program does not use drops out at link time, measured from the first slice,
    since the cube's web budget is 150 KB.
  - **Non-game examples** come after the cube, beside the games, to keep the library general: an editor viewport, a
    product viewer and a data visualization.
  - **The decided path stands, and the pass builds on it:** cosmic-forge's `render` as the start, the-mallow-man's
    techniques one at a time, the three tiers, the fixed pass list, and WGSL with WESL and node materials.

- **2026-11-11, the owner, during the graphics design pass (KYR-68): native reaches the state of the art, and the web is
  the floor.** "recall we also want native state of the art... not just web. web is probably lowest common denominator
  but output doesn't feed the simulation. so graphics fidelity can be better native if needed. or even on different
  machines"
  - This restates the 2026-11-04 rule for the library: output differs per platform over one simulation. Output never
    writes the simulation, so a machine's fidelity is its own and determinism is untouched.
  - **So a technique the web cannot run yet stays in scope natively:** hardware ray tracing, mesh shaders, 64-bit
    atomics (Nanite-class geometry, virtual shadow maps), bindless resources and multi-draw indirect with a count.
  - **Fidelity may differ by machine on one platform too**, as the render module's quality per machine already says.
  - **How a technique beyond the web is offered**, and how the library reaches it natively where wgpu-native's C API
    does not (its `wgpu.h` v29 can request ray queries but builds no acceleration structure, and has mesh shaders
    commented out; [../research/graphics.md](../research/graphics.md) § 3), is the pass's question of what goes beyond
    WebGPU.

- **2026-11-11, the owner: the graphics design pass, area 1, the object model** (KYR-68;
  [../research/graphics.md](../research/graphics.md) § 4 and its two probes). Four questions, each answered as
  recommended.
  1. **Two tiers in `@kama/graphics`.** "Sounds great to me."
     - **A flat core** of packed instances, written into the per-object buffer once a frame (question 4's item 8).
       kyoten's render module drives it, creating an instance per entity and dropping it with the entity.
     - **A scene graph built on it,** for ease of use: a mesh node owns one core instance and pushes its world transform
       when it changes.
     - These are Godot's servers with its nodes over them, and Bevy's render world under its main world. A scene graph
       alone would make kyoten copy its world into a second tree; a core of handles alone is hard to start with.
  2. **Assets are shared handles:** geometry, materials, textures and render targets. "Sounds good."
     - `copy` shares one object, as `@kama/gpu`'s handles do. The last drop frees it once the GPU has finished, so
       nothing is disposed by hand.
     - Editing a shared material changes every mesh that uses it, as in Three.js and Bevy.
     - **A separate one is `clone()`** (the owner: "Can the explicit copy of settings be a 'clone' operation?"). It is
       an instance method, `fn This clone()`, as kama's SPEC spells the self-type's copy. Measured on 0.9.911: the
       clone is independent, and changing it leaves the original alone.
     - A clone copies its own settings, and what it names stays shared: a material's clone keeps the same textures,
       as Three.js's `clone()` does. A geometry's clone copies its vertex data.
  3. **Scene nodes are held through `Shared` by both the program and the scene,** with a `Weak` link to the parent. A
     node lives until its last holder drops it. "I think this sounds good so far."
     - **Costs, accepted:** kama checks two `Shared` handles at run time, so a callback that changes the tree during
       the renderer's walk traps. A forgotten handle keeps an object alive, so the renderer counts what is alive, as
       Three.js's `renderer.info` does.
  4. **Typed node kinds behind one node contract:** `Mesh`, `Group`, the lights and the cameras.
     - Each kind embeds a shared node part (transform, children, parent). The scene holds the contract, and the program
       holds a typed handle to the same object.
     - The owner: "Kyoten uses the component model itself but the graphics model is probably better suited to the
       typed model like Three.js as you recommended. Also as you stated kyoten uses the other interface anyway."
     - **Cost:** kama contracts have no default methods, so each kind forwards to its node part. That boilerplate is in
       the library, never in a program.

- **2026-11-11, the owner: the graphics design pass, area 2, the names** (KYR-68; [../research/graphics.md](../research/graphics.md)
  § 4's third probe). Four questions, each answered as recommended.
  1. **Three.js's type names where the concept is the same:** `Scene`, `Group`, `Mesh`, `PerspectiveCamera`,
     `OrthographicCamera`, `AmbientLight`, `HemisphereLight`, `DirectionalLight`, `PointLight`, `SpotLight`,
     `BoxGeometry`, `SphereGeometry`, `PlaneGeometry`, `Texture` and `RenderTarget`. "Yes."
     - AI models know Three.js's vocabulary deeply, and someone coming from Three.js maps one to one.
     - **Where the concept differs, the name is the library's own, with the reason recorded.** The renderer is
       `Renderer`, not `WebGPURenderer`: it runs every backend, and ai-first-api names a capability, never a platform.
       Material names follow area 3's material model.
  2. **`make` takes, by name, what defines an object.** Every other setting starts at Three.js's default and is changed
     afterwards through its property. A setting that can only be chosen at creation goes in an options value
     (`openWith(…, options:)`, as `@kama/window` does).
     - The owner: "Note that kama does have named ctors so you can create different ctors with different parameters and
       such if needed. but for defaults yes we don't do default params."
     - **So a common second way to make an object is a named ctor of its own,** under kama's rule (KR-367): a
       `with<Setting>` such as `BoxGeometry.withSegments(…)`, or a `from<Input>` such as `Texture.fromImage(…)`.
       Defaults are never parameters.
  3. **Each property is a pair, after kama's own `view()`/`viewMut()`.** `position()` is a `const fn` that reads it.
     `positionMut()` hands back a `ref` and marks its owner changed, so the renderer re-uploads only what changed and a
     program never sets a `needsUpdate` flag. Three.js's helpers come under their names: `rotateY`, `translateX`,
     `lookAt`. "Seems good so far."
     - **The owner assumed "the access call is optimized away so it is like accessing a property directly". Measured
       the same day, on kama 0.9.911's release flags:**
       - The probe's kept C was compiled at `-O3 -DNDEBUG`, as kama's native release does, into an unstripped object.
       - In the program's function, `cube.positionMut().x = 2.0` is two stores: the changed flag and the value
         (`movb $0x1,0x18(%rsi)`, then `movl $0x40000000,(%rsi)`). `rotationMut().y += 0.01` is the flag and a load,
         add and store. Neither accessor is called.
       - **The one cost beyond a field access** is kama's exclusivity check on a `Shared` object: two compares against
         the thread's open accesses before a write. Any `Shared` object pays it, with or without an accessor.
       - kama emits a whole program as one C file, `std` included, so a library's accessors inline into a game's code
         too.
  4. **Units:** "Sounds good to me."
     - **Angles are radians in every call,** and the parameter's label says so (`rad:`, `fovRad:`), as `std::math` does.
       This departs from Three.js's `fov` in degrees on purpose: Three.js's habit of writing `fov: 75` must not compile
       into 75 radians. kyoten's `Camera` record keeps its decided `fov` in degrees, and the render module converts.
     - **Colors are written in sRGB** and converted to a linear working space, as Three.js's color management does.
     - **Lights use physical units:** lux for a directional light, candela for a point or spot, as glTF does.
     - **Axes:** Y up, right-handed, metres, as kyoten already decided (components question 9).

- **2026-11-11, the owner: the graphics design pass, area 3, the renderer's core** (KYR-68;
  [../research/graphics.md](../research/graphics.md) § 2 and § 5). Five questions, each answered as recommended. The
  second, the materials, was asked again with the survey the owner asked for.
  1. **Clustered forward ("Forward+") is the one lighting path,** with a depth prepass and 4× MSAA by default. "Sounds
     good to me so far. Your research is likely more ahead than my recollection on what is state of the art."
     - **How it works:**
       - a compute pass sorts the lights into screen clusters, and runs on WebGPU;
       - the depth prepass removes overdraw, and writes normals and motion vectors when an effect asks for them (SSAO,
         SSR, TAA);
       - 4× MSAA is on by default, the one multisample count WebGPU guarantees on every device;
       - one path serves opaque, transparent, XR and mobile.
     - **Why not deferred:** a G-buffer costs memory bandwidth, which mobile and Quest have least of. It cannot take
       MSAA, and transparency needs a forward pass anyway.
     - **The engines agree:** Godot's renderer is clustered forward, with no deferred path. Unity's URP offers Forward+
       and Deferred+. Bevy is clustered forward, with deferred optional. Unreal uses forward for MSAA and VR. The
       the-mallow-man reference is forward with clustered lights.
     - **Later, natively:** a visibility buffer comes with Nanite-class geometry, in the area beyond WebGPU. Deferred
       comes only if a measurement asks for it.
  2. **Three.js's mesh materials are typed presets over the one node-material system.** The owner first asked: "I
     thought materials were programmable with shaders and such? What do the others do? I assume typing them has
     advantages?" Then, with the survey (research § 5): "All of this sounds great so far."
     - **The presets keep Three.js's names:** `MeshBasicMaterial` (unlit), `MeshLambertMaterial`, `MeshPhongMaterial`,
       `MeshStandardMaterial` (glTF's metal-roughness), `MeshPhysicalMaterial`, `MeshToonMaterial`,
       `MeshNormalMaterial`, `MeshMatcapMaterial`, `LineBasicMaterial`, `PointsMaterial`, `SpriteMaterial` and
       `ShadowMaterial`. Each is a node graph over the standard slots, as three.js r187's `StandardNodeLibrary` maps
       its 13 classic materials to node materials.
     - **A preset's settings are values, so changing one never compiles a shader.** A thousand standard materials in a
       thousand colors share one pipeline, and with item 4 they can be drawn together. This is what Unreal's Material
       Instances give.
     - **A preset stays programmable:** any slot can be replaced by a node expression or by WGSL, and the rest of the
       preset (lighting, shadows, fog) is kept. three.js's `colorNode`, `roughnessNode` and the rest, and Bevy's
       `ExtendedMaterial`, do the same. Each replaced slot is a new graph, and so one new pipeline, compiled off the
       frame (item 3).
     - **`MeshPhysicalMaterial`'s extras are glTF's extensions,** so a glTF file loads unconverted: clearcoat, sheen,
       transmission, iridescence, anisotropy, dispersion, specular, IOR, volume and emissive strength.
     - **Why typed:**
       - the names and types are checked, where Unity's string property names fail silently (`_BaseColor` under URP,
         `_Color` in the built-in shader);
       - glTF maps onto the presets directly;
       - a preset is the shortest way to start.
     - **What it costs:** the list is fixed, so a material outside it is a slot override or WGSL. Layered materials like
       Unreal's Substrate go on area 5's feature map.
  3. **Pipelines are compiled off the frame, never as a hitch.** "It sounds like this is the production answer and
     likely what we start with. We are a highly parallel system so hopefully kyoten can make this work well."
     - **How it works:**
       - a pipeline is cached by a hash of what made it: the material's graph, the vertex layout, the pass, the target
         formats and the multisample count;
       - it is compiled when an object first appears, and the object draws a frame or two late, never by stalling the
         frame;
       - `renderer.compile(scene:)` compiles a whole scene ahead, as three.js's `compileAsync` and Unreal's precaching
         do;
       - a pipeline cache on disk comes later, natively.
       - **Widened 2026-11-18** (part 5's question 1, below): what a draw does while its pipeline compiles is the
         program's, the material's general form by default.
     - **Measured the same day** (research § 5): one lit-sized pipeline takes about 24 ms on one thread, a frame and a
       half at 60 Hz.
     - **Where the compiling runs:**
       - on the web, in the browser's `createRenderPipelineAsync`;
       - natively, by the ordinary call on worker threads, because wgpu-native's asynchronous call is
         `unimplemented!()` (v29.0.1.1 and trunk). wgpu-native compiled 48 pipelines 4.7× faster on 8 threads than on
         one, with no errors.
       - So kyoten's parallelism serves this directly: natively, its workers compile.
  4. **Per-object data and automatic instancing.** "So far I think this sounds good from what I can tell."
     - **The per-object buffer:** the core's instances are one storage buffer of records: the world matrix, the
       previous frame's matrix for motion vectors, the material and flags. A vertex shader reads its record by instance
       index, as cosmic-forge's renderer already reads vertex data from storage buffers.
     - **Draws are sorted** by pipeline, then material, then mesh.
     - **Instancing is automatic:** objects that share a mesh and a material become one instanced draw, as Unity's GPU
       Resident Drawer and Bevy do. three.js's explicit `InstancedMesh` stays, as a convenience.
     - **Textures:** a bind group per material on the web, which has no bindless yet. Natively, one array of textures
       where the device offers one, in the area beyond WebGPU.
  5. **Linear HDR throughout, tone mapped at output, AgX by default.** "Sounds good so far."
     - **The working space:** rendering is in linear HDR, in a 16-bit float target, and output is sRGB.
     - **The default curve is AgX:** it is filmic and takes saturated highlights gracefully, and Blender, Godot, three.js
       and the-mallow-man all offer it.
     - **The other curves are options:**
       - Neutral (Khronos PBR Neutral) for faithful colors, as a product viewer wants and cosmic-forge's viewer uses;
       - ACES and Reinhard;
       - none.
     - **Why a default at all:** three.js defaults to no tone mapping (`NoToneMapping`, r187's `Renderer.js`), so a
       bright light clips to flat white.
     - Output to HDR displays comes later, in the feature map.

- **2026-11-11, the owner: the graphics design pass, area 4, beyond WebGPU** (KYR-68;
  [../research/graphics.md](../research/graphics.md) § 2, § 3 and § 6). Five questions, each answered as recommended.
  1. **One API everywhere; each technique is a ladder of methods.** "4.1 sounds ideal to me."
     - **The ladders,** each method naming the GPU features it needs, best first:
       - global illumination: hardware ray traced, software traced, light probes, ambient;
       - shadows: virtual shadow maps, cascaded with soft edges, plain cascaded;
       - geometry: virtualized clusters, then LOD meshes;
       - draws: GPU-driven with one multi-draw, GPU culling, CPU culling;
       - textures: one bindless array, then a bind group per material.
     - **The renderer reports the device's features,** as three.js's `hasFeature` does.
     - **Quality presets** (low, medium, high, ultra) set every technique at once, as Unreal's scalability groups do,
       and a program can set one technique directly.
     - **A missing feature never stops a program:** the renderer takes the next method down and reports the one it
       chose. Bevy's virtual geometry exits the process instead, and its Solari refuses to load.
     - **kyoten's render module picks the preset per machine,** as its quality per machine already says (question 2).
     - **Every method is tested:** each has a golden image of its own, run on the platforms that have it.
  2. **Hardware ray tracing natively: help land wgpu-native's open PR #630.** "Option A sounds good. We have no control
     of the maintainers choice obviously but it would be good to test the state of the art. OK to build and run."
     - **PR #630 already declares the C API:** acceleration structures, built and compacted, and mesh pipelines and
       draws (research § 6). So no library of kyoten's own, and no C API of its own, is written.
     - **The work:**
       - build the PR, test ray queries and mesh shaders on our hardware, and report or fix what is found, in the PR;
       - until it merges, `@kama/gpu` pins a build of its branch for the native ray-tracing leg only. That pin is a
         stopgap, replaced by wgpu-native's release once the PR merges.
       - Anything posted to gfx-rs waits on the owner's go-ahead, since it is public.
     - **`@kama/graphics` keeps acceleration structures out of a program's way.** A program asks for ray-traced
       shadows, GI or reflections (item 1's top method), and the library keeps a bottom level per mesh and a top level
       per scene.
       - gpuweb's proposal (#11054, 2026-10-13) shares wgpu's concepts with one object in place of two, so when
         browsers ship it the web gains the method with no change to the library's API.
       - A program that wants its own ray queries in WGSL uses `@kama/gpu` directly.
     - **When:** the path is decided now, and the work comes when the feature map reaches ray tracing.
     - **Probed the same day,** with the owner's OK to build and run the PR (research § 6), over Vulkan on the AMD Radeon
       880M:
       - ray queries matched the CPU on every ray of a grid;
       - about 1 G coherent rays a second against half a million triangles (wall clock);
       - a task and mesh pipeline drew its target pixel for pixel;
       - there were no validation errors.
     - **Rejected:**
       - waiting without helping: slow, and uncertain;
       - a wrapper of kyoten's own over Rust's wgpu: it duplicates #630 and would share wgpu-native's internal
         handles;
       - Vulkan, D3D12 and Metal directly: a second GPU backend per platform, against the one WebGPU-shaped interface.
  3. **Virtualized geometry natively first, on the 64-bit atomics wgpu-native v29 already has.** "yes"
     - Bevy's virtual geometry runs without mesh shaders: it rasterizes small triangles in compute.
     - **Mesh shaders come later,** as a faster method once a measurement shows they pay, by item 2's path. On the web
       they are in gpuweb's Milestone 4+.
     - **On the web, Chrome's `atomic-vec2u-min-max`** (a 64-bit min and max) is to be measured for the technique's
       visibility buffer when the feature map reaches it.
  4. **Our own temporal upscaler, in WGSL, on every platform.** "yes"
     - **Vendor upscalers come later, natively, each an optional package of its own,** so a vendor SDK's license
       stays out of the MIT/Apache library: NVIDIA's DLSS, Intel's XeSS and AMD's FSR.
     - **They need a native handle wgpu-native does not expose:** the raw Vulkan or D3D12 device. Bevy's DLSS reaches
       it through wgpu's `as_hal`. That is one more C API addition, by item 2's path.
     - AMD's FSR 2 is published as open-source compute shaders, a possible start for our own; its license is checked
       when the row comes up.
  5. **WebGPU is the web's only backend, with no WebGL 2 fallback.** "yes. If we find a need in the future we can
     always add that... but webgpu for now is best. We also will likely not target the browser for Meta quest
     either... It is good to support it but native meta quest is more important up front anyway."
     - **Why:** area 3's core needs what WebGL 2 lacks: compute for the light clusters and culling, and storage buffers
       for the per-object records. A WebGL 2 backend would be a second, lesser renderer, with GLSL shaders and a doubled
       test matrix.
     - **The gap, as of the research:** Firefox on Linux, Android and Intel Macs, and Chrome on Linux. Safari, Chrome,
       Edge and Firefox on Windows and Apple silicon all have WebGPU.
     - **A page without WebGPU says what is missing** and which browsers work, and native builds cover those players.
     - **The Quest:** the owner's note matches what is decided. Players reach Quest natively first, and the Quest
       browser serves development ([web-and-native.md](web-and-native.md) question 8, item 7, 2026-11-07).

- **2026-11-11, the owner: the graphics design pass, area 5, the feature map** (KYR-68;
  [../research/graphics.md](../research/graphics.md) § 7 and § 8). Five questions, each answered as recommended, with one
  condition on budgets. This closes the design pass.
  1. **The map is `@kama/graphics`' `FEATURES.md`, one row per feature, and its `ROADMAP.md` orders it.** "5.1 sounds
     good. I assume mentioning the name of the engine isn't an issue with legal or anything?"
     - **A row says:** the feature; what three.js and the engines call it; its methods best first, each with the GPU
       features it needs; its status (`planned`, `partial` or `built`); the example that first needs it; its test; and
       its budget.
     - **`tools/check-features.sh` holds every row complete:** a status from the set, a declared example or `asked`, a
       unique test that `tests/` has once a method is built, a budget once a method is built and none before, and every
       example scheduled by a live roadmap row. Each of its 13 failure cases was seen to fail on a mutated map.
     - **Naming the other products, answered:** referring to a product by its name, to say what a feature is called
       there, is the accepted use of a trademark (in the US, nominative fair use), on four conditions the map keeps:
       - the words only, never a logo;
       - never in a name of ours: a package, a type or a tool;
       - nothing that suggests affiliation or endorsement, and a notice in the map saying so;
       - each name spelled as its owner spells it.

       What the owners publish agrees (research § 8): Unity's guidelines let its wordmarks "describe or … refer to
       Unity products" and forbid them in another's product name, and the Godot Foundation's forbids its name for a
       commercial engine or a company. Copyright is the stricter line: no code or text is copied from Unreal or
       Unity, whose source is under their own licenses, and code adapted from three.js, Godot or Bevy (MIT, or MIT or
       Apache) keeps its notice. This is the usual practice, not legal advice.
  2. **The order, slice by slice, each driven by an example.** "5.2 sounds good so far and may change."
     - A lit cube, a level, a product viewer, a shooter's level, stereo on Quest 3 natively, an editor viewport and a
       data visualization, then the state of the art as programs ask: global illumination, reflections, virtual shadow
       maps, virtualized geometry, sky and atmosphere, large outdoor worlds, characters, a reference path tracer,
       vendor upscalers and HDR displays (`@kama/graphics`' GFX-1 to GFX-17).
     - **The library's examples are its own,** named by the kind of program they stand for, since it names no engine
       or game. Each mirrors what one of kyoten's needs: the hello cube (KYR-14), level A2 (KYR-11), the fps example's
       first version (KYR-65), Quest (KYR-33) and the editor (KYR-26).
     - **Quest may move earlier.** Its graphics needs are small (multiview, foveation, space warp), and what gates it is
       kama's Android app (KY-2), the XR package (KYR-31) and `@kama/gpu`'s Android surface (GPU-11).
  3. **Each feature's budget is two ratchets, set by measurement, and a budget never limits what is built.** "5.3
     sounds good... I don't want to limit what we build though so we should be careful about this."
     - **The two numbers:** the web code a feature adds (KB, brotli) and its GPU time on each reference machine at
       that machine's default preset, from timestamp queries.
     - **The owner's condition, as the rule:**
       - a feature or method enters with whatever it first measures; a budget is a measurement, never a gate on
         building;
       - a ratchet fails only when something already built gets costlier, and raising one is a change with its reason,
         never a refusal;
       - a method's cost on a machine decides whether a preset turns it on there, never whether it exists: a path
         tracer exists on the Steam Deck, off by default;
       - a program pays only for what it uses, since an unused feature drops out at link time, so a heavy feature costs
         other programs nothing;
       - a GPU time is compared within a tolerance measured from its own noise, so noise never fails a build.
     - The hello cube's whole-program gauge of 150 KB stands ([web-and-native.md](web-and-native.md) question 4).
  4. **Goldens from a software GPU in CI, checked perceptually on the reference machines.** "5.4 sounds good so far."
     - CI renders goldens on a software GPU and compares them tightly: WARP on Windows (probed, research § 7),
       lavapipe on Linux, and SwiftShader on the web once it is verified in the pinned browsers.
     - On the reference machines the same scenes are compared with a perceptual metric (NVIDIA's FLIP), at a tolerance
       set by measurement.
     - A method a software GPU cannot run, such as hardware ray tracing, has goldens per GPU vendor.
     - A golden changes only through an explicit update command, with its diff reviewed.
  5. **The library's scope.** "5.5 yes"
     - **In `@kama/graphics`:** every rendering technique, sky, water, terrain and vegetation rendering among them; the
       scene graph; loaders for render formats (glTF, KTX2, HDR, EXR); clip playback with skinning and morph targets;
       text; and helpers and controls, as three.js offers them.
     - **Elsewhere:** animation state machines and blend graphs (kyoten's animation module); UI (`@kama/ui`); physics
       and audio; and build-time baking (texture compression, LODs, meshlets, lightmaps), which is the content
       pipeline's (KYR-29). The library reads what is baked, and offers runtime versions where three.js does, such as
       mipmaps and tangents. Other model formats become glTF in the content pipeline.
  - **What the pass wrote** (kama-graphics, the same day), each document to one purpose as decided on 2026-11-10
    ([architecture.md](architecture.md) § Decided, the eighth session, item 2):
    - `ROADMAP.md` and `ROADMAP_DETAIL.md`, GFX-1 to GFX-18, held by `tools/check-roadmap.sh`, ported from `@kama/gpu`'s;
    - `FEATURES.md`, 162 features, all `planned`, 20 of them `asked` (no planned example needs them yet), held by
      `tools/check-features.sh`;
    - `SPEC.md`, which says only that nothing is built: a spec is what a package is, never what it will be, so it grows
      from GFX-1. Until then the decided design is `AGENTS.graphics.md`'s brief and this § Decided.
- **2026-11-14, the owner: GFX-1's four questions** (`@kama/graphics`' first slice, a lit cube; its `ROADMAP_DETAIL.md`
  § cube). Each was measured first ([../research/graphics.md](../research/graphics.md) § 9, `.scratch/gfx1-probe/` and
  `.scratch/gfx1-nodes/`), asked in full in the chat on 2026-11-13, and answered the next morning:
  1. **Reversed depth, always, on a 32-bit float depth buffer** ("I will take your recommendation").
     - The measurement: two surfaces a fraction apart, near 0.1 m and far 10 km. The standard convention got 87% of
       pixels wrong or tied at 1 km with 10 cm between them, and every pixel at 5 km with 50 cm; reversed depth got none
       wrong at any distance or gap tried, down to 5 cm at 5 km, and so did reversed depth with an infinite far plane.
       Near the camera the frame is the same bytes either way.
     - There is no option for the standard convention, one way to do a thing: three.js keeps it by default only for its
       existing code (`reverseDepthBuffer`), and this library has none.
     - A camera keeps three.js's finite `far` by default, and takes an infinite one.
     - A pass that needs stencil uses depth32float-stencil8 where the device has it (an optional WebGPU feature), and
       depth24plus-stencil8 otherwise.
     - WGSL of a program's own that reads depth (fog, soft particles) gets a helper in the library's shader modules
       that turns a depth into a distance, so nobody writes the convention by hand.
  2. **Typed nodes** ("It sounds like typed is the production answer. We lean that way typically."). One node type per
     WGSL type (`FloatNode`, `Vec3Node`, …), operators by operand type, functions with named arguments, and a slot typed
     by what it holds, so a float in a colour slot or a vec4 used as a colour does not compile. A node is a reference,
     as TSL's are: handing one on shares it (`Copyable<This>(bare: copy)` over a shared expression).
     - Until kama fixes KY-55, a number goes on the left (`0.5 * x`), since a type cannot overload one operator for both
       itself and a number on the right. **Fixed in kama 0.9.947** (2026-11-14, kyoten's pin since that day's bump): a
       number goes on either side, as in WGSL (`.scratch/gfx1-nodes-947/`: `sin(x: time()) * 0.5 + 0.5`).
     - **The owner asked whether the node types are a bound list, and whether custom node types are possible.** The
       answer, measured in the sketch the same morning: the *value* types follow WGSL's own, which are few and fixed
       (scalars, vectors, matrices, structs), and what a node *computes* is open. Custom nodes are part of the API, in
       three ways, all checked by kama like the library's own:
       - a kama function from typed nodes to a typed node, as TSL's `Fn()` is (`fn FloatNode rim(...)`);
       - a WGSL function wrapped as a typed node, as TSL's `wgslFn()` is: its kama signature types it, and the WGSL is
         checked when the material's shader compiles;
       - a node type of a program's own, such as a WGSL struct with typed parts (a `Ray` with `origin()` and
         `direction()`), implementing the library's node contract (`Node<T is This>`), so it goes wherever the library
         takes any node: the library's generic `select` took it, and refused a vec3 on one side and a float on the other.

       Proposed with the answer, for the owner to object to: the contract is public from GFX-1, and the three ways
       arrive as the examples need them, with the full-WGSL escape (§ Decided, 2026-11-07) beside them.
  3. **Software goldens, one per software GPU, compared byte for byte** ("I will take your recommendation").
     SwiftShader runs WebGPU in Edge 157 with no extra flag and in the pinned Chrome for Testing with
     `--enable-unsafe-swiftshader`, the same bytes in both and on every run; WARP natively and as Firefox 160's fallback
     adapter, the same bytes. So the web's software golden is SwiftShader's, Windows' and Firefox's is WARP's, and
     Linux's will be lavapipe's once measured. The browsers and drivers are pinned, so a bump that changes bytes shows
     as a golden update to review. `@kama/gpu` gains WebGPU's `forceFallbackAdapter` (its GPU-15), which natively finds
     WARP with every backend enabled (measured).
  4. **On the reference machines, FLIP against the leg's software golden, and goldens kept as PNGs in the library's
     repository** ("I will take your recommendations as well").
     - Measured: the GPU and WARP differ at 0.29% of pixels by 1 step of 255; the GPU and SwiftShader at 0.42%, up to 72
       steps, almost all on the silhouette, where the rasterizers cover an edge's MSAA samples differently.
     - The harness ports FLIP into kama from NVIDIA's BSD-licensed reference, keeping its notice, since kyoten's tools
       are kama and the web leg compares too. A frame passes on two numbers: the mean FLIP error, and the share of pixels
       above an error threshold, so one missing highlight is not averaged away. Both limits are set while GFX-1 is
       built, from the cube on the reference machines present, plus a margin, recorded with their numbers; raising
       one later takes a written reason, as every budget does.
     - Goldens live in the library's repository, `tests/goldens/<example>/<software GPU>.png`, left out of the published
       package. A pull request shows their image diff; the flat cube's is 2.3 KB. Git LFS is out, since `kama publish`
       refuses a file stored through a git filter; if goldens ever grow large, a repository of their own takes them.

- **2026-11-14, the owner: GFX-1's part 1, questions 1 to 3** (`@kama/graphics`' first part: the gate, the golden
  harness and a `Renderer` that clears and reads back with no window). Asked in full in the chat once `@kama/gpu`'s
  GPU-15 was built. The owner asked of question 3 what a golden is, and whether the answers are the production ones; it
  was asked again in plainer words (a saved picture of what an example should look like, compared on a software GPU
  because real GPUs cover an edge's samples a little differently), then answered.
  1. **A `Renderer` gets its GPU both ways** ("Yes both I take your recommendation"). `Renderer.make(window:, options:)`
     requests its own adapter and device, returns at once and draws nothing until the GPU has answered, so a first
     program is as short as three.js's. A second ctor, `withDevice(...)`, takes a device the program already has: an
     engine, an editor's several viewports, or a test on the fallback adapter. Read on 2026-11-14: three.js's
     `WebGPUBackend` takes `parameters.device` ("If there is an existing GPU device on app level, it can be passed to the
     renderer") or requests its own, and Bevy's `RenderCreation` is `Automatic` or `Manual`. The names follow area 2's
     rules: `make` takes what defines the object, and a second common way in is a named ctor.
  2. **Images are a package of their own, `@kama/image`** ("If it makes sense to have a separate image package I'm good
     with that. I can create the repo"), over a module of `@kama/graphics` or a request for kama's std. Image formats
     are general: a tool, a server and cosmic-forge, which reads PNG headers by hand, need them with no GPU. kama's std
     has deflate, zlib and crc32 and no image format, and kama's roadmap plans none. A decoder written in kama is
     memory-safe, which answers GFX-2's question of a native decoder for untrusted files. Seeded the same day in
     `../kama-image` (its `AGENTS.image.md` holds its short design pass), the owner adding its remote; whether it is
     first-party is kama's to rule, relayed by the owner. The goldens are its first use.
  3. **A golden is named by its leg and saved only on purpose** ("yes I take your recommendations").
     - **The leg names its software GPU** (`--golden warp` natively and in Firefox, `--golden swiftshader` in Chromium),
       as legs already name their differences (`--no-immediates`), since the adapter cannot say (measured 2026-11-14:
       natively WARP's vendor is the Windows build number, `10.0.26100.9818`, and Firefox's names nothing; only
       SwiftShader names itself). The harness holds what the adapter can say: its kind is CPU, and SwiftShader's name
       where it gives one.
     - **The tests never write a golden.** A frame that differs from its golden, or has none, is printed as one line,
       the PNG in base64, which `kama run` and the drivers carry from every leg (a 4 KB line arrived whole from Edge and
       Firefox, measured 2026-11-14). `tools/update-goldens.sh`, run on purpose, writes those PNGs into
       `tests/goldens/`, and the change is reviewed in the diff, as Playwright's `--update-snapshots` and Jest's `-u`
       update only when asked. Printing is there because a page cannot write a file; if `kama run` ever lets one, the
       script uses that, and nothing else changes. The tests read the goldens through `std::asset`, preloaded on the web.

- **2026-11-14, the owner: GFX-1's part 1, questions 4 to 6, the `Renderer`'s shape with no window** ("I will take your
  recommendation on all 3 yes"). Asked in full in the chat once the gate and the golden harness were built (kama-graphics
  `3ac9c79`), each with what a program writes, the problem and the production answer. The shapes were sketched to
  compile on 0.9.949 (`.scratch/gfx1-part1/sketch/`).
  4. **A camera names the target it draws into, and with none it draws into the renderer's window.**
     - This is Bevy's `Camera` target, Unity's `Camera.targetTexture`, Godot's viewports and Unreal's scene capture, and
       kyoten's `Camera` component already has its `target` (question 2's item 7).
     - `render(scene:, camera:)` keeps three.js's two arguments. A target is cleared and read on its own:
       `renderer.clear(target:)`, and `renderer.readRenderTargetPixels(target:)`.
     - **Considered and set aside:**
       - three.js's current render target on the renderer (`setRenderTarget`). It is state a program must remember to
         reset, every view of an editor sets it, and with no window, drawing before it is set fails only when it runs;
       - a target on every call. kama has neither default arguments nor overloads, so the window would need a second
         name.
     - Part 1 builds `clear(target:)` and the read; part 2 builds the camera's target.
  5. **A render target's format decides what it holds.**
     - **The default, 8-bit sRGB, holds what the window would show:** tone mapped and sRGB-encoded. Read back, it is a
       picture, which the cube's golden needs, and screenshots will.
     - **A 16-bit float target holds the linear HDR scene,** for a program that processes it further. This is Unreal's
       scene capture, final colour or scene colour, and Bevy, which tone maps a camera into the image it draws to.
     - three.js gives a target no tone mapping or sRGB encoding, only the canvas (its PR #28909). So a headless picture
       there is not what the window shows, and an 8-bit target stores linear colours, banding in the dark.
     - A clear colour is written in sRGB, as every colour is (area 2, item 4), and reads back as written: clearing the
       default target to `#336699` reads back `0x33 0x66 0x99`.
  6. **A read hands back an `@kama/image` `Image`,** carrying its size, pixel format, colour space and alpha, so a
     screenshot or a golden is one `encode` call.
     - kama has no promises, so a read is a request the program polls, as `@kama/gpu`'s are.
     - **Costs, accepted:**
       - `@kama/graphics` depends on `@kama/image`. A program links only what it uses, so the PNG codec comes in only
         for one that encodes;
       - it is published after `@kama/image`, as it already is after `@kama/gpu` and `@kama/window`.

       Whether `@kama/image` is first-party is still kama's to rule, relayed by the owner.
     - **Considered and set aside:** raw bytes with their size and format beside them, which say nothing of what they
       hold, so every program that saves one builds an image itself.

- **2026-11-14, the owner: the browser drivers retired, and Edge kept as players run it** ("A", as recommended, asked
  at the twenty-sixth session's start). kama 0.9.956 hands a browser the flags a run names (`--chromium-arg`, KY-57
  fixed), and the pinned Chrome for Testing, given `--enable-unsafe-webgpu`, `--enable-unsafe-swiftshader` and
  `--disable-features=NetworkServiceSandbox`, loaded `@kama/graphics`' tests under `kama run` and matched both
  SwiftShader goldens (measured the day before). What that opened was the owner's to choose:
  - **The pinned Chrome for Testing runs under `kama run`,** in `@kama/gpu` and `@kama/graphics`, with those three flags
    and `--scale 1.5` (as the driver ran it) on its own command line. It stays the web's SwiftShader leg: `@kama/gpu`'s
    fallback cases, and `@kama/graphics`' goldens. Each package's `tools/webtest.mjs`, the DevTools-protocol stopgap,
    is deleted. `@kama/window` keeps its own for trusted input (kama's KR-378, its WIN-24).
  - **Edge stays as players run it: no flags, its real GPU, no golden.**
    - It is the only Windows leg of `@kama/graphics` on a real GPU: natively and in Firefox the leg names WARP, and Chrome
      for Testing names SwiftShader. Until FLIP compares hardware frames (part 6), it is what runs the library on one.
    - `--enable-unsafe-webgpu` unlocks what Chromium holds back from pages (Dawn's unsafe APIs and its adapter
      blocklist), so `@kama/gpu`'s Edge leg would stop testing WebGPU as a player's browser gives it.
    - As a SwiftShader leg it would add nothing: Edge and Chrome for Testing drew the same SwiftShader bytes.
  - **The flags go on that browser's command line, never in the tests' `kama.json`,** whose `chromiumArgs` reach every
    Chromium browser, Edge included. Each package's `tools/browsers.mjs` says what each browser is and is started with.
  - **Considered and set aside:** Edge given the flags as well, so its legs compare SwiftShader goldens (above); and
    keeping the drivers, a stopgap whose replacement had arrived.

- **2026-11-15, the owner: GFX-1's part 2, questions 1 to 3** (the scene graph on the flat core and an unlit box). Asked
  in full in the chat once the shapes compiled and ran on kama 0.9.956 (`.scratch/gfx1-part2/sketch/`); "I take the
  recommendations", after two asked back (can Euler be made hard to get wrong; is `Shared<T>` a performance cost).
  1. **A node holds its rotation both ways, under three.js's names** ("this sounds like the production and common answer.
     Yes. We need to be able to use both quats and euler"): `rotation()`/`rotationMut()`, an `Euler` (the library's own
     type; std::math has none), and `quaternion()`/`quaternionMut()`, a std::math `Quat`. The last written wins, and the
     other is made from it when next read (measured: `rotation.y += 0.5` reads back as the quaternion (0, 0.2474, 0,
     0.9689), `rotateY(rad: 0.25)` as rotation y 0.75). three.js, Godot, Unity and Unreal all keep both.
     **Its five safeguards** (the owner: "Although euler does have limitations it is easier for people to use at times...
     it can be error prone so I'm curious if that can be mitigated"):
     1. **The order is part of what an Euler means:** `Euler.make(xRad:, yRad:, zRad:, order:)` takes it, so no Euler is
        built without it; `reordered(order:)` keeps the turn (three.js's `reorder`), and there is no `orderMut()`, which
        would reinterpret the numbers. A node's own starts at XYZ, three.js's default.
     2. **Turns go through the quaternion,** so no turn meets gimbal lock: `rotateX/Y/Z(rad:)` about the object's own
        axes, `rotateOnAxis`, `rotateOnWorldAxis` and `lookAt`. The Euler is for setting and reading absolute angles.
     3. **No Euler is blended:** the library interpolates quaternions only.
     4. **The Euler made from a quaternion is the one nearest the angles the node last held,** so a read after a
        quaternion write never jumps by 2π or to the other equivalent triple (Blender's `to_euler` takes such a
        compatible Euler for the same reason).
     5. **Degrees enter only through `Euler.fromDegrees(x:, y:, z:, order:)`,** and every labelled call says radians. A
        bare `rotationMut().y += 45.0` cannot be caught, since kama cannot tell a number's unit; an angle type for the
        fields was set aside, as it would refuse three.js's `rotation.y += 0.01` and no engine uses one.
  2. **`MeshBasicMaterial` arrives in part 2** ("This sounds good"), unlit, white by default, `color()`/`colorMut()`, with
     its WGSL written by hand as a stopgap inside the library. Part 3 rebuilds it from typed nodes behind the same API, and
     part 2's golden must still match byte for byte, so it holds part 3's compiler. Set aside: no material type until
     part 3, which would change the API between parts and redraw the goldens; and the typed nodes first, which reorders
     the decided parts.
  3. **Every object the library shares is a `Shared<T>` made with `new`:** nodes, geometries, materials, textures and
     render targets, `RenderTarget` included, which changes from part 1's handle type. Colours, vectors, `Euler` and
     options are plain values, and a `Renderer` is a resource the program owns. Measured first: kama refuses a contract
     stored in a field (*"a contract (`Geometry`) borrows its object, so it can't be stored in a field — it would
     dangle; own the object instead (e.g. `Shared<Geometry>`)"*), so a mesh holds `Shared<Geometry>` and
     `Shared<Material>` either way. **Not a performance cost** (the owner asked): a handle type holding one `Shared` is
     the same pointer, count and checks, and a `Shared`'s costs are a non-atomic count when handed on (at setup), kama's
     check on a write through it, and an indirect call per node in the walk. Measured on 0.9.956 natively at release,
     10,100 meshes in 100 groups (`.scratch/gfx1-part2/bench/`, three runs each): with change marks, nothing changed
     costs 0 µs a frame, one mesh moved about 2 µs, every mesh moved 39 ns a node (0.4 ms), against 3.7 ns a node
     (37 µs) for the same transforms in flat arrays; a walk without the marks costs 15 ns a node when nothing changed.
     The scene graph is the easy layer, and an engine drives the flat core.
  - **Settled under the decided rules, reported with the questions and not objected to:**
    - the node contract is `Object3D`, three.js's base class, since `Node<T>` is the shader nodes' contract;
    - positions and scales are std::math's `Vec3`, as kyoten's `Transform` holds them;
    - `scene.add(object: cube)` is a method: each node owns a small shared part with its children, and a child's parent
      link is a `Weak` to its parent's part, since nothing reaches the `Shared` holding `this` (KY-58, filed); `parent()`
      waits on KY-58;
    - **change marks:** a write marks the node and each ancestor up to the first already marked, and the render walk
      enters only a subtree that moved or holds a mark, so an unchanged scene costs nothing to walk; three.js remakes
      every node's world matrix every frame;
    - `PerspectiveCamera.make(fovRad:, aspect:, near:, far:)`, three.js's four with radians; the renderer remakes the
      projection when the camera changed, so there is no `updateProjectionMatrix()`; reversed depth as three.js r187's
      `makePerspective` (near to 1, far to 0), an infinite far as its limit;
    - `BoxGeometry` as three.js's: faces +X, −X, +Y, −Y, +Z, −Z, counter-clockwise, a UV and a group per face,
      `withSegments`;
    - the flat core is built under the graph and stays internal; its public surface for an engine is asked when
      kyoten's render module first drives it, at the join;
    - the box's golden is two boxes in two colours crossing in depth, so it holds reversed depth, not only a silhouette.
  - **Built the same day** (kama-graphics `bc845db`, its SPEC): the scene graph on the flat core, `Euler` with its
    safeguards, `BoxGeometry`, `MeshBasicMaterial`, reversed depth with an infinite far, `render(scene:, camera:)` and
    `info()`. Its golden is `boxes/warp.png` and `boxes/swiftshader.png`, 9 of 3,072 texels apart where the boxes' top
    faces cross. 82 cases on each golden leg, 77 in Edge on its GPU, where every texel reads back exactly a colour
    written and either draw order gives the same bytes. 49 of 51 mutations caught; the other two only make it slower.
  4. **A misuse the types cannot refuse is refused and reported, and never ends the program** ("I will take your
     recommendation A", 2026-11-15; asked while building part 2). The two so far:
     - **a camera naming no target, rendered by a renderer with no window:** `render` draws nothing and records the
       error on the renderer, read by `renderer.takeErrors()` and printed by default, as `@kama/gpu`'s device prints its
       own (its decision 3, item 2);
     - **a node added under itself or one of its children:** `add` refuses, changes nothing, prints the error and returns
       `false`, which a program may ignore.

     This is `@kama/gpu`'s decision 9 ("nothing a program passes ends it") for the library above it, and what three.js
     (a console error), Godot (`add_child` prints and refuses) and Unity (an error logged) do. Set aside: ending the
     program, as kama does for a bug, which kills a page or a shipped game over a mistake that could be reported. How a
     program turns the printing off is settled when it is built.
     - **Built at the twenty-seventh session's start** (kama-graphics `faafb92`, its SPEC § Misuse), with how the
       printing is turned off settled under the owner's word and reported for the owner to object to:
       - **the renderer's switch is a property pair,** `printErrors()`/`printErrorsMut()`, true by default, as
         `clearColor()` is: three.js keeps its `renderer.debug.checkShaderErrors` on the renderer, and a renderer's own
         misuses never arise while it is made, so it is no option at its making, where `@kama/gpu`'s `DeviceOptions`
         holds its device's switch because a device's errors start at creation;
       - **`add`'s refusal always prints,** as three.js's and Godot's do, and `isAncestorOf(object:)` (Godot's
         `is_ancestor_of`) lets a program that must not print, an editor refusing a drag, ask first. A switch for the
         whole library would be global mutable state.
     - **The record:** `renderer.takeErrors()` hands back a `RendererErrors`, shaped as `@kama/gpu`'s `DeviceErrors`: the
       oldest 64 kept and the rest counted in `dropped()`, each a `GraphicsErrorReport` of a `@nonExhaustive`
       `GraphicsErrorKind` (`NoTarget` so far). A printed line begins `@kama/graphics:`, and the gate counts each leg's,
       browsers included, from outside the program. 95 cases on each golden leg, 90 in Edge, the goldens unchanged.
       Red first against a stub, 5 of the first 11 new cases; planning the mutations added two more (`printErrors`
       read back, the count drained) and sharpened a third (a refused node with a parent of its own). 20 of 21 mutations caught (`.scratch/gfx1-q4/`), five by the gate's printed-line count alone and one, `add` refusing only a node under itself, as a hang, the loop's walk never ending; the 21st, `isEmpty` ignoring the count, is equivalent, since a count above 0 exists only with 64 reports kept and `takeErrors` drains both.

- **2026-11-15, the owner: GFX-1's part 3, its question: how the library's own shader functions reach a material
  compiled at run time** ("Yes I take your recommendation", asked in full in the chat after the probe). WGSL has no
  imports, so each material's shader carries its own copy of exactly the functions it reaches, once each, in an order
  WGSL takes, and a material is a typed node graph compiled at run time (a record, the kama builder, a hot reload), so
  that gathering happens at run time too. Measured first ([../research/graphics.md](../research/graphics.md) § 10,
  `.scratch/gfx1-part3/`): the same lit material, Lambert plus three.js's GGX, its five library functions held as (A)
  typed-node functions and as (B) WGSL text with includes, compiled with no message in Dawn and naga, the two giving the
  same values exactly; (A) adds 3,949 B of web code (brotli) and links in about 42 µs a material, (B) 1,962 B and about
  6.4 µs; (C), a WESL linker at run time as Bevy 0.20 runs one, is a WGSL parser and linker (wesl-js is 39 KB gzip).
  1. **The library's shader functions are typed-node functions in kama** (A), as three.js's TSL holds its BSDFs
     (`Fn(..., layout)`): a function is a value whose body is a node expression over its parameters, and the material
     compiler emits each function a material reaches once, its callees first, so a shader carries only what it uses. One
     source, checked by kama's compiler, so a wrong type in the lighting is a build error rather than a shader error on a
     player's machine, and the library's functions are held to the public node contract a program's nodes are (GFX-1's
     question 2). The compiler writes a `let` for a node used more than once, as TSL does, so the WGSL reads as written by
     hand.
  2. **A WGSL function as text is the escape** (B's form, TSL's `wgslFn(code, includes)`): code nodes say badly, a
     program's or the library's, its signature typed in kama and its includes naming the typed or WGSL functions it
     calls, each compiled on every leg by the library's tests. It is also how a program's own WGSL calls the library's
     functions.
  3. **No WESL linker at run time** (C set aside): ten times (A)'s code on the web for what the node compiler and the
     build-time tools already do. WESL stays a format a program's files are written in, linked at build by kyoten's
     tools, as decided on 2026-11-07, reaching a material through 2.
  - **This revises one line of 2026-11-07's item 1:** the library's shared shader functions are typed nodes, not WESL
    modules a game imports. Passes the library owns whole, such as tone mapping, may stay plain WGSL; the question was
    about functions a run-time material reaches.
  - **Found on the way: KY-59** ([../KAMA_GAPS.md](../KAMA_GAPS.md)): an overloaded operator releases a node passed to it
    by value twice, so typed nodes free what a function still holds. kama fixed it the same day (`f2c8b31b`, 0.9.960),
    and kyoten's pin moved to 0.9.960 at the owner's word, so part 3's operators take named nodes as they are.
  - **Its first part is built** (kama-graphics, the twenty-eighth session, 2026-11-15; its SPEC § Typed nodes and § The
    compiler):
    - typed nodes and typed functions, each parameter declared with the argument it takes;
    - the material compiler, each function written once with its callees first, a `let` for a node used twice;
    - the varyings, and its refusals: a refused material draws nothing and is reported once;
    - `MeshBasicMaterial` rebuilt on them, part 2's golden matched byte for byte on WARP and SwiftShader.

    Settled under the owner's word and reported:
    - a material's settings are declared apart from its nodes, so a setting changed each frame builds no node;
    - programs write nodes in safe kama;
    - a float literal is written so that a WGSL compiler reading it through a float64 gets it back. Over every float32,
      one positive value, `7.038531e-26`, needs its float64 digits for that, and its negative does too.

    142 cases on each golden leg, 137 in Edge; red first against a stubbed compiler; 65 of 65 mutations caught
    (`.scratch/gfx1-part3/tools/`).

    Found on the way:
    - KY-60 and KY-61 ([../KAMA_GAPS.md](../KAMA_GAPS.md)): a chained operator's left operand is never freed, and across
      packages an operator's result is untyped unless its type is imported;
    - a material's settings were visible to the fragment stage alone, fixed test-first in this part;
    - part 2's renderer drew a mirrored mesh inside out, where three.js r187 flips its winding (`WebGPUPipelineUtils.js`:
      `matrixWorld.determinantAffine() < 0`). Fixed test-first the same session, with a pipeline per material and
      winding; 3 of 3 mutations caught.

- **2026-11-15, the owner: GFX-1's part 3, its second part's question 1: how normals reach world space under a
  non-uniform scale** ("Sounds like A is the best solution", asked in full in the chat). Multiplying a normal by the
  world matrix tilts it wrong under a non-uniform scale; the inverse transpose of the world matrix's 3x3 is right under
  any scale, shear or mirror. **(A): each mesh's record carries its normal matrix**, the inverse transpose, computed on
  the CPU when its world matrix changes, so only what moved pays, and the vertex stage multiplies by it.
  - **Prior art, read in its source on 2026-11-15** (`.scratch/gfx1-part3/prior-art/`):
    - three.js r187's `modelNormalMatrix` is a per-object `Matrix3`, `getNormalMatrix(object.matrixWorld)`, which is
      `invert().transpose()` (`ModelNode.js`, `Matrix3.js`);
    - Bevy 0.16's mesh record carries `local_from_world_transpose_a` and `_b`, a 3x3 in 36 bytes (`mesh_types.wgsl`);
    - Godot 4.4 computes `transpose(inverse(mat3(model_matrix)))` per vertex when an instance's
      `INSTANCE_FLAGS_NON_UNIFORM_SCALE` is set (`scene_forward_clustered.glsl`).
  - **Its cost:** the record grows from 64 to 112 bytes, a `mat3x3f` in a storage buffer taking 48. Bevy's packing into 36
    saves nothing here, since the record's stride is a multiple of 16. So 10,000 meshes take 1.12 MB, not 0.64 MB, and a
    mesh that moved uploads 112 bytes.
  - **Set aside:**
    - (B), the inverse in the vertex stage on every vertex every frame (about 40 operations, WGSL having no `inverse`);
    - (C), Godot's flag with (B) behind it, a branch per vertex and a flag word in the record.
  - **Built the same session** (kama-graphics, step 1 of the second part):
    - the record carries the normal matrix;
    - the normals reach the vertex stage;
    - `normalWorld()` and `positionWorld()` exist.

    The test is a box under a shear and under a mirrored shear, every texel held to S⁻¹ R n worked in float64. It was red
    against the plain 3x3, with 279 texels wrong. 18 of 18 mutations caught. A test that turns the box alone would not
    tell the plain matrix from the inverse transpose: a box's normals lie along its own axes, so only a shear, a
    non-uniform scale above a turn, separates them.

- **2026-11-15, the owner: GFX-1's part 3, its second part's question 2: how a renderer learns that a material's node
  graph changed** ("A: graphVersion() (Recommended)", asked in full in the chat at the twenty-ninth session's start).
  - **Until now** a renderer compiles a material the first time it draws it, and never again. A setting's write moves
    the material's `version()`, and the renderer writes only its bytes again.
  - **The problem:** step 2 adds the first slot whose change needs a new shader, `MeshStandardMaterial`'s
    `emissiveNode`. A program's own `Material` may change its graph too, since the contract is public. With no signal,
    a mesh keeps its old shader and nothing says so. That is three.js's `needsUpdate` trap, which area 2's item 3 says a
    program never meets.
  - **(A): the `Material` contract gains `graphVersion()` beside `version()`.**
    - `version()` moves when a value changes, and the renderer writes the bytes again.
    - `graphVersion()` moves when a node changes, and the renderer compiles again. A slot's `Mut` moves it, as
      `colorMut()` moves `version()`.
    - The renderer keeps the number it compiled at. A material whose graph never changes answers 0.
  - **Why:** it is one rule, the one the settings already follow, and the renderer's cache stays the renderer's own.
    Its cost is one more method on every implementor.
  - **Set aside:** (B), `MaterialGpu.forget()` made public, so a material drops the renderer's compiled WGSL itself
    (the twenty-eighth session's sketch). It needs no contract change. But the renderer's cache would become API that
    every program touches, and nothing would remind a program's own material that it must call it.
  - **Settled with it, and reported, step 2's scope:** with no light, a standard material's colour, roughness and
    metalness change neither a pixel nor its WGSL. So step 2 builds:
    - the five values;
    - the first slot, `emissiveNode`.

    `colorNode`, `roughnessNode` and `metalnessNode` arrive with the lights that read them (part 3's third part), where
    a test can hold them.
  - **Built the same session** (kama-graphics, step 2 of the second part; its SPEC § Materials):
    - `MeshStandardMaterial` with three.js r187's five defaults, each value a property pair, its settings 48 bytes;
    - with no light it draws its emissive alone, as three.js r187's `NodeMaterial.setupLighting` does;
    - `emissiveNode`, a program's own node in place of emissive × emissiveIntensity;
    - `graphVersion()` on the contract, so a renderer compiles a material once for each graph.

    Red first against a stub, 12 of the 15 new cases failing; the other three held what was already so. A program's own
    material that counts its compiles holds the renderer to one compile a graph and none for a setting. 166 cases on each
    golden leg, 161 in Edge. 26 of 26 mutations caught (`.scratch/gfx1-part3/step2/`), after the drawn cases were
    sharpened to hold the texel's alpha.
  - **Found for part 4:** three.js r187's `NodeMaterial.setup` clamps every material's output with `max(0)` ("force
    unsigned floats"). An 8-bit target clamps anyway, so it is built, and held, with the 16-bit float target.

- **2026-11-16, the owner: GFX-1's part 3, its third part's three questions, the lights** ("I assume your
  recommendations are the best production answer for kyoten and I will take them", asked in full in the chat at the
  twenty-ninth session's end). The prior art was read in its source (`.scratch/gfx1-part3/prior-art/` and
  `three-r187/`).
  1. **The scene's lights reach a material's shader as data, never as code (A).**
     - **The problem:** three.js r187 builds each light into every lit material's shader. `LightsNode.customCacheKey()`
       puts each light's id in the material's cache key, so adding or removing a light compiles every lit material
       again, about 24 ms a lit pipeline (measured 2026-11-11). That is a hitch, or, once part 5 compiles off the frame,
       frames drawn with the old lights.
     - **(A):** each frame the renderer writes the scene's lights into the frame's group:
       - the directional lights as a storage buffer of any length, each its direction and its colour × intensity, which
         a lit shader loops over;
       - the ambient lights summed into one colour.

       Adding, removing, moving or dimming a light compiles nothing, and there is no cap. Point and spot lights will
       reach the clusters' storage buffers the same way (area 3, item 1).
     - **Its cost:** a loop whose length is known only at run time, and one storage read a light a fragment. The
       objects' records are a storage buffer already.
     - **Set aside:**
       - (B), three.js's: a compile for each change of the light set;
       - (C), Bevy 0.16's and Godot 4.4's: a fixed number in one uniform with a count (10 and 8, Bevy's 1 on WebGL2).
         It compiles nothing, but it is a cap, which the bar refuses.
  2. **The direct light reads three.js r187's DFG table (A).**
     - **The problem:** r187's direct light compensates for multiple scattering with `1 + F0 (1/Ess - 1)`, reading Ess
       from a 16 × 16 RG16F table sampled at (roughness, dotNV) (`DFGLUT.js`, 4,096 samples a texel). r170's analytic
       fit misses the table by up to 0.41 in its scale term and by up to 4.4% in the dielectric's compensation
       (`.scratch/gfx1-part3/lights/dfg_compare.py`, in float64).
     - **(A):** the renderer makes the table once a device and binds it in the frame's group with a linear, clamped
       sampler, and a texture-sample node reads it. It is the first texture the compiler reads, and material maps need
       that node next. The tests' wants stay three.js's own numbers.
     - **Its cost:** 1 KB, one sample a fragment, and the texture node built now.
     - **Set aside:** (B), r170's fit: no texture, but not three.js's numbers.
     - **Settled with it, by the library's rule** (kama-graphics' AGENTS.graphics.md § Rules: code adapted from an MIT
       or Apache project keeps its notice): the table is three.js's data, its 512 half floats copied as they are, so
       kama-graphics carries three.js's MIT notice ("Copyright © 2010-2026 three.js authors") in a notices file, as
       kyoten's `engine/THIRD-PARTY-NOTICES.md` carries musl's.
  3. **A directional light points from its world position to `target()`, a point in world space (A).**
     - **The problem:** in three.js, `sun.target.position.set(3, 0, 0)` does nothing unless the program also calls
       `scene.add(sun.target)`. r187's own docs say so: "For the target's position to be changed to anything other than
       the default, it must be added to the scene."
     - **(A):** three.js's idea with the trap gone. `target()` and `targetMut()` are a `Vec3` in world space, the origin
       by default, a property pair whose write marks the light changed, and there is no object to add. Its default
       position is (0, 1, 0), so it shines straight down, as three.js's does (`Object3D.DEFAULT_UP`). Its colour is
       white and its intensity 1, as three.js's, and so are an `AmbientLight`'s.
     - **Given up with it:** in three.js the target may be another object in the scene, which the light then tracks.
       Under (A) a program that tracks one writes that object's world position to `targetMut()` each frame. kyoten's
       render module, whose `Light` component is aimed by its entity's rotation, writes position + forward the same way.
     - **Set aside:**
       - (B), three.js's exactly: a target object that must be in the scene before moving it does anything;
       - (C), Unity's, Godot's, Bevy's and kyoten's `Light` component's: the light's own rotation, shining along -Z and
         aimed with `lookAt`. It departs from three.js's default, which shines down, and from its examples.

- **2026-11-16, the owner: `@kama/gpu`'s `writeTexture` comes forward from GPU-8, for the DFG table (A)** ("A:
  writeTexture now", at the thirtieth session's start, after asking whether it was a stopgap).
  - **The problem:** question 2's table must reach a texture, and `@kama/gpu` could not fill one from the CPU. Its item 12,
    decision 4, had left `writeTexture` in GPU-8, after compute, queries and indirect draws.
  - **(A):** `queue.writeTexture(destination:, data:, layout:, size:)` by WebGPU's full description, probed on both legs
    first and test-first on every leg (kama-gpu's AGENTS.gpu.md item 14). It is not a stopgap: kama lacked nothing, the
    package had not wrapped WebGPU's call, and it is how three.js's WebGPU backend fills a `DataTexture`. Every texture
    `@kama/graphics` fills from the CPU later, a material's maps among them, takes it. The copies, `mappedAtCreation`
    and staging buffers stay in GPU-8.
  - **Set aside:** (B), all of GPU-8's uploads and copies now, more than this part needs; a narrow call with no origin, mip
    level or layout, which decision 5 of item 12 had replaced elsewhere; and (C), the table in a storage buffer filtered
    by hand, which would set aside question 2's texture-sample node.

- **2026-11-16, the owner: how a material's shader reads the scene's lights (A), a `LightingModel` contract** ("(A)
  LightingModel (Recommended)", asked in full in the chat at the thirty-first session's start). The prior art was read
  in its source: three.js r187's `LightsNode` and `PhysicalLightingModel`, Godot 4.4's `light()`, Bevy 0.16's PBR loop.
  - **The problem:** the lights' question 1 put them in a storage buffer whose length the shader learns only at run
    time, so a lit shader must loop over them. The compiler wrote only expressions and lets, so nothing could read the
    lights: neither `MeshStandardMaterial` nor a program's own material, nor a test holding the buffer's bytes.
  - **(A):** a public `LightingModel` contract, as three.js's `LightingModel` and Godot's `light()`.
    - A model says how ONE light lights the surface: `direct`, given that light's direction and colour as nodes, and
      `indirect`, given the ambient light's sum. Each gives a diffuse and a specular part.
    - The compiler writes `direct` once, inside a loop over the scene's directional lights. What depends on no light,
      such as the surface's normal, is computed once, before the loop.
    - A model cannot get the count, the buffer or its bounds wrong, and a program's own model, a toon look for example,
      is checked exactly as the library's, under GFX-1's question 2 (a public node contract).
    - The physical model of `MeshStandardMaterial` is the first built on it, and point and spot lights later reach the
      same `direct` from the clusters' lists.
    - It is not a stopgap: it is the shape three.js and Godot ship. Its cost is the compiler's loop and the pass that
      moves what depends on no light out of it, which step 2 builds, and step 3 builds the physical model on it.
  - **Set aside:**
    - (B), a general `Loop` node with mutable variables, as TSL's `Loop`. It is the most general, but it brings
      statements, mutable variables and their order into a compiler of pure expressions. Every model would also write
      the loop over the lights itself, which is easy to get wrong.
    - (C), nodes that read the raw data (the count, a light by index), with the loop written as WGSL text through the
      escape. Nothing inside the loop would be type-checked.
    - Lights read by `MeshStandardMaterial` alone, so a program's own material could never be lit: a stopgap, since
      three.js, Godot and Unity all let a program write its own lighting.
  - **Built the same session** (kama-graphics `dfcdc71`, the third part's step 2, its SPEC § The scene graph, § Typed
    nodes and § The compiler), with the lights as scene nodes and their buffer. A program's own toon model, a
    vertex-lit one, and models showing each light's colour and direction were held to their WGSL and their pixels across
    eight frames of lights changing. 240 cases on each golden leg, 235 in Edge; 67 of 67 mutations caught.
  - **Step 3 built the physical model on it** (2026-11-17, the thirty-second session, kama-graphics `c3ff5ed`; its SPEC §
    The renderer, § Materials, § Typed nodes and § The compiler):
    - the frame block carries the camera's position in world space (`cameraPosition()`), 96 bytes;
    - r187's BSDFs and `getRoughness` as typed functions under r187's names;
    - `PhysicalLightingModel`, r187's direct light and ambient indirect diffuse, with the DFG compensation;
    - `MeshStandardMaterial` lit by it, with `colorNode`, `roughnessNode` and `metalnessNode`.

    A lit box's centre texel is held within a step to r187's formulas worked in float64 from the exact ray through it,
    in five lightings, on WARP, SwiftShader and Edge's GPU alike. Its ambient term, amplified 128 times against the
    float64 value, matches it too. 259 cases natively and on each golden leg, 254 in Edge, each debug and release.
    35 of 35 mutations caught; five were caught only after the tests were sharpened, as kama-graphics' ROADMAP_DETAIL
    records.

    **Settled under the decisions above, and reported for the owner to object to:**
    - the node is TSL's `cameraPosition`, and the model lights in world space, where the lights' buffer is; r187 lights
      in view space, and the two agree but for rounding;
    - `PhysicalLightingModel` is public, made from nodes, so a program's own material lights physically;
    - the BSDFs are public under kama's names for r187's (`brdfGgx` for `BRDF_GGX`), each written into WGSL under
      r187's;
    - r187's geometry roughness, the change of the normal in view space across a pixel, waits for the first geometry
      whose normals vary (kama-graphics' GFX-2). It is 0 on a flat face, and every geometry the library has is
      flat-faced, so no test could hold it now. With it comes the view matrix in the frame block, which it reads.
  - **Step 4 built the lit goldens, and so part 3** (2026-11-17, the thirty-third session, kama-graphics `126ac07`; its
    SPEC § Tests): `light-directional`, two coloured suns on the default box, one aimed off the origin; `light-ambient`,
    two ambient lights; `material-standard`, a rough dielectric with an emissive, a smooth dielectric and a metal, under a
    sun and an ambient light. Each is held byte for byte on WARP and SwiftShader. On every leg, hardware included, each
    face the camera sees well is held within a step of r187's formulas in float64. WARP draws the same lit bytes
    natively and in Firefox, so no golden is kept per leg. 266 cases on each golden leg, 258 in Edge, each debug and
    release; 7 of 7 mutations caught, each by the golden of the feature it breaks alone.

    **Settled under GFX-1's decisions, and reported for the owner to object to:** "the lit box's golden" became one
    golden for each feature the part built, named as kama-graphics' FEATURES.md names each feature's test, since that map
    has a golden test per feature. Their rows hold tests that exist once a measured budget makes them `built` (part 6).

    **Found on the way and fixed first** (kama-graphics `ef418f2`): step 3 left the tests' no-device path pointing at
    its new stage, so a leg whose device never opened panicked rather than failing with its reasons. The gate now holds
    that path, asking Edge, which offers no fallback adapter, for WARP.

- **2026-11-17, the owner: every wasm leg runs debug and release, as every native leg does (A)** ("(A) Debug + release
  (Recommended)", asked in full in the chat at the thirty-second session's start, before the pin's bump to kama 0.9.966).
  - **The problem:**
    - kama 0.9.966 (KR-289, kyoten's KY-6) runs Closure over every wasm `--release` build. Closure renames each
      property name it cannot prove belongs to something outside the program.
    - No gate built a wasm release: every native leg ran debug and release, and every web and node leg debug only. So the
      bump would have passed every suite without Closure ever reading the packages' JS glue. The first place it would run
      is a game's shipped web build.
  - **The probe found two breakages before the bump,** each absent on 0.9.965 at release (`.scratch/s32/closure/`):
    - **`@kama/gpu`'s `js/gpuseam.js` does not build under Closure.** `GPUTextureUsage` is undeclared to it, because
      emscripten hands Closure no WebGPU declarations; emdawnwebgpu's own glue quotes every WebGPU name instead. So every
      release web build of a program using `@kama/gpu` failed to link.
    - **`@kama/window`'s `js/winseam.js` lost 119 of its DOM-code-to-HID table's keys** (`KeyA: 4` and the rest). The
      table is read by the browser's `e.code` string, and Closure renamed the keys it did not know. So on a release web
      build 119 keys never reached a game. Its node leg at release failed 119 cases on 0.9.966 and none on 0.9.965.

    The browser's own option keys the glue hands over kept their names under Closure, since its browser declarations
    cover them: pointer lock's `unadjustedMovement`, the rumble's magnitudes, `preventScroll`, `passive`, `box`.
  - **(A):**
    - Every wasm leg also runs a release build: each browser leg under `kama run`, `@kama/window`'s driver leg, and each
      node leg (kyoten's engine tests and fps, `@kama/window`'s, `@kama/image`'s).
    - The gate tests what ships, and keeps debug's checks on the web: kama's overflow and bounds traps in the web seam's
      code, and emdawnwebgpu's assertions.
    - `@kama/window`'s and `@kama/gpu`'s gates also check that the release JS still holds every key the glue hands the
      browser. This holds the keys that no headless case can observe, such as the rumble and pointer lock.
    - Glue that Closure breaks is fixed as kama's `docs/targets.md` § jsLibraries says: a name the browser or the page
      reads is quoted on both sides.
    - The cost is the browser time, about doubled. It is measured as each gate gains its legs, and recorded as a
      measurement, never a cap.
  - **Set aside:**
    - (B), the web legs switched to release only, as kama's own browser fixtures were. It adds no time, but debug's
      traps and emdawnwebgpu's assertions would never run in a browser again.
    - (C), one release run per package in one browser. A path only another browser takes, such as Firefox's error
      reports, would go unchecked under Closure.
    - A root manifest's `"release": { "closure": false }`, which leaves every game's download larger: on kama's
      `examples/webgpu` the JS is 15,440 bytes of brotli without Closure and 8,677 with it.
  - **Built the same session, on kama 0.9.966** (kyoten `38ac701`'s pin), each package's legs red first where Closure
    broke something:
    - **How a leg proves its build:** each tests program, and `@kama/gpu`'s two examples, print `build: debug` or
      `build: release` first, from a `@compileFor` pair, and the gate fails a run whose program says another. A release
      build's JS that still names emscripten's `UTF8ToString` was not run through Closure, and fails.
    - **`tools/closure-names.mjs`** in `@kama/window` and `@kama/gpu` reads each JS file against the release build.
      Every name the file writes or reads must be in the build, and so must every name it quotes, except the file's own
      names, listed on its `// closure-own:` lines. So a name a later change adds is held by default. It reads names as
      words, so it is the second check: the release legs' cases are the first.
    - **`@kama/window`** (kama-window `b719ab2`, its AGENTS.window.md item 11):
      - the DOM-code table is made by a function with its keys quoted. Quoting alone was not enough: emscripten writes a
        library object's own literal back with its keys unquoted, and keeps only a function's body as written;
      - a pad's `effects` is read quoted;
      - in the tests' JS, the driver's acknowledgement is read quoted, and the fake pads' keys are quoted;
      - 249 natively, 163 under node, 253 in Edge and Firefox, 264 through the driver, each debug and release; 11 of 11
        mutations caught. One, `effects` unquoted in both the package and the fake, is caught by the names check
        alone: every case in every leg passed.
    - **`@kama/gpu`** (kama-gpu `5f400be`, its AGENTS.gpu.md item 15):
      - the usage is passed as its value, and the configuration's keys are quoted;
      - its gate now makes `tests/out/` and installs the root's and the examples' dependencies, which a fresh clone lacks;
      - 339 natively, 313 in Edge, 316 in Firefox and Chrome for Testing, both examples on every leg, each debug and
        release;
      - 9 of 10 mutations caught. The tenth, the keys unquoted, is equivalent: Closure's WebGPU declarations keep a
        dictionary's keys.
    - **`@kama/image`** (kama-image `a860c6b`): 1,401 on wasm in both builds, its encoded bytes agreeing on 4 legs; 2 of 2
      mutations caught.
    - **`@kama/graphics`** (kama-graphics `9bc2e64`, its AGENTS.graphics.md): 240 natively, in Firefox and in Chrome
      for Testing, 235 in Edge, each debug and release, every golden matched in both; 4 of 4 mutations caught.
    - **kyoten** (`2fdd8ff`):
      - the engine's tests and fps on wasm in both builds;
      - the tool's `spin` and `schedule` fixtures built for the web at release (211 cases, 192 before);
      - the frame guard at release, on a fixture whose 40 KB frame is in its release build alone. Its debug build must
        build, so the leg can tell its build: without that fixture, the guard's release leg built in debug went uncaught;
      - 5 of 5 mutations caught.
  - **Measured** (2026-11-17, the thirty-third session, kama 0.9.966, kama quiet and nothing else building). Each gate
    was run back to back, once on the commit before its release legs and once on the commit that added them, on the
    same pinned compiler:

    | Gate | before (commit) | with the release legs (commit) | change |
    |---|---|---|---|
    | kyoten `tools/test.sh` | 261 s (`38ac701`) | 295 s (`2fdd8ff`) | +13 % |
    | `@kama/window` | 64 s (`dfe07c4`) | 104 s (`b719ab2`) | +63 % |
    | `@kama/gpu` | 344 s (`27760aa`) | 533 s (`5f400be`) | +55 % |
    | `@kama/image` | 66 s (`2839f81`) | 81 s (`a860c6b`) | +23 % |
    | `@kama/graphics` | 295 s (`dfcdc71`) | 416 s (`9bc2e64`) | +41 % |
    | all five | 17.2 min | 23.8 min | +39 % |

    The cost is less than the doubling expected: a gate's building and its native legs are a large part of it, and
    they were already debug and release. One run each, so the noise is not measured: `@kama/graphics`' later HEAD
    (`c3ff5ed`, 19 more cases) took 392 s, 24 s less than `9bc2e64`. `.scratch/s33/measure.sh` reruns it.

- **2026-11-17, the owner: GFX-1's part 4, the frame, its three questions, each (A) as recommended** ("Your
  recommendations sounds good to me... I assume those are the production kyoten answers?", asked in full in the chat at
  the thirty-third session's end, and confirmed as production answers, none a stopgap). The frame was decided in the
  design pass's area 3: a depth prepass, 4x MSAA, linear HDR in a 16-bit float target, and AgX at output. Part 1 decided
  what a target holds: an 8-bit sRGB target what the window would show, a 16-bit float target the linear scene. The
  survey behind these is in `.scratch/s33/part4-sources/`, pinned and checked against the sources: three.js r187,
  Bevy 0.20.1, Godot 4.7.2, Filament 1.81.0, Unity's Graphics and the WebGPU spec. Its measurements are in
  `.scratch/s33/part4/`.
  1. **How 4x MSAA resolves against the HDR scene: a ladder** of a tone-mapped resolve, best, and the GPU's own resolve,
     next, each with its golden. The presets choose: desktop and the web take the tone-mapped resolve, and a tiled GPU's
     preset (Quest's) is set by measurement at GFX-5.
     - **The problem:** the GPU's resolve averages linear values. At an edge texel where 2 of 4 samples cover a
       highlight of 20 over a surface of 0.05, the average is 10, which r187's AgX shows at 250 of 255. With 1 or 3
       samples covered it shows 242 and 254, so the edge is a hard staircase where its contrast is highest.
       - The tone-mapped resolve weights each sample by 1/(1 + its brightness), averages, and undoes the weight, so the
         result stays linear for later effects. It shows 162, 202 and 231. The coverage itself is 116, 162 and 209
         (`resolve_edge.py`).
     - **Prior art:**
       - three.js r187, Bevy, Godot and Unity URP use the GPU's resolve. Unity HDRP ships a tone-mapped resolve
         (`ColorResolve.shader`, a luma weight). Filament offers one (`customResolve`, Lottes' max3 weight), but not on
         WebGPU or Vulkan.
       - Core WebGPU lets a shader read a 4x rgba16float texture (`unfilterable-float`), so it runs on both legs.
       - Its cost is a full-screen pass, and the 4x target stored rather than resolved on chip, which a tiled GPU pays
         most for.
     - **Set aside:** (B) the GPU's resolve alone, which leaves the edge; (C) the tone-mapped resolve alone, which takes
       away the cheap method a tiled GPU's preset may need.
  2. **Which AgX: both, each under its own name, the default Blender's.**
     - `AgX` is three.js r187's (from Filament), held to its formulas in float64.
     - Blender's AgX, its default view since Blender 4.0 (EaryChow's, which Godot 4.6 moved to), goes under its own
       name. It is held to the lookup table Blender ships, its formulas ported from the generator that table is made
       from, so the web downloads no table.
     - It is the default because glTF art comes from Blender, and what an artist sees there is what the program shows.
       **Amended by the owner at the thirty-fourth session's end:** Blender's AgX stays the default, but Blender is not
       the source of truth: "We have no idea what tools artists will use... and if we use ai tools it can be just
       about anything". It is the default as a good, widely used curve (Blender's and Godot's), not to match one tool.
     - **The problem:** the two differ by up to 45 steps on saturated colours and 10 at mid-grey. A linear (1, 0, 0) is
       (221, 92, 73) under r187's and (222, 64, 28) under Blender's (`agx_compare.py`, measured against Godot 4.7's
       approximation of Blender's, not Blender's table).
     - **To verify while building:** whether the ported formulas match Blender's table within a step. If they cannot,
       the table itself as a 3D texture is the fallback, and its bytes are measured and brought to the owner, not
       settled silently.
     - **Set aside:** (B) r187's alone, Blender's when a program asks; (C) Blender's alone under the name `AgX`, which
       would make the name mean something other than it does in three.js.
  3. **Exposure: on each camera, in EV100,** as Filament, Bevy, Unreal and Unity HDRP set it (exposure = 2^−EV100 /
     1.2).
     - The default is three.js's exposure of 1 (EV100 ≈ −0.26), which matches the lights' default intensity of 1, so a
       ported three.js scene looks the same.
     - There are named values: sunlight 15, overcast 12, indoor 7, and Blender 9.7, Bevy's calibration to Blender's
       implicit exposure.
     - Automatic exposure later drives the same property (FEATURES' exposure row, GFX-4).
     - **The problem:** the lights are in lux and candela, as glTF's are, and sunlight is about 100,000 lux, so a scene in
       real units needs bringing into the display's range. Where that sits decides whether two views of a scene can
       expose differently.
     - **Set aside:** (B) three.js's renderer-wide `toneMappingExposure`; (C) Blender's 9.7 as the default, which renders
       a default light of intensity 1 nearly black.

  **Settled under area 3's prepass, and reported:**
  - After the prepass, the main pass tests depth Equal with writes off, and the position is `@invariant` in both passes,
    so each texel is shaded once (Godot's Forward+; Bevy keeps GreaterEqual with writes on).
  - **To verify first:** whether naga and Tint each honour `@invariant`. A leg that does not is reported before the pass
    is built on it.

- **2026-11-17, the owner: where a program chooses its tone mapping, (A) on each camera** ("A: on each camera
  (Recommended)", asked in full in the chat at the thirty-fourth session's start, before part 4 was built). Reading the
  code for part 4 found that its decisions place the exposure but not the curve.
  - **The problem:** three.js keeps the curve on the renderer (`renderer.toneMapping`, r187's `Renderer.js`), so a
    program that draws two views differently sets it before each render and must set it back. A game's main view under
    AgX and its minimap with none, or an editor's game view beside a material preview, each need it. Part 1 set the
    render target's equivalent aside (`setRenderTarget`) for that reason.
  - **(A):** the curve is a property pair on each camera, `toneMapping()` and `toneMappingMut()`, beside its exposure in
    EV100, Blender's AgX by default. A camera drawing into a 16-bit float target ignores it, since that target holds the
    linear scene. Bevy's `Tonemapping` is a component on a camera (`bevy_render/src/view/mod.rs`, 0.20.1); Filament's
    renderer reads its colour grading from the view (`view.getColorGrading()`, 1.81.0's `Renderer.cpp`); Godot sets its
    tone map on an environment, which a camera can carry (`environment_set_tonemap`, `camera_set_environment`, 4.7.2).
    Unity HDRP and Unreal set theirs in post-process settings a camera reads, from their documentation, not checked
    against their sources.
  - **Its cost:** a ported three.js program moves one line from its renderer to its camera.
  - **Set aside:** (B) the renderer's, as three.js's.
  - **Settled beside it, and reported:** the anti-aliasing method stays on the renderer. A technique is a machine's
    quality, which a preset sets for the machine (area 4, question 1), where tone mapping and exposure are each view's
    look.

- **2026-11-17, the owner: part 4's two checks, and Blender's AgX as a table the renderer makes (A), its source credited
  and a licence asked for (A)** (asked in full in the chat at the thirty-fourth session, after the checks ran: "I find
  it hard to believe we must rely on an unlicenced repo to make this work? I am fine with your recommendations though if
  that is the best action"). The checks' evidence is in `.scratch/s34/` (machine-local): `FINDINGS.md`, the probe in
  `invariant/`, the port and its comparison in `agx/tools/`.
  - **Check 1, `@invariant`, passes on every Windows leg.** 400 overlapping triangles drawn by a depth prepass and an
    Equal main pass shade exactly the texels one pass does, at 1x and 4x: natively on D3D12, WARP and Vulkan, in Edge,
    in Firefox on its GPU and on WARP, and in Chrome for Testing on SwiftShader. A control prepass computing the position
    in another order loses 7,000 to 18,000 texels on each, so the probe sees a mismatch. Each compiler writes the marker:
    naga's `precise` (wgpu-native's log) and SPIR-V `Invariant` (its source), Tint's `precise`, which DXC keeps in DXIL
    as `!dx.precise`, and Tint's SPIR-V `Invariant` (Dawn's `dump_shaders`). Every leg also matched without the
    attribute, since both passes run the same vertex code, so `@invariant` is the guarantee and the tests hold it in the
    emitted WGSL. The Mac's Metal legs are the Mac's to run.
  - **Check 2, Blender's AgX against its table, fails as worded.**
    - Blender 5.3.0 shows AgX on an sRGB display through a 57³ table (`AgX_Base_sRGB.cube`, last changed 2023-10-06),
      interpolated tetrahedrally by OpenColorIO. EaryChow's generator (AgX_LUT_Gen) as it stood then (`ab7415e`,
      2023-09-07) was ported to float64 with the colour-science 0.4.3 functions it calls. It reproduces all 185,193
      entries to the table's own rounding (5e-8).
    - **Blender's display is the table interpolated, not the formulas.** Over every colour on a log2 grid from −12 to
      +16 stops by 0.5, 79 % land on the same byte, 17 % one step apart and 4.6 % further, up to 22 steps; on hue rings,
      up to 18. The worst are saturated colours with a channel near zero: linear (0.00025, 0.18, 0.51) shows red 8 in
      Blender and 30 by the formulas. One cell of the table spans a sharp change there.
  - **Question 1, how Blender's AgX is computed: (A) a table the renderer makes.** When a renderer starts it makes the
    57³ table from the ported formulas and samples it as OpenColorIO samples Blender's, tetrahedrally. So it shows what
    an artist sees in Blender, the reason Blender's AgX is the default, and nothing is downloaded.
    - **Costs:** 1.48 MB of GPU memory at 16-bit float, made once, and four texel reads a pixel.
    - **Held by:** the tests hold the made table to the formulas in float64 at every grid point.
    - **Set aside:** (B) the formulas per pixel, smoother on those colours than Blender but not what it shows, and a
      heavier shader; (C) Blender's own file downloaded. Blender is GPL-3.0-or-later and the table has no licence of its
      own, so the file cannot ship in an MIT or Apache library.
  - **Question 2, the generator's licence: (A) credited now, and a licence asked for.**
    - **The problem:** EaryChow/AgX_LUT_Gen, EaryChow/AgX, sobotka/AgX and sobotka/SB2383-Configuration-Generation
      declare no licence. What kama-graphics takes from them is the method: standard colour operations (matrices, a log2
      encoding, a sigmoid, HSV) and their numbers. The code is its own, written from that method. The repository is the
      only place the method is written down whole.
    - **(A):** kama-graphics credits the generator in THIRD-PARTY-NOTICES, as Godot 4.6 (MIT) credits the same script
      for its approximation. EaryChow explained the method's design for Godot (godot-proposals#12317, 2025-04-28). The
      owner posts a request, which kyoten drafts, that EaryChow put a permissive licence on the generator, and
      kama-graphics' first publish waits on the answer. It already waits on kama's floor.
    - **Set aside:** (B) credited without asking; (C) r187's AgX alone, the default until a licence is in hand. r187's
      AgX (three.js, MIT, from Filament, Apache-2.0) is fully licensed, but it is not what Blender shows.
    - Not legal advice.
    - **The owner asked again at the session's end** ("Did you end up not finding another solution beyond EaryChow's
      unlicenced repo? ... if Godot uses it I'm doubting there is an issue there? ... can we not build our own?"). The
      answer: nothing from the repository ships or runs; it is where the method is written down, about a dozen steps and
      their numbers, and `src/agx.kama` is the library's own code written from them, checked against Blender's table.
      The alternatives each lose something: Blender's table file is GPL with Blender; Godot's AgX (MIT) approximates the
      same script, credited to it, so its provenance is the same and its image is not Blender's; r187's AgX is licensed
      but up to 45 steps from Blender on saturated colours; Troy Sobotka's original AgX states no licence either; a
      curve of the library's own design would not look like Blender, which is why Blender's is the default. Godot's
      precedent, and the author's help in its proposal, make an issue unlikely; the request only removes doubt, and the
      owner may publish on the credit alone (option B) whenever they choose.
    - **The owner's concern is legal ambiguity** ("The main thing I was trying to avoid was legal ambiguity"). Every
      AgX shares it: Filament's (Apache-2.0) says its "matrices [are] taken from Blender's implementation of AgX",
      citing `EaryChow/AgX_LUT_Gen/AgXBaseRec2020.py`, and three.js's (MIT) is Filament's, so switching to r187's AgX
      would move the ambiguity, not remove it. The generator in turn builds on Troy Sobotka's sigmoid and SB2383
      settings, whose repositories state no licence either. So two requests are drafted for the owner to post, to
      EaryChow and to Troy Sobotka (`.scratch/s34/agx/licence-request.md`, `licence-request-sobotka.md`); the curves with
      no AgX lineage are Khronos's PBR Neutral, ACES and Reinhard. If no answer has come by the first publish, the
      owner decides then: publish on the precedent, or a clean curve as the default with AgX out of the package.
  - **Step 1 built the depth prepass** (2026-11-17, the thirty-fourth session, kama-graphics `43bd19a`; its SPEC § The
    renderer and § The compiler): each material's pipeline has a depth-only twin, its own vertex stage with no fragment
    stage, culling the same faces; `render` draws every mesh into depth, then shades it where its depth is the prepass's,
    the depth tested Equal and read only; the clip position is `@invariant`. Every golden is the same bytes. 267 cases
    natively, in Firefox and in Chrome for Testing, 259 in Edge, each debug and release; 12 of 13 mutations caught, a
    camera inside a room seeing a box outside it, new, alone catching a prepass that culls nothing; the 13th, GreaterEqual
    for Equal, is equivalent after a full prepass, and is Bevy's choice.
    - **Settled, and reported:** the prepass reuses each material's own vertex stage; `info()`'s `calls` and `triangles`
      count both passes' draws, as three.js counts a shadow pass's.
  - **Step 2 built the HDR frame** (kama-graphics `81c3127`; its SPEC § The renderer, § Render targets, § The camera,
    § Reading a target back and § The compiler): the scene is drawn in linear HDR into a 16-bit float texture, an 8-bit
    target's own or a 16-bit float target itself, and an output pass writes an 8-bit target from it through the camera's
    tone mapping; exposure on each camera in EV100, its default three.js's exposure of 1, Bevy's named values;
    `max(0)` on every material's output, as three.js r187's; `RenderTarget.withFormat` and `TargetFormat`, a float
    target read back as an `Rgba16Float` image. 279 cases natively, in Firefox and in Chrome for Testing, 271 in Edge,
    each debug and release; 13 of 13 mutations caught. The three lit goldens were written again: storing the scene as
    half floats moves 2 to 44 texels of each by one step, never more.
    - **Settled, and reported:**
      - the scene is pre-exposed, as Filament, Bevy and Unreal: every material's output and the clear colour are scaled
        by the exposure before they are stored, so sunlight's 100,000 lux stays within a half float. The exposure is the
        camera's whatever its tone mapping, where three.js applies `toneMappingExposure` in its tone mapping alone, and
        the clear colour is tone mapped with the scene, as three.js r187 tone maps its cleared frame target;
      - the named exposures and `ev100For(exposure:)`, which turns three.js's `toneMappingExposure` into EV100, are
        functions, as std names its constants (`pi()`);
      - the output pass is the frame's, so `info()` does not count it.
  - **Step 3 built tone mapping** (kama-graphics `3899adb`; its SPEC § The camera, § The renderer and § Tests):
    `ToneMapping::BlenderAgX`, the default, through a 57³ table a renderer makes once from the ported formulas
    (`blenderAgxTable()`, 87 ms natively at release, not a measurement) and reads tetrahedrally, as OpenColorIO reads
    Blender's; and `ToneMapping::AgX`, r187's. Twelve of Blender's entries are held within half a half float's step;
    eighteen swatches through each curve, Blender's within a step of what Blender 5.3 shows, worked from its own table;
    the `tone-mapping-blender-agx` golden on WARP and SwiftShader. 285 cases natively, in Firefox and in Chrome for
    Testing, 276 in Edge, each debug and release; 17 of 17 mutations caught. r187's golden waits on DXC natively.
    - **Settled, and reported:** the earlier tests set their cameras' tone mapping to `None`, so each golden and face
      check holds its own feature and the curves are held by their own cases; the table is stored as half floats, which
      move 3 % of its entries one step on the display, within the decided step.
  - **r187's golden, `tone-mapping-agx`, is written** (2026-11-18, the thirty-fifth session, kama-graphics `61c5661`), once
    `@kama/gpu` shipped DXC natively (kama-gpu `b123a03`, below): `tools/legs.sh` puts its `dxcompiler.dll` on the native
    legs' PATH, and `update-goldens.sh` wrote the golden with WARP's two legs agreeing. Held by mutation: DXC left off
    the PATH fails it natively by FXC's 2 texels. 286 cases natively, in Firefox and in Chrome for Testing, 276 in Edge.
  - **Step 4 built 4x MSAA, resolved by the GPU** (the same session, kama-graphics `c1a9f51`; its SPEC § The renderer,
    § Render targets and § Tests), the ladder's second rung: both passes at 4 samples a texel, on by default, the GPU
    averaging the linear scene into the scene's texture and discarding the samples. A white box turned 30 degrees holds
    an edge's texels to a quarter, a half and three quarters, linear in a float target and 137, 188 and 225 in an 8-bit
    one; three earlier colour checks now take an edge's texel as the resolve of 4 samples of the scene's colours. The
    four goldens with edges were written again. 288 cases natively, in Firefox and in Chrome for Testing, 278 in Edge,
    Edge's real GPU giving the same quarters; 6 of 7 mutations caught, the seventh (the samples stored) equivalent.
    - **Settled, and reported:** the sample count is the renderer's, fixed at 4 until the presets set the method (part
      5), with no public switch yet, so step 5's tone-mapped resolve and the method's choice arrive together.

- **2026-11-17, the owner: natively on Windows, `@kama/gpu` compiles shaders with DXC (A)** ("A: DXC natively
  (Recommended)", asked in full in the chat at the thirty-fourth session, when part 4's tone-mapping goldens could not be
  written).
  - **The problem:** natively, wgpu-native compiles its HLSL with FXC, its default; Firefox, Chrome and Edge compile with
    DXC. WARP natively (FXC) and WARP in Firefox (DXC) drew r187's AgX ramp with 2 of its 2,048 texels one step apart,
    so `tools/update-goldens.sh` refused. One golden per software GPU (GFX-1's question 3) assumed one compiler per GPU.
    Forced onto DXC (`WGPU_DX12_COMPILER=dxc`, Firefox's `dxcompiler.dll`, an experiment), native WARP drew Firefox's
    bytes for both tone-mapping ramps and all six earlier goldens.
  - **Beyond the goldens:** FXC is Microsoft's legacy compiler, "old, slow, and unmaintained" in wgpu-native's own header,
    and stops at Shader Model 5.1. wgpu-native's 64-bit integers on D3D12 are "DXC only"; wave operations, mesh shaders
    and ray tracing on D3D12 (area 4's PR #630) need Shader Model 6, which only DXC compiles.
  - **(A):** `@kama/gpu` ships `dxcompiler.dll` beside native Windows programs, and wgpu-native, whose default is to
    use it when it finds it, compiles with DXC. When the DLL is missing, FXC is the next method down, reported, never
    stopping a program. The web build is untouched. Goldens stay one per software GPU. It is a `@kama/gpu` row brought
    forward, as `writeTexture` was.
  - **Set aside:** (B) FXC kept, a golden per leg where two legs of one GPU differ, Shader Model 6 waiting.
  - **Corrected the same day, and asked again:** the question said the DLL came under LLVM's University of
    Illinois/NCSA licence. That is DXC's source. Microsoft's prebuilt binaries (v1.9.2609's `dxc_2026_09_29.zip`, 21.2 MiB
    for x64's `dxcompiler.dll`) come under "Microsoft Software License Terms, Microsoft DirectX Shader Compiler": only
    the listed distributables may be distributed, and whoever distributes must "require distributors and external end
    users to agree to terms that protect it and Microsoft at least as much as this agreement" and indemnify Microsoft.
    Firefox's `dxcompiler.dll` is Mozilla's own build from DXC's source ("1.9.0.0 (private, 00000000)", signed by Mozilla,
    24 MB, no `dxil.dll`): an open-source build signs its shaders itself, and it ran all 276 of `@kama/graphics`' cases on
    the Radeon 880M as well as every frame on WARP. Not legal advice.
  - **The owner's answers (2026-11-17, "A: build from source (Recommended)" and "A: commit step 3 now
    (Recommended)"):**
    1. `@kama/gpu` builds DXC from its open source at a pinned tag (v1.9.2609), as Firefox does, under the NCSA licence
       and its components' notices, with a build script as `@kama/window` has for SDL3. DXC's Windows build needs Visual
       Studio 2022's Build Tools (the C++ workload) and the Windows SDK 10.0.26100, which the owner allowed installing on
       this machine. Set aside: Microsoft's prebuilt DLL under its terms; FXC kept. **Amended on 2026-11-18, below:**
       built with msys2's clang, not Visual Studio's tools.
    2. Part 4's step 3 is committed before DXC lands, with Blender's AgX goldens. r187's `AgX` is held on every leg by
       its swatches, within a step of its float64 formulas, and its golden, `tone-mapping-agx`, is written once WARP's two
       legs agree under DXC.
  - **Amended on 2026-11-18, the owner: DXC is built with msys2's clang, so nothing of Microsoft's ships (A)** ("All as
    recommended", asked in full in the chat at the thirty-fifth session's start, before anything was installed).
    - **Found first:** Firefox's `dxcompiler.dll`, built by clang against a Visual Studio sysroot (Mozilla's
      `taskcluster/scripts/misc/build-dxc.sh`), imports `MSVCP140.dll`, `VCRUNTIME140.dll` and `VCRUNTIME140_1.dll`
      (`objdump -p`): Microsoft's Visual C++ runtime, which Windows does not include and Firefox ships in its own folder.
      `@kama/gpu`'s `wgpu_native.dll` imports only Windows' own DLLs, and kama links mingw's C++ runtime into every
      Windows program statically (kama's `docs/targets.md`). Built as Firefox builds it, DXC would add Microsoft's runtime
      to every game, under Visual Studio's terms for distributable code. Those terms were not read: Microsoft's page
      loaded without them. Not legal advice.
    - **(A):** DXC v1.9.2609 is built in msys2's UCRT64 by clang, the compiler kama drives on Windows, with its C++
      runtime linked statically as kama links its own. The DLL then imports only Windows' DLLs and carries DXC's NCSA
      licence, its components' notices and the mingw-w64 runtime's, which every kama program on Windows already
      carries. Nothing from Visual Studio is installed. It is probed first: Microsoft's build documentation assumes
      Visual Studio, and Hexops' mach-dxcompiler (2024) built DXC with Zig's clang against mingw-w64 only with patches.
      A build that needs patches the package would have to keep comes back to the owner with the measurement.
    - **Set aside for now:** (B) Visual Studio's Build Tools with the static runtime (`/MT`), Microsoft's runtime code
      inside the DLL under Visual Studio's licence, read before building: the fallback if (A) cannot build. (C) As
      Firefox, Microsoft's runtime DLLs shipped beside the program. The Build Tools install allowed on 2026-11-17 waits
      on (B).
  - **Decided on 2026-11-18, the owner: `@kama/gpu` fetches Microsoft's own DXC release, as wgpu and Bevy do** ("ya it
    sounds like we fetch it", after asking "How do others do this? Direct X is meant to be used... why are we trying to
    work around things?"). It replaces both amendments above.
    - **(A) needs patches** (the probe, `.scratch/s35/dxc/FINDINGS.md`): DXC takes its Windows path only under
      `_MSC_VER`, and that path includes Microsoft's ATL, which only Visual Studio ships; 130 of its files use ATL's
      types. Under mingw-w64 it falls back to its own stand-in for Windows' types, and LLVM's Windows code then clashes
      with the real headers. Hexops' fork did it in 2023 (21 commits over 44 files, built by Zig, against a DXC two
      years older), now in its graveyard organisation.
    - **How others ship it:** wgpu's and Bevy's documentation have a game ship `dxcompiler.dll` and `dxil.dll` from
      Microsoft's DXC releases, FXC the fallback when they are missing, and wgpu offers a static DXC built from Hexops'
      fork; Chrome and Firefox build DXC with Microsoft's toolchain; Godot translates its shaders to DXIL through Mesa's
      NIR. FXC needs no DLL because it is part of Windows; DXC is not.
    - **Measured:** Microsoft's v1.9.2609 `dxcompiler.dll` and `dxil.dll` import only Windows' DLLs (its runtime linked
      statically), and with them beside the program native D3D12 offers 44 features with `shader-f16`, on the Radeon
      880M and on WARP, against FXC's 33. Its terms (`LICENSE-MS.txt` in the release) are Microsoft's for distributable
      code: an application that ships it adds significant primary functionality, has its distributors and end users
      agree to terms that protect it and Microsoft at least as much (a game's EULA), and indemnifies Microsoft except
      for claims based solely on the unmodified code. Not legal advice.
    - **How:** the package fetches the release pinned by URL and SHA-256 at setup, as it fetches wgpu-native's SDK, and
      never commits it, so kyoten distributes none of Microsoft's code; whoever ships a game obtains the DLLs from
      Microsoft under those terms, as a Bevy game's developer does, and the package's documentation says so. FXC stays
      the next method down when they are missing, reported. Steam's common redistributables (Visual C++, .NET, DirectX
      9, OpenAL, XNA, PhysX) do not include DXC, so it goes in a game's own depot beside the program, as the Agility SDK
      does. WARP's two legs are held to agree on every golden with Microsoft's build before r187's golden is written:
      last session's agreement was measured with Firefox's.
    - **Built the same day as `@kama/gpu`'s GPU-16** (kama-gpu `b123a03`, its AGENTS.gpu.md item 16): `tools/fetch-dxc.sh`;
      the seam printing one line, once, when an adapter answers on Direct3D 12 without `dxcompiler.dll` loaded; the
      fallback adapter held to `ShaderF16` natively; and the gate needing the DLL on Windows, with one run without it
      held to FXC. `dxil.dll` turned out not to be needed. WARP's two legs agreed on every golden under Microsoft's DLL.

- **2026-11-18, the owner: how a program chooses its anti-aliasing, (A) one list of whole methods on the renderer** ("A
  (Recommended)", asked in full in the chat at the thirty-sixth session's start, before part 4's step 5 was built).
  Reading the code for step 5 found that part 4's question 1 decided the ladder and the thirty-fourth session settled the
  method on the renderer, but nothing had decided how a program names it: step 4 left the sample count a private 4.
  - **The problem:** a program could not turn anti-aliasing off, as a pixel-art game or a program running its own wants,
    nor choose a resolve, and a game's graphics menu changes the method while the game runs. The sample count is built
    into every pipeline and a target's textures, so a change means new ones at the next render. The shape decides what a
    program can get wrong and where the later methods go: 8x natively, TAA, SMAA, FXAA (FEATURES.md's anti-aliasing
    row).
  - **Prior art** (`.scratch/s33/part4-sources/`): three.js r187 takes `antialias` and `samples` when the renderer is
    made, `samples` a getter only after (`Renderer.js`); Bevy 0.20.1's `Msaa { Off, Sample2, Sample4, Sample8 }` is a
    component on a camera, changed at any time, with FXAA, SMAA and TAA separate components (`bevy_render/src/view/mod.rs`);
    Godot 4.7.2's `viewport_set_msaa_3d` (disabled, 2x, 4x, 8x) changes at any time, with screen-space AA and TAA
    separate; Filament 1.81.0's `MultiSampleAntiAliasingOptions` is `enabled`, `sampleCount` and `customResolve`
    (`Options.h`); Unreal's is one method list (None, FXAA, TAA, MSAA, TSR), from its documentation.
  - **(A):** `@nonExhaustive type enum Antialiasing { Msaa4ToneMapped, Msaa4, None }`, a property pair on the renderer,
    `antialiasing()` and `antialiasingMut()`, as `clearColor`. `Msaa4ToneMapped`, the tone-mapped resolve, is the
    default, as the presets for desktop and the web take it; `Msaa4` is the GPU's resolve; `None` draws one sample a
    texel. Every value is valid. A change takes effect at the next render, its pipelines and a target's textures made
    at the new count, and the pipelines kept per count, so switching back compiles nothing. Later methods join the same
    list as the ladder's rungs, each naming the GPU features it needs, the next one down taken and reported when one is
    missing: 8x natively where the adapter has it (WebGPU's core allows only 1 and 4), TAA, SMAA, FXAA. It is area 4's
    model as it stands: one technique, one ladder, a preset picking one method.
  - **Its cost:** a combination, such as MSAA with SMAA, is a method of its own when one is wanted, as in Unreal's list;
    a changed method compiles at the next render, a hitch until part 5 compiles pipelines off the frame.
  - **Set aside:** (B) two settings, a sample count and a resolve, as Bevy and Filament: a resolve set with MSAA off means
    nothing, and the post-process methods would add a third setting, so one ladder becomes three; (C) chosen when the
    renderer is made and fixed after, as three.js r187: a settings menu would need a new renderer, which compiles every
    pipeline again anyway.
  - **Settled with it, laid out with the question and reported:**
    - the tests written before step 5 keep the GPU's resolve, so their goldens keep their bytes, as step 3 set those
      tests' tone mapping to `None`; new goldens hold the tone-mapped resolve and `None`;
    - the weight is a sample's brightest channel, Lottes' reversible form as Filament's `customResolve`: each sample
      `c / (1 + max3(c))`, averaged, then `c / (1 − max3(c))`, the form part 4's question 1 measured with
      (`.scratch/s33/part4/resolve_edge.py`; a luma weight, Unity HDRP's, agrees on grey). Alpha is averaged plainly,
      as the GPU's resolve averages it;
    - the resolve is a pass of its own writing the linear scene, as the decision says, so later effects read it; `info()`
      does not count it, as it does not count the output pass;
    - `antialiasing()` says the method asked for. Both rungs are core WebGPU, so nothing falls back yet; the report of
      the method chosen comes with part 5's report of the device's features.
  - **Step 5 built it, and so part 4** (the thirty-sixth session, kama-graphics `dad8fe2`; its SPEC § The renderer,
    § Render targets and § Tests): `Antialiasing` and the property pair; the tone-mapped resolve, a pass of its own reading the
    shaded pass's stored samples as a `texture_multisampled_2d<f32>`; pipelines kept per count, and a target's
    multisampled scene and depth made again when the count changes. One renderer draws a box turned 30 degrees into one
    float target, its method changed between renders, and each texel is held to what its method makes of k of its 4
    samples, worked in float64: at one sample of four on (20, 4, 1) over a dark clear, red 0.38 by the tone-mapped
    resolve where the GPU's gives 5.04. The goldens `anti-aliasing-msaa4-tone-mapped`, `anti-aliasing-msaa4` and
    `anti-aliasing-none`, WARP's two legs agreeing. Every test written before step 5 keeps the GPU's resolve, so no
    golden moved. 299 cases natively, in Firefox and in Chrome for Testing, 286 in Edge, each debug and release; 24 of 24
    mutations caught, among them a luma weight and the older tests left on the default. The one expected to be
    equivalent, a target's record of its count not kept, is caught too: a method set back then keeps the other count's
    textures.
    - **Settled while building, and reported:**
      - the tone-mapped resolve is held within two half-float steps: it rounds twice, the samples stored and the texel
        written, and undoing the weight multiplies the first by 1/(1 − the mean's brightest channel). WARP measured 1.1
        steps at one sample of four, every channel about 5.5e-4 of itself low, where a luma weight would read 0.87, a
        weight never undone 0.27 and the GPU's resolve 5.04;
      - two guards, each a texel the weight alone would spoil: a sample stored as infinity is taken as 65504, so its edge
        is a number, never NaN (a box whose shader squares 10^30 holds it on every GPU, since WARP stores a finite
        overflow as 65504); and the brightest channel is taken at 0 or above in the weight and its undoing alike, so a
        negative clear colour comes back as it was. Writing that case found the undoing unfloored, which turned a texel
        all clear to the clear colour over 1.25, fixed before the step was committed;
      - the multisampled scene is a `TextureBinding` under every method: WebGPU's core has no transient attachment the
        GPU's resolve alone could take instead, so the usage costs nothing a method without it would save.

- **2026-11-18, the owner: GFX-1's part 5, its three questions, each (A) as revised** ("all sounds good now as revised
  recommendations", asked in full in the chat at the thirty-sixth session's end, after part 4 was built). The first
  draft of question 1 offered compiling ahead and skipping a draw whose pipeline was not ready. It said Godot's
  ubershader could not serve a node material, and that a renderer waiting for its pipelines could exist only natively.
  The owner asked: "We are building a general purpose solution. Shouldn't we support the uber shader designation
  approach? Shouldn't we also support pre-compiling all shaders as an approach? … recall that before shaders the fixed
  function pipeline was basically an 'uber shader'." Both claims were wrong, as the sources showed, and the question was
  laid out again. Of question 2: "How flexible are the quality settings? can developers of a game specify what falls
  into each quality?" Of question 3: "it sounds like this is just a scope question? we build what we know and add on as
  we go?" The sources are `.scratch/s33/part4-sources/`, and Unreal's and Unity's documentation.
  1. **Pipelines: every way, chosen by the program.** It widens area 3's item 3, where an object drew a frame or two
     late: a frame is still never a hitch unless a program asks for one.
     - **Compiling ahead:** `renderer.compile(scene:, camera:)` hands back a request the program polls, as `@kama/gpu`'s
       pipeline requests are polled: `Ready` once every pipeline the scene needs has answered, a refused material still
       reported by `takeErrors()`. It compiles general forms and stand-ins too, so a loading screen waits on it and a
       test compiles before it renders.
     - **A miss,** a draw whose pipeline is not ready (a material new at run time, a method changed), is a setting on
       the renderer that a material may override (a hero object waits, a particle skips):
       - `General`: the material's own general form, the same graph with every option the renderer would otherwise
         compile in read from uniforms instead, so it draws the same pixels, slower. Godot 4.7.2 does this
         (`render_forward_clustered.cpp:496-531`): each material's shader is compiled a second time with its
         specialization constants as push constants and culling in the shader, when a mesh loads, the loader waiting
         for it (`:5030`). Each feature that adds such an option adds it to the general form, with a case that both
         forms draw the same pixels. Today's one is the cull flip for a mirrored object;
       - `StandIn`: a material the program names, the library's plain grey by default, as Unreal's
         `r.PSOPrecache.ProxyCreationDelayStrategy` 1 draws the engine's default material;
       - `Skip`: nothing until the pipeline is ready, as Bevy and Unreal's default (strategy 0) do;
       - `Wait`: compiled during the frame, as three.js r187 does, and Godot when even the general form is missing
         (`pipeline_hash_map_rd.h:193`). It is for tools, tests and cutscenes. On the web the page does not freeze,
         but the browser's GPU process waits at the submit, so the frame is late on both legs alike.
     - **The default is `General`, then `Skip`** when the general form is not ready or there is none, as for a graph
       new at run time. `info()` counts the draws drawn each way, so a test or a loading screen can wait for no misses.
     - **The fixed-function point:** a preset's settings are already values (area 3's item 2), so a thousand standard
       materials share one pipeline. The general form carries the same idea to whatever would otherwise compile a new
       variant.
     - **Set aside:** (B) compiling ahead and skipping, the first draft, which left out three of the engines' ways;
       (C) (A) without `General`, cheaper to build, but a miss then always changes what the player sees.
     - **Part 5 builds** the setting with its four ways and the general form for the one option there is, the cull
       flip. Each later feature extends it as it arrives. Compiling everything at start from a list is question 11's.
  2. **Quality presets: a value the game owns, the library's four only starting points.**
     - `type value Quality` has one field per technique, each the technique's whole setting: the method now, and later
       its parameters, such as a shadow map's size. `Quality.low()` to `Quality.ultra()` are the library's.
     - A game makes as many as it likes and names them ("Steam Deck", "Quest 3"), each from one of the library's or
       from nothing. `renderer.applyQuality(quality:)` writes every technique, takes the next method down where the
       device lacks a feature, and reports what it chose; a player's settings menu still changes one technique after
       it. The renderer reports the device's features, area 4's item 1.
     - In kyoten a game's presets are records, and its rule, or kyoten's default rule, picks one per machine. That side
       comes with the render module's row, not part 5.
     - **Prior art,** from their documentation: Unity's quality levels are the project's, how many, their names, what
       each holds and each platform's default; Unreal's are four numbered levels per scalability group, Epic's defaults
       in `BaseScalability.ini`, which a project overrides level by level in its `DefaultScalability.ini`
       (`[ShadowQuality@2]`).
     - **Set aside:** (B) four fixed levels a game fills in, Unreal's, so a Deck or Quest preset squeezes into a number;
       (C) the library's contents, the first draft, a game only changing one technique after applying one.
     - **The library's four hold provisional contents** until measured (timestamp queries, GPU-6; a tiled GPU at
       GFX-5): low takes the GPU's resolve, and the rest the tone-mapped one. No preset turns anti-aliasing off.
  3. **Question 11 is scope: part 5 builds what is known, and the rest is decided at its row.** Part 5 builds compiling
     at load and the miss setting, and keeps the rest open: a material's WGSL is the same each time it is generated, so
     the `kyoten` tool can generate it ahead, and a pipeline's key holds everything that made it, which a cache on disk
     keys on. Compiling everything from a list (recorded from play, as Unreal's bundled cache, or written by the tool
     from a game's records), WGSL built ahead, DXIL and the cache on disk natively are decided at question 11's row, at
     the join.
