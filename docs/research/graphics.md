# Graphics: Three.js, the engines, beyond WebGPU, object models without a garbage collector, the renderer's core, the feature map, and the engine-facing render surface

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
- **Built and run here** once the owner gave the OK with the design pass's 4.2 ("OK to build and run").
  - **The build:** `.scratch/wgpu-native-630/`, head `8322fe1`, `cargo build --release` in UCRT64 (Rust 1.99, LTO
    off). It took 1 min 24 s, with no errors.
  - **The probe:** `.scratch/kyr68-raytrace/rt.c`, C against the PR's own header, over Vulkan on the AMD Radeon 880M
    (driver 25.20.42.14).
  - **The adapter offers:** `RayQuery`, `ExperimentalRayTracingPipelines`, `ExperimentalMeshShader` and
    `ExperimentalRayHitVertexReturn`.
  - **Ray queries are correct.** One BLAS of one triangle, placed twice in a TLAS with different custom data. A
    64 × 32 grid of rays from a compute shader (`enable wgpu_ray_query;`) matched the CPU on all 2048: which instance
    was hit, and `t` exactly 1.0. There were no validation errors.
  - **Ray queries are fast.** One BLAS of a heightfield; 1920 × 1080 coherent primary rays a dispatch, timed by wall
    clock over 19 submissions, each waited on, so the GPU's own time is lower:

    | Triangles | Build, BLAS and TLAS (wall) | Trace a 1080p grid | Rays a second |
    |---|---|---|---|
    | 131,072 | 12–42 ms | 1.42–1.46 ms | about 1.4 G |
    | 524,288 | 63 ms | 1.94–2.06 ms | about 1.0 G |
    | 2,097,152 | 192 ms | 4.9 ms | about 0.42 G |

    Primary rays are the most coherent kind. The scattered rays of global illumination run far slower, and a
    measurement of those belongs to the feature map's row.
  - **Mesh shaders are correct.** A task stage (`enable wgpu_mesh_shader;`) launched four mesh workgroups through
    `wgpuDeviceCreateMeshPipeline` and `wgpuRenderPassEncoderDrawMeshTasks`. Each drew one quadrant of a 64 × 64
    target as two triangles, and the task's payload culled quadrant 2. All 4096 pixels read back as expected, with no
    validation errors.
  - **One thing a C user must know:** a device has to ask for the acceleration-structure and mesh limits, which
    default to 0 as in Rust's wgpu (`using_minimum_supported_acceleration_structure_values`). With the defaults,
    `CreateBlas` reports "Limit `max_blas_geometry_count` is 0". The probe asked for the adapter's limits, chaining
    `WGPUNativeLimits`.
  - **Nothing was posted to the PR.** That waits on the owner's go-ahead.

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

## 7. The feature map: what area 5 rests on

Read and probed 2026-11-11.

**The reference machines are decided** ([examples.md](../design/examples.md) § Decided, 2026-11-07):
- the Steam Deck, the low-end native gauge and the Linux leg;
- the Windows mini PC with the Radeon 880M, which is this machine;
- the Mac Mini;
- a mid-range laptop's browsers;
- Quest 3.

Every measured number is a ratchet on them (KYR-13).

**A software GPU for deterministic golden images** (`.scratch/kyr68-warp/`, wgpu-native v29.0.1.1):

| Backend | `forceFallbackAdapter` | Adapter |
|---|---|---|
| DX12 | no | AMD Radeon 880M (integrated) |
| DX12 | yes | **Microsoft Basic Render Driver, type CPU: WARP**, which every Windows has |
| Vulkan | no | AMD Radeon 880M |
| Vulkan | yes | none: "vulkan had no fallback adapters" (no lavapipe installed here) |

- **Elsewhere:**
  - Linux's software Vulkan is Mesa's lavapipe, where a distribution installs it;
  - on the web, Chromium's fallback adapter is SwiftShader, verified in Edge 157 and the pinned Chrome for Testing on
    2026-11-13 (§ 9);
  - macOS has no software Metal.
- **Whether WARP, lavapipe and SwiftShader run hardware-only methods** (ray queries, mesh shaders) was not checked.
  Such a method's goldens come from hardware.

## 8. Naming other products: what their owners publish

Searched 2026-11-11, when the owner asked whether the feature map may name the engines. These were read through a web
search's summaries of the pages, not the pages themselves, so each is *(unchecked)*. Re-read the page before relying on
a detail.

- **Unity** ([Guidelines for Using Unity Trademarks](https://unity.com/legal/branding-trademarks), version 4.2):
  - its wordmarks may be used "to describe or to refer to Unity products or services themselves";
  - they may not be used for another's "business, products, or services", nor as a social media name;
  - nothing may suggest "an affiliation with, or endorsement/sponsorship/approval by" Unity;
  - published material carries a notice that it is "not sponsored by or affiliated with Unity Technologies";
  - its logos are stricter: only to promote Unity's own products.
- **Godot** ([the Godot Foundation's trademark policy](https://godot.foundation/policies-and-procedures/trademark-policy)):
  - a royalty-free license for contributors and users;
  - the name may not be used for a commercial game engine without a custom license, nor in a company's or trading
    name;
  - its logos are CC BY 4.0, separately from the word mark.
- **Unreal Engine:** Epic's current page is its branding and trademark usage page, which the search did not open.
  - Epic's older guides ask that its marks keep their spelling, are never made possessive or plural, and are never
    altered;
  - they ask for a license to use the marks in a product or its marketing;
  - they suggest the notice "Unreal® and Unreal Engine® are trademarks or registered trademarks of Epic Games, Inc."
- **Not found:** whether any engine's terms forbid publishing benchmarks of it (a "DeWitt clause"). A search of Unity's
  terms surfaced none, which is not evidence there is none. KYR-74 reads each engine's terms before a number about it is
  published.

## 9. GFX-1's questions, measured

Measured 2026-11-13, kyoten's twenty-first session, before `@kama/graphics`' GFX-1 questions were asked. One shader ran
unchanged in each browser and natively (`.scratch/gfx1-probe/`, its `FINDINGS.md`), and a node builder was sketched in
kama (`.scratch/gfx1-nodes/`), on kama 0.9.943. This machine: the AMD Radeon 880M, Windows 11.

**The depth convention.** Two tilted quads, the back one a copy of the front a fraction `rel` further at every pixel,
depth32float, near 0.1 and far 10 km, drawn in both orders so ties show:

| Distance | Gap | Standard: pixels wrong or tied | Reversed | Reversed, infinite far |
|---|---|---|---|---|
| 100 m | 1 cm | 2% | 0 | 0 |
| 100 m | 1 mm | 87% | 0 | 0 |
| 1 km | 10 cm | 87.5% | 0 | 0 |
| 5 km | 50 cm | 100% | 0 | 0 |
| 5 km | 5 cm | 50% | 0 | 0 |

Every case at 1 m and 10 m, and at gaps of 1% and 0.1%, is 0 in every convention, and a cube near the camera is the
same bytes in all three.

**A node graph in kama.** Typed nodes, one per WGSL type, each holding a shared expression and copied as a reference
when handed on (`Copyable<This>(bare: copy)`, as TSL's nodes are references), with operators by operand type:

```kama
FloatNode pulse = 0.5 + 0.5 * sin(x: time());
m.colorNode(node: mix(from: color(hex: 0x0066ff), to: texture(map: albedo, at: uv()).rgb(), by: pulse));
m.emissiveNode(node: 2.0 * color(hex: 0xff3300) * fresnel(power: 3.0));
```

It compiles to the WGSL the expression says. A float in a colour slot and a vec4 used as a colour are refused at compile
time. Measured limits: an operator takes its right operand by value only, a number on the left is a two-operand form
declared in the type, and a type cannot overload one operator for both itself and a number on the right (KY-55), so
until that is fixed a number goes on the left. kama 0.9.947 fixed it on 2026-11-14: the sketch takes a number on
either side (`.scratch/gfx1-nodes-947/`).

**Custom nodes** (measured 2026-11-14, after the owner asked whether node types are a bound list): three ways, each
compiled and run in the sketch. A kama function from typed nodes to a typed node (TSL's `Fn()`); a WGSL function wrapped
as a typed node (TSL's `wgslFn()`); and a node type of the program's own, a struct `Ray` with typed `origin()` and
`direction()`, implementing the library's contract `Node<T is This>`, which kama requires so a contract can name its
implementor's type. The library's generic `select<T: Node<T>>` took the program's `Ray` and refused a vec3 on one side
and a float on the other (*"cannot unify type parameter 'T'"*).

**Software GPUs.** The lit cube, 4× MSAA, sRGB, 256 × 256, hashed:
- every hardware leg gives the same bytes: Vulkan and D3D12 natively, Edge 157, Chrome for Testing 157 and Firefox 160;
- **SwiftShader runs WebGPU** in Edge 157 with no extra flag and in the pinned Chrome for Testing with
  `--enable-unsafe-swiftshader` (`forceFallbackAdapter`), the same bytes in both and on every run;
- **WARP** natively (wgpu-native's fallback on D3D12) is deterministic, and **Firefox 160's fallback adapter is WARP**,
  the same bytes;
- Vulkan has no fallback here, since lavapipe is not installed; Linux's is unmeasured.

**How far apart the frames are:**

| Pair | Pixels that differ | by more than 32 of 255 | Largest |
|---|---|---|---|
| the GPU and WARP | 0.29% | 0 | 1 |
| the GPU and SwiftShader | 0.42% | 15 pixels | 72 |

SwiftShader's larger differences are on the cube's silhouette (136 of the 146 pixels off by more than 8): the shading
agrees, and the rasterizers cover an edge's MSAA samples differently. A frame of the flat-shaded cube is about 2.3 KB as
a PNG. FLIP, the perceptual metric decided for the reference machines (rendering § Decided, area 5), was not run: it is
not installed here.

## 10. GFX-1's part 3 question, measured

Measured 2026-11-15, kyoten's twenty-seventh session, before the question was asked: how the library's own shader
functions reach a material compiled to WGSL at run time, since a material is a typed node graph (GFX-1's question 2) and
WGSL has no imports. On kama 0.9.956 (`.scratch/gfx1-part3/`, its `FINDINGS.md`), this machine.

**What the engines do** (read 2026-11-15):
- **three.js r187's TSL** holds its BSDFs as node functions (`Fn(..., layout)`), and its builder emits each function a
  material reaches once per shader stage (`FunctionNode.generate`: *"The includes and the function code are generated
  once per builder and shader stage, further calls only need the function name"*). A program's own WGSL joins through
  `wgslFn(code, includes)`.
- **Bevy 0.20** removed naga_oil and links WESL **at run time in the shipped game**: `ShaderCache::get` (0.20.1) keys on
  the pipeline's shader defs and calls `wesl::compile` on a miss, the defs becoming WESL features. wesl-rs' `wesl` crate
  says to link in `build.rs` *"unless your WGSL code must be assembled at runtime"*; its default strips to what the
  entry points reach and mangles names by their path (`Escape`).
- **Unity and Unreal** compile their variants offline, at build or cook time; **Godot** compiles pipelines at load time
  (bakes them at export since 4.5).

**One material, its library functions held two ways.** Lambert diffuse plus three.js's GGX specular (`F_Schlick`,
`V_GGX_SmithCorrelated`, `D_GGX`, `BRDF_GGX`, `BRDF_Lambert`), the material's graph in typed nodes either way:
- **(A) typed-node functions in kama**, a function a value whose body is a node expression over its parameters, as TSL's;
- **(B) WGSL text with includes**, as `wgslFn`'s.

Each route's WGSL compiled with no message and no validation error in Edge (Dawn, the AMD RDNA 3 GPU) and Firefox 160
(naga), and run in a compute shader over three inputs both gave the same nine values exactly. On the web, release, brotli
-q 11, wasm plus JS:

| Build | Code | Over neither |
|---|---|---|
| neither route: the node machinery, strings and float formatting any material compiler carries | 21,762 B | |
| (A) typed | 42,149 B | 20,387 B |
| (B) table | 40,162 B | 18,400 B |
| both | 44,111 B | 22,349 B |

What each route adds on its own, five functions and their linker: **(A) 3,949 B, (B) 1,962 B.** A material's link,
natively in release and building the library's functions each time: (A) about 42 µs, (B) about 6.4 µs (taken beside a
mutation run, so an order of magnitude).

**(C) a WESL linker at run time** is a WGSL parser and linker: wesl-js 0.7.31 is 127,915 B minified and 39,206 B gzip
(bundlephobia), and wesl-rs-web 0.6.0's wasm 4,034,088 B with naga, both read by the research agent and not re-measured
here. None is in kama.

**Found on the way: KY-59.** An overloaded operator whose operand is a node passed by value releases it twice
([KAMA_GAPS.md](../KAMA_GAPS.md)), so `RECIPROCAL_PI * diffuseColor` and `a * a` freed nodes a function still held. The
probe hands operators a temporary (`a.again()`). Typed nodes are the decided material API, so part 3 needs it fixed.

## 11. The engine-facing render surface: what GFX-21 and step 9 rest on

Read 2026-11-27, the fifty-third session, for [rendering.md](../design/rendering.md) § The questions for step 9's kyoten
half and `@kama/graphics`' GFX-21 (its ROADMAP_DETAIL.md § GFX-21). One research agent read the sources below. The
claims the questions rest on were then fetched again here by curl and read at the line, each marked *Checked*;
*(unchecked)* marks a claim taken from the agent's one reading. Unreal's source is not public, so its claims come from
Epic's pages, most of which load only as search-index snippets, and are marked so.

| Source | Pinned at |
|---|---|
| Godot | `godotengine/godot` master `7c97c29` (2026-11-26) |
| Bevy | `bevyengine/bevy` main `5c485c4` (2026-11-26; the latest release is 0.20.1) |
| Unity Entities Graphics | 1.5.0, through `needle-mirror/com.unity.entities.graphics`, an unofficial copy of the published package |
| Unity BatchRendererGroup | docs.unity.com's current manual and script reference |
| Unreal Engine 5 | Epic's documentation, 2026-11-27 |

**Each gives a renderable a stable id in a table the renderer owns, and registers meshes and materials apart.**
- Godot: `instance_create` hands back a RID, set with `instance_set_base`, `_scenario`, `_transform`, `_visible` and
  `instance_geometry_set_material_override`, freed by `free_rid` (`servers/rendering/rendering_server.h`). Off the
  render thread each setter is queued on its command queue and run at the frame. Lights, cameras, environments and
  viewports are RIDs of their own (`directional_light_create`, `camera_create`, `environment_create`,
  `viewport_create`). *(unchecked, but the setter's name is checked below)*
- Bevy: an entity marked `SyncToRenderWorld` gets a render-world twin, spawned and despawned with it
  (`bevy_extract/src/sync_world.rs`), and its mesh holds a stable slot in a persistent input buffer
  (`bevy_render/src/batching/gpu_preprocessing.rs`). *(unchecked)*
- Unity: `BatchRendererGroup.RegisterMesh` and `RegisterMaterial` hand back ids, and `AddBatch` a batch over a
  `GraphicsBuffer` the program fills itself, instance by instance, `unity_ObjectToWorld` and the rest named in its
  metadata. *(unchecked, from the manual)*
- Unreal: primitives are placed in "a scene-wide primitive data buffer called GPUScene", indexed by `PrimitiveId`.
  *(Epic's mesh-drawing-pipeline page, unchecked)*

**What counts as a change, and how changed records reach the GPU.**
- *Checked:* Godot compares values. `RendererSceneCull::instance_set_transform` returns when the new transform equals
  the old ("Must be checked to avoid worst evil.", `renderer_scene_cull.cpp:1024-1025`), and otherwise queues the
  instance for the frame's update.
- Unity's Entities counts write access per whole chunk: "The change version is updated even when another job or system
  that has declared write access to a component does not actually change the component value" (`ArchetypeChunk.DidChange`'s
  docs, Entities 1.3). Entities Graphics copies a chunk's property to the GPU when the chunk is new, reordered, or
  `DidChange` since its last run (`EntitiesGraphicsChunkUpdate.cs`). *(unchecked)*
- *Checked:* Bevy uploads sparsely, and whole above a share. `SPARSE_UPLOAD_THRESHOLD` is `0.15`: "The fraction of the
  buffer that may be changed before we fall back to full reupload … obtained experimentally by testing very large scenes
  and roughly matches the values used by other engines that perform sparse buffer updates"
  (`bevy_render/src/render_resource/sparse_buffer_vec.rs:97-103`); below it the changed slots are scattered into the
  buffer by a compute shader (`SparseBufferUpdatePipelines`, in the same file).
- Entities Graphics scatters too, through its `SparseUploader`, a compute shader over upload buffers written with
  `LockBufferForWrite` (`SparseUploader.cs`). *(unchecked)* Unreal's GPU Scene uploads its dirty primitives together
  (`FGPUScene::UpdateInternal`'s `PrimitivesToUpdate`, from a third-party excerpt; an Epic reply of May 2025 names
  `FGPUScene::UploadGeneral()`). *(unchecked)*
- Godot's Forward+ is the exception: it writes every listed instance's record each frame into a mapped buffer
  (`render_forward_clustered.cpp`'s `_fill_instance_data`). *(unchecked)*

**Who keeps the previous matrix, for motion vectors.**
- *Checked:* Godot's renderer does. On an instance's first transform change in a frame it copies the old one into
  `prev_transform` (`render_forward_clustered.cpp:5055-5057`), sets it equal to the transform once it stops moving
  (`:1118-1119`), and writes both into the instance's record (`:847`). `instance_teleport(RID)` resets it
  (`rendering_server.h:753`), so a teleport draws no motion.
- Bevy's GPU path reads the old matrix from the entity's slot into a previous-input buffer each frame
  (`bevy_pbr/src/render/mesh.rs`). Unity's Entities keeps `unity_MatrixPreviousM` as a component its
  `MatrixPreviousSystem` copies after the upload. Raw `BatchRendererGroup` leaves it to the program. *(unchecked)*

**What the extract copies.** *Checked:* Bevy's `#[derive(ExtractComponent)]` copies a component into the render world
as itself: the derive writes `type Out = Self` and `Some(item.clone())` (`bevy_extract/macros/src/extract_component.rs:94,
97`); Bevy makes types of its own where it derives something, such as a view's matrices (`ExtractedView`) or a mesh's
GPU record (`MeshInputUniform`). *(the second clause unchecked)*

**Large worlds.** Unreal draws each view in translated world space, relative to its camera's `PreViewTranslation`, and
HDRP's camera-relative rendering, on by default, does so per camera (Epic's and Unity's pages). Godot offers a
`precision=double` build and splits each instance's origin into a float and its remainder for the GPU
(`render_forward_clustered.cpp:855-857`, *checked* as read for the previous matrix). Bevy has nothing built in.

**What a view hands back.** None of the four hands a program the projection a view was drawn with: Godot's picking is
`Camera3D::project_ray_origin` in its scene layer, Bevy's `Camera.computed` holds the matrices in the main world, and
Unity's is `Camera.ScreenPointToRay`. *(unchecked)* kyoten's `DrawnView` comes back from the platform instead, since only
the platform knows the size it drew (input.md § Decided, 2026-11-26).
