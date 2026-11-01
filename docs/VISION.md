# kyoten — the vision

This is the owner's brief, recorded as it was given on 2026-11-01 (in several messages) and organised by topic. **It is the input to
the design spike, not its output.** Where the brief leaves a choice open, the design docs under
[design/](design/) list it as a question rather than answering it here.

## What kyoten is

- **A game engine, written in [kama](../../kama), that competes with Unity, Unreal and Godot.** Licensed
  MIT OR Apache-2.0, like kama.
- **AI-driven.** kyoten generates games by keeping an **AI-coordinated database and wiki of the game project**.
  Several agents can design and coordinate across systems through it, and the game project stays consistent.
- **Easy for AI to use from day one.** That is a first-class requirement, not a later integration.
- **Visible to humans throughout.** People can see the whole process, and they get tuning tools at every step.
  The tools named so far: **audio tools (a DAW)** and **timeline and cinematic tools**.
- **General purpose and component-based.** The engine does not hard-code game systems. It gives each game
  project clean patterns to use. Component-driven is the ideal.
- **The driver for games, never one game.** The engine is never shaped around a particular game. A test game
  project is built to consume it from the outside.
- **Easy to use correctly, and high performance.** It uses the raw performance kama aims for, across parallel
  processes.
- **As quick to prototype in as Three.js.** Three.js became the quick, iterative environment for games on the
  web, and kyoten wants the same ease of prototyping on both web and native.

## The frame: Input, Update, Constraints, Output

A phased, parallel model. **Each phase can run its work in parallel.** Within a phase, **components can update at
different fixed frequencies**, each chosen for what makes sense to human perception.

| Phase | Examples from the brief |
|---|---|
| **Input** | networking (receive), bot and human input, random seeds. **Recorded**, so they can feed the simulation again for replay. Each system updates at the frequency that makes sense for it. |
| **Update** | game logic, bot and AI state machines |
| **Constraints** | physics |
| **Output** | rendering, network sends |

The owner wants to know whether the peer projects used this model, and how kyoten can build on it
([research/peer-games.md](research/peer-games.md) answers the first part).

## Platform: web first, native at parity

- **Web first, and light on the web.** It uses what the browser already does best: **HTML/CSS, Web Audio,
  WebGPU**, and so on. The web build does not ship heavy features of its own.
- **Native implements the same interfaces** where it needs to, so everything stays fully cross-platform.

## N platforms, and an engine that is extensible to more

Added to the brief the same day:

- **The engine supports N platforms and must be extensible**: a new platform is added without changing the engine
  for every other one.
- **The platforms named:** the web (wasm), Windows PC, Linux, Mac and Steam Deck; **eventually game consoles**
  (Nintendo Switch 2, Xbox, PlayStation, and so on).
- **XR:** OpenXR natively, for certain; WebXR on the web. XR is perhaps a package of its own.
- **Roblox and UEFN** (Unreal Editor for Fortnite) may be good targets as well.

## Beyond the engine: a platform for developers

Added to the brief the same day:

- **A platform for developers to build, deploy and sell games and content**, something like Steam or the Unity
  asset store. **kyoten hosts the marketplace.**
- **A networking backend built for games**, hosted as part of that platform.

## Distribution and the web presence

Added to the brief the same day:

- **Each example game is its own repository**, so the engine manager can offer them one at a time as projects to
  start from. In a kyoten checkout they sit under `games/`, which is git-ignored, so they take no space for anyone who
  only wants the engine.
- **The first examples: an FPS, and a VR game for Meta Quest.**
- **An engine version manager**, so a developer can download and run several versions of the engine on one machine,
  and download individual example projects to start from.
- **kyotenengine.com**, the website the owner already has, with **provisioned, automated deployment**. Its home page
  is the marketing and the getting started, much like kama's site. **Subdomains** will host other purposes.

## Relationships

- **cosmic-forge stays the general-purpose content-creation component.** kyoten uses it; it does not
  duplicate it ([research/cosmic-forge.md](research/cosmic-forge.md)).
- **References:** friendly-fire-department, the-mallow-man and cosmic-forge.
- **kama:** kyoten keeps a [KAMA_GAPS.md](KAMA_GAPS.md) in `docs/`, as the peer projects do.

## The repository

- **A monorepo**, seeded with `kama seed`. The engine's workspace holds the engine; each example game is a separate
  repository (above).
- **`docs/design/` files** plan out each system's design.
- The owner adds the git remote after the initial commit.
