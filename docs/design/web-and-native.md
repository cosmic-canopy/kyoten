# Web first, native at parity

**Status:** questions 1, 4, 5 and 6 decided on 2026-11-07; 2, 3 and 8 are open in the spike, and 7 waits for
KYR-13.

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

1. **Where is the seam?** *(Decided 2026-11-07, below.)* Designed against the browser's API (WebGPU, Web Audio, DOM events, WebRTC), with native
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
4. **"Light on the web": what is the budget?** *(Decided 2026-11-07, below.)* The wasm and JS size of the examples ([examples.md](examples.md))
   on their first slice, and a number to hold it to.
5. **What does native gain beyond parity?** *(Decided 2026-11-07, below.)* Threads without COOP/COEP, files, raw UDP. How does a game ask for a
   capability one target lacks (kama's `@compileFor` gates whole declarations, so per-platform types)?
6. **The cost of crossing into JS.** *(Decided 2026-11-07, below.)* Measure the `wgpu*` call cost on the web before designing a renderer that makes
   thousands of calls per frame ([rendering.md](rendering.md)).
7. **CI for the web.** kama's wasm leg runs under node, not a browser. kyoten needs a browser leg (headless Chrome)
   to test COOP/COEP, workers and WebGPU for real.
8. **A third family: the headset.** Meta Quest is either a browser (WebXR) or an Android device (OpenXR). kama's
   Android target shipped in 0.9.830, and its installable app (KR-283) is next ([xr.md](xr.md)). Does the seam's
   design leave room for it from the start?

## Decided

- **2026-11-07, the owner: questions 1, 4, 5 and 6.** "All of this sounds good to me so far." Question 2 is next, then
  3 and 8; 7 waits for KYR-13.
  - **Question 1: the seam has two levels.**
    - **Below, the libraries:** `@kama/window`, `@kama/gpu`, `@kama/graphics`, `@kama/ui`, and audio's later. Each is
      a general kama package shaped after the browser's API (WebGPU, DOM events, HTML/CSS, Web Audio), with native
      implementing the same API. kyoten builds them *as* those packages, in their own repositories (decided for window,
      gpu and graphics: KYR-51, KYR-52, KYR-9), so any kama program can use them. A platform's implementation lives
      here, and how platforms plug in is target-platforms questions 1–4; nothing assumes two.
    - **Above, the engine modules' interfaces are kyoten's own:** input, render, audio, net, physics and UI present
      components, records, world components and processors, which components question 8 part a promises a game. A
      library sits behind a module, and a borrowed backend (Jolt, RmlUi) behind that; replacing either changes no game.
      **This confirms the proposal of 2026-11-05** (SPIKE's standing direction) that each engine module's interface is
      kyoten's from the start.
    - **A game never sees wgpu handles, html5 events or GLFW,** only `Mesh`, `Camera`, `Actions` and their kind. **The
      escape hatch:** an Output processor may call `@kama/graphics` directly to draw something of its own, since Output
      is outside the simulation.
  - **Question 4: "light on the web" is a ratchet with a gauge.**
    - **The ratchet:** CI measures each example's code (wasm plus JS, release, brotli -q 11, without the page shell or
      assets) and fails when it grows; raising the number is a decision recorded with its reason, the rule chosen the
      same day for the hello cube's lines ([ai-first-api.md](ai-first-api.md)).
    - **The gauge:** at most 150 KB of code for the hello cube, about Three.js's whole WebGL library minified (153 KB),
      with room for kyoten's core, a renderer and one C library above the WebGPU binding's 16–23 KB
      ([../research/web-baseline.md](../research/web-baseline.md) § Candidate budgets). It is tightened once the hello
      cube first builds and is measured.
    - **The free savings first:** Closure (4.6 KB on the triangle; kama's release build does not run it, KY-6),
      `ENVIRONMENT=web`, and kyoten's own page shell (emscripten's is 12.9 KB).
    - **Assets get a budget of their own,** rendering question 6 and KYR-10's.
  - **Question 5: native's gains are mostly invisible to a game.** The engine uses them behind the same interfaces:
    threads without COOP/COEP, raw UDP in the net module (WebRTC or WebSocket on the web), files. Where a game must
    know (pointer lock, a file dialog, haptics), it asks for a capability at run time, spelled at target-platforms
    question 3. **The simulation never branches on a capability:** one may shape Input and Output, since two machines
    in one match differ, and a file a player opens enters as recorded I/O.
  - **Question 6: the renderer is designed around the number of calls.** KYR-5 measured an empty crossing at about
    5 ns, with the browser's WebGPU 60–70% of a call. The rules for rendering question 2: a few thousand draws a frame
    need no batching; about 10⁴ do (instancing, fewer state changes); 32-bit draw arguments, with shared buffers bound
    once; one `writeBuffer` a frame for per-object data; a JS-side command list only if calls still reach 10⁴ after
    that. Native is not uniformly cheaper, so designing against the browser does not penalize it.
