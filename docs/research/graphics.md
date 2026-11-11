# Graphics: Three.js, the engines, beyond WebGPU, and object models without a garbage collector

KYR-68, the graphics design pass, read 2026-11-11 for [rendering.md](../design/rendering.md) § Decided (2026-11-10:
the design pass's questions) and `../kama-graphics`. Four research agents read the sources below. Their key claims were
then re-checked here: the local headers and Three.js's r187 source were read directly, and the engines' and WebGPU's
pages were fetched again by a second agent, quoting each page. The *Checked* notes say what was checked and how;
*(unchecked)* marks a claim taken from one reading only. The probe is in `.scratch/kyr68-objects/` (git-ignored).

| Source | Version, as of 2026-11-11 |
|---|---|
| three.js | r187 (`three@0.187.0`, 2026-10-30); no r188 yet |
| Unreal Engine | 5.8 (June 2026, Epic's last planned major UE5); 5.9 Preview posted 2026-11-09 |
| Unity | 6.6 (September 2026); 6.3 LTS; 6.7 LTS in beta |
| Godot | 4.7 (June 2026); 4.8 in beta |
| Bevy | 0.20.1 (0.20 on 2026-10-08), on wgpu 30.0.1 |
| WebGPU | the Editor's Draft of 2026-11-10 |
| wgpu-native | v29.0.1.1 (2026-06-23, its latest release), in `../kama-gpu/third_party/` |
| emdawnwebgpu | v20260423.175430 (Dawn `31e25af2`), emsdk 6.0.13's; the latest is v20261110.181728 |

## 1. Three.js, the reference for ease of use

The whole inventory is in the agent's report; what bears on the design:

- **Its renderer for WebGPU is still called experimental.** Its manual says "the renderer itself is still in an experimental state",
  and `WebGPURenderer` falls back to a WebGL 2 backend. Its custom shaders are TSL: "`ShaderMaterial`,
  `RawShaderMaterial` and modifications of built-in materials via `onBeforeCompile()` are not supported in
  `WebGPURenderer`". *Checked:* `NodeBuilder` errors "Material … is not compatible" (r187 source).
- **Lifetime is by hand.** Its manual says GPU resources "are not released automatically". r186's `Object3D.dispose()` only fires an event:
  "Geometries, materials and textures are potentially shared with other 3D objects and must be disposed of separately"
  (*checked*, `src/core/Object3D.js:1670`). r187's `WeakRef`/`FinalizationRegistry` only prune the renderers' own
  tracking sets (*checked*, `src/renderers/common/`).
- **Scale has moved off the scene graph.**
  - `InstancedMesh` and `BatchedMesh` are core.
  - r187 adds experimental meshlet and visibility-buffer drawing pipelines: "experimental and its interface might
    change". They need the WebGPU backend. *Checked* in `examples/jsm/pipelines/`.
- **Lighting at scale is an addon:**
  - `ClusteredLighting` (r185, Forward+) and `DynamicLighting` (r184);
  - cascaded shadows: `CSM`, `CSMShadowNode` and `SunLight`;
  - global illumination: `VXGINode` (WebGPU only), `SSGINode`, `LightProbeGrid`, and `LightMapper` (r187).
- **Post-processing** is `RenderPipeline` over MRT, with about 40 effect nodes as addons:
  - AO and GI: GTAO, SSAO, SSGI, SSR and VXGI;
  - anti-aliasing and upscaling: TRAA, TAAU, FSR1, FXAA and SMAA;
  - lens and transparency: bloom, depth of field, motion blur and OIT.
- **Shadows:** `PCFSoftShadowMap` was removed in r186, and soft PCF is the default (*checked*, `Renderer.js:1033`).
- **Tone mapping:** Linear, Reinhard, Cineon, ACES Filmic, AgX and Neutral.
- **XR:** WebXR runs on WebGPU since r185, but "WebGPU XR does not support multiview yet" (*checked*, `XRManager.js:789`).
- **No official minimal lit cube on `WebGPURenderer`.** The manual's `fundamentals-with-light` is 35 lines of script on
  `WebGLRenderer`; porting it is three edits.

## 2. The engines' state of the art, and what each technique needs

| Technique | Engine | Needs | Without it | WebGPU today |
|---|---|---|---|---|
| Virtualized geometry (Nanite) | UE | 64-bit atomics: "DirectX 12 (with Shader Model 6.6 atomics), or Vulkan (VK_KHR_shader_atomic_int64)" (*checked*) | a generated fallback mesh | no |
| Meshlets / virtual geometry | Bevy (experimental), three.js r187 (experimental) | Bevy: 64-bit texture atomics, Vulkan and Metal only | none | three.js's runs on WebGPU *(unchecked how)* |
| GPU-driven culling and instancing | Unity GPU Resident Drawer, Bevy | compute; Bevy's full path needs multi-draw indirect and bindless | CPU culling | GPU transforms only: Bevy's table marks multi-draw and bindless ✗ on WebGPU (*checked*) |
| Software ray-traced GI (Lumen SW), SDFGI | UE, Godot | compute, distance fields | probes, screen traces | possible *(inferred)* |
| Hardware ray tracing: GI, reflections, shadows, MegaLights at full quality | UE, Unity HDRP, Bevy Solari | hardware RT | software RT, screen space, probes | no |
| Virtual shadow maps | UE | as Nanite | cascaded shadow maps | no |
| Clustered forward/deferred, CSM, PCSS, contact shadows, SSR, SSGI, probes, lightmaps | all | compute or fragment | | yes |
| TAA, TSR/STP-class upscalers, all post-processing, atmosphere, clouds, froxel fog, GPU particles | all | compute | | yes |
| DLSS, XeSS | vendor SDKs | vendor hardware | | never on the web |

- **On the web today:**
  - **Unity runs on WebGPU**, beside WebGL 2, no longer labelled experimental. It unlocks compute shaders, indirect
    rendering, GPU skinning and the VFX Graph. It lacks async compute, dynamic resolution, cubemap arrays, wave
    intrinsics, Int64 and native 16-bit (*checked*, Unity 6.6's manual).
  - **Unreal 5.9 Preview has an experimental web target,** "Powered by WebAssembly and WebGPU, this experimental
    capability uses the mobile renderer". It "currently requires a source build and C++ project" (*checked*, Epic's
    forum announcement, not its docs).
  - **Godot is not on WebGPU:** "Godot 4 can only target WebGL 2.0 (using the Compatibility rendering method)", and
    "Godot currently does not support WebGPU" (*checked*).
- **Render graphs:** Unity's URP and HDRP share one render graph since 6.3. Godot's RenderingDevice builds an acyclic
  graph itself. Bevy 0.19 replaced its render graph with ECS schedules.
- **Tone mapping:** Khronos PBR Neutral is built into Bevy alone of the four; Godot has AgX, HDRP has ACES and Neutral
  *(unchecked)*.

## 3. Beyond WebGPU: the web's proposals, and the native extensions

**On the web.**
- **Shipped in Chrome as optional features:**
  - subgroups (134, requested per device: *checked*, "request a GPUDevice with this feature");
  - shader-f16, timestamp queries, dual-source blending, clip distances and texture-format tiers;
  - `atomic-vec2u-min-max` (157), the only 64-bit atomic. There are no general 64-bit atomics.
- **Immediates (push constants), `maxImmediateSize`,** arrived in Chrome 149 to 150 (*checked*, Chrome's WebGPU notes).
  Whether they are core in the spec, with no feature required, was not confirmed verbatim. Both local headers carry the
  limit.
- **Bindless** is a draft proposal (resource tables, issue #380, Milestone 2).
- **Multi-draw indirect** is behind Chrome's unsafe flag only.
- **Ray tracing and mesh shaders are open issues in "Milestone 4+"** (*checked*, gpuweb #535 and #3015).
  - A #3015 comment of 2026-06-27: "I wouldn't expect it to arrive anytime soon".
  - On 2026-11-11 ray queries and acceleration structures were split into new issues (#11055, #11053), each with a
    proposal PR.
- **Firefox and Safari** trail on most optional features *(unchecked: MDN's compatibility data)*.

**Natively, through wgpu-native v29's `wgpu.h`** (*checked*, read here):
- **Reachable now:**
  - 64-bit atomics: `ShaderInt64AtomicMinMax`, `ShaderInt64AtomicAllOps` and `TextureInt64Atomic`, which is what
    Nanite-class geometry needs;
  - binding arrays and non-uniform indexing, which is bindless in effect;
  - `MultiDrawIndirectCount`, `Multiview`, subgroups, `ShaderF64`/`ShaderInt64`, conservative rasterization,
    barycentrics;
  - pipeline statistics and timestamps inside passes, `Immediates`, and SPIR-V shader modules.
- **Not reachable through its C API:**
  - **Hardware ray tracing.** `WGPUNativeFeature_RayQuery` (`0x3001C`, "EXPERIMENTAL") can be requested, but `wgpu.h`
    has no function that builds an acceleration structure (a search for `blas`, `tlas` and `acceleration` finds only
    feature comments).
  - **Mesh shaders**, whose features are commented out ("TODO: requires wgpu.h api change").

  Rust's wgpu 30 has both, experimental. So the native state of the art through wgpu-native waits on its C API
  *(inferred)*.
- **emdawnwebgpu, emsdk 6.0.13's pin,** lacks `SetImmediates` and `atomic-vec2u-min-max`. The latest release has both
  (*checked* for the pin, `grep`).

**How libraries offer a feature beyond their floor:**
- **wgpu:** splits its features into "web and native" and "native only", with downlevel limits.
- **Bevy:** each technique states the features it needs and falls back or skips:
  - GPU culling has three rungs;
  - Solari warns and does not load;
  - meshlets exit the process.
- **three.js:** one feature vocabulary across its WebGPU and WebGL backends (`renderer.hasFeature`).
- **Babylon.js:** one capability object across its engines.
- **Filament:** coarse feature levels, raised and never lowered.

## 4. Object models without a garbage collector

| Library | The user holds | GPU lifetime | Sharing |
|---|---|---|---|
| Filament | raw pointers from `Engine`, and entities | `engine->destroy(x)` in dependency order; leaks swept at engine teardown | the same pointer |
| Godot | RIDs in its servers, with ref-counted Resources and owned Nodes over them | `free_rid` by hand at the server tier; per-frame dispose lists | the same RID or `Ref<Resource>` |
| bgfx, sokol | 16- or 32-bit handles, sokol's with a generation | explicit destroy, queued to the frame's end and released per frame in flight | copy the handle |
| Bevy | ECS entities; ref-counted `Handle<T>` assets | the last strong handle's drop removes the GPU asset, and wgpu keeps it until the GPU is done | clone the handle |
| three-d | owned values; `Arc<Texture>` | RAII `Drop` | `Material for &T`, `Rc`, `Arc` |
| kiss3d | `Rc<RefCell<…>>` scene nodes, a `Weak` parent | `Rc` drop, then wgpu | `Rc` clones |
| Diligent | COM-style ref-counted pointers | a release queue keyed to the command list | ref-counted |

*(Unchecked: the agent's reading of each library's docs and source, with quotes.)*

- **Every mature backend separates the user's release from the GPU's free.** WebGPU does too: `@kama/gpu`'s handles
  are `type resource`s released in their destructors, a copy is webgpu.h's `AddRef`, and the GPU free waits for
  submitted work. So a library on `@kama/gpu` needs no deferred-release queue of its own *(inferred from `@kama/gpu`'s
  SPEC and the survey)*.
- **Only ref-counted or RAII APIs meet "nothing disposed by hand".**
- **Two engines split a data-oriented core from a friendly layer over it:** Godot (servers and RIDs, with nodes over
  them) and Bevy (a retained render world extracted from the main world). Weissflog's "Handles are the better pointers"
  argues the core's case: systems own their memory in packed arrays, and smart-pointer webs cause "fake memory leaks".
  Granite's Vulkan backend takes the other side: ref-counted pointers with deletions deferred to a frame context.

**The probe** (`.scratch/kyr68-objects/`, kama 0.9.911): a scene graph of `Shared<Node>` with a `Weak` parent link
and a `Shared` material on two nodes.
- The program turns a node through its own copy after adding it (`cube.local().angle = …`, an assignment through a
  `ref`-returning method).
- Dropping the program's copies frees nothing, since the scene holds them. Clearing the scene frees the node, its child
  and the shared material, each exactly once. Nothing is disposed by hand.
- **kama's rules met:**
  - a `ref` parameter may not name a smart pointer, so a walk borrows the node (`walk(n: k.deref())`);
  - `Weak.tryUpgrade()` is not a `const fn`, so a `const fn` upgrades a local copy;
  - `Shared` exclusivity is checked at run time (kama SPEC § Shared, Swift's model). A walk that holds a node's children
    while code changes them through another handle traps, which ordinary "change, then render" never does.
