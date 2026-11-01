# Audio, and the DAW tool

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **Web Audio** on the web: the browser's own audio engine, rather than a heavy replacement shipped to it.
- **Native implements the same interface.**
- **Audio tools like a DAW** for humans to tune with.

## What already exists

- The peers' audio: how each reaches Web Audio and a native callback, mixing, voice (Opus). See
  [../research/peer-games.md](../research/peer-games.md) § platform split.
- What kama offers for audio (std, examples, the real-time constraints of a callback such as `@noheap`, and
  "a lock window cannot wait"). See [../research/kama-for-engines.md](../research/kama-for-engines.md).

## The questions

1. **The runtime interface.** A graph of nodes, as Web Audio is (sources, gain, filters, panners, a mixer), or a
   smaller engine-level API (play this sound here, with this bus) that maps onto it? Designed against Web Audio's
   own concepts, per the web-first rule?
2. **Custom DSP.** An AudioWorklet on the web (and kama compiled to wasm inside it?) and a native callback: the
   same kama DSP code in both?
3. **Clock and phases.** Audio runs on its own clock, not the frame. Does the Output phase schedule events with
   timestamps a little ahead, as Web Audio expects? What does a sound triggered in the Update phase look like?
4. **Native backend.** What implements the interface natively (a small C library such as miniaudio, the OS APIs,
   or the peers' existing code)?
5. **Spatial audio** and the listener: in the first slice, or later?
6. **The DAW tool.** Tracks, clips, a mixer, effects, automation, export. Does it edit project-database records
   ([project-database.md](project-database.md)) that the runtime plays, so what a human tunes is exactly what
   ships? Does it share a clock and transport with the timeline tool ([timeline.md](timeline.md))?
7. **What comes from cosmic-forge** (generated sounds, voice) and what is authored in the DAW?

## Decided

*(nothing yet — filled in during the walk-through)*
