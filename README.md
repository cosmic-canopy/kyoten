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

**Status: the first slice is under way.** The design spike is done, and the frame core is built and tested. Start
with [docs/REFERENCE.md](docs/REFERENCE.md), the model in one read, then [docs/FIRST-SLICE.md](docs/FIRST-SLICE.md).

```sh
kama pkg install kama_workspace.json          # the engine
tools/test.sh                                 # the whole suite
```

**Each example is its own repository**, so you can take only the one you want, and the engine manager can offer each
as a project to start from. They are optional, and sit under `examples/` by kind: clone a game into
`examples/games/<name>`, which this repository ignores, so an engine-only checkout never downloads them. The first two
are an FPS, [kyoten-example-fps](https://github.com/cosmic-canopy/kyoten-example-fps), and a VR game for Meta Quest,
[kyoten-example-vr](https://github.com/cosmic-canopy/kyoten-example-vr).

```sh
git clone https://github.com/cosmic-canopy/kyoten-example-fps.git examples/games/fps
kama pkg install examples/games/fps/kama.json
kama run examples/games/fps/kama.json         # prints "fps example, on kyoten"
```

| | |
|---|---|
| [docs/VISION.md](docs/VISION.md) | the brief |
| [docs/REFERENCE.md](docs/REFERENCE.md) | the model: the picture, the vocabulary and the prior art |
| [docs/FIRST-SLICE.md](docs/FIRST-SLICE.md) | the first slice: where it stands and the order of work |
| [docs/SPIKE.md](docs/SPIKE.md) | the design spike and what it decided |
| [docs/design/](docs/design/) | one draft per system, with its open questions |
| [docs/research/](docs/research/) | what the peer projects and kama already offer |
| [docs/ROADMAP.md](docs/ROADMAP.md) | the order of work |
| [docs/KAMA_GAPS.md](docs/KAMA_GAPS.md) | what kyoten hits in kama |

Licensed under either of [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE), at your option.
