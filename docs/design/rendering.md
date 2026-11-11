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
