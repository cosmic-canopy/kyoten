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
  (Nintendo Switch 2, Xbox, PlayStation, and so on). **iOS** was added later the same day (see the last section).
- **XR:** OpenXR natively, for certain; WebXR on the web. XR is perhaps a package of its own.
- **Roblox and UEFN** (Unreal Editor for Fortnite) may be good targets as well.

## Beyond the engine: a platform for developers

Added to the brief the same day:

- **A platform for developers to build, deploy and sell games and content**, something like Steam or the Unity
  asset store. **kyoten hosts the marketplace.**
- **A networking backend built for games**, hosted as part of that platform.
- *Refined the same day: the platform is a separate product the owner builds in parallel, the easy option for
  hosting and never a lock-in (see the last section).*

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

## Added at the first roadmap review

Given the same day, 2026-11-01, once the seeded plan had been read back to the owner. The decisions among them are
recorded in the design docs they settle; this section keeps the brief itself.

- **friendly-fire-department and the-mallow-man ship on their own engines.** The owner has Steam partner approval and
  wants FFD out as soon as possible; kyoten is built in parallel and gates neither game
  ([design/architecture.md](design/architecture.md)).
- **Roadmap everything**, so there is a record of what is wanted, even where the work is far off
  ([ROADMAP.md](ROADMAP.md)).
- **The marketplace and platform are a separate product**, which the owner builds in parallel. kyoten is aware of the
  goal so that its own decisions can serve it ([design/marketplace.md](design/marketplace.md)).
- **Start from the peers' code.** FFD, the-mallow-man and cosmic-forge are the starting point, and at the very least
  the reference. kyoten must also move toward being **generic and component-driven**.
- **Learn from Unity's growth.** Unity succeeded, and grew in phases, from its component-based design. kyoten takes
  different approaches but can learn from that model ([design/components.md](design/components.md)).
- **The FPS example may well be the first example** ([design/examples.md](design/examples.md)).
- **The first Quest game will likely be a new project of its own**, as FFD and the-mallow-man were
  ([design/xr.md](design/xr.md)).
- **iOS is wanted as well**, and Android support (which Quest runs on) is expected to need kama work
  ([design/target-platforms.md](design/target-platforms.md), [KAMA_GAPS.md](KAMA_GAPS.md) KY-2 and KY-3).

Given in the owner's next messages, the same day:

- **The platform is the "easy button", never a lock-in.** Self-hosting a backend for kyoten is fine, and kyoten will
  likely ship a backend server of its own. The platform's offerings are fair and easy to use, which is why developers
  may choose it to host for them ([design/networking.md](design/networking.md)).
- **The engine's first consumer is AI.** kama is opinionated, strict and AI-friendly, and kyoten carries the same
  mentality, with query support and MCP built in ([design/ai-first-api.md](design/ai-first-api.md)).
- **The project database and wiki are central to kyoten's success.** They let several agents develop concurrently on
  separate machines and still keep one consistent game direction. A wiki per game project, as what coordinates them,
  is what the owner sees as unique ([design/project-database.md](design/project-database.md)).
- **The "database" may be an abstraction.** It could literally be kama postgres, or an abstract interface that a
  database or flat files fulfil. Game lookups go through an abstraction, with overriding by priority, which serves
  content on disk against DLC and similar cases.
- **A Quest prototype as soon as possible.** The owner has not built for Quest before and is tempted to start the
  Quest game on its own, so as not to hold kyoten up; it comes here only if it fits in a reasonable time
  ([design/xr.md](design/xr.md)).
- **kyoten is open-ended and general purpose**, never pigeonholed into one game project.
- **The wiki is decided now.** Its design is settled in the spike, even though it is built after the first slice
  ([SPIKE.md](SPIKE.md)).
- **Showcase as many games running on kyoten as possible** when it is ready to host games: the examples, and ports of
  friendly-fire-department and the-mallow-man once each has shipped ([ROADMAP.md](ROADMAP.md)).

Given on 2026-11-02:

- **Generative worlds, later, on high-end machines.** A game world generated interactively, on the fly. The owner has
  seen it prototyped several times, most recently as Wizard: "I still see doing traditional game engines for a while…
  especially on current hardware… but generative games are likely the future" ([ROADMAP.md](ROADMAP.md) KYR-50,
  [design/rendering.md](design/rendering.md) question 10).
