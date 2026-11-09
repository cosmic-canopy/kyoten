# kyoten — what is true in THIS repo

`AGENTS.md` is kama's guidance on the kama language, and it is **not** hand-edited. Refresh it with
`kama agents print > AGENTS.md`. `kama agents install` takes a member's `kama.json` and refuses this workspace root.
This file is the project-specific part, and it is the one to edit.

**kyoten** is a game engine written in kama: AI-driven, component-based, web-first with native at parity,
general purpose, MIT OR Apache-2.0. The owner's brief is [docs/VISION.md](docs/VISION.md).

## Where things stand: the spike is done, the first slice is under way

**Learn kyoten's model from [docs/REFERENCE.md](docs/REFERENCE.md)**: the picture of how a game, the engine's tiers
and modules, the world, processors and phases fit together, the vocabulary to use, and the prior art. Use its terms:
a "processor" is a function over components that the scheduler runs (what Bevy, flecs and Unity call a system), and
a "module" is an area of code, one kama module: an engine module such as render or audio, or a game module. kyoten
says neither "system" nor "subsystem". A bare "layer" is a scene's layer; the engine's levels of code are its "tiers",
and a screen layer and a content layer (a content database priority level) are always called so.

**The design spike is done** (KYR-1, 2026-11-07). [docs/SPIKE.md](docs/SPIKE.md) § What the spike decided is its
record, and each design doc's *Decided* holds the decisions with their reasons. **The first slice is under way**
([docs/ROADMAP.md](docs/ROADMAP.md) § NEXT), and **[docs/FIRST-SLICE.md](docs/FIRST-SLICE.md) is where to
start:** § Where it stands says what is built and what the next session does first, then its order of work, the
questions to ask on the way, and the hello cube's checks. A question the spike left open is decided when its row
comes up. **No
engine code is written before the decision it depends on is recorded**, and a decision is the owner's: propose,
compare and measure, then ask.

## Layout

| Path | What it is |
|---|---|
| `kama_workspace.json` | the engine's workspace. It names no game, by rule |
| `engine/` | the engine, package `kyoten` (`import { kyoten::… }`): one package with modules, and a package of its own for anything standalone or gated (architecture question 2). Each tier is a module, one folder under `engine/src/` (`frame/` is `kyoten::frame`) |
| `engine/tests/` | the engine's tests, one program depending on the engine by path |
| `engine/THIRD-PARTY-NOTICES.md` | the notices of code compiled into every program built on kyoten (musl's, through `reproducible-float`) |
| `tools/test.sh` | the whole suite, the gate before every commit |
| `tools/kyoten/` | the `kyoten` tool, package `@kyoten/cli`, built with `-o kyoten`: it writes a game's generated kama from its records, then runs kama (`generate`, `check`, `build`, `run`, `clean`). Its tests are one program in `tools/kyoten/tests/`, run on the fixture games there |
| `examples/<kind>/<name>/` | **one separate repository per example**, git-ignored here and optional, kept by kind (the owner, 2026-11-08): games under `examples/games/`, and later kinds such as a simulation or a graphics sample beside it. The games so far are `examples/games/fps` ([kyoten-example-fps](https://github.com/cosmic-canopy/kyoten-example-fps)) and `examples/games/vr` ([kyoten-example-vr](https://github.com/cosmic-canopy/kyoten-example-vr), Meta Quest). Each is a standalone project that depends on `../../../engine` by path. Commit an example in its own repository, never here |
| `docs/VISION.md` | the owner's brief |
| `docs/SPIKE.md` | the design spike: what it decided, then its brief as written |
| `docs/FIRST-SLICE.md` | the kickoff brief for the first slice, from the hello cube to slice B |
| `docs/REFERENCE.md` | the model in one read: the picture, the vocabulary and the prior art, each item decided or proposed. The future SPEC's core, built into kyotenengine.com's docs (KYR-39) |
| `docs/design/` | one doc per area (rendering, audio, networking…): its questions, and under *Decided* the answers with their reasons |
| `docs/research/` | what the peer projects and kama already offer, with pointers |
| `docs/ROADMAP.md` | the order of work (ids `KYR-<n>`) |
| `docs/KAMA_GAPS.md` | what kyoten hits in kama (ids `KY-<n>`) |

## Build

```sh
tools/kama pkg install kama_workspace.json          # the engine
tools/kama check engine/kama.json
tools/kama pkg install examples/games/fps/kama.json # an example, when kyoten-example-fps is cloned there
tools/kama run examples/games/fps/kama.json         # prints "fps example, on kyoten"
tools/kama build tools/kyoten/kama.json -o tools/kyoten/out/kyoten   # the kyoten tool
tools/kyoten/out/kyoten check <game>/kama.json --kama "$(tools/kama --which)"   # generate, then kama check
tools/test.sh                                       # the whole suite: the gate before every commit
```

**kyoten builds with its own copy of kama, `.kama-pin/`** (the owner, 2026-11-08: kama "will rebuild as it develops
on this machine so you need to keep your own copy if you want it stable"). `tools/kama` runs it, and so does
`tools/test.sh`. `.kama-version` names the commit it was built from, and the shim warns when the compiler it runs is
another. `$KAMA` overrides it, to try a newer kama before a bump. `../kama` is never the fallback, and never edited
or rebuilt from here.

- **Make the pin from a clean clone, never from `../kama`'s binary,** which may hold uncommitted work and lag its own
  HEAD. Clone `../kama`, check out the commit, build it in UCRT64, and copy the binary with the trees it reads:

  ```sh
  git clone ../kama .scratch/kama-pin-src && git -C .scratch/kama-pin-src checkout <commit>
  (cd .scratch/kama-pin-src && make -j8)                    # in UCRT64; leave cores for kama's own session
  rm -rf .kama-pin && mkdir .kama-pin
  cp .scratch/kama-pin-src/out/UCRT64-x86_64/kama.exe .kama-pin/
  cp -r .scratch/kama-pin-src/lib .scratch/kama-pin-src/include .scratch/kama-pin-src/prelude .kama-pin/
  tools/kama --version                                      # must be .kama-version's, with no warning
  ```

  The binary finds `include/` and `lib/` beside itself, and its prelude is embedded, so `prelude/` is only what an
  editor opens.
- **Bump the pin as a commit of its own:** rebuild at the new commit, run `tools/test.sh` and both packages' suites on
  it with no other change, then update `.kama-version` with what moved and re-check `docs/KAMA_GAPS.md`'s entries.
- **The packages' suites take `KAMA`,** so run them on kyoten's pin:
  `KAMA=$PWD/.kama-pin/kama.exe ../kama-gpu/tools/test.sh`.

**`tools/test.sh` is the suite** (§ Rules). It runs `kama check` on the engine and its tests program, then the
engine's tests (`engine/tests/`, one program), native debug and release and on wasm under node, and the 32 KiB
frame guard (`tools/fixtures/frame-guard`, a game whose 40 KB frame must be refused off Windows), and the `kyoten`
tool's tests (`tools/kyoten/tests/`, on its fixture games, natively and with one built for wasm). Then each cloned
example: `examples/games/fps` is checked and run natively and on wasm, and `examples/games/vr` is checked. A leg with
no `emcc` or `node`, or a game that is not cloned, is skipped, and says so. Run it from an interactive UCRT64 shell
(`bash -lic`) so the wasm legs run.

On Windows, drive kama from msys2 UCRT64, as kama's own `docs/platforms/windows.md` describes.

**A web build** (`--target WASM`) needs emscripten's `emcc`; kama's CI and the peer games use the latest emsdk. On
Windows, emsdk 6.0.13 is verified (2026-11-01, a kama program built and ran under node, debug and release). Put
`<emsdk>/upstream/emscripten` on `PATH` and set `EMSDK_PYTHON` to emsdk's bundled `python/<version>/python.exe`.
Without it, `emcc.exe` reaches the Windows Store's python alias, and kama reports `emcc failed (exit 9009)`. A UCRT64
shell does not inherit the Windows `PATH` unless `MSYS2_PATH_TYPE=inherit`, so `emsdk activate --permanent` does not
reach it; set both in the shell's own profile.

## Rules

- **The engine is the driver for games, never one game.** Nothing in `engine/` names or special-cases a game.
  A feature a game needs arrives as a pattern or a component every game can use, and the examples consume it
  from the outside.
- **Web first, native at parity.** An engine interface is designed against the browser's own API (WebGPU,
  Web Audio, HTML/CSS, WebRTC/WebSocket); native implements the same interface.
- **N platforms, extensible.** No engine code assumes a fixed list of platforms. Web, desktop, Steam Deck, XR
  (OpenXR natively, WebXR on the web) and, later, consoles each implement the engine's interfaces, and a console's
  implementation may be a private package under NDA (`docs/design/target-platforms.md`).
- **Verify, don't trust.** Compile the snippet, run the command, read the emitted C. A doc is not evidence,
  including these.
- **kama gaps go in [docs/KAMA_GAPS.md](docs/KAMA_GAPS.md)**, each with a minimal repro and the kama version it was
  reproduced on. Never edit `../kama` from here; the gap file is how kama hears about it.
- **Every decision is written down with its reason**: in the design doc it settles, and as a roadmap row when it
  creates work.
- **Production grade, general solutions** (the owner, 2026-11-08). A recommendation is the production answer, or says
  plainly that it is a stopgap and names what replaces it.
- **Test-driven, with one full suite** (the owner, 2026-11-08: "We will need to use test driven development and use a
  full suite of tests as well so we keep kyoten on track and regression free").
  - A change starts with a test that fails without it. A bug is fixed only after a test reproduces it.
  - `tools/test.sh` at the root runs the whole suite: the engine's tests, the generator's, and every example's check
    and run, natively and on wasm. It passes before every commit, and CI (KYR-13) runs the same script.
  - A test that fails is never deleted or loosened to pass. A ratchet is loosened only as a decision, with its reason.
- **Dependencies are injected** (the owner, 2026-11-08: "best practices like dependency injection").
  - Code takes what it depends on as a parameter, or as an implementation of a `type contract` it is handed. The clock
    takes each frame's time, the frame driver takes the `World`, and `run` takes the `Platform`, so a test hands each
    one a fake: a fixed time, a hand-written world, a headless window.
  - No global mutable state, no service locator, no container. kama has no reflection, and the generator wires the
    world at build time, so the wiring is plain code a reader can follow.
  - This is the decided model's own rule: a processor never reads a clock, and is handed its components and its
    `Time` (frame-phases question 2).
