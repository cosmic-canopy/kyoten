# Web first, native at parity

**Status:** questions 1–6 and 8 decided on 2026-11-07; 7 waits for KYR-13.

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
2. **The web thread topology.** *(Decided 2026-11-07, below.)* This is the hardest web question, and it decides the frame model's parallelism on
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
3. **UI in HTML/CSS.** *(Decided 2026-11-07, below.)* The game's UI is the browser's DOM on the web. Natively: RmlUi
   through `@kama/ui`, as the peers do, or a webview? Is a game's UI the same HTML on both?
4. **"Light on the web": what is the budget?** *(Decided 2026-11-07, below.)* The wasm and JS size of the examples ([examples.md](examples.md))
   on their first slice, and a number to hold it to.
5. **What does native gain beyond parity?** *(Decided 2026-11-07, below.)* Threads without COOP/COEP, files, raw UDP. How does a game ask for a
   capability one target lacks (kama's `@compileFor` gates whole declarations, so per-platform types)?
6. **The cost of crossing into JS.** *(Decided 2026-11-07, below.)* Measure the `wgpu*` call cost on the web before designing a renderer that makes
   thousands of calls per frame ([rendering.md](rendering.md)).
7. **CI for the web.** kama's wasm leg runs under node, not a browser. kyoten needs a browser leg (headless Chrome)
   to test COOP/COEP, workers and WebGPU for real.
8. **A third family: the headset.** *(Decided 2026-11-07, below.)* Meta Quest is either a browser (WebXR) or an Android
   device (OpenXR). kama's Android target shipped in 0.9.830, and its installable app (KR-283) is next ([xr.md](xr.md)).
   Does the seam's design leave room for it from the start?

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
- **2026-11-07, the owner: question 2, the web thread topology.** "All sounds good to me so far."
  - **The evidence.** A probe in headless Edge 157 here (a page and a second origin served locally), a research agent's
    reading of the specs, MDN's browser-compat-data and release notes, and two claims checked at their source (the Fetch
    Standard's WebSocket rule, and Safari's missing `credentialless`):

    | Fact | Where |
    |---|---|
    | COOP/COEP does not block a cross-origin WebSocket: Fetch sets a `"websocket"` request's tainting to `"basic"`, and applies the CORP check only *"If either request's response tainting or response's type is "opaque""* | every browser; probed under `require-corp`, `credentialless` and none. kama's `tools/check-target.sh` says otherwise, which is KY-36 |
    | `credentialless` gives `crossOriginIsolated` and still loads a cross-origin image without CORP; `require-corp` blocks it | Chrome 96, Firefox 119, not Safari (browser-compat-data); `require-corp` from Safari 15.2. Probed |
    | WebGPU in a dedicated worker, rendering into an `OffscreenCanvas` the page transferred | Chrome 113, Firefox 141 on Windows (macOS on Apple Silicon from 145 and 147; Linux not yet in release), Safari 26. Probed |
    | `requestAnimationFrame` in a dedicated worker, which needs an owning window; emscripten's threads always have one | Chrome 69, Firefox 99, Safari 16.4 |
    | The Gamepad API is `[Exposed=Window]` | every browser |
    | A SharedArrayBuffer reaches an AudioWorklet, which writes it | probed; WebKit fixed its bugs here in 2022 |
    | emscripten's `PROXY_TO_PTHREAD` runs `main` on a pthread worker, and `OFFSCREENCANVAS_SUPPORT` transfers the canvas to it; emdawnwebgpu accepts a transferred canvas, and keeps its objects per worker | emscripten 6.0.13 and Dawn's source; no official document |
    | A hidden tab stops `requestAnimationFrame`, in windows and workers; Chrome checks page timers about once a second, and once a minute after 5 minutes hidden; worker timers are mostly not throttled | MDN; Chrome's documentation |

  1. **Two web builds, one engine.** Single-threaded is the default and threads are a switch a game turns on by
     measurement (frame-phases questions 7 and 8). The topology is the platform libraries' (question 1), below the seam,
     so a game's code is the same in both.
  2. **The single-threaded build runs everything on the page:** `requestAnimationFrame` drives frames, WebGPU draws on
     the page's canvas, and the DOM UI and Web Audio are used directly. It needs no headers, so it runs on any host and
     in any iframe.
  3. **The threaded build: the page is the browser's edge, and the game runs on workers.**
     - **The page thread** holds the frame source and visibility. Each frame it writes input events and the gamepad's
       poll into an input ring in shared memory, applies the DOM UI from a ring Output fills, and owns the AudioContext,
       whose worklet reads an audio ring in shared memory.
     - **kama's `main` runs on a worker,** as kama does for any build that spawns, since `Atomics.wait` throws on the
       page thread. It runs the step loop (Input's hand-off drains the input ring, then Update and Constraints) and
       Output's rendering through WebGPU into the canvas transferred at start. The loop returns to the worker's event
       loop each frame, so the worker's own `requestAnimationFrame` fires.
     - **The job pool's workers** take the parallel chunks.
     - **Why render on `main`'s worker:** the page stays free for input, layout and UI, so a long frame never delays an
       input event's timestamp; WebGPU objects belong to the thread that made them; and every engine that ships WebGPU
       supports it in a worker.
     - **Considered:** `main` on the page with workers for the simulation only (kama moves `main` to a worker anyway,
       and rendering on the page puts encoding back on the busy thread); and no threaded web build (the web capped at one
       core).
  4. **The hosting headers are COOP `same-origin` and COEP `require-corp`, the same everywhere,** the one pair that
     isolates in Safari too, with the WebSocket unaffected. kyoten's host sends `Cross-Origin-Resource-Policy` on every
     file it serves, and a game embedding a third-party image loads it with CORS. **Considered:** `credentialless`,
     friendlier but missing in Safari; choosing headers per browser by user agent is fragile. **COOP's cost:**
     cross-origin popups lose their opener, so OAuth and payment flows use redirects.
  5. **A threaded game also ships its single-threaded build,** and the loader picks one at start by
     `crossOriginIsolated`. Results are the same (parallel equals serial, and the same on every platform), so the
     fallback is only slower. It covers hosts that cannot send headers and embeds on other sites. Chromium's
     `Document-Isolation-Policy` (137) may later isolate an embedded game without its host; Firefox and Safari lack it.
  6. **Hidden tabs:** Output stops. A game's record chooses `"whenHidden": "Pause"` or `"Run"`. Running, the threaded
     build steps on the worker's timer; the single-threaded build steps as the throttled page timer allows and catches
     up through frame-phases' owed steps to a cap on return, past which networking resyncs (KYR-18). So a networked web
     game that must keep pace while hidden runs threaded.
- **2026-11-07, the owner: questions 3 and 8, UI and the headset.** "All of this sounds good to me." This closes the
  questions open in the spike; 7 waits for KYR-13.
  - **What was known.** `@kama/ui` is on the registry: the DOM on the web, and RmlUi natively through `@kama/rmlui`.
    the-mallow-man and cosmic-forge use it. Its known gaps are no native `<video>` or `<audio>` element (cosmic-forge's
    CF-9) and no native GPU canvas element (CF-22). For the headset, [xr.md](xr.md) records that WebXR exists only on
    the page thread, and that WebGPU in WebXR is experimental and behind a flag in the Quest browser.
  1. **One UI format everywhere, kyoten's UI profile:** the HTML and CSS that `@kama/ui` renders natively. The DOM
     renders it on the web, and `@kama/ui` natively. **The build checks every UI document against the profile,** so
     nothing that works only on the web slips in. A document marked web-only (a store page, say) is let through. **The
     profile grows as the native renderer does, never ahead of it:** RmlUi now, kyoten's own renderer later (KYR-16,
     the owner's direction of 2026-11-05). So a game's UI is the same HTML on both, which is what this question asked.
  2. **Natively `@kama/ui`, no webview for games.** A webview ships a browser engine with each game (CEF, WebView2,
     WKWebView), adds a process, draws the UI off-screen and copies it into the game's GPU surface, is missing on
     consoles, and sits outside the budgets. It may still serve tools such as the editor.
  3. **UI is presentation plus input, and never touches the simulation.**
     - **Values flow out:** Output processors read the snapshot and write the values a document binds. In the threaded
       web build they travel over the UI ring (question 2).
     - **Events flow in as actions:** a click is an `Actions` field like a key's, entering at Input's hand-off and
       recorded. So a menu click replays, and an agent or a bot presses the same buttons a player does. Typed text is an
       action's payload.
     - **UI-only state** (the open tab, hover, a scroll position) is Output's own `"output": true` state, never saved or
       hashed. Anything that matters to the game, such as pausing, is an action.
  4. **UI documents are content.** They hot-reload, and DLC and mods layer them, so a mod can reskin the menus. **Every
     name a document binds is checked at build** against the generated names, the values it reads and the actions it
     sends, so `data-action="fastr"` is a build error as an action's typo already is. The binding syntax is for
     `@kama/ui` and KYR-16 to settle.
  5. **Accessibility:** the DOM gives screen readers on the web. RmlUi has nothing equivalent natively, as far as is
     known *(not checked)*, so native accessibility is KYR-16's to build, not an afterthought.
  6. **The headset is two platform implementations on the existing seam, not a third family.** Quest natively is the
     Android family with OpenXR, and the Quest browser is the web family with WebXR, with XR as its own package
     (KYR-31). What it needs is already decided: the frame source can be the headset's predicted display time
     (frame-phases question 10), a view's target can be an eye (components, 2026-11-06), controllers and hands are
     devices bound to actions (components question 7), and a pose enters at Input's hand-off, recorded like any outside
     clock (G12).
  7. **A WebXR build renders on the page thread,** where WebXR lives, so the single-threaded web build serves it first.
     A later threaded WebXR build would keep the simulation on workers and move only Output's rendering to the page.
     **Players reach Quest natively first,** through OpenXR on Android, once kama's installable app (KY-2) lands. The
     Quest browser serves development until WebGPU in WebXR ships without its flag, and the owner's Quest prototype
     (KYR-4) may revisit this with what it finds on the headset. This answers [xr.md](xr.md) question 1.
