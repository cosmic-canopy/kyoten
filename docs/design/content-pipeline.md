# The content pipeline: consuming cosmic-forge

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **cosmic-forge stays the general-purpose content-creation component.** kyoten uses it and does not duplicate it.

## What already exists

From [../research/cosmic-forge.md](../research/cosmic-forge.md):

- forge is a **local, single-user asset pipeline**. It treats tool manifests and per-subject `flow.json` files as
  data, runs external scripts (ComfyUI, Blender, AI-Toolkit), and produces standard files: PNG, GLB, MP4, JSON reports.
- **Built:** the engine, a CLI of about 45 commands (`--json`), a localhost JSON API with a live job stream (SSE),
  and a web page with a WebGPU glTF viewer (its `render` package).
- **Not built:** publishing to destinations, adapters (**kyoten's included**), provenance sidecars, audio tools, a
  catalogue, remote runners.
- **forge's docs already name kyoten:** a future kyoten adapter and live preview, and a `render` package "shaped as
  kyoten's render package would be".
- **It has no agent coordination or change history.** It coordinates AI sessions through repo documents, as the
  peers do. kyoten's project database ([project-database.md](project-database.md)) would have to supply that.
- Its packages are unpublished 0.1.0 path dependencies; `jobs` is POSIX-only; `http`/`webnet` are due to be replaced
  by `@kama/http`.

## The questions

1. **Where is the boundary?** *(Narrowed 2026-11-05 by the owner's direction that heavy assets are never stored with
   the code, [../SPIKE.md](../SPIKE.md) § Standing direction. The reading below puts forge's project directory, whose
   `out/` holds GLB, PNG, MP4 and LoRA checkpoints, inside the game's repo, which that direction rules out for the heavy
   files. forge's own plan already moves them out: a store "outside the game repo" with a catalogue, and "bundles keyed
   to a range of game commits", which is the code-to-asset match the direction asks for
   ([../research/cosmic-forge.md](../research/cosmic-forge.md) § 4, *Planned*).)* The research's reading of forge's
   own docs: forge stays an external process that owns a
   forge project directory inside the game's repo, and kyoten talks to it only through its CLI (`--json`), its
   localhost API and its job stream, receiving finished assets through a kyoten adapter written as forge tools. Is
   that the boundary?
2. **The kyoten adapter.** What does a game asset look like when it arrives: which formats (glTF/GLB, PNG/KTX2,
   audio), which conventions (units, axes, naming, LODs), and as which project-database records? The adapter writes
   to that contract.
3. **Ids and provenance.** forge uses UUIDv7 ids and keeps names apart from them. Does the project database use the
   same scheme, so an asset's forge history and its game records line up?
4. **The live preview loop.** forge produces an asset, and the running kyoten game shows it: through hot reload of
   assets, a shared viewer, or both?
5. **Shared code.** Does kyoten's renderer start from forge's `render` package, as forge intends, or does forge
   later take kyoten's? Which repository owns it?
   - *Answered 2026-11-07 at [rendering.md](rendering.md) question 1:* `@kama/graphics`, in its own repository,
     starts from forge's `render`, and forge then depends on it in place of its own copy: shared, not forked.
6. **Who drives forge?** kyoten's agents through the project database (request a character; forge's flow runs; the
   record updates), a human in forge's own page, or both? How is a forge job visible in kyoten's tools?
7. **Audio.** forge has no audio tools yet. Does the DAW ([audio.md](audio.md)) belong to kyoten, to forge, or
   stay a kyoten tool that forge later feeds?

## Decided

*(nothing yet — filled in during the walk-through)*
