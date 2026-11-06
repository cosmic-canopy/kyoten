# kama's KR-3 pool brief, audited against kyoten

KYR-59, written 2026-11-05. kama's KR-3 row says the pool *"waits on an audit by the engine that asked"*, and this is
that audit. The owner asked for two things. The first is the brief checked against every question kyoten has left. The
second is a full picture of kyoten's kama gaps, as early as possible, so kama hears about them before it builds.

**What was read:**
- The brief: kama `docs/ROADMAP_DETAIL.md` § *The job pool and the offload pool: one brief (KR-3)*, ruled 2026-11-05
  (`09a59b39`), with KR-320 to KR-327 and KR-288, KR-313 and KR-315. It was read at kama's HEAD, `4b6d33d8`.
- kyoten's decided designs: architecture, frame-phases, and components questions 1 and 2.
- The 41 questions still open in the narrowed spike ([../SPIKE.md](../SPIKE.md) § Narrowed).

**How it was checked:** every probe ran on kama **0.9.852** (`0.9.852+g4b6d33d8`), on Windows 11 under msys2 UCRT64, and
the wasm builds ran under node 24.21 (emsdk 6.0.13). Each claim says how it was checked: *probed*, *read* (with a file
and line), or *not checked*.

## The verdict

- **The brief gives kyoten what it asked for, and nothing in it conflicts with a decided kyoten design.** It answers
  KY-12 (a pool that runs borrowing work with no allocation per hand-out), KY-5 (decision 10), KY-13 (decision 11) and
  KY-15 (decision 12). Each stays open in [../KAMA_GAPS.md](../KAMA_GAPS.md) until it is built, because a gap closes on
  a repro, not on a ruling.
- **kama asked kyoten two questions, answered below:**
  - KR-326: which arena shape kyoten needs. It needs both, for two decided cases.
  - KR-327: whether a single-threaded wasm build is a per-build setting. Yes, and frame-phases decided it.
- **One new gap was found, and it is a bug against kama's own promise.** `reproducible-float` does not cover
  `std::math`'s transcendental functions, so `sin` gives different bits natively and on wasm (KY-19, filed today).
- **A second bug was found the same day, while components question 3 was prepared, and it touches the pool directly.**
  A `parallel_for` body may read the container it splits by `ref`, so a worker reads an element another worker is
  writing (KY-20). *Probed:* three runs read a counter mid-count. KR-323 closed the write half on 0.9.851. Moving
  `parallel_for` onto the pool is the moment to close the read half. *(Later the same day, kama filed it as KR-333 and
  fixed it in `c39d620c`.)*
- **kyoten's needs, added to five rows kama already has:**
  - **KR-320:** long jobs arrive with the held `Job<R>`, not later.
  - **KR-325:** names, priorities and core classes for threads.
  - **KR-298:** `trySend`, for Output's hand-off from a job.
  - **KR-79:** a step that reaches no outside input.
  - **KY-18:** a held job cannot borrow, so it can read a shared asset only through `Shared<immutable T>`.
- **KR-322 is no longer needed for kyoten's tables.** It came from kyoten (2026-11-04), before components question 1
  put each table's columns in one chunk.
- **Every other remaining question was checked for a kama dependency.** Most have none. A few depend on how their
  question is answered, and those are marked *conditional* in the map below.

## The seventeen decisions, against kyoten

| # | Decision | What kyoten does with it | Missing for kyoten |
|---|---|---|---|
| 1 | `parallel_for` moves to the pool; `spawn job` is new | The generated phase methods split each table by chunk with `parallel_for` (components question 1). The pool takes a 10-chunk hand-out from 102 µs to 39 µs (the brief, M4). The source break touches no code kyoten has written, since the generator will emit the new spelling | nothing |
| 2 | `spawn job` is a language form, its count read off the block | One `spawn job` per table, in a generated `scope`. Tables are fields of the generated world, so the count is static. Zones loaded at run time (G7) go through a `parallel_for` over zones with another nested inside it, which *probed* fine (exit 2) | nothing |
| 3 | The held `Job<R>` | Work that spans frames and runs off the simulation (frame-phases question 1): streaming a zone, generating cells (components question 9), decoding assets, building a navmesh | **KR-320** and **KY-18** (*kyoten's needs* below) |
| 4 | One process pool, started at its first hand-out or by `setJobThreads` | frame-phases question 7: "the build decides whether threads exist, and start-up decides how they are used". `setJobThreads(count:)` at start-up is the second half. `count: 1`, which runs every form on its caller in order, is the serial default, and CI holds serial and parallel runs to one hash | the build half, on the web: **KR-327** (below) |
| 5 | A job may wait on the OS, not on another task | A simulation step should wait on neither. A step that reads a file or a clock breaks replay | conditional: a proof of that, through **KR-79** |
| 6 | A barrier spins for 50 µs, with no knob | A few hand-outs per phase, which is the shape the brief measured (twelve in a 60 Hz frame) | not measured on Quest or phones, where a spin costs battery and heat (KR-281, KR-283). kyoten's VR prototype (KYR-4) can measure it there. No ask yet |
| 7 | A job cannot reach a module `static` | kyoten welcomes it, since a result that depends on which worker ran it is what a world hash exists to catch. **Its consequence for kyoten:** engine code that runs inside an Update or Output job keeps no module statics, and the peers' renderers do keep them ([harvest.md](harvest.md) *What this does not decide* 3). Rendering questions 1 and 4 design for that | nothing |
| 8 | `stack:` is kept | — | nothing |
| 9 | Panics, and `@onPanic` | — | nothing |
| 10 | KR-288: readers share | It closes KY-5, and lets several tables' tasks read one asset store (components question 2, kind 3) | nothing |
| 11 | KR-313: a `spawn` over several places | It closes KY-13. A table's `dt` no longer has to ride inside the table | nothing |
| 12 | KR-315: parts chosen at run time, checked distinct when the scope runs | It closes KY-15 for a fixed set of tasks; a count known only at run time is `parallel_for` with `continue`. A side-store system that writes tables through handles stays serial (components question 1), because a parallel write through a list of handles is outside this decision. kyoten spells that case with a damage store instead | nothing; kyoten has a spelling for the case outside it |
| 13 | `workers:` becomes `chunks:` | kyoten already says "chunk" for its block of up to N entities (Unity's term, components question 1). Generated code would read `parallel_for (ref SoldierChunk c in this.chunks, chunks: n)`, one word for two things | not an ask: kyoten can rename its own term (a choice for the owner) |
| 14 | The pool in kama, with `Atomic.wait` and `notify` | — | nothing |
| 15 | The offload pool | A streaming job may read files, which decision 5 allows | nothing |
| 16 | `parallel_for` may bind a chunk | Per-chunk reductions: the world hash over a parallel step (replay question 5), counts against budgets (G2), and Output's culling. **kyoten's own rule:** the hash must not depend on `chunks:`, so it hashes per entity chunk and combines in order | nothing |
| 17 | A view may go to a scope child, and `splitAt` makes two | Parallel sorts: render sort keys and a broadphase | nothing |

## kama's two questions

### KR-326: which arena shape does kyoten's work need?

**Both shapes, each for a case kyoten has already decided:**
- **A frozen handle** covers components question 1. A zone's tables are sized when it loads and never grown, and each
  table runs as its own task in the generated `scope`. A handle made after the tables are built, which may only free,
  covers this at no cost.
- **An atomic bump allocator** covers components question 2, decided today. It put owned per-entity data (kind 4) and
  lists that spill past their capacity on day one, in resource chunks that grow inside a worker. Question 9 adds
  world-store cells, filled by generators off the simulation.
  - *Probed:* a `parallel_for` over resource chunks whose `DynamicArray`s draw from one zone `Arena` is refused at the
    element: *"`ItemChunk` does not declare `implements Sendable`"*. It cannot declare it, because its allocator is a
    `BumpAllocator`. KY-17 carries the repro.
  - So today kind-4 data can split across workers only on the global heap, outside the zone's budget.
  - An atomic bump over the zone's arena covers it, and a full arena answering `Err` is G2's stated rule for a full
    budget.

### KR-327: a single-threaded wasm build of a program holding a form

**Yes, a per-build setting, and kyoten has decided it.** frame-phases questions 7 and 8 (2026-11-04) say a web build is
single-threaded by default, and threads come from a build-time switch a game turns on by measurement. The same source
builds both ways. Under the setting, `parallel_for` and `spawn job` run on the caller in order, no threaded runtime is
linked, and no COOP/COEP headers are needed.

**Why a setting, and not gating the forms out:**
- `@kama/graphics` and kyoten's own modules will use `parallel_for` inside. A library must not decide its host's
  headers, which is KR-327's own reason.
- **Who sets it:** the program being built, not a dependency. This is the rule `no-heap` and `webgpu` already follow:
  each is read from the program's own manifest only.

## kyoten's needs, added to rows kama already has

- **KR-320, job priorities: kyoten's long jobs arrive with the held `Job<R>`, so design them in step 4, not after a
  later measurement.**
  - Streaming and generation run off the simulation for several frames, while every frame's barriers wait for
    workers.
  - For a game with a procedural world (components question 9), that happens on its first day.
  - kyoten needs a frame's barrier never to wait behind a generation job. A second set of threads for long work, which
    KR-320 itself names, would answer it.
- **KY-18, as a held job's way to read shared data.** A held job cannot borrow, so a generator that reads biome tables,
  or a navmesh build that reads level geometry, can read them only through `Shared<immutable T>`. That type cannot hold
  an array today. KR-288 fixes the scope form only.
- **KR-298, `trySend`.** If Output's work runs in a job, a channel `send` is refused (decision 5), and `trySend` is the
  only send left. kyoten needs it for Output's hand-off to audio and the network, whenever Output goes parallel. It is
  already in the build order's step 4.
- **KR-325, thread control.**
  - **Names:** profiles of frame time per phase need named threads (examples question 3).
  - **Priority and core class:** the brief itself says a chunk on a slower core holds the barrier, which matters on
    Quest, phones and Apple silicon.
  - *Not checked:* how a native audio backend's real-time thread calls into kama (audio, KYR-15).
- **KR-79, reachability properties: conditional on replay questions 1 and 5.**
  - The property kyoten would ask for: the simulation step reaches no outside input. That means no clock, no file or
    socket, no environment, no `cpuCount()` and no OS randomness.
  - A replay from the record would then be guaranteed by the compiler, where FFD relies on discipline and a hash in CI.
  - The walk already exists, for `@noheap` and for decision 5's task waits.

## New: `reproducible-float` does not cover `std::math` (KY-19)

- **What kama promises.** Its `docs/targets.md` says the key means *"this program's floating point must give the same
  bits on every target"*. It emits `-ffp-contract=off`, which fixes fused multiply-add.
- **What breaks it.** `sin`, `cos`, `exp`, `pow`, `atan2` and the rest are each a call into the platform's own libm
  (`include/kama_math.h:13`).
- **Probed,** with `"reproducible-float": true` and `--release`, over 200,000 inputs from −120 to 154. Each differing
  result is one ulp off:

  | Function | Inputs whose bits differ between native and wasm |
  |---|---|
  | `sin` | 2 |
  | `cos` | 5 |
  | `exp` | 3 |
  | `pow` | 1 |
  | `atan2` | 8 |
  | `sqrt` | 0 (IEEE requires it correctly rounded) |

- **The minimal repro:** an `x` read at run time, so the call cannot fold, gives `sin(-93.54667…)` the bits
  `4603985457226728705` natively and `4603985457226728704` on wasm. With a constant `x`, both builds agree, because the
  C compiler folds the call.
- **What it puts at risk:**
  - replay and lockstep across platforms (replay question 1);
  - slice B's bit-identical replay (examples question 2), if a recording made on the web must play natively, since
    slice A runs "on web and native";
  - regenerating a procedural world from its seed (components question 9).
- **Precedent:** Box2D hand-codes its own trigonometry: *"The atan2f function in the standard library is not
  cross-platform deterministic"* ([math_functions.h](https://github.com/erincatto/box2d/blob/main/include/box2d/math_functions.h)).

## The gap map: the 41 open questions

Each row says what the question leans on in kama. **none** means the question was checked and needs nothing from kama.
**conditional** means it needs something only if the question is answered a certain way, so the gap is filed then.

### components (3–9)

| Q | What it leans on in kama | Status |
|---|---|---|
| 3 systems | An engine system generic over a world it did not write, through a contract the generated world implements | **none**. *Probed:* a generic system splits the world's chunks with `parallel_for` through a `ref`-returning contract method, and reads them through a `const` one (exit 128). Layer rules are `importsOnly` (kama KR-308, shipped) |
| 4 determinism | A specified iteration order, which is the generator's. std's `DefaultHasher` is unseeded (`hasher.kama:11`), so a `Map`'s order repeats run to run | **none found**; whether a `Map`'s order matches on wasm and native is to probe at the question |
| 5 records | serde's `@generate`. Errors in generated code map back to records through the generator's own map over `kama check --json`. kama has no `#line`-style directive in kama source, and this does not need one | **none**; **conditional** on KY-14 (KR-314) if records may load a type the engine never named (mods) |
| 6 scale and storage | Arena-backed budgets per zone | KY-17 (KR-326, answered above) |
| 7 the prototype | — | **none** |
| 8 growing in phases | — | **none** |
| 9 world stores | Allocation while tasks run, long jobs, shared tables in a held job, regeneration from a seed | KY-17 (KR-326), KR-320, KY-18, KY-19 |

### replay-and-determinism (1–3, 5–6)

| Q | What it leans on in kama | Status |
|---|---|---|
| 1 determinism by contract | `reproducible-float` (it exists); portable maths functions | **KY-19**; **conditional:** KR-79's property |
| 2 what is recorded | serde | **none** |
| 3 the log format | serde field ids and `@deprecated` give versioned records | **none** |
| 5 tripwires | A parallel world hash: decision 16 | **none** beyond decision 16; **conditional:** KR-79 |
| 6 Output read-only | `const` is deep in kama (the brief measured it, decision 10) | **none** |

### project-database (1–6, 8, 11)

| Q | What it leans on in kama | Status |
|---|---|---|
| 1, 3, 5, 11 | — | **none** |
| 2 where it lives | Files in git through serde; `@kama/postgres` (0.4.0, on the registry) | **none**; *not checked:* an SQLite binding |
| 4 the schema | serde; a type added without a rebuild | **conditional:** KY-14 (KR-314) |
| 6 agents coordinating | HTTP and WebSocket in std, on fibers | *not checked* |
| 8 the running game reads it | Hot reload in development needs a file watcher. std has none: kama's KR-24 names file-watching only inside the hot-reload library, which is unscheduled | **conditional:** a file watcher in std on its own, if question 8 wants hot reload |

### web-and-native (1–6, 8)

| Q | What it leans on in kama | Status |
|---|---|---|
| 1 the seam | `@kama/gpu` and `@kama/window`, which kyoten builds (KR-25, KR-26) | **none** |
| 2 the thread topology | KR-327; the pool on wasm (KR-3 step 10); `main` on a worker when threaded (KR-327 says it moves there) | KR-327 answered; *not checked:* OffscreenCanvas through kama's wasm harness |
| 3 UI | HTML and CSS, the browser's own on the web and kyoten's counterpart natively (the owner, 2026-11-05, [../SPIKE.md](../SPIKE.md) § Standing direction). `kama-ui` and `kama-rmlui` already exist as packages, in their own repositories (the owner, 2026-11-05); kama's own roadmap has no row for them, and they were not read for this audit | **conditional** on question 3 |
| 4 the size budget | Closure in a wasm release | KY-6 (kama KR-289) |
| 5 what native gains | `@compileFor` | **none**; see target-platforms 1 for dependencies per target |
| 6 the crossing cost | measured (KYR-5) | **none** |
| 8 the headset | An installable Android app | KY-2 (kama KR-283) |

### target-platforms (1–4)

| Q | What it leans on in kama | Status |
|---|---|---|
| 1 a platform as a package | A dependency for one target only, such as a console's private package. *Probed:* refused, *"unknown key `dependencies` in the target `CONSOLE`"*. A thin executable project per platform, depending on the game, works without it | **conditional** on question 1 |
| 2 the interface | Contracts chosen at build time, monomorphized: the components 3 probe is the same shape | **none**; **conditional:** KY-14 for a capability looked up at run time |
| 3 capabilities | `flags` and `@compileFor` | **none** |
| 4 feature packages | as question 1 | as question 1 |

### rendering (1–4)

| Q | What it leans on in kama | Status |
|---|---|---|
| 1 where it starts | `@kama/gpu` (KR-25, kyoten's to build) | **none** |
| 2, 3 | — | **none** |
| 4 rendering in the frame | Output reads a snapshot: a `copy` of the chunks (*probed* at components question 2). Output in a held job reads meshes through `Shared<immutable T>`. Renderer code keeps no module statics (decision 7) | KY-18, if Output runs in a held job |

### ai-first-api (1–3) and examples (1–3)

| Q | What it leans on in kama | Status |
|---|---|---|
| ai-first-api 1, 2 | — | **none** |
| ai-first-api 3 correct by construction | Races and phases are the compiler's. A resource freed while the GPU uses it is `@kama/gpu`'s design (RAII plus frame fences), not kama's | **none** |
| examples 1 | — | **none** |
| examples 2 the first slice | Slice B's bit-identical replay, if it must hold on web and native both | **KY-19** |
| examples 3 what "done" measures | Frame time per phase, profiled; the bundle's size | KR-325 (thread names); KY-6 |

## Beyond the spike

These docs are roadmapped for later rows, not the spike. Each was scanned for what it would ask of kama. Nothing below
was probed.
- **audio (KYR-15):** a real-time callback must neither allocate nor block. `@noheap` exists, and *no blocking syscall*
  is KR-79's. On the web, Web Audio runs code in an AudioWorklet's own scope. Whether kama's wasm build can run there
  is *not checked*.
- **networking (KYR-18, KYR-45):** the fiber runtime (KR-3 steps 1–6, shipped), and WebSocket and WebTransport in std.
  Raw UDP natively and WebRTC data channels on the web are *not checked*.
- **xr (KYR-31 to KYR-33):** KY-2 (KR-283). The OpenXR binding is kyoten's.
- **human-tools (KYR-26, KYR-27):** web-first tools in kama, over the same HTTP and WebSocket. Code hot reload is
  kama's KR-24.
- **content-pipeline, timeline, version-manager:** nothing found.

## Who could take what: a suggestion for kama

This is the owner's question of 2026-11-05: what the Windows box can work on while the Mac builds KR-3. It is a
suggestion from kyoten, and the claims are kama's to make in its own roadmap.
- **What kama's roadmap already assigns:**
  - KR-3 is the Mac's. Step 8 and step 7's `Poller.wait` over AFD are the Windows box's.
  - The Windows box holds defects and blockers meanwhile.
  - KR-283, the Android app, is claimed by the Windows box (2026-11-02).
- **The Windows bench is done** (kama `a6413d57`, 2026-11-05): a dozen short phases at 10 chunks take 8.55 ms through
  today's `parallel_for` (51% of a 60 Hz frame), and 0.71 ms on the pool.

**KR-326 is an allocator, not a container.** kama's containers already take the allocator as a type parameter
(`FixedArray<T, A>`, `DynamicArray<T, A>`), so its two shapes are new allocator types that existing containers take.
kyoten needs both (above).

**The Mac:** KR-3's build order, steps 1–6. kyoten's two asks inside it:
- **KR-320:** designed with the held `Job<R>` in step 4.
- **KR-327:** ruled with step 10.

KR-288 and KR-313 (step 1) need no pool, but they are inside the Mac's claim and touch the same borrow checker that
`spawn job` will, so they stay there.

**The Windows box, in this order:**
1. **KR-324's Windows half.** It is step 0 of the pool's build order, since the pool sizes itself by `cpuCount()`, and the
   row still says "The Windows box is measuring".
2. **KR-326, the two allocators.**
   - The row says design first, and kyoten's answer is in KY-17.
   - It must land before `spawn job` (step 3), so it runs alongside the Mac's work.
   - It touches `std::collections`, not the pool. Its only overlap is `Atomic`, which the Mac extends with `wait` and
     `notify`.
3. **KY-19, once kama files it.** The fix must show the same bits natively and on wasm, and this box builds and runs
   both: the repro ran here, on emsdk 6.0.13 and node 24.21.
4. **Then the rows independent of KR-3:**
   - KY-18 (an `immutable` type holding an array), in the compiler;
   - KR-314 (kyoten's KY-14);
   - KR-289 (kyoten's KY-6, Closure), which is small.

**KR-283's place in this order is the owner's call.** The owner's Quest prototype (KYR-4) needs it, and KR-326 has a
workaround in kyoten: one global allocation per table.

## The probes

All are in the session's scratchpad (`audit/`, `c1/`, `c2/`) and ran on 0.9.852:

| Probe | Shape | Result |
|---|---|---|
| `c1/*`, `c2/*` | components questions 1 and 2, re-run after 0.9.851 (KR-323) tightened what a `parallel_for` body may capture | unchanged from 0.9.850 |
| `c2/d_snapshot.kama` | a resource chunk's snapshot by `copy`, then two steps of the live table | 39 live, 35 kept (exit 4) |
| `audit/a_arena_grow_pfor.kama` | chunks whose arrays draw from one arena, grown in a `parallel_for` | refused: the element is not `Sendable` |
| `audit/b_nested_zones.kama` | a `parallel_for` over zones, each with its own over chunks | exit 2, as expected |
| `audit/c_contract_world.kama` | an engine system generic over a contract the generated world implements | exit 128, as expected |
| `audit/libm/` | `std::math` bits, natively and on wasm, under `reproducible-float` | 19 of 1,000,000 results differ; `sqrt` 0 of 200,000 |
| `audit/tdep/` | a dependency under one target in `select` | refused: unknown key |
