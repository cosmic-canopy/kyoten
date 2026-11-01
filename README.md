# kyoten

A game engine written in [kama](https://kama-lang.org): **AI-driven, component-based, web-first, and fast.**

- **AI-driven.** A game is built by keeping an AI-coordinated database and wiki of the game project, so several
  agents can design across systems and the project stays consistent.
- **Visible to humans.** People see the whole process and tune it as it goes: audio (a DAW), timelines and
  cinematics, and more.
- **Web first, native at parity, extensible to N platforms.** It uses the browser's own WebGPU, Web Audio and
  HTML/CSS rather than shipping heavy replacements; Windows, Linux, Mac, Steam Deck, XR (OpenXR, WebXR) and, later,
  consoles implement the same interfaces.
- **A phased, parallel frame:** Input, Update, Constraints, Output. Each phase is parallel, and each component
  updates at the rate that suits it.
- **General purpose.** It drives games and is never written for one. As quick to prototype in as Three.js.

**Status: seeded for a design spike.** Nothing is built yet beyond a workspace that compiles end to end. Start
with [docs/VISION.md](docs/VISION.md), then [docs/SPIKE.md](docs/SPIKE.md).

```sh
kama pkg install kama_workspace.json          # the engine
```

**Each example game is its own repository**, so you can take only the one you want, and the engine manager can offer
each as a project to start from. They are optional: clone one into `games/<name>`, which this repository ignores, so
an engine-only checkout never downloads them. The first two are an FPS (`kyoten-fps`) and a VR game for Meta Quest
(`kyoten-vr`).

```sh
git clone <kyoten-fps-url> games/fps
kama pkg install games/fps/kama.json
kama run games/fps/kama.json                  # prints "fps example, on kyoten"
```

| | |
|---|---|
| [docs/VISION.md](docs/VISION.md) | the brief |
| [docs/SPIKE.md](docs/SPIKE.md) | the design spike: how to walk through it |
| [docs/design/](docs/design/) | one draft per system, with its open questions |
| [docs/research/](docs/research/) | what the peer projects and kama already offer |
| [docs/ROADMAP.md](docs/ROADMAP.md) | the order of work |
| [docs/KAMA_GAPS.md](docs/KAMA_GAPS.md) | what kyoten hits in kama |

Licensed under either of [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE), at your option.
