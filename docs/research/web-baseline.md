# The web baseline: build size and the cost of crossing into JS

KYR-5, measured 2026-11-01, for [web-and-native.md](../design/web-and-native.md) questions 4 (the size budget) and 6
(the JS crossing cost), and for [rendering.md](../design/rendering.md). The probes are in `.scratch/kyr-5/` (git-ignored,
written `S/` below); [Reproducing](#reproducing) lists every command. *(inferred)* marks a conclusion drawn from the
numbers, not a measurement.

| | |
|---|---|
| Machine | Acer RB102, AMD Ryzen AI 9 465 w/ Radeon 880M (10 cores, 20 threads), 12 GB RAM, mains power (no battery) |
| GPU | AMD Radeon 880M, integrated. Windows driver 32.0.22042.14002. WebGPU reports vendor `amd`, architecture `rdna-3`, not a fallback adapter. wgpu-native reports Vulkan, driver 25.20.42.14 (LLPC) |
| OS | Windows 11 Home 25H2, build 26200.9711, power plan Balanced, console session |
| Display | one active display: Amyuni "USB Mobile Monitor Virtual Display", 1920×1080 at 60 Hz |
| Browser | Microsoft Edge 156.0.4314.58 (headless user agent `HeadlessChrome/156.0.0.0 … Edg/156.0.0.0`) |
| kama | 0.9.803+gaa9093dc. `examples/webgpu` and `include/kama_app.h` are identical at `aa9093dc` and at the source tree's HEAD `cd549777` |
| emscripten | emsdk 6.0.13 (`e13ee988ce3d`); the emdawnwebgpu port `v20260423.175430` (Dawn `31e25af254ab`) |
| Native WebGPU | wgpu-native v29.0.1.1 (`wgpuGetVersion` = `0x1d000101`): FFD's prebuilt `third_party/wgpu-windows`, used read-only |
| Native C | msys2 UCRT64 clang 23.1.3 |
| Tools | node v24.21.0, gzip 1.14 (`-9 -n`), brotli 1.2.0 (`-q 11`), terser 5.51.2 (emsdk's own) |

**Conditions.** A process named `integration--release.exe` (from a temp folder, started 2026-10-22, not part of this
work) kept about one of the 20 logical cores busy for the whole session: 1,976 CPU-seconds in about 33 minutes. It was
left running. RustDesk's service and tray were running. A fourth RustDesk process, started at 18:14, had exited by
18:45, before the timed runs (18:47–19:00); after that no connection-manager process was seen, so no remote session
was active while measuring. The session was the console, not RDP. VS Code and Claude Code were open and mostly idle. Treat the
absolute numbers as this machine under light load.

## Summary

- **Hello world, release:** 792 B wasm + 8,876 B JS. Compressed with brotli that is **3,355 B**; with closure and
  `ENVIRONMENT=web`, 2,039 B.
- **A minimal WebGPU triangle, release** (kama's `examples/webgpu`): 29,514 B wasm + 51,453 B JS, **22,518 B brotli**
  (25,764 B gzip). With `--closure=1` and `ENVIRONMENT=web` it is **17,476 B**. Adding emmalloc brings it to
  **15,969 B**. All of these still draw the triangle.
- **emdawnwebgpu is most of that.** It accounts for about 35.4 KB of the 51.5 KB of JS, and about 14 KB of the 26 KB of
  wasm code (its own C++ plus the libc++ it pulls in). kama's own code is about 4 KB.
- **kama's `--release` does not run closure,** although emdawnwebgpu's README asks for it. Closure cuts the compressed
  JS by 40%. This is a candidate kama gap.
- **The crossing itself is cheap:** an empty wasm-to-JS call costs **~5 ns** (4.5–6.5). A native C call costs ~1 ns.
- **A `wgpu*` render-pass call from kama costs 30–60 ns:** `draw` 31 ns, `setPipeline` 44, `setBindGroup` 57. These are
  headless medians at N = 10⁴ over 3 launches. Calls with `uint64` arguments cost **116–133 ns**, and a 64-byte
  `queue.writeBuffer` costs **302 ns**. In a headful window these calls were 24–32% cheaper.
- **Most of a 32-bit call is the browser's own API.** `pass.draw()` called from plain JS costs 19 of the 31 ns. 64-bit
  arguments cross as BigInt, which roughly doubles the cost of the call.
- **Per draw:** `setPipeline` + `setBindGroup` + `draw` costs **140 ns**. A mesh draw (`setBindGroup` +
  `setVertexBuffer` + `setIndexBuffer` + `drawIndexed`) costs **359 ns**. So 1,000 mesh draws take 2.2% of a 60 Hz frame
  and 3.2% of a 90 Hz frame; 10,000 take 22% and 32% *(inferred)*.
- **Cost per call is flat up to ~10⁵ calls per pass,** then rises 2–3×. After 6.4 MB of `writeBuffer`, the next
  measurement ran 3–4× slower while the GPU process caught up.
- **Native wgpu-native (Vulkan) is not uniformly cheaper.** `setPipeline` costs 3 ns and `setBindGroup` 4 ns, but
  `draw` costs 56 ns, a mesh draw 162 ns and a 64-byte `writeBuffer` 2.1 µs. Per draw, the web costs 2–3× native; per
  small upload, it is 7× cheaper.
- **WebGPU ran in headless Edge** on the real GPU, cross-origin isolated (5 µs clock), with no human in the loop.

## Method

### Size

1. `S/hello`: a kama project whose `main` calls `println`. `S/triangle`: `kama/examples/webgpu` copied out unchanged.
2. Each was built with `kama build <kama.json> --target WASM`, in debug and with `--release`. The output was `-o x.js`, so
   no HTML shell is included. One extra build used `-o x.html` to measure emscripten's default shell.
3. `kama build … --cc echo` printed the link lines. A release wasm build compiles with
   `-Oz -DNDEBUG -ffunction-sections -fdata-sections -fwrapv` and links with `-sEXIT_RUNTIME=1 -sSTACK_SIZE=262144`. A
   WebGPU build adds `--use-port=emdawnwebgpu -sDEFAULT_TO_CXX=1`. Neither passes `--closure` or `-flto`.
4. Variants are copies whose manifest differs by one entry (`S/mkvariant.py`): `--closure=1` as an `ldflags` entry gated
   `ARCH_WASM32`; `"emSettings": {"ENVIRONMENT": "web"}`; `"MALLOC": "emmalloc"`; and `--profiling-funcs`, which keeps
   function names for attribution. With names kept, the code section is the same 26,256 B.
5. `S/sizes.sh` reports raw bytes, `gzip -9 -n` and `brotli -q 11`. These are the best static precompression; a server
   compressing on the fly at lower levels sends somewhat more.
6. Attribution: `S/tools/wasm-attrib.mjs` sums code-body bytes by function name. `S/tools/js-attrib.mjs` parses the JS
   with acorn (emsdk's copy) and sums top-level declarations, splitting out emdawnwebgpu's import bodies.
7. Each triangle variant was loaded in Edge. On its 90th frame the page copied the WebGPU canvas into a 2D canvas
   (`S/pages/triangle.html`) and sampled it. All four builds gave the triangle's orange (255,102,25) at the centre and
   the clear colour in a corner, so the smaller builds still work.
8. The emdawnwebgpu port was downloaded into a copy of emsdk's cache (`EM_CACHE=S/em-cache`), so emsdk itself was not
   changed.

### Crossing cost

**The probe** (`S/bench`) is a kama program over `webgpu.h`, written the way `examples/webgpu` is:

- It requests an adapter and a device, then renders into an **offscreen** 256×256 `RGBA8Unorm` texture. No canvas is
  needed, and the same source builds natively.
- Each frame tick takes **one measurement**: it opens a render pass, sets the pipeline, bind group and index buffer, then
  times N calls of one kind with `probe_now()` around the loop. It then ends the pass, finishes the encoder and releases
  everything.
- Command buffers are **never submitted**, so the GPU executes none of the draws. What is timed is the cost of recording.
- The emitted C was checked: in release, the loop holds only the call and a plain `i + 1`.

**The probe seam** (`S/bench/csrc/probe.h`) is JS on the web (`S/bench/js/probe.js`, a `jsLibraries` entry) and C
natively (`S/bench/csrc/probe_native.c`). The clock is `performance.now()` on the web and `QueryPerformanceCounter`
natively.

**Kinds.** Each kind is one call, or a fixed sequence of calls, repeated N times.

| Kind | What N iterations do |
|---|---|
| `empty0`, `empty5`, `empty64` | an empty `jsLibraries` function: no arguments; five `int32`; two `uint64` |
| `draw`, `drawIndexed`, `setPipeline`, `setBindGroup` | that `wgpuRenderPassEncoder*` call (bind group without dynamic offsets) |
| `setVertexBuffer`, `setIndexBuffer` | that call; both take two `uint64` (offset, size) |
| `writeBuffer64` | `wgpuQueueWriteBuffer` of 64 bytes into a 256-byte uniform buffer |
| `seq3` | `setPipeline` + `setBindGroup` + `draw`: the per-draw sequence the brief named |
| `meshSeq4` | `setBindGroup` + `setVertexBuffer` + `setIndexBuffer` + `drawIndexed`: a mesh draw |
| `jsDraw`, `jsSetVertexBuffer` | a loop in JS calling the browser's `pass.draw()` / `pass.setVertexBuffer()` directly: no wasm, no glue |
| `jsGlueDraw` | a loop in JS calling emdawnwebgpu's `_wgpuRenderPassEncoderDraw`: the glue, without the wasm crossing |

**Why these calls.** Render-pass calls only record commands, so none of them waits on the GPU. `wgpuQueueSubmit` and
`mapAsync` would wait, so they were not timed. `draw` is the cheapest call a renderer must make per object;
`seq3` and `meshSeq4` are what one object costs.

**Plan.** The repetitions are interleaved: for each repetition, for each N, every kind once. Repetition 0 is dropped as
warm-up, which leaves 10 samples per launch. N is 10⁴, 10⁵ and 10⁶; `writeBuffer64` is capped at 10⁵. The result is
the median ns per iteration, with the interquartile range and each launch's own median. `S/tools/analyze.mjs` computes
them.

**Runs on the web.**

- `S/tools/run-edge.mjs` serves the page with COOP/COEP headers, so the page is cross-origin isolated and the clock
  steps in 5 µs (measured; 100 µs without isolation).
- It launches a private Edge with `--headless=new` and its own profile under `S/`, and waits for the page to POST its
  results.
- **Headless:** 3 launches of the full plan (`web-run1..3`). Another 2 launches add `empty64` and `jsSetVertexBuffer`
  (`web-i64`, `web-release-b`).
- **Headful:** one launch in a normal window (`web-headful`).
- One launch of a `--closure=1` build (`web-closure`), run back to back with `web-release-b`.
- One N sweep from 10³ to 10⁶ (`web-sweep`).
- Each launch takes about 32 s.
- Launches 1–3 ran before `empty64` and `jsSetVertexBuffer` were added. The loops for the other kinds are unchanged.

**Validity check.** A validation error invalidates an encoder, and later calls on it might then be cheaper. So every run
reports device errors:

- On the web: an `uncapturederror` listener, plus a wait on `queue.onSubmittedWorkDone()` before reporting. Chrome
  delivered the event only while the page was waiting on the GPU process. A bare timer saw nothing.
- Natively: a validation error scope around the whole run.
- A deliberately invalid call (kind 13) was caught both ways. Web: "Bind group index (7) exceeds the maximum (4)".
  Native: "Binding with size 1024 at offset 0 would overflow buffer size of 64".
- **Every measured run reported zero errors.**

**Native.** The same `bench.kama` was built natively and linked against FFD's prebuilt wgpu-native, read-only. It was
run 3 times with 11 repetitions each. wgpu-native picked Vulkan on the integrated GPU.

## Results

### 1. Size

Bytes; "br" is brotli -q 11; the last column is what a player downloads for code, wasm + JS, brotli.

| Build | .wasm raw | gzip | br | .js raw | gzip | br | **wasm+js br** |
|---|---:|---:|---:|---:|---:|---:|---:|
| hello, debug | 157,863 | 60,843 | 51,022 | 59,512 | 18,025 | 15,673 | 66,695 |
| hello, release | 792 | 511 | 490 | 8,876 | 3,163 | 2,865 | **3,355** |
| hello, release + closure | 792 | 511 | 490 | 4,301 | 2,155 | 1,941 | 2,431 |
| hello, release + closure + `ENVIRONMENT=web` | 792 | 511 | 490 | 3,295 | 1,730 | 1,549 | 2,039 |
| triangle, debug | 2,198,331 | 513,607 | 403,486 | 145,802 | 34,493 | 29,310 | 432,796 |
| triangle, release | 29,514 | 12,654 | 10,750 | 51,453 | 13,110 | 11,768 | **22,518** |
| triangle, release + closure | 29,514 | 12,654 | 10,750 | 19,259 | 8,092 | 7,117 | 17,867 |
| triangle, release + closure + `ENVIRONMENT=web` | 29,514 | 12,654 | 10,750 | 18,118 | 7,646 | 6,726 | **17,476** |
| triangle, the same + `MALLOC=emmalloc` | 24,669 | 10,695 | 9,243 | 18,118 | 7,646 | 6,726 | **15,969** |

- **The HTML shell is extra.** `-o hello.html` uses emscripten's default shell, which is 19,598 B (12,898 br) in
  release. It also grows the JS to 18,702 B (5,452 br), because the shell pulls in emscripten's `Browser` library
  (canvas, fullscreen, preload plugins).
- **The brief's starting numbers were `-o x.js` builds.** Their JS sizes (59,512 / 8,876 B) reproduce exactly. The
  wasm differs by 127 B (debug) and 8 B (release), probably because the two programs' strings and source paths differ
  *(inferred)*.
- **Debug is not a shipping size.** A debug wasm is mostly DWARF (`-g -O0`), and the debug triangle also links the port
  at `-O0`.

**What the triangle's 29,514 B of wasm holds.** The code section is 26,256 B. The rest is 2,597 B of data and 661 B of
other sections.

| Part | Code bytes | Largest functions |
|---|---:|---|
| libc + emscripten runtime | 7,817 | dlmalloc `malloc` 5,054, `free` 1,503 |
| libc++ and the C++ ABI, which only the port needs (hello has none) | 7,120 | `std::__next_prime` 1,625, `unordered_map` code, `__cxa` type info |
| emdawnwebgpu's `webgpu.cpp` | 6,826 | `EventManager::TrackEvent` 2,061, `emwgpuOnRequestDeviceCompleted` 1,028 |
| kama: the program plus its runtime | 4,148 | `frameTick` 859, `onDevice` 818, `onAdapter` 629; panic and format helpers |
| other | 209 | `__cxa_atexit`, `write` |

**What the triangle's 51,453 B of JS holds:**

- About **35,400 B is emdawnwebgpu.** That is the `WebGPU` object (18,720 B), 22 inline `wgpu*` import bodies
  (15,793 B), and its export wrappers.
- About **16,000 B is emscripten's runtime**: the loader, `MainLoop` (about 2,750 B, needed by `std::app`), UTF-8 and
  exit handling.
- The hello's 8,876 B of JS is emscripten's runtime alone, without the main loop.

**References** *(not built here)*:

- **FFD records no web build size in its docs.** Its Windows native bundle is 55 MB, 31 MB of which is the speech
  model (`friendly-fire-department/docs/ROADMAP_DETAIL.md:107`). The `wgpu_native.dll` inside it is 13.6 MB
  (`:162`); the same v29.0.1.1 DLL here is 13,919,443 B. Natively the WebGPU implementation ships with the game; on the
  web the browser provides it.
- **Three.js 0.187.0** (npm tarball, sha512 checked) ships no minified build. The whole libraries were minified with
  terser (`--module --compress --mangle`), with no tree-shaking, so these are upper bounds; an app bundler would ship
  less.
  - WebGPU (`three.core` + `three.tsl` + `three.webgpu`): 1,156,004 B raw, 311,035 gzip, **249,502 br**.
  - WebGL (`three.core` + `three.module`): 770,036 B raw, 189,208 gzip, **153,389 br**.

### 2. Crossing cost on the web

Headless Edge, ns per call. Each cell is the median over 30 samples (3 launches × 10 kept repetitions); brackets give
the 25th–75th percentile. "Run medians" are the 3 launches' own medians at N = 10⁴. Multi-call rows give ns per
iteration, with ns per call after the slash.

| Kind | N = 10⁴ | N = 10⁵ | N = 10⁶ | Run medians (10⁴) | Headful, 1 launch (10⁴ / 10⁵) |
|---|---:|---:|---:|---|---:|
| `empty0` | 5.0 [4.5–6.5] | 5.3 | 4.8 | 4.5 / 5.3 / 5.3 | 5.0 / 4.3 |
| `empty5` | 6.5 [5.6–7.4] | 5.8 | 5.6 | 6.0 / 6.3 / 6.5 | 13.0 / 4.6 |
| `empty64` † | 17.5 [11.6–19.0] | 13.3 | — | 18.3 / 14.3 | 6.5 / 6.6 |
| `draw` | **31.5** [24.1–43.6] | 31.3 | 74.5 | 31.3 / 31.5 / 37.0 | 24.0 / 20.2 |
| `drawIndexed` | 34.5 [24.5–43.9] | 34.3 | 77.4 | 30.0 / 33.0 / 40.7 | 23.0 / 23.3 |
| `setPipeline` | 43.7 [31.0–46.4] | 44.6 | 51.7 | 32.5 / 31.5 / 46.5 | 29.8 / 30.5 |
| `setBindGroup` | 57.0 [45.3–71.2] | 60.3 | 173 | 48.7 / 59.0 / 67.7 | 43.0 / 45.9 |
| `setVertexBuffer` | 116 [87–129] | 108 | 178 | 87 / 110 / 138 | 81 / 87 |
| `setIndexBuffer` | 133 [117–154] | 131 | 137 | 127 / 133 / 151 | 94 / 92 |
| `writeBuffer64` | 302 [234–387] | 320 | — | 238 / 266 / 358 | 205 / 222 |
| `seq3` | **140** / 47 [99–153] | 133 / 44 | 539 / 180 | 103 / 124 / 147 | 98 / 99 |
| `meshSeq4` | **359** / 90 [290–398] | 1,304 ‡ | 565 / 141 | 343 / 316 / 410 | 257 / 789 ‡ |
| `jsDraw` (no wasm, no glue) | 19.2 [16.5–24.0] | 17.8 | 65.3 | 27.2 / 17.8 / 18.3 | 16.0 / 12.4 |
| `jsGlueDraw` (no wasm) | 25.7 [23.5–38.3] | 29.8 | 75.7 | 27.0 / 24.5 / 31.7 | 16.0 / 20.0 |
| `jsSetVertexBuffer` † | 53.5 [42.9–81.7] | 49.9 | — | 55.3 / 41.8 | 39.5 / 35.8 |

† From the 2 later launches (`web-i64`, `web-release-b`): 20 samples. In those same launches, `empty0` measured 6.5 ns
and `setVertexBuffer` 102 ns at 10⁴.

‡ In the main plan, `meshSeq4` at 10⁵ ran right after `writeBuffer64` at 10⁵, which had just queued 6.4 MB of writes.
In the sweep, where nothing heavy preceded it, the same measurement is **345 ns**. `jsDraw`, `jsGlueDraw` and
`setIndexBuffer` at 10⁵ show the same tail: maxima of 146–1,213 ns. This is a backlog in the GPU process, not a cost of
the call *(inferred)*.

**Closure does not measurably change the cost.** One launch each, back to back, at N = 10⁴, closure build first:
`draw` 35.0 vs 34.2; `seq3` 123 vs 101; `meshSeq4` 286 vs 260; `setVertexBuffer` 109 vs 90; `writeBuffer64` 303 vs 315.
Each difference is smaller than the spread between launches of the same build above. For example, `seq3`'s three
launch medians span 103–147 ns.

**The first frame is slower.** In repetition 0 (cold) at N = 10⁴, `draw` cost 134–155 ns, `seq3` 245–613 and
`meshSeq4` 506–820, across the 3 launches. The run's very first measurement averaged 135–2,353 ns per empty call, which
includes compiling the code on first use.

### 3. Where the time goes

ns per call at N = 10⁴, headless. Each part is the increment over the column before it.

| Call | Browser API (from plain JS) | emdawnwebgpu glue | wasm crossing | Total from kama |
|---|---:|---:|---:|---:|
| `draw` (32-bit arguments) | 19.2 (61%) | 6.5 (21%) (`jsGlueDraw` 25.7 − 19.2) | 5.8 (18%) | **31.5** |
| `setVertexBuffer` (two `uint64`) | 53.5 (52%) | ≈ 31 (30%) (by difference) | ≈ 17.5 (17%) (`empty64`) | **102** |

- **In a 32-bit call, the browser's API is most of the cost.** Headful shows the same pattern: 16.0 ns from plain JS,
  16.0 through the glue, 24.0 from kama.
- **A 64-bit argument costs extra twice.** Emscripten passes `uint64` as a BigInt, so two of them raise an empty
  crossing from about 6 to 14–18 ns. The glue then converts each one with `bigintToI53Checked`, which is visible in the
  emitted JS. Together that makes `setVertexBuffer` 3–4× a `draw`.

### 4. How cost depends on N (headless, 1 launch, ns per iteration)

| Kind | 10³ | 3·10³ | 10⁴ | 3·10⁴ | 10⁵ | 3·10⁵ | 10⁶ |
|---|---:|---:|---:|---:|---:|---:|---:|
| `empty0` | 7.5 | 5.0 | 4.8 | 5.0 | 5.2 | 4.8 | 4.6 |
| `draw` | 35.0 | 36.7 | 32.5 | 27.3 | 32.0 | 33.7 | 112 |
| `seq3` | 160 | 145 | 130 | 126 | 134 | 310 | 428 |
| `meshSeq4` | 420 | 353 | 292 | 334 | 345 | 511 | 636 |
| `setVertexBuffer` | 123 | 121 | 120 | 119 | 130 | 246 | 198 |
| `jsDraw` | 35.0 | 20.0 | 17.0 | 19.7 | 17.1 | 169 | 74.7 |

- **Cost per call is flat from 10³ to 10⁵ iterations.** It rises past about 3·10⁵ calls in one pass.
- At 10³ iterations a measurement lasts 7.5–420 µs, so the clock's 5 µs step makes that column coarse. For `empty0` it
  is meaningless.

### 5. Native: wgpu-native v29.0.1.1, Vulkan, 3 runs (ns per iteration, median of 30)

| Kind | N = 10⁴ | N = 10⁵ | N = 10⁶ | Web ÷ native at 10⁴ |
|---|---:|---:|---:|---:|
| `empty0` / `empty5` / `empty64` (a C call) | 1.25 / 1.23 / 0.93 | 1.15 / 1.14 / 0.93 | 1.02 / 0.97 / 0.94 | 4–19× |
| `draw` | 55.8 [42.8–68.2] | 41.4 | 39.9 | 0.6× |
| `drawIndexed` | 11.3 | 38.4 | 38.5 | 3.1× |
| `setPipeline` | 2.71 | 2.09 | 2.10 | 16× |
| `setBindGroup` | 3.63 | 3.21 | 2.94 | 16× |
| `setVertexBuffer` | 32.7 | 53.8 | 57.5 | 3.5× |
| `setIndexBuffer` | 26.9 | 54.3 | 58.7 | 4.9× |
| `writeBuffer64` | 2,123 | 2,133 | — | **0.14×** |
| `seq3` | 43.6 | 49.2 | 48.5 | 3.2× |
| `meshSeq4` | 162 | 182 | 198 | 2.2× |

This compares implementations, not just the crossing: wgpu-native natively against Chrome's Dawn wire client on the
web. Dawn native was not measured. A 64-byte write costing 2.1 µs in wgpu-native suggests a staging allocation per
write *(inferred)*.

## What this means

### For question 4, the size budget

- **The binding floor is 16–23 KB brotli.** That is the floor for a kama program that draws with WebGPU, before
  kyoten adds anything. Roughly two-thirds of it is emdawnwebgpu: its JS, its C++ and the libc++ it pulls in
  *(inferred from raw shares)*.
- **Closure is the largest free lever.** It saves 4.6 KB brotli on the triangle and costs nothing measurable at run
  time. kama does not run it (see [the gaps](#candidate-kama-gaps)). With closure on, a `jsLibraries` file must quote
  any property names that leave it; the probe had to.
- **`ENVIRONMENT=web` saves 0.4 KB brotli**, and leaves out node support code that a shipped web build never uses.
- **emmalloc saves 1.5 KB brotli** compared with dlmalloc. Its speed was not measured.
- **A page needs its own shell.** emscripten's default shell is 12.9 KB brotli, more than the triangle's JS. A kyoten
  page should bring its own through `shellFile` *(inferred)*.
- **Assets will dominate.** Textures and meshes will outweigh code quickly, so a code budget and an asset budget are
  separate numbers (rendering.md question 6, KTX2/Basis) *(inferred)*.

### For question 6, the crossing cost

- **The crossing is not the cost to design around. The number of calls is.** An empty wasm-to-JS call is about 5 ns.
  The browser's WebGPU API is 60–70% of a 32-bit call, and no wasm design removes that. The only way to cut it is to make
  fewer calls *(inferred)*.
- **Frame budgets.** The costs per draw below use the headless medians, with headful in brackets. The frame shares are
  arithmetic on those costs *(inferred)*:

| Per draw | ns | Draws per ms of encoding | 1,000 draws: share of a 60 / 90 Hz frame | 10,000 draws: 60 / 90 Hz |
|---|---:|---:|---:|---:|
| `setPipeline` + `setBindGroup` + `draw` | 140 (98) | 7,100 (10,200) | 0.8% / 1.3% | 8.4% / 12.6% |
| mesh draw: `setBindGroup` + `setVertexBuffer` + `setIndexBuffer` + `drawIndexed` | 359 (257) | 2,800 (3,900) | 2.2% / 3.2% | 21.5% / 32.3% |
| mesh draw + a 64-byte `writeBuffer` | 661 (462) | 1,500 (2,200) | 4.0% / 5.9% | 39.7% / 59.5% |

  At the Quest's 72–120 Hz (13.9–8.3 ms per frame), 10,000 mesh draws would take 26–43% of a frame.

- **What follows for the renderer** *(inferred)*:
  - **A few hundred to a few thousand draws per frame need no batching.**
  - **Ten thousand draws do.** Instancing, fewer state changes, and render bundles (not measured) cut the number of
    calls; nothing else cuts the cost by more than half.
  - **Keep 64-bit arguments out of the per-draw path.** Bind shared vertex and index buffers once, and select ranges
    with `drawIndexed`'s 32-bit `firstIndex` and `baseVertex`. `setVertexBuffer` and `setIndexBuffer` cost 3–4× a
    `draw` from wasm.
  - **Upload per-object data once per frame,** in one `writeBuffer`, not one per object. It is the most expensive
    common call on the web (302 ns), and by far the most expensive in wgpu-native (2.1 µs).
  - **Keep a pass under about 10⁵ calls,** and keep uploads modest. Past that, cost per call climbs, and a large
    upload slows the following calls while the GPU process catches up.
  - **A JS-side command list replayed in one crossing is worth at most ~40% on 32-bit calls and ~50% on 64-bit ones.**
    Those are the crossing and glue shares measured above, before paying to write and read the list. It is worth
    measuring only if the call count still reaches ~10⁴ per frame after the steps above.
- **Native is not uniformly cheaper.** wgpu-native makes `setPipeline` and `setBindGroup` almost free, but costs more
  than the web per `draw` and per small write. An interface designed against the browser does not penalize native
  through these calls *(inferred)*.

### For rendering.md and the rest of web-and-native.md

- **Question 2, the layers:** the scene layer is where draw counts become call counts. It needs instancing or
  batching before scenes reach about 10⁴ objects at 90 Hz *(inferred)*.
- **Question 5, parallel recording:** on the web, these costs land on whichever thread owns the device (the topology
  question, web-and-native.md question 2). At 359 ns per mesh draw, recording is a measurable part of that thread's
  frame *(inferred)*.
- **Question 7 (web-and-native), CI:** headless Edge ran WebGPU on the real GPU here, and a node server plus a POST
  collected the results with no human. One trap for a browser CI leg: Chrome delivered `uncapturederror` only while the
  page was waiting on the GPU process, so a test must wait on `queue.onSubmittedWorkDone()` or an error scope before
  concluding that there were no errors.

## Candidate budgets

For the owner to choose from. Each is **code only: wasm + JS, release, brotli -q 11, without the page shell or
assets**, for one example's first slice. For scale: the triangle is 17.5 KB (with closure and `ENVIRONMENT=web`) to
22.5 KB (kama's default).

| Candidate | Room above the triangle | What it would allow | What it would force |
|---|---:|---|---|
| **32 KB** | about 10–15 KB | A thin engine core over the binding | Closure and `ENVIRONMENT=web` on; no C or C++ library on the web; every std import watched |
| **64 KB** | about 40–45 KB | A small engine: components, a renderer, input and audio glue *(inferred)* | Third-party libraries argued for one at a time |
| **150 KB** | about 130 KB | Room for one or two C/C++ libraries compiled to wasm (sizes not measured). About the size of Three.js's whole WebGL library minified (153 KB) | A per-package size report so growth stays visible |
| **250 KB** | about 230 KB | Parity with Three.js's whole WebGPU library (250 KB) | Little, beyond measuring |
| **A ratchet** instead of a number | — | Any size, but no silent growth: CI measures each example and fails on growth past a stated percentage without a recorded reason | A CI browser leg (question 7) and a baseline file |

A number and a ratchet can be combined. Whichever is chosen, an asset budget needs its own decision.

## Not measured

- Firefox and Safari; Linux and macOS; other GPUs; the Quest browser.
- A threaded (pthread) build: its size, and the crossing from a worker that renders through an OffscreenCanvas.
- GPU execution time. No command buffer was submitted.
- The per-frame fixed calls: `getCurrentTexture`, `createView`, `beginRenderPass`, `end`, `finish`, `submit`.
- Calls not in the probe: `setBindGroup` with dynamic offsets (it passes a `HEAPU32` view), `setViewport` and
  `setScissorRect`, render bundles, compute passes, `mapAsync`, and per-frame object creation.
- A batched command-list replay. Only its upper bound was inferred, from `jsDraw`.
- Dawn native, and wgpu-native on D3D12. wgpu-native chose Vulkan.
- Startup: download, compile and instantiate times. Only the first repetition's cold cost was seen.
- Memory, and garbage-collection pauses from BigInt arguments.
- emmalloc's speed; `-flto` for wasm.
- A tree-shaken Three.js app; the size of kyoten's or forge's own render code.
- FFD's and the-mallow-man's web builds. FFD's docs record none, and peers are not built from here.

## Candidate kama gaps

Reproduced on kama 0.9.803+gaa9093dc. The coordinator re-checked both and filed them as [KY-6 and KY-7](../KAMA_GAPS.md).

**1. `--release --target WASM` does not run closure, though emdawnwebgpu asks for it.** The port's README (in emsdk's
`tools/ports/emdawnwebgpu.py`) says: *"In all cases, it is important to enable Closure to reduce code size in release
builds."* kama's docs never mention closure, and `--cc echo` shows no `--closure` in the release link line.

```sh
cp -r kama/examples/webgpu tri
kama build tri/kama.json --target WASM --release -o out/a/triangle.js
#   out/a/triangle.js  51,453 B   (brotli -q 11: 11,768 B)
# add to tri/kama.json:  "ldflags": [{ "flag": "--closure=1", "compileFor": ["ARCH_WASM32"] }]
kama build tri/kama.json --target WASM --release -o out/b/triangle.js
#   out/b/triangle.js  19,259 B   (brotli -q 11:  7,117 B)
```

Both builds draw identical pixels in Edge 156, and closure changed no call cost measurably. The ask: run closure for a
release wasm build (at least with `webgpu`), or document it as the knob. Either way, say that closure renames a
`jsLibraries` file's unquoted property names.

**2. A native build does not say which C compiler it ran** *(low priority; the PATH was mine)*. With emsdk's
`upstream/bin` ahead of msys2 on PATH, kama ran emsdk's `clang` for a native build:

```sh
export PATH="/c/Users/Matt/emsdk/upstream/bin:$PATH"
kama build bench/kama.json --release -o out/x/bench.exe
#   kama_runtime.h:1675:10: fatal error: 'stdio.h' file not found
#   kama: clang failed (exit 1)
```

A line naming the resolved compiler path would have made the cause obvious.

## Reproducing

From `.scratch/kyr-5/`. `env.sh` puts emsdk 6.0.13 on PATH and sets `EMSDK_PYTHON` and `EM_CACHE=./em-cache` (a copy of
emsdk's cache). `env-native.sh` puts msys2 UCRT64 first and points `KAMA_WGPU_DIR` at FFD's
`third_party/wgpu-windows`. Use one or the other, never both.

```sh
. ./env.sh
$KAMA build hello/kama.json --target WASM [--release] -o out/hello-<debug|release>-js/hello.js
$KAMA build triangle/kama.json --target WASM [--release] -o out/tri-<debug|release>/triangle.js
python -I mkvariant.py triangle v-tri-closure-web \
  '{"ldflags":[{"flag":"--closure=1","compileFor":["ARCH_WASM32"]}],"emSettings":{"ENVIRONMENT":"web"}}'
$KAMA build v-tri-closure-web/kama.json --target WASM --release -o out/v-tri-closure-web/triangle.js
./sizes.sh out/*/*.wasm out/*/*.js                          # raw, gzip -9 -n, brotli -q 11
node tools/wasm-attrib.mjs out/v-tri-names/triangle.wasm    # the --profiling-funcs variant
node tools/js-attrib.mjs out/tri-release/triangle.js
node tools/run-edge.mjs --root www --page "tri-release/triangle.html?name=draw-tri-release" \
  --name draw-tri-release --results results                 # the pixel check

$KAMA build bench/kama.json --target WASM --release -o out/bench-release/bench.js   # then copy into www/bench-release/
node tools/run-edge.mjs --root www \
  --page "bench-release/bench.html?name=web-run1&reps=11&ns=10000,100000,1000000&kinds=0,1,2,3,4,5,6,7,8,9,10,11,12" \
  --name web-run1 --results results                         # add --headful for a window
node tools/analyze.mjs results/web-run1.json results/web-run2.json results/web-run3.json

. ./env-native.sh
$KAMA build bench/kama.json --release -o out/native-release/bench.exe
cp "$KAMA_WGPU_DIR/lib/wgpu_native.dll" out/native-release/
PROBE_REPS=11 out/native-release/bench.exe > results/native-run1.txt
node tools/analyze.mjs results/native-run1.txt results/native-run2.txt results/native-run3.txt
```

The raw results and the pooled summaries (`results/summary-*.txt`, `.json`) are in `S/results/`. The Three.js
reference came from `S/dl-three/three-0.187.0.tgz`, minified into `S/three-min/` with emsdk's terser.
