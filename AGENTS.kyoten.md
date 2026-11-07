# kyoten — what is true in THIS repo

`AGENTS.md` is kama's guidance on the kama language, and it is **not** hand-edited. Refresh it with
`kama agents print > AGENTS.md`. `kama agents install` takes a member's `kama.json` and refuses this workspace root.
This file is the project-specific part, and it is the one to edit.

**kyoten** is a game engine written in kama: AI-driven, component-based, web-first with native at parity,
general purpose, MIT OR Apache-2.0. The owner's brief is [docs/VISION.md](docs/VISION.md).

## Where things stand: the design spike

**Learn kyoten's model from [docs/REFERENCE.md](docs/REFERENCE.md)**: the picture of how a game, the engine's tiers
and modules, the world, processors and phases fit together, the vocabulary to use, and the prior art. Use its terms:
a "processor" is a function over components that the scheduler runs (what Bevy, flecs and Unity call a system), and
a "module" is an area of code, one kama module: an engine module such as render or audio, or a game module. kyoten
says neither "system" nor "subsystem". A bare "layer" is a scene's layer; the engine's levels of code are its "tiers",
a screen layer is always called so, and the record stack's levels are "priority levels".

**Read [docs/SPIKE.md](docs/SPIKE.md) first.** The repository was seeded to be walked through with the owner.
The design drafts under [docs/design/](docs/design/) list questions; they do not answer them. **No engine code is
written before the decision it depends on is recorded**, and a decision is the owner's: propose, compare and
measure, then ask.

## Layout

| Path | What it is |
|---|---|
| `kama_workspace.json` | the engine's workspace. It names no game, by rule |
| `engine/` | the engine, package `kyoten` (`import { kyoten::… }`). Whether it splits into several packages is a spike question. |
| `games/<name>/` | **one separate repository per example game**, git-ignored here and optional: `games/fps` (`kyoten-fps`) and `games/vr` (`kyoten-vr`, Meta Quest). Each is a standalone project that depends on `../../engine` by path. Commit a game in its own repository, never here |
| `docs/VISION.md` | the owner's brief |
| `docs/SPIKE.md` | the kickoff brief for the design spike |
| `docs/REFERENCE.md` | the model in one read: the picture, the vocabulary and the prior art, each item decided or proposed. The future SPEC's core, built into kyotenengine.com's docs (KYR-39) |
| `docs/design/` | one draft per area (rendering, audio, networking…), each ending in its open questions |
| `docs/research/` | what the peer projects and kama already offer, with pointers |
| `docs/ROADMAP.md` | the order of work (ids `KYR-<n>`) |
| `docs/KAMA_GAPS.md` | what kyoten hits in kama (ids `KY-<n>`) |

## Build

```sh
kama pkg install kama_workspace.json          # the engine
kama check engine/kama.json
kama pkg install games/fps/kama.json          # an example, when kyoten-fps is cloned as games/fps
kama run games/fps/kama.json                  # prints "fps example, on kyoten"
```

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
