# Web first, native at parity

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **Web first, and light on the web.** It uses the browser's best-in-class features (HTML/CSS, Web Audio, WebGPU,
  and so on) rather than shipping heavy replacements to it.
- **Native implements the same interfaces where needed**, for full cross-platform compatibility.
- **Each system is built on a general-purpose library** (the owner, 2026-11-02; [architecture.md](architecture.md) §
  Decided): "each should be as lean as possible on the web and rely on the best in class browser APIs for that
  purpose". The graphics library is its own package on `@kama/gpu`, and audio and networking follow it.
- **N platforms, extensible** ([target-platforms.md](target-platforms.md)): the web and desktop native are the first
  two implementations of the platform interface, not the only ones, so nothing here may assume there are two.

## What already exists

From [../research/kama-for-engines.md](../research/kama-for-engines.md) §§ 2–3:

- **One source builds to wasm through emscripten** (`--target WASM`). `std::app::run` drives the frame from
  `requestAnimationFrame` on the web and from a loop natively. Browser APIs are bound with `jsLibraries` (JS glue a
  package ships) and C prototypes, and std's own glue uses a pull model: JS events enqueue and kama polls.
- **Threads on the web have a price.** A wasm program that spawns runs `main` on a **worker**
  (`PROXY_TO_PTHREAD`). That needs COOP/COEP headers (which kama says break a cross-origin WebSocket; disputed, see
  question 2), and the worker has no
  `document`, so no DOM or canvas there. A WebGPU client has already died reading `getContext` on a worker. Nothing in
  kama designs the split between the page thread and workers for an engine; kyoten has to.
- **The platform packages are designed but unbuilt:** `@kama/gpu` (KR-25, RAII WebGPU handles, typed `acquire`),
  `@kama/window` (KR-26, window plus one event ring; html5.h on the web, GLFW natively; headless for tests and replay),
  `@kama/http` (KR-173). **kyoten builds `@kama/window` and `@kama/gpu`** (the owner, 2026-11-02; KYR-51, KYR-52).
  **Nothing exists for audio.** `@kama/ui` (HTML documents: the DOM on the web, RmlUi
  natively) is on the registry, and the-mallow-man and cosmic-forge use it.
- **The peers built their own platform layers** (GLFW plus emscripten html5, wgpu-native against the browser's
  WebGPU). See [../research/peer-games.md](../research/peer-games.md) § platform split.
- Every wasm call into a browser API is a JS crossing; WebGPU on the web is emscripten's `emdawnwebgpu`, which
  implements `webgpu.h` in JS. **KYR-5 measured it, and the build size**
  ([../research/web-baseline.md](../research/web-baseline.md)):
  - **Question 6:** an empty wasm-to-JS call costs about 5 ns, a `draw` 31 ns, a mesh draw 359 ns, and a call with
    `uint64` arguments 116–133 ns. Most of a call is the browser's own WebGPU work, so the number of calls is what to
    design around.
  - **Question 4:** a WebGPU triangle is 22.5 KB brotli as kama builds it, and 17.5 KB with Closure and
    `ENVIRONMENT=web`; emdawnwebgpu is most of it. The doc lists candidate budgets for the owner to choose from.
    kama's release build does not run Closure ([../KAMA_GAPS.md](../KAMA_GAPS.md) KY-6).

## The questions

1. **Where is the seam?** Designed against the browser's API (WebGPU, Web Audio, DOM events, WebRTC), with native
   implementing each one, per the rule. Which interfaces are kyoten's own, and which does kyoten take from kama's
   packages once they exist (`@kama/gpu`, `@kama/window`, `@kama/ui`)? Does kyoten build them, wait for them, or build
   them *as* those packages?
2. **The web thread topology.** This is the hardest web question, and it decides the frame model's parallelism on
   the web ([frame-phases.md](frame-phases.md)). Options:
   - a single-threaded wasm `main` on the page thread, with no parallel phases on the web at first;
   - `main` on a worker, rendering through an OffscreenCanvas transferred to it, and the DOM driven by messages;
   - the page thread owning input, DOM and audio scheduling, with simulation workers fed through SharedArrayBuffer.
   Which one, and is COOP/COEP acceptable for every game kyoten hosts ([marketplace.md](marketplace.md))?
   - *Found 2026-11-04* ([frame-phases.md](frame-phases.md) § Decided, question 2):
     - The Gamepad API is `[Exposed=Window]`, so a gamepad is read on the page thread in every topology, once a frame.
     - rAF pauses in a hidden tab, so a networked game needs a policy for its clock there.
   - *Narrowed 2026-11-04* ([frame-phases.md](frame-phases.md) § Decided, questions 7 and 8): a web build is
     single-threaded by default, and threads come from a build-time switch a game turns on by measurement. So this
     question picks the topology a *threaded* web build gets, and whether kyoten's hosting serves the COOP/COEP headers
     it needs. Whether those headers break a cross-origin WebSocket is disputed (frame-phases question 8), and question
     7's browser leg should settle it.
3. **UI in HTML/CSS.** The game's UI is the browser's DOM on the web. Natively: RmlUi through `@kama/ui`, as the peers
   do, or a webview? Is a game's UI the same HTML on both?
4. **"Light on the web": what is the budget?** The wasm and JS size of the examples ([examples.md](examples.md))
   on their first slice, and a number to hold it to.
5. **What does native gain beyond parity?** Threads without COOP/COEP, files, raw UDP. How does a game ask for a
   capability one target lacks (kama's `@compileFor` gates whole declarations, so per-platform types)?
6. **The cost of crossing into JS.** Measure the `wgpu*` call cost on the web before designing a renderer that makes
   thousands of calls per frame ([rendering.md](rendering.md)).
7. **CI for the web.** kama's wasm leg runs under node, not a browser. kyoten needs a browser leg (headless Chrome)
   to test COOP/COEP, workers and WebGPU for real.
8. **A third family: the headset.** Meta Quest is either a browser (WebXR) or an Android device (OpenXR). kama's
   Android target shipped in 0.9.830, and its installable app (KR-283) is next ([xr.md](xr.md)). Does the seam's
   design leave room for it from the start?

## Decided

*(nothing yet — filled in during the walk-through)*
