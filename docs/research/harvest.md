# Harvest: what kyoten could take from the peers' code

Research for KYR-2, made 2026-11-01. The owner decided that kyoten starts from the code of three of their own kama projects,
"at the very least great references", while moving toward generic and component-driven
([../design/architecture.md](../design/architecture.md) § Decided). This is the inventory that decision needs: what
exists, what game-shaped assumptions each piece carries, and what making it generic would cost. **It decides nothing.**

Surveyed read-only, at these HEADs:

| Repo | HEAD | Date | kama pin |
|---|---|---|---|
| `friendly-fire-department` (**FFD**, 2D) | `77a2604` | 2026-10-13 | 0.9.577 (`.kama-version:1474`) |
| `the-mallow-man` (**TMM**, 3D) | `70fe7ef` | 2026-10-28 | 0.9.667 on Windows (`.kama-version:16-20`); packages say `>=0.9.530` |
| `cosmic-forge` (**forge**) | `f9c182e` | 2026-11-01 | 0.9.765 (`.kama-version:4`); packages say `>=0.9.667`, `render` `>=0.9.675` |

kyoten is on 0.9.803 (`engine/kama.json` says `>=0.9.793`). TMM's two uncommitted edits (`game/src/camerakit.kama`,
`game/src/roundplay.kama`) were not considered.

Pointers are relative to `C:\Users\Matt\Documents\`, with line numbers as read today. Sizes are lines of `.kama` under
a package's `src/` (`wc -l`) unless a row says otherwise; C, C++, Objective-C and JS are counted apart. *(inferred)*
marks a judgement, not something the code or its docs state. This builds on
[peer-games.md](peer-games.md) (how the games work) and [cosmic-forge.md](cosmic-forge.md) (what forge is) and does
not repeat them; § *Corrections* lists where the code now says otherwise.

## Summary

- **Only FFD's pieces have a proven web leg.** Its platform header, Web Audio device, DOM UI, browser WebSocket
  client and fixed-point Opus all build and run on wasm32, checked in real browsers (168 `check-web` and 328
  `check-net` checks, `friendly-fire-department/docs/ROADMAP.md:67-69`). TMM's engine "has never been built for the
  browser here", and "Jolt and opus have no WASM builds" (`the-mallow-man/docs/CHARACTER_TOOL.md:74-75`): its
  renderer, physics, netcode, voice and Steam are native only. forge's `render` is the reverse, web only, with its
  native leg stubbed (`cosmic-forge/render/src/view/canvas_native.kama:1-3`). No donor has a 3D renderer on both legs.
- **The renderers keep their state in module statics.** FFD's `gfx::gpu` has 16 and TMM's has 63
  (`friendly-fire-department/gfx/src/gpu/gpu.kama:147-236`, `the-mallow-man/gfx/src/gpu/gpu.kama:147-293`). That was
  forced by a kama limit fixed in 0.9.537 and kept by choice since (`friendly-fire-department/docs/SPEC.md:806-830`).
  A static is per isolate, so it blocks parallel Output and a second view *(inferred)*. forge's `render` has none: its
  device, readback and mips are `type resource`s.
- **TMM's 3D renderer is shaped like its one scene.** The 1,040-byte frame uniform has exactly one moon, one
  flashlight, one campfire, one lantern and one lake (`the-mallow-man/engine/src/scene/frame.kama:15-60`). The
  showpiece shader is the Mallow Man's own material (`gfx/src/render/shaders.kama:2144-2470`). The techniques (tiers,
  TAA, FSR 1, clustered lights, GTAO, froxel fog, bench budgets) are the reusable part, not the frame.
- **FFD's `engine::phase` is the cheapest high-value piece**: 874 lines, no dependencies, no statics, determinism
  proven on five legs. But `InputFrame` is FFD's controller (2D move and aim, an `accusation` seat, eight seats, a
  24-byte wire; `engine/src/phase/input.kama:89-119,246`), and the four-phase *driver* is game code, `sim::World.stepAll`
  (`sim/src/world.kama:2249-2273`). The clock, RNG and hasher move nearly verbatim; the input record and the driver do
  not *(inferred)*.
- **The netcode is less reusable than its size says.** FFD's `engine::net` (7,395 lines) is socket-free and tested, but
  its tick wire carries FFD's own messages (`Vote`, `Say`, `Voice`, `Ready`; `engine/src/net/tick.kama:401-402`). TMM's
  rollback lives in `play` (its game-side netcode is about 9,500 lines), tied to its `Round` and Jolt
  (`play/src/netpredict.kama:1-20`). `net`'s own snapshot, prediction and interpolation are E5 spike code the game no
  longer imports. TMM's mirror sends raw struct bytes, so "a wasm build could never join" (`docs/M3_PLAN.md:27-28`),
  and its UDP cipher is a stub (`net/src/cipher.kama:1-4`).
- **UI is already generic and published.** `@kama/ui` (MIT OR Apache-2.0; the DOM on the web, RmlUi natively) grew out
  of FFD's `ui`/`uidoc` and names no game. TMM uses 0.4.0 and forge 0.6.0. FFD still carries its own older copy.
- **Where two copies exist, none is ahead on everything.** TMM's are ahead on native features, FFD's on the web leg,
  and forge's on API shape (see § *Overlap*).
- **Nobody has CI.** Every gate in all three repos is a local script (`tools/gates`, `tools/test`, `check-*`); none
  has a `.github/`. FFD's container (`Dockerfile`, `tools/cdev`) is the nearest thing to a reproducible leg.
- **Porting is a real cost for FFD's code.** FFD is pinned at 0.9.577, 226 versions behind kyoten. forge's move from
  0.9.667 to 0.9.758 alone touched 29 files (Poller's API, `ExitStatus`, `find` returning `Optional<isize>`, a
  discarded `Result` became an error; commit `84c0684`).

## The overview

"Game-shaped" is how much of the piece names or assumes its game; "cost" is the cost of making it generic, not of
copying it. Every cost is a judgement *(inferred)*; each section says why.

| Piece | Source | Size (kama + C/JS) | Game-shaped? | Cost | Feeds |
|---|---|---|---|---|---|
| Frame core: clock, RNG, hash, input log, countdown | FFD `engine::phase` | 874 | the input record and seat count | small | KYR-6, KYR-12, KYR-46 |
| Input vocabulary and fold | TMM `engine::input` (FFD's, extended) | 1,576 | no; binds live in game code | small | KYR-8 |
| Platform header (window, surface, keys, mouse, pads) | FFD `ffd_platform.*`; TMM `tmm_platform.*` | 166 + 1,398 C; 225 + 1,874 C | names only; one-window, file-static C state | medium | KYR-8 |
| WebGPU bindings generator | forge `render/tools/wgpugen` | 1,019 | no | small | KYR-9 |
| GPU device, frame loop and capture | TMM `gfx::gpu`; forge `render::gpu` | 1,873 + 28; 3,044 | TMM: statics and its renderer's options | medium | KYR-9 |
| 2D renderer | FFD `engine::render` + `gfx::render` | 3,079 + 1,613 | fixed 1440×810 design size, heat haze, FFD's fonts | medium | KYR-49, KYR-47 |
| 3D renderer | TMM `engine::scene` + `gfx::render` | 6,603 + 13,403 | heavily: the frame is TMM's scene | large | KYR-9 (as reference), KYR-48 |
| glTF viewer renderer | forge `render` | 7,391 + 189 JS | no; web only | medium | KYR-9, KYR-10, KYR-14, KYR-29 |
| glTF, KTX2 and images | TMM `engine::gltf`, `render::ktx2`; forge `render::gltf`, `anim` | 6,617 + 482; 1,924 + 405 | TMM: its art contract's node names | medium | KYR-10 |
| Audio device, synth, mixer | FFD `audio` + `engine::audio`; TMM `audio` | 495 + 772 C/JS, 2,085; 2,923 | FFD's cues and music; TMM: device lives in `voice` | medium | KYR-15 |
| Voice, Opus, speech | FFD `engine::voice`, `opus`, `speech`; TMM `voice` | 1,958, 226 + 214 C, 196 + 363 C; 3,802 + 610 C | TMM: singing detector, pitch-shift roles | medium | KYR-15, KYR-18, KYR-47, KYR-48 |
| UI | `@kama/ui` 0.4.0 (in TMM's deps); FFD `ui`, `uidoc` | 3,627; 938 + 1,891 C++/JS, 459 | no (`@kama/ui`) | small | KYR-16 |
| Lockstep netcode, rooms, relay | FFD `engine::net` + `server` | 7,395 + 1,392 | the tick wire's messages, 8 seats, `FFD-` names | medium | KYR-18, KYR-45, KYR-46 |
| Snapshot and rollback netcode, transports | TMM `net` + `play/src/net*` | 8,080 + 9,495 | rollback is `Round`- and Jolt-bound | large | KYR-18 |
| Physics (Jolt) | TMM `physics` + `engine::gltf::collision` | 1,878 + 37 C++, 1,112 | layer names, one world per thread | medium | KYR-17 |
| Steamworks | TMM `steam` (FFD's spike, extended) | 347 + 909 C | no; Spacewar default app id | small | KYR-19, KYR-20 |
| Settings, args, dev gating, chat | FFD and TMM `engine` | 121–639 each | settings paths name each game | small | KYR-21, KYR-23 |
| forge's `http`, `jobs`, `jsonvalue`, `webnet` | forge | 1,729, 421, 999, 263 | no | small to replace | KYR-26, KYR-29, KYR-45 |
| Test and dev tooling | FFD and TMM `tools/`, `tests/`, forge `render/check` | scripts | per-game flags | small to medium | KYR-13, KYR-12, KYR-14, KYR-26 |
| Shipping tooling | FFD `tools/bundle-*`, `sign-mac`, `check-licenses`, `gen-credits`, `docs/LICENSES.md` | scripts | names each game | medium | KYR-21, KYR-39 |

## 1. The frame core: FFD's `engine::phase`

**Where.** `friendly-fire-department/engine/src/phase/`: `clock.kama` (166), `rng.kama` (160), `hash.kama` (110),
`input.kama` (353), `countdown.kama` (85). 874 lines, kama 0.9.577.

**What it does.** A fixed-step clock that says how many ticks are owed and the interpolation `alpha`, clamping and
counting discarded time (`clock.kama:1-36,108-149`). xoshiro256\*\* seeded through SplitMix64, all `uint64` so nothing
traps (`rng.kama:1-31`). FNV-1a 64 fed field by field (`hash.kama:1-29,43-109`). One tick's settled input
(`InputFrame`), a fixed-capacity log of frames plus the seed, and a per-roster `TickInput` (`input.kama:89-280`).
Tick-counted deadlines (`countdown.kama:1-18`). How FFD uses them is [peer-games.md](peer-games.md) § 1-2.

**Game-shaped assumptions.**
- `InputFrame` is FFD's controller: `buttons`, a 2D `moveX/Y`, a 2D unit `aimX/Y`, and `accusation`, a crew seat for
  FFD's vote (`input.kama:89-119`). The aim-as-unit-vector choice is argued from FFD's prototype (`input.kama:69-88`).
- `INPUT_MAX_SEATS = 8`, chosen because the presence mask is one wire byte and FFD's crew is eight
  (`input.kama:227-246`). `INPUT_DEPARTED` is bit 31 of `buttons` (`input.kama:248-260`).
- The phase **driver** is not here. `Input → Update → Constraints×N → tick++` is `sim::World.stepAll`
  (`sim/src/world.kama:2249-2273`) and the frame order is in `game/src/game.kama:10282-10283`. What the package gives
  is the parts, not a scheduler.
- `PhaseRates` has one fixed rate plus an iteration count; sub-rates are the game's tick arithmetic
  (`clock.kama:18-26,40-56`).
- No module statics (a grep of `engine/` finds none), and `engine/kama.json` declares only `@kama/sodium`.

**C/C++ dependencies.** None; `calloc`/`free` from `<stdlib.h>` (`input.kama:58-60`).

**Overlap.** TMM took only the RNG, as audio's own stream (`the-mallow-man/audio/src/rng.kama`; `docs/PROVENANCE.md:164`).
TMM's tick loop is hand-written in `game/src/roundplay.kama`. FFD's is the only version.

**Cost to make generic: small** *(inferred)*. The clock, RNG, hasher and countdown name nothing and move as they are,
plus a port to 0.9.803. The input record is the real work: a generic engine needs an input record a game defines (or
one per component), with its wire size fixed across legs (`int32`, never `isize`, `input.kama:109-117`), and a
roster size that is not FFD's eight. The driver is written fresh against whatever KYR-7 decides. FFD's pinned
world-hash literals (`docs/SPEC.md:2495-2501`) are the acceptance test for KYR-46 only if the RNG stream and hash
order are kept bit for bit, since "changing the RNG stream invalidates every recorded log" (`docs/SPEC.md:1755-1759`).

**Feeds** KYR-6, KYR-12, KYR-27, KYR-46.

## 2. Input: the event vocabulary and the fold

**Where.** FFD `engine/src/input/` (`event.kama` 545, `state.kama` 653, `tokens.kama` 250; 1,448). TMM's copy
`the-mallow-man/engine/src/input/` (1,576).

**What it does.** Key and button codes keyed to DOM `code`, pad identity as `vendor << 16 | product` with
`padBrandOf` in kama, an event queue folded into `InputState` (levels, edges, axes, dead zones), and text tokens for
binds in a settings file (`friendly-fire-department/docs/SPEC.md:391-410,467-533`). The bind table that turns state
into an `InputFrame` is game code (`sim/src/input.kama`; TMM `play/src/binds.kama`).

**Game-shaped assumptions.** Few. FFD's state has no per-frame mouse delta; TMM added `MouseDelta`, look accumulators,
`F1`–`F4`, and `pressSpeaking` for a Deck's gyro (`the-mallow-man/docs/PROVENANCE.md:26-27,195-197`).

**Overlap.** TMM's is a superset; FFD's input files are unchanged since TMM copied them at `f8a4265` (FFD's later
commits touch only `engine/src/net` and the kama bump; `git log f8a4265..77a2604`). **TMM's is ahead.**

**Cost: small** *(inferred)*. It already names no game. It needs a home beside the platform seam, a touch or pointer
model if mobile and XR come (KYR-31, KYR-34), and the port.

**Feeds** KYR-8.

## 3. The platform header: window, surface, keys, mouse and pads

**Where.**
- FFD `gfx/src/platform/`: `ffd_platform.h` (804), `ffd_platform.c` (528), `ffd_platform_mac.m`, `platform.kama` (166).
- TMM `gfx/src/platform/`: `tmm_platform.h` (929), `tmm_platform.c` (877), `platform.kama` (225).
- forge `render/src/view/canvas_web.kama` (73) with `render/web/kama_render.js` (147), and a native stub.

**What it does.** One C header with the web half as `static inline` over `<emscripten/html5.h>` and the native half in
a `.c` over GLFW 3.4, compiled by kama through `csources` (`friendly-fire-department/docs/SPEC.md:391-466`). Only C
scalars cross; kama polls. The native block declares 14 functions in FFD (`ffd_platform.h:788-801`) and 31 in TMM
(`tmm_platform.h:896-926`).

**Game-shaped assumptions.**
- Names only (`ffd_`/`tmm_`). The one-caller rule: the header's file-static state is safe because exactly one kama file
  says `extern "ffd_platform.h"` (`SPEC.md:432-446`). That makes it **one window per process** *(inferred)*.
- FFD's web half maps keys from `KeyboardEvent.code`, binds keys to the window and the mouse to `#canvas`
  (`SPEC.md:452-462`). That assumes the game owns the page. forge's canvas lives inside a page element, sized by a
  `ResizeObserver`, with no window key listeners "so a page's fields keep their keys"
  (`cosmic-forge/render/README.md:22-25`), which suits a tool or an editor page.
- TMM's Windows thread timer that keeps ticking during the OS's modal move/size loop
  (`the-mallow-man/gfx/src/platform/tmm_platform.c:582-610`) is native-only and general.

**C/C++ dependencies.** GLFW 3.4 (zlib), vendored for macOS and Linux, MSYS2's static `libglfw3.a` on Windows
(`friendly-fire-department/gfx/kama.json` `csources`, `select.WINDOWS`); emscripten's html5 on the web.

**Overlap.** TMM's native half is a superset: raw-mouse pointer lock, window placement, focus, a recreated surface,
modal ticks, pad mapping loads and pad names (`tmm_platform.h:909-926`). But its web half "gains a
`pointerlockchange` callback and `movementX/Y` accumulation (written, **not verified** in E1)"
(`the-mallow-man/docs/PROVENANCE.md:59`), and TMM never builds for the web. **Natively TMM is ahead; on the web FFD's
is the only one proven.** forge's is a third, page-embedded shape.

**Cost: medium** *(inferred)*. The code is small, but a generic layer needs several windows or canvases (an editor,
a tool page, XR), a way for a platform package to supply its own implementation (the N-platform rule,
[../design/target-platforms.md](../design/target-platforms.md)), and a decision on kama's designed `@kama/window`
(KR-26), whose design (html5 callbacks with no JS library, HID keys matching DOM `code`, an event ring, a headless
window for tests) is close to FFD's header ([kama-for-engines.md](kama-for-engines.md) § 3).

**Feeds** KYR-8, and through it KYR-11.

## 4. WebGPU bindings: `wgpugen`

**Where.** FFD `wgpugen/src/main.kama` (1,227; output `gfx/src/gpu/webgpu.gen.kama` 2,484 + `webgpu_constants.gen.c`
630); TMM's is identical apart from one comment line (`diff`). forge `render/tools/wgpugen/src/main.kama` (1,019;
output `render/src/gpu/webgpu.gen.kama` 2,312).

**What it does.** Reads `webgpu.h` with a line-based parser and writes 199 `extern fn`s (FFD's docs say 201), each
behind a de-prefixed wrapper, plus the structs, enums and constants, so every C declaration agrees by construction
(`friendly-fire-department/wgpugen/src/main.kama:1-40`).

**Game-shaped assumptions.** None.

**C/C++ dependencies.** wgpu-native's `webgpu.h` (v29.0.1.1, BSD-3 header; the library `MIT OR Apache-2.0`) and
emdawnwebgpu's from emsdk.

**Overlap.** FFD's reads one header and takes the web leg's differences from a hand-kept `native-only.txt`, and it also
binds wgpu-native's own `wgpu.h` extras (`webgpu.gen.kama:1030`). forge's reads **both** headers, gates a declaration
present in only one to that leg, fails on any function or constant the two declare differently, and stamps both
headers' sha256 in the output (`cosmic-forge/render/tools/wgpugen/src/main.kama:1-20`). **forge's is ahead**, but it
drops the `wgpu.h` extras TMM relies on (`wgpuQueueGetTimestampPeriod`, which TMM declares by hand in
`gfx/src/gpu/period_native.kama:7-17`).

**Cost: small** *(inferred)*. Take forge's, add a third input for `wgpu.h`'s native extras, and keep FFD's
`check-wgpu-constants`, which asserts every constant against the real header on both legs.

**Feeds** KYR-9. This is also exactly what kama's `@kama/gpu` (KR-25) would replace, if it is built.

## 5. The GPU device, the frame loop and capture

**Where.** FFD `gfx/src/gpu/gpu.kama` (1,647). TMM `gfx/src/gpu/gpu.kama` (1,873) and `period_*.kama` (28). forge
`render/src/gpu/` (`device.kama` 241, `resources.kama` 146, `mips.kama` 154, `readback.kama` 123, `image_*.kama`;
3,044 with the bindings).

**What it does.** The adapter and device handshake through `fnptr` callbacks, surface configuration, the frame loop and
its guards, and one-shot frame capture to bytes. FFD's frame loop holds the invariant "must never return without
either presenting or sleeping" (`friendly-fire-department/docs/SPEC.md:63-100`), learned from a loop that panicked a
machine twice.

**Game-shaped assumptions.**
- **Module statics.** FFD: the batcher, the renderer, fonts, ramps, the scene callback (`gpu.kama:147-236,445-446`). TMM: the
  renderer, lights, decals, emitters, "screen goo", quality, timing and capture state, 63 in all
  (`the-mallow-man/gfx/src/gpu/gpu.kama:147-293`). Both are one device, one surface, one renderer per process.
- FFD opens its window at `DESIGN_W × DESIGN_H` (1440 × 810) times `FFD_WINDOW_SCALE` (`gpu.kama:180-181,1615-1637`).
- TMM's `gpu.kama` is "trimmed to App, adapter/device handshake, `configureSurface`, the frame-loop guards and
  one-shot capture", then grew device-lost and uncaptured-error callbacks, timestamp queries, a late swapchain acquire
  (−1.3 ms mean) and a settle on resize (`the-mallow-man/docs/PROVENANCE.md:29`; `docs/RENDERING.md:124`).

**Overlap.** forge's `Gpu` is TMM's handshake "its game's features and renderer taken out"
(`cosmic-forge/render/src/gpu/device.kama:12-13`), rebuilt as a `type resource` whose callbacks write into a heap
block it owns, polled by `phase()`. **forge's has the shape a library wants; TMM's has the native features**
(timestamps, device loss, late acquire) and the only proven native leg.

**Cost: medium** *(inferred)*. The work is restructuring TMM's statics into owned values (forge shows the shape) and
giving forge's device a native leg. Native command recording on several threads needs that done first.

**Feeds** KYR-9, KYR-22.

## 6. FFD's 2D renderer

**Where.** `friendly-fire-department/engine/src/render/` (3,079: `batch.kama` 1,177, `font.kama`, four generated glyph
tables, `tess.kama`, `transform.kama`, `ramp.kama`, `pattern.kama`, `ppm.kama` 452) and `gfx/src/render/renderer.kama`
(1,613). The letterbox and the controller-glyph art are in `view/src/viewport.kama` (162) and `view/src/keycap.kama`
(233), the only two `view` files that do not import `sim` (`grep -c sim::`).

**What it does.** A GPU-free batcher with a transform stack, every shape FFD's canvas prototype draws (quads, arcs,
rounded rects, quadratics, radial gradients) and MSDF text; then four pipelines (premultiplied, MSDF, blit, haze) and
three passes through two offscreen targets, so the world renders into a texture before it reaches the window
(`docs/SPEC.md:640-703,1026-1035`). The scene arrives through a `fnptr SceneFn(ref Batcher, …)` the game supplies
(`SPEC.md:1046-1060`).

**Game-shaped assumptions.**
- One virtual resolution, 1440 × 810, scene-wide (`SPEC.md:1112-1130`; `gpu.kama:180-181`).
- The haze pass and its heat mask are FFD's fire shimmer; the glow and fog ramps are FFD's fog of war
  (`gpu.kama:214-221,995`).
- The fonts (Inter, Archivo Black, JetBrains Mono) are baked into kama glyph tables (`engine/src/render/glyphs_*.kama`).
- State in `gfx` statics (§ 5). The batcher has a fixed capacity and counts what it drops (`Batcher.droppedTotal`).

**C/C++ dependencies.** None beyond the GPU layer; the fonts are OFL 1.1 (`docs/LICENSES.md`).

**Overlap.** TMM took its MSDF text path into a debug overlay (`the-mallow-man/engine/src/render/textbatch.kama`,
`gfx/src/render/overlay.kama`; `docs/PROVENANCE.md:193-194`) and its pipeline helpers into a general `PipelineSpec`
(`gfx/src/render/pipeline.kama`; `PROVENANCE.md:30`). FFD's is the only 2D renderer.

**Cost: medium** *(inferred)*. The batcher and primitives are already GPU-free and named for nothing. The owner's
decision that 2D is a layer, onto a screen or into a texture ([../design/rendering.md](../design/rendering.md)
§ Decided), fits FFD's offscreen-first passes, but the fixed design size, the haze and ramps, and the statics would
go, and the batcher would need to draw into a target the 3D renderer composes.

**Feeds** KYR-49, then KYR-47 (FFD on kyoten).

## 7. TMM's 3D renderer

**Where.** `the-mallow-man/engine/src/scene/` (6,603: `frame.kama` 722, `film.kama` 2,094, `quality.kama`, `cluster`,
`cullgrid`, `froxel`, `taa`, `fsr`, `exposure`, `decals`, `particles`, `grass`, `foliage`, `light`, `camera`,
`mallowlook.kama` 345) and `gfx/src/render/` (13,403: `renderer3d.kama` 3,433, `shaders.kama` 3,330, `gpuscene.kama`
1,811, `pipeline.kama` 1,250, and one file per technique).

**What it does.** A forward renderer on WebGPU with four measured quality tiers (Steam Deck to RTX 4090): metal-rough
PBR, AgX tone mapping, bloom, cascaded shadows with PCSS, TAA, FSR 1, GTAO, clustered lights, GPU particles,
procedural decals, froxel volumetric fog, water with SSR, grass, ragdolls, instancing and a CPU culling grid. Each
technique has a cost in milliseconds on named hardware (`docs/RENDERING.md:1-130,576-600`). Renderer CPU is about
0.9 ms a frame.

**Game-shaped assumptions.** The most of any piece.
- The frame uniform is the campsite: `spotPos/Dir/Color` (the flashlight), `moonDir/Color`, `firePos/Color` (the
  campfire), `lampPos/Color`, `lake`/`lake2`, the sky's stars and moon disc (`engine/src/scene/frame.kama:15-60`).
- The Mallow Man's material is in the shared shader file (`mallowWgsl`, `gfx/src/render/shaders.kama:2144-2470`) and
  its constants in `engine::scene::mallowlook`. Decals are "the goo" (`engine/src/scene/decals.kama:1-12`).
- `film.kama` is the teaser's cut-list camera; `quality.kama`'s tiers name the game's hardware and its grass reach.
- 63 statics in `gfx::gpu` (§ 5). Never built for the web.

**C/C++ dependencies.** wgpu-native; FidelityFX FSR 1 ported to WGSL (MIT, `PROVENANCE.md:181-182`); the AgX fit from
three.js (MIT, `PROVENANCE.md:33`).

**Overlap.** forge calls its `render` "the-mallow-man's renderer ported and shaped as kyoten's render package would
be" (`cosmic-forge/docs/ROADMAP.md:27-31`). What it took is TMM's device, container, pipeline helpers and skin
sampling, not these techniques (§ 8).

**Cost: large** *(inferred)*. The techniques are reusable; the frame description, the light set and the material
system would have to become data the scene supplies (a light list, materials, environment), and the statics an owned
renderer. It is best read as the reference for *what to build and what it costs on a Deck*, with `tools/bench`'s
budgets (§ 19) as the bar.

**Feeds** KYR-9 (as reference), KYR-48.

## 8. forge's `render`: a glTF viewer on WebGPU

**Where.** `cosmic-forge/render/src/` (7,391: `gpu` 3,044, `gltf` 1,924, `anim` 405, `camera` 126, `pass` 1,261,
`view` 631) and `render/web/kama_render.js` (147). kama `>=0.9.675`. Skins and clips landed today in `76738e9`, after
[cosmic-forge.md](cosmic-forge.md) was written.

**What it does.** Reads a `.glb` strictly, shades glTF metal-rough (GGX, Smith, Schlick, a hemisphere with Karis's
analytic BRDF, Khronos PBR Neutral), plays skinned clips, orbits, and renders offscreen with a readback that measures
coverage and mean colour, so a headless check sees what was drawn (`render/README.md:1-107`). Attributes come from
storage buffers by vertex index, so a missing attribute needs no stand-in buffer.

**Game-shaped assumptions.** None. Its camera follows forge's rig convention and its key light follows the camera
(`README.md:54-57`), which are viewer choices.

**C/C++ dependencies.** wgpu-native header vendored (BSD-3); emdawnwebgpu on the web, which "links only as C++"
(CF-20, `README.md:109-118`).

**Overlap.** Ported from TMM at `45f15d4`: the glTF container and schema, the device handshake, readback, pipeline
helpers, the generator and the skeleton and clip sampling (`README.md:165-167`). It is the cleanest API of the three,
and the only one shaped as a library.

**Cost: medium** *(inferred)*. It is a viewer, not a scene renderer: one model, one key light, no shadows, no
post-processing, no instancing, and no native leg (its native canvas returns "the 3D view is in the browser for now",
`render/src/view/canvas_native.kama:24-31`). It is also forge's: kyoten taking it means a shared package or a fork,
which is [../design/rendering.md](../design/rendering.md) question 1 and content-pipeline question 5.

**Feeds** KYR-9, KYR-10, KYR-14 (the Three.js bar is close to its `Viewer` API), KYR-29.

## 9. Assets: glTF, KTX2 and images

**Where.** TMM `engine/src/gltf/` (6,617: `model.kama` 2,789, `anim.kama` 1,467, `collision.kama` 1,112, `water.kama`
521, `schema.kama` 412, `roles.kama` 171, `glb.kama` 145), `engine/src/render/ktx2.kama` (282), `tga.kama` (200),
`ppm.kama` (453). forge `render/src/gltf/` (1,924) and `anim/` (405). FFD's asset path (`engine/src/assets_native.kama`
66, `assets_web.kama` 14).

**What it does.** TMM: a level `.glb` as instanced meshes in shared pools, LOD groups, metal-rough materials whose
textures are **external** `assets/textures/<name>.ktx2` files linked by image name (`model.kama:1-12`); skeletons, a
crossfading animation player and springs (`anim.kama:1-12`). forge: the same container, read strictly, with embedded
PNG/JPEG maps and skins, refusing what it does not read with what and where (`render/README.md:58-82`). FFD: assets
beside the executable natively, embedded with `--embed-file` on the web.

**Game-shaped assumptions.**
- TMM's art contract decides render paths and collision by node names: `water_*`, `backdrop_*`, `*_collider`
  (`gltf/roles.kama:1-10`; `gltf/collision.kama:1-12`). `water.kama` is a camper wading.
- TMM's KTX2 reader takes RGBA8 and BC7 only, no supercompression (`render/ktx2.kama:14-21`). BC7 is a desktop format,
  so the web's size budget and a Quest would want Basis or ASTC *(inferred)*.
- TMM reads glTF through a typed schema because kama had no untyped JSON tree (KM-1, `docs/KAMA_GAPS.md`); std's
  `JsonValue` landed in 0.9.662 ([cosmic-forge.md](cosmic-forge.md) § 6).

**Overlap.** forge's reader is the strict, general one; TMM's has the scene-scale features (instancing, LOD, external
compressed textures, collision plans). **Neither is ahead overall**; they answer different jobs.

**Cost: medium** *(inferred)*. A union of the two: forge's strictness and embedded images, TMM's instancing, LOD and
KTX2, with the name-based roles turned into data a project declares. A texture format story for the web and Quest is
new work.

**Feeds** KYR-10, KYR-29.

## 10. Audio: device, synth and mixer

**Where.**
- FFD `audio/` (495 kama; `ffd_audio_native.c` 362, `ffd_audio_web.js` 150, headers) and `engine/src/audio/` (2,085:
  `synth` 812, `core` 375, `wav` 311, `sequencer` 191, `cues` 177, `biquad`, `mixer`, `mood`).
- TMM `audio/` (2,923: `synth` 1,130, `core` 740, `wav` 368, `space` 199, `bank` 151, `rng`, `biquad`, `mixer`) and
  `sfx/` (2,601, depends on `sim`).

**What it does.** FFD: a `type contract AudioSink` with two `@compileFor` devices; the seam is a **pull** on both legs,
miniaudio's thread natively and `pump()` from the frame loop on the web, which schedules `AudioBufferSourceNode`s
ahead of the cursor (`docs/SPEC.md:1415-1450`; `audio/src/ffd_audio_web.js:16-19,133`). Commands cross to the audio
thread on a lock-free ring (`engine::audio::AudioCore`). TMM: a stereo synth with sample voices, 32 voices, 16 loop
slots, ramped gains, positional playback and a listener (`the-mallow-man/docs/PROVENANCE.md:159-164`).

**Game-shaped assumptions.**
- FFD's `cues.kama` is the game's sound list (`SprayCrew`, `AxeOnBurning`, `Accuse`, `Extinguished`;
  `engine/src/audio/cues.kama:101-161`); `synth.kama:88` has one loop, `HoseHiss`; `sequencer.kama` and `mood.kama` are
  the game's chiptune and its fire-driven intensity.
- TMM's device is not in `audio`: miniaudio is compiled once, in `voice`, and `audio` depends on `voice`
  (`the-mallow-man/audio/kama.json`; `PROVENANCE.md:153-154`). No web leg ("no wasm gates", `PROVENANCE.md:139`).
- `sfx` (event to cue, footsteps by surface, ambience) is the game's, though its shape is a pattern.

**C/C++ dependencies.** miniaudio 0.11.25 (public domain or MIT-0), vendored in both.

**Overlap.** TMM's synth and mixer are ahead in features; FFD's device is the only one with a web leg. The AudioWorklet
route stays deferred in FFD (`audio/src/sink.kama:27-30`); kama 0.9.160 removed the flags that blocked it
([kama-for-engines.md](kama-for-engines.md) § 3).

**Cost: medium** *(inferred)*. Take FFD's two-backend pull seam and TMM's stereo synth, sample bank and spatial code,
drop both games' cue lists, and move the device out of `voice`. Web Audio as the browser's own mixer (the vision's
"use what the browser does best") is a different design from either, and is [../design/audio.md](../design/audio.md)'s
open question.

**Feeds** KYR-15.

## 11. Voice, Opus and speech

**Where.** FFD `engine/src/voice/` (1,958: `mix` 668, `jitter` 424, `gate`, `send`, `ulaw`, `upsample`, `levels`,
`meter`), `opus/` (226 + 214 C, libopus 1.6.1 vendored), `speech/` (196 + 363 C, whisper.cpp) and
`engine/src/speech/` (385). TMM `voice/` (3,802 + 610 C).

**What it does.** Mic capture as a push into a C ring, a send gate, Opus 20 ms frames, a per-speaker jitter buffer, a
mixer on the audio thread after the synth, and (FFD) push-to-talk whisper speech-to-text into the chat board, the
same funnel a quick-chat line uses (`docs/SPEC.md:3709-3716`). FFD's libopus is built
fixed-point, so packets and decoded samples are bit-identical on every leg, wasm included (`docs/SPEC.md:1551-1580`).

**Game-shaped assumptions.**
- TMM's `detect.kama` (1,373) is the Campfire Song's singing detector (`voice/src/detect.kama:1-5`), and `shift.kama`
  pitch-shifts by game role, "the squeaky Mallowling (up) and the Mallow Man's Roar (down)" (`voice/src/shift.kama:1-3`).
- FFD's proximity rule is one earshot function shared with what you see (`SPEC.md:3666`), keyed to its floors.
- TMM's voice owns the only miniaudio device and drops every wasm gate (`voice/src/device.kama:1-4`); libopus is a
  prebuilt archive (`voice/kama.json` `link: tmm_opus`).

**C/C++ dependencies.** libopus (BSD-3 with royalty-free patent licences), miniaudio, whisper.cpp + ggml (MIT) and the
`tiny.en` weights (MIT, 30.6 MB, fetched by SHA-256) (`friendly-fire-department/docs/LICENSES.md:180-182`).

**Overlap.** TMM's is ahead natively: FEC, stereo, spatial gain, device enumeration (`PROVENANCE.md:136-143`). FFD's is
the only one on the web, and the only one with speech.

**Cost: medium** *(inferred)*. Drop TMM's detector and role shifts (or make them plug-ins), keep FFD's fixed-point
`opus` package and `@compileFor` gates. Voice belongs with whatever transport KYR-18 picks.

**Feeds** KYR-15, KYR-18, KYR-47, KYR-48.

## 12. UI

**Where.** `@kama/ui` 0.4.0, read from TMM's installed copy (`the-mallow-man/game/.kama/deps/ui/`, 3,627 lines,
`MIT OR Apache-2.0`, repository github.com/cosmic-canopy/kama-ui). FFD `ui/` (938 kama, `ffd_ui_native.cpp` 991,
`ffd_ui_web.js` 421) and `uidoc/` (459). TMM's draw pass `gfx/src/render/uipass.kama` (590).

**What it does.** One set of RML documents: the browser's own DOM on the web, RmlUi natively, both checked against the
`UiHost` contract. Natively it records draw commands that the program's own renderer draws
(`.kama/deps/ui/README.md:1-30`). "Matt's own HTML/CSS engine replaces `@kama/rmlui` later, behind this same
contract."

**Game-shaped assumptions.** None in `@kama/ui`; its docs "never name these games"
(`the-mallow-man/docs/UI_PACKAGES.md:34-36`). FFD's copy carries `ffd_` names and the `focusHeld` disagreement between
backends that shipped an unstartable build (`friendly-fire-department/docs/ENGINE_TODO.md:20-60`).

**C/C++ dependencies.** RmlUi 6.3 (MIT) and FreeType 2.14.3 (FTL, never GPLv2), vendored by `@kama/rmlui` and
`@kama/freetype`; a C++ runtime natively.

**Overlap.** `@kama/ui` grew out of FFD's copy through TMM's (`UI_PACKAGES.md:1-12`). TMM switched at 0.4.0; forge uses
0.6.0 (`cosmic-forge/forgeui/kama.lock`). FFD has not switched; it is listed as step 2 (`UI_PACKAGES.md:94-102`).
**`@kama/ui` is ahead.** Note forge's port commit: "the published `@kama/ui` 0.5.1 does not build on 0.9.758"
(`84c0684`), so its versions move with kama's.

**Cost: small** *(inferred)*. Depend on it. kyoten writes the native draw pass (TMM's `uipass` is a 590-line example)
and decides how a UI layer relates to the 2D layers (rendering question 9). There is no GPU canvas element natively
yet (CF-22).

**Feeds** KYR-16.

## 13. Lockstep netcode, rooms and the relay (FFD)

**Where.** `friendly-fire-department/engine/src/net/` (7,395: `tick` 1,344, `relay` 1,056, `lockstep` 906, `secure`
632, `e2e` 493, `bytes` 448, `ws` 395, `router` 389, `rooms` 360, `lobby` 354, `handshake` 330, `hosting` 265, `raw`
209, `link` 159, `invite` 55) and `server/` (1,392).

**What it does.** Every file is bytes in, bytes out, no socket (`relay.kama:1-20`; `router.kama:1-14`). A lockstep
scheduler driven by four `fnptr` hooks into the world (`lockstep.kama:14-60`). A fixed-width tick wire, because KBIN
made a 24-byte frame 97 bytes (`tick.kama:1-14`). Rooms and routing as a pure function, used by the relay binary and
by a host routing its own room (FR-35, `hosting.kama:1-14`). A transport seam, `NetLink`/`NetPeers`
(`link.kama:1-20`). RFC 6455 server framing; the browser uses kama's `WsConnection` (`ws.kama:1-14`). Per-hop
encryption with a pinnable relay key, and an end-to-end room key the relay never holds (`secure.kama`, `e2e.kama`).

**Game-shaped assumptions.**
- The tick wire is FFD's protocol: `TickKind { Start, Frame, Closed, Hash, Vote, VoteClosed, SnapWanted, SnapChunk,
  Say, Voice, Ready }` (`tick.kama:401-402`), the `accusation` field (`:548-568`), `LEAVERS_STAND` "the crew member
  stands where they were left" (`:361-363`), and a frame sized for `INPUT_MAX_SEATS` (`:188`).
- Lockstep only: "Nobody predicts, nobody rolls back, and nobody snapshots" (`lockstep.kama:16-18`); input delay 8,
  hash every 60 ticks (`:92-149`).
- Names: `lobbyCodePrefix() "FFD-"` (`lobby.kama:136`), `"FFD relay key v1"` (`secure.kama:481`), the `FFD` magic
  (`raw.kama:58`).
- Reliable transports only (TCP and WebSocket); FEC and a UDP transport are deferred (`docs/SPEC.md:1575-1576`).
- No statics.

**C/C++ dependencies.** `@kama/sodium` ^0.5.0 (MIT) vendoring libsodium 1.0.20 (ISC) (`engine/kama.json`;
`docs/LICENSES.md`).

**Overlap.** The relay and routing have no TMM counterpart (TMM is listen-server only). The encryption is ahead of
TMM's, whose cipher is a stub. FR-42 is open: a browser host in a room of three or more is dropped
(`docs/ROADMAP.md:162`).

**Cost: medium** *(inferred)*. The sans-IO layers (`ws`, `secure`, `e2e`, `rooms`, `router`, `link`, `bytes`) are
close to generic. The tick wire and `lockstep` need the game's messages taken out and the roster size and input record
made the game's. The relay is a natural seed for KYR-45, since it already routes what it cannot read.

**Feeds** KYR-18, KYR-45, KYR-46.

## 14. Snapshot and rollback netcode, transports (TMM)

**Where.** `the-mallow-man/net/src/` (8,080: `steamfake` 1,348, `connection` 901, `steam` 901, `snapshot` 618,
`endpoint` 572, `udp` 526, `netprofile` 394, `xordelta` 384, `netsim` 268, `character` 269, `loopback` 226,
`transport` 220, …) and the game half in `play/src/net*.kama`, `roundwire.kama`, `lobby.kama` (9,495).

**What it does.** A `Transport` contract shaped after Steam's `ISteamNetworkingMessages`, with Steam, UDP and loopback
implementations (`net/README.md:19-34`); a socket-free connection layer with acks, RTT, reliable-ordered and
fragmentation (`endpoint.kama:1-8`); seeded network simulation and named profiles (`netprofile.kama:1-8`); an in-process
fake Steam (`steamfake.kama:1-14`); XOR delta coding of a byte array (`xordelta.kama:1-12`). In `play`, the host
mirrors the whole 17.5 KB `Round` and each client predicts by copying the authoritative tick, rewinding Jolt and
replaying its inputs through `stepRound` (`play/src/netpredict.kama:1-20`; `docs/M3_PLAN.md:6-66`).

**Game-shaped assumptions.**
- The rollback is in `play`, over `Round` and `JoltWorld.rewindTo`. The game uses only `Transport`/`GameLink`, the
  Steam and UDP transports, `xorRunEncode`/`Decode` and `ServerClock` from `net` (grep of `play/src`, `game/src`).
  `net`'s `snapshot`, `predict`, `interp`'s `InterpBuffer`, `character` and `input`'s `InputQueue` (about 1,550 lines)
  are the E5 spike's; `play/src/netinput.kama:74` says outright it is "not the spike's `net::InputQueue`". The
  README's opening still says the layer "has **not been integrated into the game**" (`net/README.md:1-6`).
- The spike's snapshot names the game's entities (camper, Mallow Man, Mallowling, cocoon, glob;
  `snapshot.kama:1-12`); the channels name its events (`transport.kama:35-39`).
- Raw struct bytes on the wire tie it to the native layout: "A wasm build could never join"
  (`docs/M3_PLAN.md:27-28`), refused by a layout fingerprint (`:40`).
- The UDP layer's encryption is stubbed (`cipher.kama:1-4`); Steam encrypts its own.

**C/C++ dependencies.** A 24-line UDP socket helper (`net/src/tmm_udpsock.c`); Steam's library through `steam` (§ 16).

**Overlap.** Complements FFD's: TMM has UDP, Steam, simulation and rollback; FFD has a relay, rooms, encryption and a
web client. Neither yet offers "lockstep and snapshots with rollback as patterns a game picks" (KYR-18).

**Cost: large** *(inferred)*. The transports, endpoint, net simulation, fake Steam and XOR delta are reusable as they
are. The rollback pattern has to be re-expressed over whatever the component store is, without raw-byte mirroring if
the web is to join, and with a physics world that can rewind.

**Feeds** KYR-18, KYR-48.

## 15. Physics: Jolt through joltc

**Where.** `the-mallow-man/physics/src/` (1,878: `world.kama` 1,195, `native/jolt.kama` 401, `types.kama` 282) and
`native/jolt_seam.cpp` (37). The level-to-collision plan is `engine/src/gltf/collision.kama` (1,112).

**What it does.** One `PhysicsWorld` owns every Jolt object; callers hold plain-data `BodyId`, `CharacterId`,
`RagdollId` (`world.kama:1-14`). Static level geometry, dynamic bodies, `CharacterVirtual`s, ray and shape casts,
swing-twist ragdolls. The C++ file pins layout assumptions with `static_assert`s and brings the C++ runtime
(`jolt_seam.cpp:1-37`).

**Game-shaped assumptions.**
- `Layer { Static, Moving, Character, Projectile, Ragdoll }` (`types.kama:34`).
- One thread owns a world; joltc has one process-wide temp allocator, so two worlds must not step concurrently
  (`world.kama:12-14`).
- `CROSS_PLATFORM_DETERMINISTIC` off, "because only the host simulates" (`docs/WORKING.md:77`); no web build:
  "Jolt and opus have no WASM builds" (`docs/CHARACTER_TOOL.md:75`), and `native/Makefile` builds Jolt natively only.

**C/C++ dependencies.** Jolt Physics v5.6.0 (MIT) and joltc `886e088` (MIT), built by `native/Makefile` as release
archives, not `csources`, so a debug game does not get an `-O0` Jolt (`native/Makefile:17-19`). joltc's CMake cache
silently disables x86 SIMD unless overridden (`:56-61`). KM-63: a `.cpp` in `csources` could not build on Windows
before 0.9.667.

**Overlap.** None; FFD has no physics solver (its Constraints phase is clamping, [peer-games.md](peer-games.md) § 1).

**Cost: medium** *(inferred)*. The wrapper is small and general; layers would become the game's. The open costs are
outside the code: a wasm build of Jolt, cross-platform determinism if lockstep must cover physics, and whether
physics is a Constraints-phase system or called inline as TMM does (KYR-17).

**Feeds** KYR-17.

## 16. Steamworks

**Where.** TMM `steam/` (`shim.kama` 347, `tmm_steam.c` 795, `tmm_steam.h` 114). FFD `steamspike/` (989 + 297 C) and
`game/src/ffd_steam.c` (344), `steam_native.kama` (593), `steam_web.kama` (21).

**What it does.** TMM loads Valve's `steam_api` flat API at run time (LoadLibrary/dlopen), so a build with no SDK still
builds and runs (`shim.kama:6-9`). It covers Networking Messages, lobbies, invites, persona, stats, achievements, rich
presence, the overlay and the on-screen keyboards (`shim.kama:11-22`; `docs/STEAM.md:8-191`).

**Game-shaped assumptions.** Few. App id 480 (Spacewar) as the default for runs Steam did not launch
(`shim.kama:16`). TMM's achievement tables are in `play`, not `steam`.

**C/C++ dependencies.** The Steamworks SDK 1.65 flat API, never committed; fetched by `tools/fetch-steamworks.sh`
(`the-mallow-man/docs/PROVENANCE.md:110-121`). It is proprietary, which fits KYR-19's "feature package".

**Overlap.** TMM's started from FFD's spike and is ahead (runtime loading, lobbies, stats, presence;
`PROVENANCE.md:110-129,250-254`). FFD has the overlay launch route (`tools/steam-game`) and host routing over Steam
in progress (FR-35 step D, `engine/src/net/hosting.kama:1-10`). Neither has had a two-account live run of Steam networking: "the two-account run this has never had"
(`the-mallow-man/steam/src/shim.kama:22`).

**Cost: small** *(inferred)*. Rename, publish as an optional package, and verify live.

**Feeds** KYR-19, KYR-20.

## 17. Settings, arguments, developer gating and chat

**Where.** FFD `engine/src/settings.kama` (284), `args.kama` (121), `dev.kama` (87), `chat/` (908). TMM
`engine/src/settings.kama` (639), `args.kama` (122).

**What it does.** FFD's settings are a `key = value` document that is its own store, so lines for absent hardware
survive (`settings.kama:1-8`). TMM's are per-user versioned JSON with atomic writes and unknown keys named
(`the-mallow-man/engine/src/settings.kama:1-8`). `engine::dev` compiles developer features out of release builds,
"not a runtime flag, because Steam lets a player type launch options"
(`friendly-fire-department/docs/SPEC.md:2143-2170`). `chat` is a speech board, a word filter and mute lists.

**Game-shaped assumptions.** The settings header names FFD (`settings.kama:59`); TMM's paths name TMM
(`%APPDATA%\TheMallowMan`). `dev.kama` exists because FFD is a hidden-role game (`dev.kama:3-7`). The chat filter's
word list is a placeholder (`the-mallow-man/docs/PROVENANCE.md:247`).

**Overlap.** TMM's settings are ahead; `args` is the same file.

**Cost: small** *(inferred)*. A project name parameter. Whether settings are records in the project database
([../design/project-database.md](../design/project-database.md)) is a bigger question than the code.

**Feeds** KYR-21, KYR-23.

## 18. forge's small packages: `http`, `jobs`, `jsonvalue`, `webnet`

Covered in [cosmic-forge.md](cosmic-forge.md) § 6; unchanged since (`git log 1d0abca..f9c182e` touches none of them).
In short: `http` (1,729) and `webnet` (263) are slated for replacement by `@kama/http` (KR-173); `jsonvalue` (999)
overlaps std's `JsonValue`; `jobs` (421) is POSIX only. For kyoten they matter as the local tool server a human-tools
page could start from (KYR-26) and as forge's API surface the content pipeline talks to (KYR-29) *(inferred)*.

## 19. Test and development tooling

**Where and what.**

| Tool | Where | What it does |
|---|---|---|
| One-binary suite | `friendly-fire-department/tests/src/harness.kama` (86); TMM's is a copy | every test a function in one program, because kama has no incremental build; exit code is the failure count |
| Frame capture and diff | FFD `tools/capture-frame` (249), `tools/diff-ppm`, `ppmdiff/` (347); TMM copies | deterministic PPMs, a frame a function of `(seed, tick)` (`game/src/game.kama:4121-4178`); a delta image "black everywhere the frame did not move" |
| GPU pixel checks in a browser | `cosmic-forge/render/check/` (`run.sh`, `page/`, fixtures in Python) | headless Firefox renders fixtures and holds read-back pixels to expected values, each case proved by a mutation (`render/README.md:142-163`) |
| Determinism soak | FFD `soak/` (2,482), `tools/soak`, `soak-compare` | 1,000 seeded headless rounds against the prototype's distribution |
| Browser and network checks | FFD `tools/check-web` + `check-web.mjs` (1,355, Playwright), `tools/check-net` | DOM structure in a real browser (WebGPU renders nothing in headless Chromium, `ENGINE_TODO.md:20-60`), browser tabs plus native clients plus a relay |
| Net soak and migration | TMM `tools/net-soak`, `net-soak-check`, `check-migration` | real game windows under named network profiles, judged from logs |
| Stack-frame guard | TMM `tools/check-frames` (181); FFD's 32 KB `-Wframe-larger-than` | catches the KM-29 class on every platform |
| Perf gate | TMM `tools/bench` (251), `bench-window`, `machine-state`, `gates` (153) | a deterministic camera path, per-pass p50/p95/p99 against per-tier budgets, exit 4 on a miss; the machine's state logged with each number |
| Runaway guard | FFD and TMM `tools/run-game` | an RSS ceiling, after a loop reached 15.6 GB (`friendly-fire-department/docs/SPEC.md:63-100`) |
| Linux and wasm container | FFD `Dockerfile`, `tools/cdev` (223) | podman or docker toolchain image, both trees bind-mounted |
| Constants check | FFD `tools/check-wgpu-constants` | generated WebGPU constants asserted against the real header on both legs |

**Game-shaped assumptions.** Flags per screen and per game (`--title-card`, `--vote-card`; `--level`, `--quality`);
the bench flies TMM's campsite.

**Overlap.** TMM copied FFD's capture, diff, run-game and platform scripts and added the perf and frame tooling
(`the-mallow-man/docs/PROVENANCE.md:64-79`).

**Cost: small to medium** *(inferred)*. The harness, capture/diff, the stack guard and the constants check move as
they are. The bench and gates need a scene that is kyoten's, not a game's. None of it is CI: every script runs on a
developer's machine, and none of the three repos has a CI config. KYR-13 starts from scripts, not pipelines.

**Feeds** KYR-13, KYR-12, KYR-14, KYR-26.

## 20. Shipping tooling and the licence ledger

**Where.** FFD `tools/bundle-linux` (301, "proved to run on Steam's runtime"), `bundle-mac` (272, a signed `.app`),
`bundle-windows` (179), `sign-mac` (148, ad hoc or Developer ID, optional notarization), `check-licenses` (295,
allowlists of what a binary may link), `gen-credits` (387), and `docs/LICENSES.md` (310). TMM `tools/bundle` (76,
Windows only so far). Both: `tools/site`, `provision` (OpenTofu on Cloudflare), `deploy-site`.

**What it does.** Self-contained bundles per OS, linkage checked against allowlists, a credits file per platform from
a manifest, and a licence ledger that records each component's licence, obligation and how it ships, down to the
GCC runtime exception on Windows and a fetched-and-shipped model file (`docs/LICENSES.md:180-182`).

**Game-shaped assumptions.** Names, bundle identifiers and the signing identity are FFD's.

**Overlap.** FFD's is ahead; TMM's bundle is a first pass.

**Cost: medium** *(inferred)*. Parameterize by project, and make the licence ledger generated from each package's
declared licences rather than hand-kept. It is the head start for KYR-21.

**Feeds** KYR-21, KYR-39.

## Overlap: which copy is ahead

| Thing | FFD | TMM | forge | Ahead, and why |
|---|---|---|---|---|
| Platform header | web proven | native superset; web half unverified | page-embedded canvas, web only | native: TMM; web: FFD |
| Input fold | 1,448 | 1,576 | — | TMM: a superset, FFD unchanged since the copy |
| `wgpugen` | one header + a hand list, plus `wgpu.h` | identical | both headers, sha256, gated by difference | forge, less `wgpu.h` |
| GPU device | statics | statics plus device loss, timestamps, late acquire | `type resource`, polled, no statics | shape: forge; features: TMM |
| glTF | — | scene-scale, external KTX2, art-contract roles | strict, embedded images, skins | different jobs |
| Synth and mixer | mono, web leg | stereo, samples, positional | — | features: TMM; web: FFD |
| Voice | fixed-point Opus on wasm, speech | FEC, stereo, spatial | — | native: TMM; web: FFD |
| UI | own copy at 0.9.577 | `@kama/ui` 0.4.0 | `@kama/ui` 0.6.0 | `@kama/ui` |
| Net security | per-hop and end-to-end (sodium) | stub (Steam encrypts its own) | — | FFD |
| Steam | spike, overlay route | runtime-loaded, lobbies, stats, presence | — | TMM |
| Settings | key = value document | versioned JSON, atomic | — | TMM |
| Shipping | three OS bundles, signing, licence checks | Windows bundle | — | FFD |

## kama versions, and what a port costs

| Source | Pin | Distance to 0.9.803 | Evidence of what a bump costs |
|---|---|---|---|
| FFD | 0.9.577 | 226 versions | 0.9.530 → 0.9.577 cost 44 compiler errors in three files (`.kama-version:24,35`) |
| TMM | 0.9.667 (Windows), 0.9.577 (Linux box) | 136 | 0.9.542 → 0.9.577 needed three fixes (`the-mallow-man/docs/UI_PACKAGES.md:41-45`) |
| forge | 0.9.765 | 38 | 0.9.667 → 0.9.758 touched 29 files, +272 −174 (`84c0684`) |

Everything forge's port hit (std's `Poller` API, `ExitStatus` as an enum, `find` returning `Optional<isize>`, `main`
returning `uint8`, a discarded `Result` as an error) lies between FFD's pin and kyoten's, so FFD's and TMM's code will
meet it too *(inferred)*. What changed between 0.9.765 and 0.9.803 was not checked.

## Corrections to the earlier surveys

- **forge's HEAD moved** from `1d0abca` to `f9c182e`, and `render` gained skins and clips (`76738e9`). Its `src/` is
  7,391 lines today, not the 6,072 in [cosmic-forge.md](cosmic-forge.md) § 2.
- **TMM's rollback is in `play`, not `net`** (a clarification of [peer-games.md](peer-games.md) § 2 and § 4, which
  describe the mechanism and `net`'s transports but not where the prediction lives). It is
  `play/src/netpredict.kama`; `net`'s own snapshot and prediction modules are unused by the game (§ 14 here).
- **FFD has not switched to `@kama/ui`.** peer-games § 4 is right about TMM; FFD still links its own `ui`/`uidoc`.
- **FFD's platform header declares 14 native functions** (`gfx/src/platform/ffd_platform.h:788-801`), where
  `docs/SPEC.md:398` and peer-games § 4 say thirteen.
- **`the-mallow-man/docs/UI_PACKAGES.md:96` gives FFD's pin as 0.9.457**; FFD has since moved to 0.9.577
  (commit `a2c6322`).

## Not surveyed

The games themselves: FFD's `sim` (17,396), `game` (16,423) and `view` beyond § 6; TMM's `sim` (16,477), `play` beyond
its netcode (17,718), `game` (21,182), `mapgen` and `kitgen`; both JS prototypes; forge's `flows`, `forge` and
`forgeui`. Nothing was built or run, so no claim here about what compiles on 0.9.803 is verified.

## What this does not decide

These are for the spike, and each names the doc that holds it.

1. **The platform layer: on, as, or beside kama's `@kama/window` and `@kama/gpu`?** Both are designed and unbuilt
   (KR-26, KR-25). FFD's header is close to `@kama/window`'s design; forge's resources are close to `@kama/gpu`'s.
   kyoten could build those packages from these pieces, depend on them later, or keep its own layer
   ([../design/architecture.md](../design/architecture.md) question 3).
2. **Where the renderer starts.** forge's `render` (library-shaped, web only), TMM's (feature-rich, native only,
   scene-shaped), or fresh with both as references; and whether it is shared with forge or forked
   ([../design/rendering.md](../design/rendering.md) question 1, content-pipeline question 5).
3. **Statics or owned state.** Whether taking TMM's or FFD's GPU code means first moving its statics into values,
   given what statics mean for parallel Output ([../design/frame-phases.md](../design/frame-phases.md) questions 5-7).
4. **The input record.** FFD's `InputFrame` is fixed-width and replayable but is FFD's controller. Whether kyoten's is
   one record a game defines, one per component, or something else ([../design/components.md](../design/components.md),
   [../design/replay-and-determinism.md](../design/replay-and-determinism.md)).
5. **Copy, depend or publish.** TMM copied with provenance because a dependency's own path dependencies were refused
   across workspaces (`the-mallow-man/docs/PROVENANCE.md:11-12`); the UI then became published packages that name no
   game. Which pieces kyoten copies into `engine/`, which it depends on (`@kama/ui`, `@kama/sodium`), and which it
   would publish for the games to adopt ([../design/architecture.md](../design/architecture.md) question 2).
6. **Whether the ports set the order.** KYR-46 needs FFD's RNG stream and hash order bit for bit; a generic frame core
   that changes either loses that acceptance test.
7. **The web's netcode.** TMM's raw-byte mirror cannot include a wasm client; FFD's relay can. Whether kyoten's
   snapshot pattern must work in a browser from the start ([../design/networking.md](../design/networking.md)).
8. **Physics on the web and in lockstep.** Jolt has no wasm build here and is built without
   `CROSS_PLATFORM_DETERMINISTIC`; whether that is acceptable for the first physics row, or lockstep must cover
   physics (KYR-17, [../design/replay-and-determinism.md](../design/replay-and-determinism.md)).
