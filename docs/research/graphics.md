# Graphics: Three.js, the engines, beyond WebGPU, object models without a garbage collector, and the renderer's core

KYR-68, the graphics design pass, read 2026-11-11 for [rendering.md](../design/rendering.md) § Decided (2026-11-10:
the design pass's questions) and `../kama-graphics`. Four research agents read the sources below. Their key claims were
then re-checked here: the local headers and Three.js's r187 source were read directly, and the engines' and WebGPU's
pages were fetched again by a second agent, quoting each page. The *Checked* notes say what was checked and how;
*(unchecked)* marks a claim taken from one reading only. The probes are in `.scratch/kyr68-*/` (git-ignored).

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
  - **Ray tracing is moving.** Two issues were opened on 2026-10-13, both in Milestone 3:
    - #11053, "Add ability to create acceleration structures", with proposal PR #11054;
    - #11055, "Add support for rayQuery to WGSL": "some of the ray tracing capabilities without the requirement of the
      full ray tracing pipelines". On 2026-10-27 the WGSL group resolved "document accepted to land as a proposal".

    A comment on #535 of 2026-11-11 points to them. No browser implementation or flag was found (*checked*, the issues
    and Chrome's blog).
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

  - **Still missing on wgpu-native's development branch,** read 2026-11-11 (`trunk`'s `ffi/wgpu.h`, *checked*):
    - no function that creates or builds an acceleration structure;
    - no mesh-shader feature or draw call;
    - only a ray-query feature, and acceleration-structure binding arrays.

    Its open PRs include #632, which regenerates `wgpu.h` from a description file, and #630, "Expand wgpu 30 API
    parity".
  - **Rust's wgpu 30.0.1 has both, experimental and "native only"** (*checked*, docs.rs):
    - `EXPERIMENTAL_RAY_QUERY` runs on Vulkan;
    - `EXPERIMENTAL_RAY_TRACING_PIPELINES` exists;
    - `EXPERIMENTAL_MESH_SHADER` runs on Vulkan, DX12 and Metal (its WGSL path on Vulkan only, passthrough shaders
      elsewhere).

    wgpu-native is the C binding of that same Rust wgpu, so the native state of the art through it waits on its C
    header, not on a new renderer *(inferred)*.
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

**The second probe** (`.scratch/kyr68-objects2/`, kama 0.9.911): Three.js's typed node kinds behind one contract.
- `Mesh` and `Group` each embed a `NodePart` (transform, children, weak parent) and implement a contract, `Placed`, by
  forwarding to it.
- The scene stores `Shared<Placed>`, and the program keeps a typed `Shared<Mesh>` to the same object. The handle widens
  when it is added (kama SPEC § upcast: "both handles share one Circle").
- The program calls a mesh's own method on its typed handle; the walk goes through the contract.
- Everything is freed once, by its last holder. It built and ran on the first try.
- **The cost:** a kama contract has no default methods, so each kind forwards about eight methods to its part. That code
  is in the library, never in a program.
- **A clone:** `public const fn This clone()` on a material makes an independent one. Renaming the clone leaves the
  original alone (`.scratch/kyr68-clone/` and probe 2, kama 0.9.911). kama's SPEC spells the self-type's copy so.

**The third probe** (`.scratch/kyr68-props/`, kama 0.9.911): Three.js's `cube.position.x = 2;
cube.rotation.y += 0.01;` with a resource's private fields.
- A property is a pair, after kama's own `view()`/`viewMut()` and `dataPtr()`/`dataPtrMut()`. `position()` is a
  `const fn` that reads it. `positionMut()` hands back a `ref Vec3` and marks its owner changed.
- `cube.positionMut().x = 2.0;` and `cube.rotationMut().y += 0.01;` work through a `Shared<Mesh>`.
- One upload follows the writes, and a read marks nothing. The program never sets a `needsUpdate` flag.

## 5. The renderer's core: materials across the engines, and pipelines compiled off the frame

Read and measured 2026-11-11 for the design pass's area 3, after the owner asked of its question 2: "I thought materials
were programmable with shaders and such? What do the others do? I assume typing them has advantages?"

**Every engine but Unreal pairs a typed, ready-made material with a programmable path, and lets the second reach into
the first.**

| | Ready-made, typed | Programmable | How the two meet |
|---|---|---|---|
| three.js r187 (`WebGPURenderer`) | 13 classic materials (`MeshStandardMaterial`…), each mapped to a node material by `StandardNodeLibrary` | TSL node expressions | **A preset's slot takes an expression.** `NodeMaterial` has `colorNode`, `normalNode`, `opacityNode`, `positionNode`, `outputNode`, `fragmentNode`, `vertexNode` and more; `MeshStandardNodeMaterial` adds `metalnessNode`, `roughnessNode` and `emissiveNode` (read in `src/materials/nodes/`) |
| Godot 4 | `StandardMaterial3D`, `ORMMaterial3D` | `ShaderMaterial` (its shading language), `VisualShader` | The editor converts a `StandardMaterial3D` into a `ShaderMaterial`'s source, as a starting point. Editor only, never at run time ([docs](https://docs.godotengine.org/en/4.2/tutorials/shaders/shader_materials.html), [forum](https://forum.godotengine.org/t/convert-standard-material-to-shader-material-from-script/124377)) |
| Bevy | `StandardMaterial` | the `Material` trait, with WGSL | **`ExtendedMaterial<StandardMaterial, MyExtension>`** replaces a stage and keeps the standard material's bindings, lighting and shadow passes ([example](https://bevy.org/examples/shaders/extended-material/)) |
| Unity | the pipeline's Lit and Unlit shaders: a `Material` is a shader plus values | Shader Graph, HLSL | **Property names are strings:** URP's Lit is `_BaseColor`, the built-in Standard is `_Color`, so `SetColor("_Color", …)` silently does nothing under URP ([URP Lit](https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@9.0/manual/lit-shader.html), [conversion guide](https://docs.unity3d.com/6000.6/Documentation/Manual/urp/urp-shaders/birp-urp-custom-shader-upgrade-guide.html)) |
| Unreal | none: every material is a graph | the Material Editor, with a Custom HLSL node; **Substrate** layers material slabs (metal, clear coat, skin, cloth), production-ready since 5.7 ([5.7 release](https://www.unrealengine.com/news/unreal-engine-5-7-is-now-available)) | **Material Instances:** a parent graph's parameters are overridden without recompiling, so variants share one compiled shader |

- **What a typed preset buys,** across them:
  - its names and types are checked, where Unity's strings fail silently;
  - its variants are data. A different color or roughness is a value in a buffer, never a new compiled shader, which is
    what Unreal's Material Instances exist to give;
  - glTF's material maps onto it unconverted;
  - it is the shortest way in.
- **What it costs:** a fixed list, so a material outside it is a slot override or WGSL.

**wgpu-native cannot compile a pipeline asynchronously.** `wgpuDeviceCreateRenderPipelineAsync` and
`wgpuDeviceCreateComputePipelineAsync` are `unimplemented!()` in `src/unimplemented.rs`, at v29.0.1.1 and at trunk
(read 2026-11-11), so a call panics. On the web, `createRenderPipelineAsync` is the browser's, and compiles off the
page's thread.

**The probe** (`.scratch/kyr68-pipelines/`, C, wgpu-native v29.0.1.1 over Vulkan on the AMD Radeon 880M, 20 logical
cores): can the program's own threads compile in parallel instead?
- **What it builds:** 48 render pipelines, each from its own shader module, split over 1, 2, 4 and 8 threads, after one
  warm-up pipeline.
  - Each shader is about the size of a lit material: GGX over eight lights, fbm noise, fog and an AgX curve.
  - Each targets `rgba16float` with 4× MSAA.
  - Each carries the run's seed and its own index as constants, so neither naga nor the driver's disk cache returns an
    earlier one.
- **The runs:** three rounds, each thread count in a process of its own.

| Threads | Wall time for 48 (three rounds) | Per pipeline | Speed-up |
|---|---|---|---|
| 1 | 1220, 1189, 1127 ms | 23.5–25.4 ms | 1× |
| 2 | 637, 606, 610 ms | 12.6–13.3 ms | 1.9× |
| 4 | 395, 366, 422 ms | 7.6–8.8 ms | 3.0× |
| 8 | 256, 246, 256 ms | 5.1–5.3 ms | 4.7× |

- **No errors, and no null pipelines.** wgpu-native takes concurrent `CreateShaderModule` and `CreateRenderPipeline`
  calls on one device from many threads, and they compile in parallel.
- **One pipeline costs about 24 ms on one thread:** a frame and a half at 60 Hz. Compiled mid-frame, it is a visible
  hitch.
- **So pipelines are compiled natively by the ordinary call on worker threads,** until wgpu-native implements its
  asynchronous call. That answers `@kama/gpu`'s GPU-4 question of "whether pipelines are made asynchronously … or both
  ways": both, the browser's asynchronous call on the web and the ordinary one on a worker natively.

## 6. Beyond WebGPU: what the design pass's area 4 rests on

Read 2026-11-11, after § 3.

**wgpu-native's C API for ray tracing and mesh shaders exists, in an open pull request.**
- **The PR:** wgpu-native #630, "Expand wgpu 30 API parity and fix native surface ownership".
  - Open since 2026-09-12, last updated 2026-10-12, by matthargett.
  - It continues #594, "Complete parity with wgpu", by inner-daemons, which closed unmerged on 2026-09-12. #594 called
    itself "the sister PR to gfx-rs/wgpu#9570".
  - Its changelog: "Expose additional wgpu 30 functionality, including ray tracing, mesh shaders, …". Its tests are a
    separate PR, #631.
- **What its `ffi/wgpu.h` declares** (head `8322fe1`, read here):
  - **ray tracing:** `wgpuDeviceCreateBlas`, `wgpuDeviceCreateTlas`, `wgpuCommandEncoderBuildAccelerationStructures`,
    `wgpuCommandEncoderMarkAccelerationStructuresBuilt`, and compaction (`wgpuBlasPrepareCompactAsync`,
    `wgpuBlasReadyForCompaction`, `wgpuQueueCompactBlas`);
  - **mesh shaders:** `wgpuDeviceCreateMeshPipeline`, `wgpuRenderPassEncoderDrawMeshTasks` with its indirect, multi and
    count forms, and the `ExperimentalMeshShader` features;
  - **native handles for Metal only:** `wgpuDeviceGetNativeMetalDevice`, `wgpuQueueGetNativeMetalCommandQueue` and
    `wgpuTextureGetNativeMetalTexture`. There is nothing for Vulkan or D3D12, and v29's header has no native handle at
    all.
- **Its review:** one reviewer comment, by Vipitis on 2026-10-01: "everything works in our test suites with a local
  build", with the new native-only features not tried. There is no maintainer approval.
- **Not built or run here.** A build runs a third party's code, which waits on the owner (the auto-mode classifier
  blocked it). The branch is cloned, unbuilt, in `.scratch/wgpu-native-630/`.

**gpuweb's acceleration-structure proposal** (PR #11054, draft, by dj2, opened 2026-10-13; `proposals/acceleration_structure.md`, read here).
- **Its API:**
  - one object, `GPUAccelerationStructure`, either "bottom-level" or "top-level";
  - `createAccelerationStructure`, and `createAndBuildAccelerationStructure` to do both in one call;
  - compaction and refit;
  - gated by the feature `acceleration-structure`, "used by both ray query and full ray tracing".
- **Against wgpu's:** wgpu has two objects, `Blas` and `Tlas`. The concepts are the same in both:
  - a bottom level of triangles or AABBs;
  - a top level of instances, each with a transform;
  - compaction, and refit (wgpu's update).

**A vendor upscaler natively needs a native handle.**
- **Bevy's DLSS:** it goes through `dlss_wgpu`, which works only on wgpu's Vulkan backend. It reaches the raw Vulkan
  device through wgpu's `as_hal`, and the crate cannot redistribute the DLSS SDK (docs.rs, *unchecked* beyond a search).
- **wgpu-native has no such handle:** its C API exposes no Vulkan or D3D12 handle, in v29 or in #630.

**Chrome's `atomic-vec2u-min-max`.** Dawn lowers it to a 64-bit atomic, min and max only, on Vulkan, Metal and D3D12
(Dawn's commits, found by a search). Whether it carries a software rasterizer's visibility buffer on the web is to be
measured.

**WebGPU's reach** (web.dev's announcement, late 2025, and later reports, by a search):
- **Supported:**
  - Chrome and Edge on Windows, macOS and ChromeOS, and Chrome on Android 12 and later;
  - Safari on macOS, iOS, iPadOS and visionOS 26;
  - Firefox 141 on Windows, and Firefox 145 on Apple-silicon macOS.
- **In progress:** Firefox on Linux, Android and Intel Macs, and Chrome on Linux.
- **Quest's browser:** WebGPU in WebXR is behind a flag ([xr.md](../design/xr.md)).
