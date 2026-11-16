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

    `colorNode`, `roughnessNode` and `metalnessNode` arrive with the lights that read them (step 3), where a test can
    hold them.
