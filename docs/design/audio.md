# Audio, and the DAW tool

**Status:** draft, deferred past the first slice to KYR-15 and KYR-35. These are questions, not decisions.

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

- **2026-11-01, the owner: deferred past the first slice** when the spike was narrowed
  ([../SPIKE.md](../SPIKE.md#narrowed-2026-11-01)). Questions 1–5 and 7 are taken up with KYR-15, and question 6, the
  DAW, with KYR-35.
- **2026-11-13, the owner: question 2 is answered by `@kama/audio`** (its `AGENTS.audio.md` § Decided, 1): the same
  kama DSP runs on both legs. On the web it is the processor of one `AudioWorkletNode`, and Web Audio supplies the
  audio thread, the device, the clock, the microphone, decoding where it is reliable, and MIDI. Natively it runs in the
  device's callback. A built-in node is used only where a measurement shows it is the better tool. § What the vision
  asks still holds ("rather than a heavy replacement shipped to it"): the wasm carries only the DSP. Measured in the package's
  `RESEARCH.md`: the built-in nodes sound different in each browser, and one worklet is 2.7 to 4 times cheaper for many
  voices.
- **2026-11-13, the owner: question 1 is answered by `@kama/audio`** (§ Decided, 2): both, as two tiers of one
  package. The lower tier is Web Audio's graph of nodes and `AudioParam`s, and the upper tier is the engine-level API:
  sounds, voices, buses, snapshots, and emitters with a listener, built only on the graph. What kyoten's components bind to
  is KYR-15's. The split is "similar to what we are doing with kama graphics" (the owner).
