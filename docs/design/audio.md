# Audio, and the DAW tool

**Status:** KYR-15 started on 2026-11-13 as `@kama/audio` (`../kama-audio`), designed and built on the Mac Mini in
parallel with Track 1 (§ Decided). The DAW waits for KYR-35. Below, the questions as kyoten first wrote them; the
package's design pass answers 1, 2, 4 and 5 in its own `AGENTS.audio.md`, and 3, 6 and 7 stay kyoten's.

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

- **2026-11-13, the owner: audio is its own package, `@kama/audio`, in its own repository (`kama-audio`), designed
  and developed on the Mac Mini in parallel with the graphics track here.** "Should we do that in a separate kama-audio
  package? It seems like that is probably a good way to do it? Then other apps can use the same audio engine." Then:
  "If you could seed kama audio I could add a remote for it and we can push that so the mac box can focus on that
  part... The mac kyoten clone can then design it and develop it in parallel to what we are doing here for graphics."
  - **How:** architecture.md § Decided (2026-11-02) had already put each engine module on a general-purpose library,
    and audio's under `@kama/<noun>` "when KYR-15 comes up"; this starts it. Seeded on 2026-11-13 with `kama seed` on
    0.9.938. Its `AGENTS.audio.md` holds the design pass: its open questions, where the evidence is, its rules, and
    how the two machines share the work. Its decisions are recorded there, and this doc keeps what binds kyoten: how
    kyoten's phases schedule sound (question 3), the DAW (question 6), what comes from cosmic-forge (question 7), and
    what kyoten's audio module presents.
  - **Its first users:** cosmic-forge, whose page cannot play a loop exact to the sample (its KAMA_GAPS CF-24); kyoten's
    audio module; later the DAW.
  - **The owner asked for "the most cutting edge audio (webaudio 2?)".** There is no Web Audio 2: the v2 work became
    Web Audio API 1.1, a W3C Working Draft since November 2024 (`setSinkId`, `renderSizeHint`). Natively, the
    candidates are web-audio-api-rs (Web Audio's spec, natively), miniaudio (the games' device) and the OS APIs. The
    design pass measures them before the owner decides.
  - **Why its own package:** the same as `@kama/graphics`' (architecture.md, 2026-11-02): only a package boundary keeps
    it from importing the engine, and the owner wants other apps to use the same audio engine.
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
- **2026-11-13, the owner: `@kama/audio`'s area 2 binds kyoten in three ways** (its `AGENTS.audio.md` § Decided, 3 to
  11). The rest of area 2 (names, ownership, the rings) is the package's own.
  - **The upper tier runs in the context's `update()`, on the thread that owns the context, once a frame.** The
    library starts no thread. So kyoten's audio module calls `update()` from a phase, which question 3 decides.
  - **Times are Web Audio's:** float64 seconds on the context's clock, each stamped once into an int64 sample frame.
    "A little ahead" (question 3) is the stamp kyoten chooses.
  - **Audio's memory is declared:** every capacity is a field of the context's options, and everything the library
    allocates comes from an `Allocator` the program hands it. So kyoten sizes audio's block from a Budget record
    ([components.md](components.md) question 6), as it sizes a zone's. Which scope that budget has is KYR-15's.
- **2026-11-13, the owner: question 4 is answered by `@kama/audio`'s area 3, which binds kyoten in four ways** (its
  `AGENTS.audio.md` § Decided, 12 to 19). The rest of area 3 is the package's own.
  - **Natively, the backend is miniaudio's device layer inside `@kama/audio`** (decision 17), with small seams of the
    package's own for what miniaudio lacks. So kyoten's audio module vendors and links nothing for sound. A console's
    private package implements miniaudio's custom backend. The owner foresees kama-native backends replacing it later,
    inside the package.
  - **The web's two routes fit [web-and-native.md](web-and-native.md) § Decided, item 5** (decision 12). A threaded
    game's build is the shared route: its `main` in a worker, the `AudioContext` on the page's thread, and the ring.
    Its single-threaded build is the other route, and gains a second artifact, the same program built for the
    AudioWorklet. The loader that picks by `crossOriginIsolated` is the one item 5 already decided. Until kama can
    build that artifact (the package's KAUD-5), kyoten's generator writes what the package's template asks for.
  - **`reproducible-float` is the program's choice** (decision 14). kyoten sets it, which is what makes a game's sound
    the same on every leg and in every build.
  - **Render workers are a declared count** (decision 19): 0 by default (the device's own thread), more for a large mix.
    They are the one kind of thread the package starts, natively only (amended 2026-11-14: decision 25 adds a decode
    thread, below). A game's count, like its audio budget, is KYR-15's.
- **2026-11-13, the owner: `@kama/audio`'s area 4, questions 1 and 2, bind kyoten's question 5 in three ways** (its
  `AGENTS.audio.md` § Decided, 20 to 22). Whether spatial audio is in the first slice stays deferred (2026-11-01).
  - **Spatial sound is the package's own rungs, the same on every leg** (decision 20): equal-power panning, HRTF
    binaural and Ambisonics, chosen per sound. kyoten's emitters and listener bind to them, and an XR head pose turns
    the Ambisonics field.
  - **The room is the program's input until the package's geometric-acoustics tier exists** (decision 20). The inputs
    are occlusion and transmission filters, reverb sends, and a slot for a reflection impulse response, and kyoten's
    audio module sets them from its world. That later tier takes triangles with acoustic materials and a ray-tracing
    contract, which kyoten fills with its own scene (the physics one, or a WebGPU tracer).
  - **HRTF data is converted when a game is built** (decision 22), by the package's converter, from the game's chosen
    SOFA set or the default (SADIE II's KU100 set, about 1 MB). When the audio module links the package, two notices
    join `engine/THIRD-PARTY-NOTICES.md`: pffft's FFTPACK notice (decision 21) and SADIE II's citation.
  - **On the web, a game's voice count waits on kama:** a wasm release is always `-Oz`, where the renderer costs 5 to 10
    times what it does at `-O3` (the package's KAUD-6).
- **2026-11-14, the owner: `@kama/audio`'s area 4, questions 3 and 4, bind kyoten in two ways** (its `AGENTS.audio.md`
  § Decided, 23 and 24).
  - **A game's sounds decode the same on every leg, except AAC** (decision 23). The package decodes WAV, FLAC, MP3,
    Vorbis and Opus itself, each codec a module the game opts into, and AAC through the platform. So kyoten's asset
    pipeline prefers Opus, Vorbis or FLAC wherever a sound must equal itself across legs (a bounce, a replay). Each
    codec the game ships adds 21 to 168 KB to its wasm, so the game's records decide which ship (KYR-15's).
  - **Each sound chooses its resampling rung** (decision 24): linear and cubic are cheap and alias; band-limited
    interpolation costs more per voice. A file at another rate than the context's is converted once, at load. Which
    rung a sound record names, and its default, are KYR-15's.
- **2026-11-14, the owner: `@kama/audio`'s area 4, questions 5 and 6, bind kyoten in three ways** (its `AGENTS.audio.md`
  § Decided, 25 and 26).
  - **A game's long sounds are streams** (decision 25): music, dialogue and ambience beds. The package decodes each a
    little ahead into a ring, on every leg. A stream starts, stops and hands off to the next on a stamped frame, so
    music's sections join with no gap, and a seek plays the file's own samples. Which sounds a game's records mark as
    streams is KYR-15's. So is each stream's ring, a declared capacity (341 ms by default) that the audio Budget record
    sizes.
  - **The package starts a decode thread** natively (a declared count, 1 by default), besides its render workers. On
    the web, a threaded game's build decodes in a Wasm Worker. A single-threaded build gains a third artifact, a
    decode Worker beside the AudioWorklet's (decision 12's second artifact), which kyoten's generator writes until kama
    can build it (the package's KAUD-5).
  - **The room's reverb is the package's own convolver on every leg** (decision 26), never the browser's
    `ConvolverNode`. So kyoten's reverb sends and the room's reflection slot (decision 20) are fed by impulse responses
    the game loads as assets, and they sound the same on every leg.
