# Accessibility: what every kyoten game gives its players

**Status:** draft, deferred to KYR-76. One decision so far, speech's package (§ Decided); the rest are questions. A
platform fact marked *(not checked)* was not measured or read from its source when this was written; each is checked
before its question is asked. Questions 4, 5 and 9's facts were checked on 2026-11-15, in `@kama/audio`'s
`RESEARCH.md` § 10.3.

## What the owner asks

- **Accessibility** (2026-11-14): "Accessibility tools like grid of dots for motion sickness... Colorblindness tools?
  Speach to text, text to speach, etc."

## What already exists

- **Screen readers on the web come from the DOM.** kyoten's UI is HTML and CSS, as the DOM on the web
  ([web-and-native.md](web-and-native.md) § Decided, question 3), so the browser's accessibility tree and ARIA reach
  screen readers. Natively, `@kama/ui` has nothing equivalent, so native accessibility is KYR-16's to build
  (web-and-native.md, item 5).
- **Speech to text has prior art in the owner's games.** friendly-fire-department transcribes push-to-talk speech into
  its chat board through whisper.cpp (MIT) and the `tiny.en` weights (MIT, 30.6 MB), natively
  ([../research/harvest.md](../research/harvest.md) § 11). Its Windows bundle is 55 MB, 31 MB of it that model
  ([../research/web-baseline.md](../research/web-baseline.md)).
- **The pieces each question would build on:**
  - `@kama/audio`'s engine: its input node (decision 18), its own DSP on every leg, and emitters with a listener
    (`../kama-audio/AGENTS.audio.md` § Decided);
  - `@kama/graphics`' post-processing ([rendering.md](rendering.md));
  - semantic actions, which every input becomes (KYR-54);
  - XR's own package ([xr.md](xr.md)), where VR's comfort options would live.

## The questions

1. **Where accessibility lives.**
   - *The problem:* each setting touches a different module. A colour filter is rendering, captions are UI fed by
     audio, speech is audio, remapping is input. If every game builds them, most games will not.
   - *A likely shape:* a player's accessibility profile, kept as a record and saved per player. Each engine module
     applies its part, so a game gets the settings without code of its own and adds only its own content (dialogue
     captions, a narrator's lines).
   - *To settle:* which settings the engine owns and which a game must supply, and how a player's profile follows
     them between games and devices.
2. **Motion comfort.**
   - *The problem:* when what you see moves and your body does not (a camera turning, a vehicle, VR), many players get
     motion sick.
   - *The candidates:*
     - a field of dots drawn over the view that moves with the camera's motion, so the eyes see the motion the body
       expects. Apple's Vehicle Motion Cues work this way *(not checked)*;
     - a fixed reference in the view, such as a centre dot;
     - turning down what adds motion: camera shake, head bob, motion blur, and a wider field of view;
     - in VR, a vignette while moving, snap turning and teleporting, with [xr.md](xr.md).
   - *To settle:* which of these the engine draws itself, as an overlay after the scene on every leg, and which are a
     game's camera settings the engine exposes.
3. **Colour vision.**
   - *The problem:* about 1 in 12 men and 1 in 200 women have a colour-vision deficiency *(not checked)*, so a game
     that tells teams, items or dangers apart by colour alone is unplayable for some of them.
   - *The candidates:*
     - filters for players, a colour transform at the end of the frame (daltonization), as a `@kama/graphics` post
       effect;
     - a simulation of each deficiency for developers (protanopia, deuteranopia, tritanopia, achromatopsia), as a view
       mode in the tools and a check on content's palettes. The usual models are Brettel and Viénot, and Machado
       *(not checked)*;
     - guidance that a game never relies on colour alone: shapes, patterns and labels beside it.
   - *To settle:* whether the filter runs before or after the UI, whether it is the same on every leg (it is DSP on the
     GPU, so `@kama/graphics` decides), and how a content check reports a palette that fails.
4. **Speech to text.**
   - *The problem:* a deaf or hard-of-hearing player cannot follow voice chat, and a player who cannot type or use a
     controller may need to speak commands.
   - *The uses:* voice chat captioned live, voice commands, dictation into chat.
   - *The candidates:*
     - **on the web, the Web Speech API's recognition.**
       - Chrome 139+ and Firefox 160 recognise on the device when a page asks for it (`processLocally`, with
         `available()` and `install()`; measured in the pinned Chrome 157 and Firefox 160).
       - From Chrome 135 and Firefox 160 it takes a `MediaStreamTrack`, so the engine's own frames can feed it.
       - Chrome sends audio to a server unless `processLocally` is set.
       - Firefox's is on the device only, and desktop only.
       - Safari has only the prefixed API, with no track input, on the device only where the locale has a model;
     - **a local model on every leg.** whisper.cpp, as friendly-fire-department ships it, is MIT and 31 MB at 5 bits,
       and does not stream. Moonshine is MIT and streams, at 26M parameters. A streaming Zipformer is Apache-2.0 and
       41 MB. Each keeps speech on the device and works offline, but its model weighs tens of MB, which kyoten's rule to
       lean on the web argues against for every web game;
     - **the OS natively.** Apple's Speech framework (and `SpeechAnalyzer` on 26) and Android's on-device recognizer
       (API 33) take the app's own buffers. Windows has no production on-device API that takes them, since its dictation
       is a web service, and Linux has none.
   - *To settle:* which runs on each leg, what happens to privacy when audio leaves the device, and whether the model
     is downloaded only by a player who turns it on. `@kama/audio` supplies the frames (the microphone's and the remote
     voices'), and recognition runs off the audio thread in a speech package of its own (§ Decided).
5. **Text to speech.**
   - *The problem:* a blind or low-vision player cannot read menus, chat or on-screen text, and the OS's screen reader
     cannot see inside a game's canvas.
   - *The uses:* menus and UI read aloud, chat read aloud, a game's own narrator.
   - *The candidates:*
     - **on the web, the Web Speech API's synthesis, in every browser.**
       - Its voices differ by browser and OS. Chrome's and Edge's online voices send the text to a server.
       - Its sound never passes through Web Audio: `speechSynthesis` has no stream, node or sink (measured in Chrome
         157 and Firefox 160), and the proposal to add one has had no activity since 2019.
       - So the engine cannot place, mix or send it, only duck its own mix while it speaks;
     - **the OS natively.** AVSpeechSynthesizer (`write(_:toBufferCallback:)`), WinRT's `SynthesizeTextToStreamAsync`
       and Android's `onAudioAvailable` hand back samples. Linux's Speech Dispatcher plays the speech itself and returns
       none;
     - **a local voice model rendering into `@kama/audio`'s engine on every leg.** Kokoro is Apache-2.0 and about 82 MB
       at 8 bits; Kitten TTS is Apache-2.0 and 8 to 17 MB a language; Piper's maintained fork is GPL-3, and each of its
       voices has its dataset's licence. It is the same voice everywhere and mixes like any sound, at a download's
       cost.
   - *To settle:* where the voice comes from on each leg. That speech goes through the engine's mix wherever the
     platform or a model gives samples is decided (§ Decided).
6. **Captions and subtitles.**
   - *The problem:* a player who cannot hear misses dialogue and the sounds that matter, such as footsteps behind
     them or an alarm.
   - *The candidates:*
     - dialogue subtitles from a game's dialogue records;
     - captions for sounds, from `@kama/audio`'s emitters: what a sound is and where ("footsteps, behind, left");
     - a visual indicator of loud sounds' directions;
     - the styling a player sets: size, background, speaker names and colours.
   - *To settle:* which sounds are captioned (a field on a sound's record?), and how captions reach the UI through
     Output.
7. **Screen readers and the UI.**
   - *The problem:* a screen reader needs a tree of what is on screen, with names and roles.
   - *What exists:* on the web the DOM gives that tree. Natively `@kama/ui` must publish one to each OS's
     accessibility API: UI Automation, NSAccessibility, AT-SPI, Android's *(not checked)*. That is KYR-16's.
   - *To settle:* whether kyoten exposes anything beyond the UI (the game world, through text to speech or audio
     description), and how a UI document's accessibility is checked at build, as its bindings are.
8. **The other settings the guidelines list.**
   - input remapping (natural over semantic actions, KYR-54), hold instead of press, one-handed layouts, timing
     assists and game speed;
   - text size, contrast and a high-contrast UI;
   - reduced flashing, perhaps by measuring flashes in the rendered frame against the photosensitivity criteria
     (the Harding test, ITU-R BT.1702) *(not checked)*;
   - mono audio, and separate volumes for dialogue, music and effects.
9. **Which standards, and the law.**
   - *Guidelines to measure against:* the Game Accessibility Guidelines, Xbox's Accessibility Guidelines (XAG), and
     WCAG for UI *(not checked)*.
   - *The law:* in the US the CVAA has asked games with voice or text chat to make that communication accessible
     since 1 January 2019. Checked on 2026-11-15, in a reading of the rule, not legal advice:
     - the rule asks for a mode that needs no hearing and one that needs no speech, and names no technology;
     - the FCC's guide gives text to speech for chat and captions of voice chat as ways to comply.

     Xbox's guideline 119 asks for both, speaking a player's typed chat on the voice channel, but it is guidance, not
     a certification gate. Consoles' certification may ask for more (KYR-42).

## Decided

- **2026-11-15, the owner: speech is a package of its own, on `@kama/audio`'s public API** (questions 4 and 5's audio
  half; `@kama/audio`'s `AGENTS.audio.md` § Decided, 30). The owner took the recommendation.
  - **Its two ladders:**
    - **text to speech:** the platform's voice played by the platform (on the web the only rung without a model, with
      the engine ducking around it); then the platform's voice as samples into the mix; then a local voice model on
      every leg;
    - **speech to text:** the platform's recognizer on the device, fed the engine's frames; then a local model on every
      leg, downloaded only when a player turns it on.
  - **`@kama/audio`'s half is three features of its voice-chat slice** (AUD-32): frames tapped from any node, a source
    the program feeds, and the output as a media stream on the web.
  - **Wherever the platform or a model gives samples, speech goes through the engine's mix,** so it can be placed,
    ducked and sent over voice chat.
  - **What stays open here:** which rung each leg defaults to, what may leave the device, and when a model is
    downloaded (questions 4 and 5's *To settle*).
  - **Why:**
    - Web Speech's synthesis cannot reach Web Audio.
    - The models are tens of MB and need an inference runtime, which an audio engine does not.
    - The platforms' speech services are bindings of their own.
    - Recognition runs off the audio thread anyway.
