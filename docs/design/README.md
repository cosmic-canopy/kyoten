# Design docs

One draft per system. Each one says what [the vision](../VISION.md) asks of it, what already exists (with pointers
into [../research/](../research/)), and the **questions** the design spike has to answer. Its `Decided` heading is
empty until the walk-through fills it. The order to take them in, and why, is in [../SPIKE.md](../SPIKE.md).

| Doc | System | Status |
|---|---|---|
| [architecture.md](architecture.md) | the engine/game boundary, the package split, the repositories | draft, four decisions recorded |
| [frame-phases.md](frame-phases.md) | Input, Update, Constraints, Output: parallel phases, per-component rates | draft |
| [components.md](components.md) | the component model: how a game holds state and behaviour | draft |
| [replay-and-determinism.md](replay-and-determinism.md) | recorded inputs, seeds, bit-identical replay | draft |
| [web-and-native.md](web-and-native.md) | web first, native at parity: the platform seam and the web thread topology | draft |
| [target-platforms.md](target-platforms.md) | N platforms, extensible: desktop, Steam Deck, mobile, consoles, Roblox and UEFN | draft, one decision recorded (iOS; Android for Quest) |
| [xr.md](xr.md) | VR: OpenXR natively, WebXR on the web, kyoten's own package; Meta Quest first | draft, five decisions recorded |
| [networking.md](networking.md) | netcode in the frame, and the hosted game backend | draft, one decision recorded (a self-hostable server; the platform is the easy option) |
| [project-database.md](project-database.md) | the AI-coordinated project database and wiki | draft for the spike (build: KYR-24), four decisions recorded |
| [human-tools.md](human-tools.md) | human visibility and tuning: the tool surface | deferred to KYR-26, KYR-27 |
| [rendering.md](rendering.md) | WebGPU first | draft, one decision recorded (2D as layers) |
| [audio.md](audio.md) | Web Audio first, and the DAW tool | deferred to KYR-15, KYR-35 |
| [timeline.md](timeline.md) | timeline and cinematic tools | deferred to KYR-36 |
| [content-pipeline.md](content-pipeline.md) | consuming cosmic-forge | draft |
| [asset-manager.md](asset-manager.md) | delivering a game's built assets to developers and players | draft, questions only (KYR-66) |
| [ai-first-api.md](ai-first-api.md) | easy for AI from day one, as quick as Three.js | draft, one decision recorded (AI first; query and MCP built in) |
| [version-manager.md](version-manager.md) | several engine versions side by side, and example projects to start from | deferred to KYR-38 |
| [marketplace.md](marketplace.md) | the developer platform: build, deploy and sell | a separate product; the engine's side is KYR-44 |
| [website.md](website.md) | kyotenengine.com: the site, its subdomains, provisioning and deployment | deferred to KYR-39 |
| [examples.md](examples.md) | the example games (FPS, VR on Meta Quest), each its own repository, and the first vertical slice | draft, four decisions recorded |

**A doc's status moves from `draft` to `decided`** when every question in it is answered or deferred with a reason,
and to `superseded` if a later design replaces it (then it says by which).
