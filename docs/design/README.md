# Design docs

One draft per system. Each one says what [the vision](../VISION.md) asks of it, what already exists (with pointers
into [../research/](../research/)), and the **questions** the design spike has to answer. Its `Decided` heading is
empty until the walk-through fills it. The order to take them in, and why, is in [../SPIKE.md](../SPIKE.md).

| Doc | System | Status |
|---|---|---|
| [architecture.md](architecture.md) | the engine/game boundary, the package split, the repositories | draft, one decision recorded |
| [frame-phases.md](frame-phases.md) | Input, Update, Constraints, Output: parallel phases, per-component rates | draft |
| [components.md](components.md) | the component model: how a game holds state and behaviour | draft |
| [replay-and-determinism.md](replay-and-determinism.md) | recorded inputs, seeds, bit-identical replay | draft |
| [web-and-native.md](web-and-native.md) | web first, native at parity: the platform seam and the web thread topology | draft |
| [target-platforms.md](target-platforms.md) | N platforms, extensible: desktop, Steam Deck, consoles, Roblox and UEFN | draft |
| [xr.md](xr.md) | VR: OpenXR natively, WebXR on the web, perhaps a package; Meta Quest first | draft, two decisions recorded |
| [networking.md](networking.md) | netcode in the frame, and the hosted game backend | draft |
| [project-database.md](project-database.md) | the AI-coordinated project database and wiki | draft |
| [human-tools.md](human-tools.md) | human visibility and tuning: the tool surface | draft |
| [rendering.md](rendering.md) | WebGPU first | draft |
| [audio.md](audio.md) | Web Audio first, and the DAW tool | draft |
| [timeline.md](timeline.md) | timeline and cinematic tools | draft |
| [content-pipeline.md](content-pipeline.md) | consuming cosmic-forge | draft |
| [ai-first-api.md](ai-first-api.md) | easy for AI from day one, as quick as Three.js | draft |
| [version-manager.md](version-manager.md) | several engine versions side by side, and example projects to start from | draft |
| [marketplace.md](marketplace.md) | the developer platform: build, deploy and sell | draft |
| [website.md](website.md) | kyotenengine.com: the site, its subdomains, provisioning and deployment | draft |
| [examples.md](examples.md) | the example games (FPS, VR on Meta Quest), each its own repository, and the first vertical slice | draft, two decisions recorded |

**A doc's status moves from `draft` to `decided`** when every question in it is answered or deferred with a reason,
and to `superseded` if a later design replaces it (then it says by which).
