# kama for engines: research for kyoten

What kama **0.9.793** (`C:\Users\Matt\Documents\kama`, commit `87985659`, 2026-11-01) offers an engine today. Paths are
relative to the kama repo unless they start `kyoten/`. `SPEC` is `docs/SPEC.md`, `RD` is `docs/ROADMAP_DETAIL.md`, `RM`
is `docs/ROADMAP.md`; a number after a colon is a line at 0.9.793. *(verified 0.9.793)* means I compiled and ran it here
(Windows 11, msys2 UCRT64 clang 23, 20 logical cores, `out/UCRT64-x86_64/kama`); the probe sources lived in the session
scratchpad and are not kept. *(inferred)* means my reading, not something kama states or I ran.

## Summary

- **The core is there:** no GC, RAII, C parity (a release build folds the program into one C translation unit at
  `-O3`), and ECS-shaped primitives that monomorphize to direct calls: `SlotMap`, `DynamicArray`, `View`, contract
  bounds. Also `std::math` (Vec/Mat/Quat, WebGPU depth), explicit 128-bit `Simd`, allocator control and a proved `@noheap`.
- **Concurrency is shared-nothing:** OS-thread isolates (Web Workers on wasm), channels, `scope`, `parallel_for`,
  `parallel_spawn` and `Atomic`, plus `Locked`/`ReadWriteLocked`/`ConcurrentMap`, whose lock window provably cannot
  wait or nest. Native fibers are half built (KR-3).
- **Data and tooling:** opt-in serde (JSON and three binary forms, strict reads, in-place merge, untyped `JsonValue`);
  `kama query --json`, `kama stats --json` and an LSP; and `kama agents`, which writes AGENTS.md.
- **Web:** one source builds to wasm through emscripten, and `std::app` runs the frame on `emscripten_set_main_loop`
  (rAF). Browser APIs are bound with `jsLibraries` and C prototypes, and `std::net::web` has WebSocket, WebTransport
  and WebRTC.
- **The registry has 7 `@kama/*` packages**, among them `@kama/ui` (HTML: the DOM on the web, RmlUi natively). None of
  them is GPU, window, input, audio or HTTP.
- **Build or wait 1, a job system with a cheap per-phase barrier.** `parallel_for` spawns and joins K OS threads on
  every call: 1.3–1.8 ms a call at 16–20 workers here *(verified 0.9.793)*. std's job pool is KR-3 step 9, not built.
- **Build or wait 2, the web thread topology.** A wasm program that spawns runs `main` on a worker
  (`PROXY_TO_PTHREAD`), needs COOP/COEP, and has no DOM or canvas there. Fibers on wasm are refused until KR-3 step 10
  (JSPI).
- **Build or wait 3, the platform layer.** The WebGPU binding (`@kama/gpu`, KR-25), window and input (`@kama/window`,
  KR-26) and HTTP/fetch (`@kama/http`, KR-173) are designed but not built. Audio has nothing anywhere.
- **Build or wait 4, fast iteration.** Hot reload (KR-24) is unscoped and desktop-only, and scripting/REPL is 2.0
  (KR-35). Three.js-speed prototyping has to come from kyoten: data-driven content plus serde `merge` reloads.
- **Build or wait 5, language shape.** There are no capturing closures (use functor contracts), no overloading or
  default parameters, no scoped `unsafe`, module statics are per isolate, and `@compileFor` gates whole declarations.
  The component and system API has to be designed around these.

## 1. Parallelism primitives

| Primitive | What it gives | Pointer |
|---|---|---|
| **Isolate**, via `spawn` | An OS thread natively, a Web Worker on wasm, with its own stack, heap and module statics. Two forms: a bare `spawn` inside `scope {}`, where the scope owns the join; or `Isolate h = spawn f(b: …)`, where the handle owns it. The handle can live in a field and RAII-joins on drop. Isolates are meant to be coarse: about one per core. | SPEC:7052-7079; `lib/std/concurrent/concurrent.kama:42-62` |
| **Stack** | 8 MiB on 64-bit native (reserved, not committed), 2 MiB on 32-bit, 256 KiB on wasm (`STACK_SIZE`, carved from linear memory). Set per spawn with `spawn(stack: n)` or `parallel_for(…, stack: n)`. An overflow names the clause to raise it. Fibers get a 256 KiB reservation with a guard page. | SPEC:7081-7113; `include/kama_isolate.h:42-57`; RD:2432-2433 |
| **Bundle** | The entry is a top-level `fn void` with exactly one parameter. Either `give` a `resource` that `implements Sendable` (unbounded lifetime), or `ref` a place (only from a bare `spawn` in a `scope`). | SPEC:7115-7163 |
| **Sendable** | Declared, then verified field by field. Primitives, `string`, payload-less enums, `fnptr`, `UnsafePtr` and extern structs cross without a declaration. `Shared<T>` crosses only when `T` is deeply `immutable`. An arena-backed container never crosses. `Owned<Contract>` crosses only when the contract requires `Sendable`, which is the job-queue shape. | SPEC:7229-7272 |
| **Channel\<T\>** | `bounded(capacity:)`, where 0 is a rendezvous. Endpoints are counted, so channels are many-to-many: several receivers make a worker pool. `send` returns `Undelivered<T>`. Also `tryRecv` and `recvTimeout` (monotonic clock). On a fiber, a wait parks the fiber. | SPEC:7165-7227 |
| **`scope`** | Joins every child at its closing brace, before any local drops. Children may borrow disjoint places (the prefix rule). An element borrow (`ref xs[0]`) is refused. The scope body may not touch a place a child holds. | SPEC:7274-7325; SPEC:7151-7155 |
| **`parallel_for`** | Splits a contiguous container into K disjoint sub-`View`s. `workers:` is mandatory (`workers: cpuCount()`); there is also a `const ref` read-only form. An element must not wait on another element's progress. | SPEC:7327-7372 |
| **`parallel_spawn`** | One long-lived isolate per element of a container, joined by the enclosing `scope`, with no cap. This is the pool shape. | SPEC:7374-7417; `tests/parallel_spawn_pool.kama` |
| **Atomic\<T\>** | `load`/`store`/`swap`/`compareExchange`/`fetchAdd`/`fetchSub`, sequentially consistent by default, with `…Explicit(order:)` forms. No wait/notify, no thread `yield`. | SPEC:7439-7454; `lib/std/concurrent/atomic.kama:70-151` |
| **Locked\<T\>, ReadWriteLocked\<T\>** | A lock that owns its value. The value is reachable only in `borrow h.lock().value() as v { … }`. The handle is 16 B and `copy` gives another handle; `give h.intoInner()` returns the value to the last holder. Uncontended, it costs two atomic RMWs. | SPEC:7456-7521 |
| **ConcurrentMap\<K,V\>** | Sharded `Locked<Map>`, with `cpuCount()×4` shards. Values leave by copy; there is no `compute` because there are no closures. | SPEC:7523-7579 |
| **`type immutable`** | Deeply immutable types. `Shared<immutable T>` lets many isolates read one asset with no copy; only then is its refcount atomic. | SPEC:7581-7601 |
| **Module `static`** | Per isolate (`_Thread_local`), so it cannot race. Shared mutable state goes through `Atomic` or `Locked`. | SPEC:7419-7437, 5915-5935 |
| **Fibers** (native only) | `spawn fiber f(b: …)`, `Fiber<R>`, `give f.join()`. Sockets, `sleep`, channels and joins park. One cooperative scheduler per isolate (thread-per-core). | RD:2420-2470; `lib/std/concurrent/fiber.kama` |

**What "a lock window cannot wait" means.** The body of `borrow h.lock().value() as v { … }` may reach no `@parks`
function. That covers a channel `send`/`recv`, any join (a `scope` close, an `Isolate` drop), `sleep`, the poller, a
file, a socket, DNS, stdio, a child process, and `println`/log. It may not take a second lock either: several locks are
taken together in one `borrow`, in the address order of their cells. And it may not call through a `fnptr` or a bound
function. The check is the same call-graph walk `--no-heap` runs, and a call through a contract is judged against every
implementer. The refusal names the chain (SPEC:7487-7513). `@parks` goes on a body, never on an `extern fn`, and
`grep @parks` lists every wait (`docs/KEYWORDS.md:129`). Two blind spots are stated: a blocking foreign call with no
`@parks` wrapper, and a spin on an `Atomic` (SPEC:7510-7513). A `println` inside a window is refused with *"a lock
window may not wait or take another lock … reaches `core::println`, which waits"* *(verified 0.9.793)*.

**Worker pool and job system today.** std has no job pool and no persistent pool. RD:2474-2475: *"Nothing of a pool
exists yet: `parallel_for` spawns its isolates per call."* The C emitted for one `parallel_for` makes, per call, a heap
bundle and a `kama_isolate_spawn` for each worker, then K `kama_isolate_join`s *(verified 0.9.793, `kama transpile`)*.
Because of that heap bundle, a `@noheap` body cannot contain one (SPEC:1001-1003). Measured in release builds on this
Windows host *(verified 0.9.793)*:

| Shape | Cost per call/frame |
|---|---|
| serial `foreach (ref …)` over 100k `{x, vx}` | 15–17 µs |
| `parallel_for` over the same, `workers: cpuCount()` (20) | 1.83 ms |
| `parallel_for` over 64 elements: k=1 / 4 / 8 / 16 | 0.15 / 0.43–0.47 / 0.76–0.79 / 1.34–1.38 ms |
| persistent pool (`parallel_spawn` × 20, one job channel out, one ack channel back): 20 jobs + 20 acks | 245–252 µs |

Windows thread creation is slow. Linux and macOS will be cheaper, but they are not measured here. Either way a
per-call spawn is the wrong shape for 4 phases × 60 Hz *(inferred)*.

**KR-3's plan for the job pool** (fibers.md decision 5, `docs/design/fibers.md:272-294`):

- There are two schedulers: per-isolate fibers for I/O, and a separate CPU job pool sized by `cpuCount()`.
- The pool's unit is a `Sendable` job, so the pool may steal work.
- A job entry that reaches `@parks` is refused at compile time.
- A fiber that needs CPU work submits a job and parks on its result.
- This is step 9 of 11 (`fibers.md:763`), after step 7 (an offload pool for files, DNS and blocking C) and step 8
  (Windows). Steps 1–6 shipped in 0.9.737–0.9.751 (RM:83).
- `docs/ENGINE_READINESS.md:130` calls the engine scheduler "an ordinary library … no language work left".

**What a per-phase parallel-for can be built from now** *(inferred)*:

- A `cpuCount()`-sized `parallel_spawn` pool inside a long-lived `scope`, or `Isolate` handles held in fields.
- Jobs as `Owned<Job>` with `type contract Job for resource implements Sendable` (SPEC:7250-7255).
- A phase barrier on `Atomic<int32>` counters, or on channels if workers should sleep: there is no futex or condvar.
- The catch: while children hold `ref` to world data, the scope body may not touch it (SPEC:7151-7155). So a persistent
  pool over a world that the main loop also writes needs `UnsafePtr` plus ranges in an `unsafe fn` seam. SPEC:7269-7272
  calls this "the primary isolate idiom", with the join or barrier ordering the writes. Disjointness then becomes
  kyoten's invariant to keep, not the compiler's.
- Fixed-rate components need nothing special: `std::time` has a monotonic `Instant`/`Duration`, and `sleep` parks
  (`lib/std/time/time.kama:3`).

## 2. On the web (wasm / emscripten)

- **Toolchain.** `--target WASM` (`wasm32-emscripten-none`) needs `emcc` and emits `.html` + `.js` + `.wasm`
  (docs/targets.md:42-48, 809-814). Every build passes `-msimd128`, so a browser needs wasm SIMD. Release is `-Oz` on
  wasm (docs/GOALS.md:171-173).
- **CI.** Every positive fixture runs under **node 24**, not in a browser (`.github/workflows/ci.yml:105-129`). So
  browser hosting (COOP/COEP, a worker-hosted `main`) has no CI leg *(inferred)*.
- **Threads.** Isolates are emscripten pthreads, which are Web Workers over one SharedArrayBuffer. A build turns
  threaded only when the program creates a thread (`spawn`/`parallel_for`/`parallel_spawn`), never because it
  imported `Atomic` (docs/FLOOR.md:46-52; `src/kama.driver.cpp:13714-13721`).
- **What a threaded build gets.** The link line for a `parallel_for` program adds `-pthread -sPROXY_TO_PTHREAD=1
  -sPTHREAD_POOL_SIZE=0 -sPTHREAD_POOL_SIZE_STRICT=0 -sSTACK_SIZE=262144 -sEXIT_RUNTIME=1` *(verified 0.9.793,
  `--cc echo`)*.
  - **`PROXY_TO_PTHREAD` moves `main` onto a worker**, because `Atomics.wait` throws on the JS main thread
    (`src/kama.driver.cpp:13851-13857`).
  - **The cost is stated in `tools/check-target.sh:188-192`:** the SharedArrayBuffer needs COOP/COEP headers, which
    "break a cross-origin WebSocket", and the worker has no `document`. A WebGPU client "died … reading `getContext` on
    a worker".
  - **Consequence for kyoten** *(inferred)*: a threaded kyoten web build runs its kama `main`, and so its `std::app`
    loop and any WebGPU or DOM call, on a worker. To keep rendering and DOM on the page thread, kyoten has to design
    the split itself: OffscreenCanvas transfer, JS-side proxying, or a single-threaded wasm main plus separately
    hosted workers. Nothing in kama sets this up. Whether rAF pacing holds for a main loop on a worker is unverified.
  - **Worker pool.** `KAMA_PTHREAD_POOL` pre-warms worker slots (docs/targets.md:790). The pool is a latency knob,
    not a cap.
- **`spawn` on wasm** works: an isolate is a worker. **`spawn fiber` on wasm is a compile error:** *"fibers on wasm run
  over JSPI, which kama does not build yet (KR-3)"* *(verified 0.9.793, `kama check --target WASM`)*. JSPI is ruled as
  KR-3 step 10 (fibers.md:245-270, 764).
- **Main loop.** `std::app::run(tick:, state:)` is `emscripten_set_main_loop_arg(step, l, 0, 1)` on the web: fps 0
  means `requestAnimationFrame` in a browser. Natively it is `while (tick(state)) {}` (`include/kama_app.h:26-41`).
  - `TickFn` is `@callerThread fnptr int32 TickFn(UnsafePtr state)` and `run` is `@parks unsafe`
    (`lib/std/app/app.kama:18-23`).
  - On the web `run` never returns, so `main`'s locals are never dropped. That is required, not a leak (RD:2907).
  - Use `quit(code:)`, because a plain exit is ignored (SPEC:3176-3182).
- **Binding JS.** `jsLibraries` is a list of `--js-library` files that a package ships with its glue, and
  `emSettings` carries `-s` settings: lists union, scalars are last-wins with the root winning, and two dependencies
  setting one scalar differently are refused (docs/targets.md:438-500). Also `shellFile`, `embedFiles` and
  `preloadFiles` (docs/targets.md:455-475).
- **std's own JS binding pattern.** `lib/std/net/web/kama_net_web.js:1-8` and `kama_net_web.h:1-10`:
  - `extern fn` C prototypes in a header, with JS bodies via `mergeInto(LibraryManager.library, …)`.
  - Integer handles index a JS table.
  - A **pull model:** JS events enqueue, and kama polls (`-1` means WouldBlock). There are no callbacks into wasm, no
    Asyncify and no `expose`.
  - The glue declares no `__proxy`, so in a threaded build a socket lives on the calling worker *(inferred)*.
- **The other direction.** `expose fn` exports a symbol from the `.wasm` (`EMSCRIPTEN_KEEPALIVE`). An embedder calls it
  through the module's exports, not as `Module._x` (SPEC:4513-4517).
- **C callbacks.** A C callback (WebGPU's async adapter and device) is a kama `fnptr` that must carry `@callerThread`
  or `@foreignEntry` (SPEC:1216-1259). The WebGPU example threads its state through `userdata`
  (`examples/webgpu/README.md`, "How it maps").
- **Cost model.** Each `extern` call is a wasm→JS import call. Strings cross as a pointer plus `UTF8ToString`, a copy;
  bytes cross as `(ptr, len)` into `HEAPU8` (exported for std's glue, `src/kama.driver.cpp:13849-13850`). WebGPU on the
  web is emscripten's `emdawnwebgpu` port (`--use-port=emdawnwebgpu`, which also forces `-sDEFAULT_TO_CXX`), and it
  implements webgpu.h in JS, so every `wgpu*` call is a JS crossing (docs/targets.md:167-172 *(inferred for the
  per-call claim)*). Nothing in the repo measures any of this.

## 3. Graphics, windowing, input, audio

- **Where the GPU seam is.** It left std in 0.9.652. It is now `examples/webgpu`'s own platform layer:
  `csrc/gpu.h`, which holds the web bodies as `static inline` (`#canvas` selector, present a no-op, pump returns 1);
  `csrc/gpu.c` (native GLFW); and `csrc/gpu_macos.m` (CAMetalLayer). These are gated by fact in the example's
  `kama.json` (RD:2806-2812, 2851-2867).
  - The whole seam is four functions: `gpu_surface`, `gpu_present`, `gpu_pump` and `gpu_sleep_ms`.
  - `src/triangle.kama` (461 lines) is pure kama over webgpu.h: handles are `UnsafePtr`, descriptors are `type extern
    value`, and the async device setup uses `fnptr` callbacks.
  - **Its known faults:** five hand-written `wgpu*Release` calls per frame; leaked shader module, adapter and instance;
    hardcoded 512×512 BGRA8; a native window that is a file static, never destroyed; and no input at all (RD:2860-2861,
    2936-2942).
  - **The toolchain keeps `--webgpu` / `"webgpu": true`.** Natively that is the wgpu-native SDK via
    `tools/fetch-webgpu.sh` or `$KAMA_WGPU_DIR`; on the web, the emdawnwebgpu port (docs/targets.md:167-178).
    `tools/check-webgpu.sh` keeps the example building.
  - **webgpu.h differs** between emdawnwebgpu and wgpu-native: 199 functions are shared (RD:2862-2864).
- **`@kama/gpu` (KR-25, RM:141): designed, not built.** It is a LATER row and gets its own repository.
  - **Design** (RD:2846-2925): one RAII `type resource` per handle; `adopt`/`raw` escape hatches; the once-only steps as
    moves (`encoder.finish()`, `queue.submit(give …)`, `frame.present()`); a typed `surface.acquire() ->
    Result<SurfaceTexture, SurfaceError{Occluded, Outdated, Lost, …}>`; and a polled `DeviceRequest`, with no closures
    or Asyncify.
  - **Decided 2026-10-16:** copy is `AddRef` (`Copyable(bare: give)`); handles are independent of their parent; safe
    creation covers the triangle's set first; and `Occluded` sleeps 32 ms natively.
  - Size L, four commits. No date. RM's LATER section "mostly gates on the repo going public" (RM:127).
- **`@kama/window` (KR-26, RM:142): designed, not built.** It also gets its own repository.
  - **Design** (RD:2929-3009): a non-`Sendable` `Window` (GLFW natively; `#canvas` plus html5.h callbacks on the web,
    with no JS library); one coalescing ring of `Event` (`KeyDown`/`KeyUp`/`Text`/`MouseMove`/`Scroll`/`Resize`/
    `Focus`/`PointerLock`/`CloseRequested`/`Dropped(n)`); a physical `Key` keyed by USB HID ids, matching DOM `code`; an
    explicit `pump()`; `Window.headless` + `post` for tests, replay and servers; and gamepad later.
  - RD:2801-2804: *"No consumer uses the std seam today: the downstream engines bind `<webgpu/webgpu.h>` and their own
    GLFW platform layer … nothing waits on the packages."*
- **What exists for UI, from the registry** *(verified 0.9.793, `kama pkg search` + `registry.kama-lang.org/catalog.json`)*:
  - `@kama/ui` 0.6.0: "One set of HTML documents for kama UIs: the browser's own DOM on the web, RmlUi natively".
  - `@kama/rmlui` 0.2.0 and `@kama/freetype` 0.1.0.
  - The source is at github.com/cosmic-canopy/kama-ui. `the-mallow-man/game/kama.json` and
    `cosmic-forge/forgeui/kama.json` depend on it. Not inspected here.
- **Audio: nothing.** There is no audio module in `lib/std` and no audio example; `grep -ri audio` hits only comments
  and fixtures. What kama does provide:
  - **The browser blocker is gone.** 0.9.160 removed the `-fsanitize` flags that made emscripten refuse
    `-sWASM_WORKERS`, "and with it AudioWorklet". Wasm Workers still need SharedArrayBuffer and so COOP/COEP
    (RD:1709-1719; SPEC:2351).
  - **The real-time callback shape:** `@foreignEntry @noheap @onPanic(recover: …)` on the C-called function, with
    state passed through the userdata pointer (SPEC:1216-1297).
  - **`debug.optimize`**, which lets a DSP package run at release speed inside a debug build. A DSP was measured 95×
    slower at `-O0` (docs/targets.md:248-266).
  - **Glue:** `jsLibraries` (its own example file is `js/audio_glue.js`, docs/targets.md:442) and `csources` for
    miniaudio or CoreAudio.
- **Networking.** std has TCP, UDP, Unix sockets and `Poller` natively. In the browser it has `WsConnection`,
  `WtConnection` (WebTransport datagrams) and `RtcConnection` (WebRTC DataChannel, unreliable or reliable)
  (SPEC:3184-3201). HTTP is out of std on every target: `fetch`, `EventSource` and the HTTP/1.1 server are
  `@kama/http` (KR-173, LATER, RD:521-536). TLS is `@kama/tls`.
- **What kyoten must build itself today** *(inferred from the above)*:
  - its own webgpu.h binding and RAII layer, or wait for KR-25;
  - its own GLFW and html5 window/input/gamepad layer, or wait for KR-26;
  - Web Audio and native audio glue;
  - `fetch`-based asset streaming on the web (emscripten's `preloadFiles`/`embedFiles` cover bundled assets);
  - the decision on how page-thread DOM, WebGPU and workers fit together (§2).
  - The engine spine (buffers, pipelines, renderer, scene) is by charter "the engine product built on kama, not part
    of kama" (RD:2786-2792; docs/ENGINE_READINESS.md:149).

## 4. Performance features

- **Release build.** Native `--release` folds the whole program into **one translation unit** (cross-module inlining)
  at `-O3`; wasm is `-Oz`, `-DNDEBUG`, stripped (docs/targets.md:25-28; docs/GOALS.md:171-173). A debug build is per
  TU at `-O0`. **`debug.optimize`** lifts named packages or modules to the release level in a debug build. Only the
  root manifest's applies, and per-function `@optimize` is a non-goal (docs/targets.md:248-266; RD:706-707).
- **Benchmarks** are at C parity by design: kama is compiled by the same clang (`docs/benchmarks/RESULTS.md:1-30`).
- **Iteration time** *(verified 0.9.793, Windows)*, for a small program importing 8 units: `kama check` 0.38 s, debug
  build 1.8 s with or without the object cache, release 1.3 s.
- **SIMD.**
  - **Auto-vectorization comes first.** `std::math`'s layout packs at `-O3`, and clang de-interleaves AoS→SoA for `dot`
    and `Mat4.transform`. `tools/check-simd-native.sh` and `check-simd-wasm.sh` guard it (docs/ENGINE_READINESS.md:111).
  - **Explicit `Simd<T>#(N)`** is for what auto-vectorization cannot express: `shuffle` with a literal pattern,
    `blend`, `Mask<T>#(N)` with `select`, `reduceAdd/Mul/Min/Max`, `min/max/abs/sqrt/floor/ceil`, and the
    `@compileFor(SIMD128)` flag.
  - **The limits:** `sizeof(T)*N` must be **exactly 16 bytes**, so there is no AVX, pending a CPU-tuning knob (KR-23).
    A hand-written lane batch measured 65% slower than scalar source for a cross product (SPEC:4251-4342).
  - Shuffle, mask, select and reduce compile and run correctly *(verified 0.9.793)*.
  - ⚠️ `docs/ENGINE_READINESS.md:66` still says "there is no explicit vector type … a shuffle or a lane mask has no
    spelling". That line is stale: SPEC and line 111 of the same file say otherwise.
- **`@noheap` / `--no-heap` / `"no-heap"`.** This is a whole-call-graph proof, not a lint (SPEC:999-1137).
  - It sees through destructors and contract slots, to every implementer.
  - A `fnptr` call needs an `@noheap fnptr` signature.
  - `parallel_for`, `spawn`, `"${…}"` interpolation, string building and `GlobalAllocator` containers are refused
    inside. A `DynamicArray<T, BumpAllocator>` is fine.
  - The diagnostic names the chain: `tick -> DynamicArray<Particle>::add -> growTo -> GlobalAllocator::allocate`
    *(verified 0.9.793)*.
  - Open: KR-245. Once any isolate runs fibers, `@noheap` socket I/O and `sleep` are refused program-wide.
- **Allocators.**
  - Every container takes `A: Allocator = GlobalAllocator` (a direct monomorphized call). `Arena` + `BumpAllocator`
    give an O(1) `reset()`.
  - Placement `new(allocator: a) T.make(…)` yields `Owned/Shared/Weak<T, A>`, and `try new` returns
    `Optional<Owned<T>>` on exhaustion (SPEC:895-997, 1298-1335).
  - `@globalAllocator type resource Pool implements GlobalHeap` replaces the process-wide funnel; its fields must be
    `Atomic`, immutable, or raw (SPEC:1139-1214).
  - An arena-backed container is **not Sendable** (SPEC:7246).
- **Layout and bytes.**
  - `InlineArray<T>#(N)` is a bounds-checked value array (ENGINE_READINESS:112).
  - `@align(N)`/`@packed` describe vertex or std140 layout (ENGINE_READINESS:66).
  - `@generate(BytesViewable)` / `@generate(Blittable)` give a plain value's own bytes as
    `ConstView<uint8>`/`View<uint8>` for upload or networking, with no serde pass (SPEC:715-763).
  - `bitcast<T>` and `std::num` byteswaps cover byte work. KR-270 (endian load at an offset) is queued.
- **Views and zero-copy.** `View<T>`/`ConstView<T>` are stack-only borrows (a C# `ref struct`). They are escape-checked,
  compose, and `borrow <place> as v { }` windows them (SPEC:400-713). Zero-copy deserialization into a view (KR-231)
  and a `string` from owned bytes without a copy (KR-273) are queued.
- **Frame sizes in debug** *(verified 0.9.793, a 16 KB value, `clang -fstack-usage`)*:

| Shape | -O0 frame | -O2 frame |
|---|---|---|
| `Big b = Big.make(…); byValue(b: b)` (caller) | 32,824 | 16,440 |
| same, but `byConstRef(b: b)` | 16,440 | 16,440 |
| `foreach (Big x in xs)` (by value) | 32,888 | 40 |
| `foreach (ref Big x in xs)` | 120 | 40 |
| `Big b = xs[0]` | 16,440 | 56 |

  Constructor, fill, return and `match` copies were removed in 0.9.534–0.9.654 and are guarded
  (`tools/check-construct-frame.sh:1-20`, `tools/check-fill-frame.sh:1-10`). By-value arguments and by-value `foreach`
  bindings still copy at `-O0`. In a debug wasm build, frames live in the 256 KiB stack (SPEC:7090), so big by-value
  components hit that first *(inferred)*. The rule: `const ref` parameters and `foreach (ref …)`.
- **Arithmetic** (SPEC:2295-2330):
  - Signed overflow traps in debug and wraps in release (`-fwrapv`).
  - Divide by zero, `INT_MIN/-1`, an out-of-range shift, an out-of-range float→int and a narrowing `cast` that does not
    fit trap in **every** build.
  - Explicit `wrapping…`/`truncate<T>`/`try cast` exist.
  - Dynamic bounds checks are emitted C, with no `NDEBUG` gate in `include/kama_runtime.h:392, 624`, so they stay in
    release *(inferred)*.
  - **`"reproducible-float": true`** turns off FMA contraction, so the same source gives the same bits on native and
    wasm: 13 of 64 triples differed without it on aarch64 (docs/targets.md:180-211). It matters for replay and lockstep.
  - **`Rng.seeded(seed:)`** (xoshiro256**) gives the same stream on every platform and build, and a fixture pins it
    (`lib/std/random/random.kama:4-21`).

## 5. Data and tooling for an AI-driven engine

- **Serde** (SPEC:7613-7979).
  - **Opt-in:** `@generate(Serializable, Deserializable)`, plus `@field(name:|id:|default)`, `@deprecated` and
    `@skip`. An unmarked field is a compile error.
  - **Four back ends:** JSON, and three binary KBIN forms (named, numbered with protobuf-style ids, positional). Each
    has `…Buffer` and `…Stream` entry points.
  - **Object graphs** with `Shared`/`Weak`, including `Shared<Contract>`.
  - **Merge:** `mergeJsonBuffer(src:, into:)` writes only the fields the document names. It merges per key into maps,
    recursively into records, and atomically: on error the value is untouched (SPEC:7657-7700). That makes it the
    live-reload and layered-config primitive.
  - **Strict reading:** `JsonDeserializer.strict(src:)` refuses an unknown key (`UnknownField`), for hand-written files
    (`lib/std/serialization/text/json/json.kama:241-248`).
  - **`JsonValue`** (`Null/Bool/Number/String/Array/Object` over an `OrderedMap`) keeps exact numbers and key order and
    can be a field of a typed schema, for example glTF `extensions` (SPEC:7710-7740).
  - **Open:** yaml and csv back ends, plus two named bugs (KR-189); view deserialization (KR-231).
- **`kama query`** answers from the compiler's resolution, not text: `--symbols`, `--search NAME`, `--def`/`--type`/
  `--refs`/`--impl`/`--complete`/`--sighelp L:C`, `--diagnostics` and `--coverage`. Modes combine in one analysis. A
  leading `kama.json` or `kama_workspace.json` widens the scope (`docs/agents.md:38-198`). `--json` gives
  `{"schema":1,"mode":…,"file":…,"results":[…]}` *(verified 0.9.793)*.
- **`kama stats --json`** counts lines by the lexer, declarations by kind, templates vs emitted instances, the
  unsafe/FFI surface, gated-out code and the largest declarations *(verified 0.9.793)*.
- **`kama check`** analyzes every `@compileFor` configuration with no cross toolchain (`kama --help`).
- **`kama demangle`** plus LLDB formatters.
- **Gaps in query:** no `callers-of` and no unsaved-buffer mode (KR-33); no doc comments or export flag in answers, and
  no `kama doc` (KR-268); no `kama describe --json` (KR-84).
- **LSP:** `kama lsp`, one server for 8 editors, and a VS Code extension with F5 debugging through CodeLLDB
  (docs/editors.md:1-60). Residuals are KR-30.
- **`kama agents`.**
  - `install <kama.json>` writes `AGENTS.md`. `--claude` adds a `CLAUDE.md` that `@`-imports it, `--all-tools` adds
    pointer files for Cline, Copilot, Junie, Kiro and Qoder, and `--skill` adds `.claude/skills/kama/SKILL.md`.
  - A `"kind": "library"` project also gets `AGENTS.package.md`.
  - Nothing is overwritten without `--force`, and there is no include or extension mechanism: "use `kama agents print`
    and merge by hand" (`docs/agents.md:10-36`; `kama agents list` *(verified 0.9.793)*).
  - The shipped guide's sections: ask the compiler; demangle; check then build; rules an LLM will get wrong;
    conventions; where the truth is (`agents/AGENTS.md`).
  - kyoten already keeps its own rules in a separate `kyoten/AGENTS.kyoten.md` so that a re-install cannot clobber them
    (`kyoten/AGENTS.kyoten.md:1-4`).
  - KR-148 (agent tooling: a Claude Code plugin, symbol-named query modes, call hierarchy) has 9 decisions owed. MCP is
    proposed as a non-goal (RM:139).
- **Hot reload (KR-24, RM:117): unscoped.** Both compiler primitives ship: `kama build --shared` (only `expose`d
  symbols are visible) and `expose` with a stable C symbol `module_path_name` or `@linkName`. A generated `<project>.h`
  host header and `type expose value` cover published layouts (SPEC:4482-4581). The `dlopen`/watch/rebind loop is a
  library nobody has written, the architecture is "data in host, code in module", and the scope is desktop dev only:
  there is no dlopen on wasm or iOS (RD:2830-2842).
- **Comptime.** `comptime` constants and parameters, `comptime fn` (runs in the compiler, bakes a scalar or a table into
  a `static const`, bounded and pure, never emitted), and `comptime assert` (SPEC:5960-6130).
- **Scripting/REPL** is the 2.0 flagship (KR-35, RM:151; RD §7). Nothing ships today; `kama run` is native-only and
  goes build-then-execute (`kama --help`).

## 6. Packages and monorepos

- **Kinds.** A project states `"kind": "executable"` (with an `entry`) or `"library"` (with `modules`). A monorepo root
  is not a project: it holds only `kama_workspace.json`, with no name or version (docs/packages.md:117-167).
- **`kama seed X --kind monorepo --members engine,game`** writes `kama_workspace.json` (each member
  `"optional": false`), one library per member (`kama.json` with `"kama": ">=0.9.793"` and `"modules": {".":
  {"visibility": "public"}}`, plus `src/<name>.kama`), `.gitignore` and `README.md` *(verified 0.9.793)*. Optional
  extras: `--license mit|apache-2.0|mit-or-apache`, `--agents`/`--claude`.
- **Workspace rules** (docs/packages.md:332-472):
  - A project never reads the workspace file for compilation, so every member stays extractable.
  - Members come from paths or globs (`libs/*`), and each states `optional`.
  - Workspaces do not nest. A `kama.json` beside `kama_workspace.json` is an error.
  - **A member declares every sibling it imports** as `{ "path": "../x" }`. An undeclared import fails and names the
    line to add.
  - Path dependencies are allowed only between members of the workspace that declares them. A fetched package's path
    dependency is refused. A path dependency on an unlisted directory is refused by design (RD:708-712).
  - `kama pkg install kama_workspace.json` resolves every member on its own.
- **What a dependency contributes.** Its `cflags`/`ldflags`/`link`/`csources`/`jsLibraries`/`emSettings` and embed
  files reach your build. `no-heap` and `webgpu` come from the root manifest only. `reproducible-float` propagates
  one-way (docs/targets.md:204-211, 502-536).
- **Fact-gated entries.** `csources`, `link` and dependency edges take fact gates (`"compileFor": ["OS_MACOS"]`), which
  is how one manifest carries web and native platform layers (`examples/webgpu/kama.json`).
- **Registry.** `registry.kama-lang.org` is the built-in default: a static file tree with tarballs at
  `dl.kama-lang.org`. Signing is optional; the trust model and provenance are KR-27, in progress (RM:131;
  docs/packages.md:557-850).
  - **The seven packages** *(verified 0.9.793)*: `@kama/freetype` 0.1.0, `@kama/postgres` 0.4.0, `@kama/redis` 0.3.0,
    `@kama/rmlui` 0.2.0, `@kama/sodium` 0.6.0, `@kama/tls` 0.1.8, `@kama/ui` 0.6.0.
  - `kama pkg search gpu` and `… window` match nothing.

## 7. Known gaps and limits that shape an engine

- **No capturing closures** (`(int32 x) => x * k` is a parse error *(verified 0.9.793)*).
  - The answer is a **functor**: a callback contract plus one `type resource` per handler, its captures held as fields.
    Store it as `Owned<Handler<E>>`, or lend it through a `<V: Visitor<T>> ref V` bound, which monomorphizes
    (SPEC:1983-2003).
  - Closure sugar is "sized, not scheduled" (RD:1300-1318). This shapes system registration, event tables and
    `ConcurrentMap` updates.
- **No overloading** (operators are the exception, RD:1394-1397) and **no optional or default parameters**
  (SPEC:7343-7344). Construction goes through named ctors such as `withAllocator(allocator:)`.
- **No scoped `unsafe {}`: a non-goal** (RD:701-705). `unsafe` marks a function body, and calling one is unrestricted
  (SPEC:3578-3643). Raw pointer use lives in private `unsafe fn` helpers.
- **`@compileFor` gates whole declarations, never a member, by design.** Platform deltas go in per-platform types or
  file gates (`file @compileFor(X);`). A `type adapter` block cannot be gated (KR-21, RM:114; SPEC:3779-3990).
- **`fnptr` limits** (SPEC:4344-4481, 1983-1989):
  - non-null, with no type parameters;
  - refused inside a lock window;
  - inside `@noheap` only through an `@noheap fnptr` type;
  - every C crossing needs `@callerThread` or `@foreignEntry`.
  - `BindableFunctionPtr` is move-only, never `Sendable` when bound from a `Shared`, and refuses an arena box.
- **Module statics** are per isolate. On a foreign thread (audio, a C callback) a static holds only its initializer,
  which `@foreignEntry` turns into a compile error (SPEC:1216-1256). A static cannot own a destructible resource, a
  deliberate deferral (RD:1726). Engine singletons are passed in as state, not held in globals.
- **No mutex or condvar besides `Locked`, and no `Once`** (SPEC:7199-7200, 2010-2012). No thread `yield` and no atomic
  wait or notify (`atomic.kama`).
- **Debug-tier copies:** by-value arguments and by-value `foreach` (§4 table).
- **SIMD stops at 128 bits** (KR-23).
- **Fibers.** On wasm they are refused (KR-3 step 10). On Linux x86-64 under CET shadow stacks they refuse with a
  message (KR-238). `@noheap` reach is program-wide once fibers run (KR-245).
- **Engine track (RD §8).** The language side is "done"; buffers, pipelines, renderer and scene are the engine
  product's own. GPU and window are packages, not std, decided 2026-10-16 (RD:2794-2804).
- **Windows-only traps** (docs/platforms/windows.md:180+): `long` is 32-bit; `system()` runs cmd.exe; a running exe is
  locked. kyoten already filed KY-1 (`kama run` on a library, `kyoten/docs/KAMA_GAPS.md`).

## Addendum: fibers in detail (KR-3), and what they mean for kyoten

Read from `docs/design/fibers.md` (807 lines, ruled 2026-10-22) at 0.9.793. Added after the survey above, because the
owner asked about fibers directly.

- **The model** (`fibers.md` §4): one isolate per core, each running a cooperative fiber scheduler over its own
  `Poller`. A fiber is a 256 KiB stack *reservation* (1–2 pages resident when parked) plus about 128 B; a switch is
  about 10 ns each way (measured, arm64). A park on a socket costs the failed `read` on epoll/kqueue and one IOCTL on
  Windows.
- **Shipped: steps 1–6** (`fibers.md` §8): the switch and stacks (`0.9.737`), the scheduler (`0.9.738`),
  `spawn fiber`, `Fiber<R>` and `join` (`0.9.741`), the park rule (`0.9.743`), sockets/`sleep`/`Poller` park on a
  fiber (`0.9.745`–`0.9.748`), channels and joins park (`0.9.751`). Pipes park since `0.9.786`.
- **Not yet:** step 7 the offload pool (files, DNS, `offload(…)`), step 8 Windows completion I/O, **step 9 the CPU job
  pool**, **step 10 fibers on wasm over JSPI** (standardized: Chrome 137, Firefox 153, Safari 27; *not* Asyncify, and
  not emscripten's `fiber.h`), step 11 docs and the debugger plugin.
- **Decision 5, two schedulers** (`fibers.md:272-294`): fibers are for I/O and never migrate between isolates (they hold
  non-`Sendable` state). CPU fan-out is a **separate job pool** sized by `cpuCount()`, whose `Sendable` jobs can be
  stolen. A fiber that wants CPU work submits a job and parks on its result. **A job that could park is refused at
  compile time.** `parallel_for` stays the data-parallel layer; the job pool is the task-parallel one.
- **Related open rows:** KR-255 (thread-per-core loses to work stealing for a few bursty connections; the burst goes to
  the job pool), KR-265 (a virtual clock for the fiber scheduler), KR-244 (a read half and a write half on one
  socket), KR-245 (`@noheap` reach once fibers run), KR-238 (CET shadow stacks).

**For kyoten** *(inferred)*:
- **The frame phases' parallel work belongs on the job pool** (step 9) or on a pool kyoten builds until it lands.
  Frame jobs never park, which the job-entry rule enforces for free.
- **Fibers fit kyoten's I/O:** the hosted networking backend is exactly KR-3's server model (an isolate per core, a
  fiber per connection), and so are asset streaming and the tools' dev server.
- **On the web,** fibers wait for step 10, and need a JSPI browser when they arrive; the frame loop does not depend
  on them.
- **Game-logic coroutines** ("wait two seconds, then open the door") are *not* obviously fibers: a fiber parks on the
  real clock, and a replayable simulation needs its own clock (KR-265 is about the scheduler's clock, for tests). This
  is a question for the frame-phases walk-through, not a recommendation.
