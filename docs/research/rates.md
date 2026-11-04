# The rates: each subsystem's floor, and a default for any game

KYR-55, gathered 2026-11-04, for [frame-phases.md](../design/frame-phases.md) question 3. Its structure is decided:
which clock drives each subsystem, what sets its floor, and whether a game changes it. Its numbers are decided from
this doc. The owner's rule: each default is "the lowest frequency we can go while maintaining high fidelity", where
"What goes wrong below is a good thing to keep in mind and sets the floor", and the defaults suit "ANY" game.

Two research passes gathered the evidence: perception and physics, and engines and shipped games. **Every claim in
*Summary* that a default rests on was re-checked against its source before this was committed**, and is marked
**[checked]**. Claims taken from a pass without that re-check are marked **[pass]**, and are listed again under *Thin or
unverified*. One claim failed the re-check and is not used (*Corrections*).

## Summary

| Subsystem | Proposed default | Its floor, and what breaks below it | Shipped range |
|---|---|---|---|
| **Gameplay (Update)** | **60 Hz** | Interpolation renders one or two steps behind, which is 17–33 ms at 60 Hz and 33–67 ms at 30 Hz, the whole of an aiming budget. | 50 (Unity), 60 (Godot, Unity Entities, Netcode for Entities), 64 (Bevy, CS2), 66.7 (Source), 128 (Valorant); 22.4 and ~15 for lockstep RTS |
| **Physics and constraints** | **60 Hz**, with the solver's own sub-steps and iterations | 30 Hz is the documented floor: Box2D "1/30 seconds (30Hz) or smaller" [checked], and Godot "at very low tick rates (usually below 30), physics behavior can break down" [checked]. A spring faster than half the step rate goes unstable (Jolt [checked], Box2D [pass]). | 50–60 by default; racing and VR raise it |
| **Game AI decisions** | **10 Hz** (every 6th step at 60), staggered per entity; re-pathing at 1–2 Hz; distant agents down to ~1 Hz | Decision interval plus perception delay should come to about human reaction time, 213–231 ms (Woods et al. 2015) [pass]. Steering and animation run every step. | Source NPCs 10 / 5 / 2.5 / 1.67 Hz by tier [pass]; OpenAI Five 7.5 Hz [pass]; Detour re-plans after 1 s [pass] |
| **Input hand-off** | every step that consumes input; camera look at the newest sample every frame | FPS aiming degrades from about 41 ms (Ivkovic et al., cited by Spjut et al.) and lower latency beats higher refresh (Spjut et al. 2019) [checked]. XR motion-to-photon about 20 ms (Carmack 2013) [pass]. Menus tolerate 100 ms or more (Claypool 2006) [pass]. | — |
| **Net send, server to client** | **30 Hz**, interpolated two snapshots behind (about 67 ms) | 20 Hz is the shipped floor (Apex, Warzone) at about 100 ms of delay. Netcode for Entities: the network rate defaults to the simulation's, "but half (or one third) is often good enough" [checked]. | competitive FPS 60–128; battle royale 20–30; MOBA ~30; MMO 1–10 |
| **Net send, client to server** | every simulation step, carrying recent inputs again | Unreal sends a move about every 16.6 ms [pass]; GGPO and CS2 send every frame [pass]. | 45–64 |
| **Rendering, flat screen** | the display's rate | Gains are hard to see above about 100 Hz (Denes et al. 2020) [pass], and a high refresh rate matters "largely because of the latency reduction it provides" (Spjut et al.) [checked]. | 60–360 |
| **Rendering, XR** | the headset's rate; Quest's default is 72 Hz | "The default display refresh rate for apps is 72 Hz", and "An app that misses this budget will judder" (Meta) [checked]. Meta's store floor is 60 fps, and half rate needs SpaceWarp [pass]. | Quest 2 and 3: 72–120 Hz; Quest Pro 72–90 [checked] |
| **Audio** | the device's clock; on the web a 128-frame quantum with `latencyHint: "interactive"`; the listener and emitters once a rendered frame | Sound must never lead the picture. Detectability is "about +45 ms to -125 ms", and "a positive value indicates that sound is advanced" (ITU-R BT.1359-1) [checked]. FMOD: set the listener "once per frame" [pass]. | — |
| **Animation** | cosmetic poses at the display's rate; what gameplay reads (hitboxes, root motion) at the simulation's; distant poses down to ≤15 Hz | Unreal's URO targets "15Hz and under, at appropriate distances" [pass]. Valorant keeps per-tick animation state for its rewinds [pass]. | — |

**What it means for question 2's derived base.** 60, 60, 10 and 30 all divide 60, so the base stays at 60 Hz. A
competitive game at 128 Hz needs AI at 8 or 16 Hz and a send rate of 32 or 64. With AI kept at 10, the base becomes 1,920
Hz and question 2's warning fires, which is the warning working as intended.

## The evidence, by subsystem

### Gameplay and physics

- **Box2D v3** [checked]:
  - Step size: "But generally you should use a time step of 1/30 seconds (30Hz) or smaller. A time step of 1/60
    seconds (60Hz) will usually deliver a high quality simulation."
  - Sub-steps: "The recommended sub-step count is 4."
  - Continuous collision: "By default, Box2D uses continuous collision detection (CCD) to prevent dynamic bodies from
    tunneling through static bodies"; "Normally CCD is not used between dynamic bodies"; bullets "will perform CCD
    with all body types, but **not** other bullets" (box2d.org/documentation/md_simulation.html).
  - [pass]: the pass also read Box2D's source (main, 2026-10-30). Contact stiffness is clamped to 0.125 × the sub-step
    rate, so 60 Hz × 4 sub-steps is exactly the cap for the default 30 Hz contact stiffness, and any lower rate softens
    contacts.
- **Jolt** [checked]:
  - "In general, the system is stable when running at 60 Hz with 1 collision step."
  - On springs: "a frequency larger than half of the physics simulation frequency will result in instability".
  - Its linear-cast CCD uses "time stealing", where "an object may appear to move much slower for a single time step",
    and "Fast rotating long objects are also to be avoided" (`Docs/Architecture.md`, master).
- **Godot** [checked]: `physics/common/physics_ticks_per_second` defaults to `60`. "at very low tick rates (usually
  below 30), physics behavior can break down"; "racing games may benefit from increasing the tick rate above the
  default 60" (`doc/classes/ProjectSettings.xml`, master).
- **PhysX 5.6.1** [pass]: "use at least fifty frames per second" for complex scenes, and sweep CCD "operates using only
  linear motion".
- **Bullet** [pass]: `stepSimulation`'s fixed step is 1/60. **Rapier** [pass]: the default timestep is 1/60.
- **Engines' fixed steps:**
  - Bevy's `Time<Fixed>`: "The default timestep() is 64 hertz, or 15625 microseconds" (docs.rs, bevy 0.20.1) [checked].
  - Source's `#define DEFAULT_TICK_INTERVAL (0.015) // 15 msec is the default` (source-sdk-2013 `src/public/const.h`,
    line 31) [checked].
  - Unity Entities' fixed step is 1/60 s [pass]. Unity's classic `Time.fixedDeltaTime` is 0.02 s, which its docs never
    state as the default (see *Thin or unverified*).
- **The sweeping answer to tunnelling, and its limits.** Every engine above sweeps linearly. Rotation and repeated
  impacts are where it misses (Jolt, PhysX). Between two dynamic bodies it is opt-in (Box2D's bullets). So the rate is
  still what keeps stacks, joints and springs stable, as recorded with question 2.

### Input and latency

- **Spjut et al., "Latency of 30 ms Benefits First Person Targeting Tasks More Than Refresh Rate Above 60 Hz"** (NVIDIA,
  SIGGRAPH Asia 2019 Technical Briefs) [checked]:
  - The subjects were eight globally ranked players.
  - "reduced latency has a clear benefit in task completion time while increased refresh rate has relatively minor
    effects on performance when the inherent latency reduction present at high refresh rates is removed".
  - "high refresh rate is important largely because of the latency reduction it provides".
- **Direct touch** [pass]: dragging latency is perceptible below 10 ms (Ng et al. 2012, 2014). Deber et al. (CHI 2015)
  give just-noticeable differences of 11 ms for direct dragging and 96 ms for indirect tapping.
- **By genre** [pass]: Claypool & Claypool (CACM 2006) give network-latency thresholds of 100 ms for first-person
  games, 500 ms for third-person, and 1,000 ms for "omnipresent" ones such as RTS.

### Network

- **Netcode for Entities 1.6** [checked]:
  - `SimulationTickRate` has "Default: 60Hz".
  - `NetworkTickRate` "Defaults to the SimulationTickRate … but half (or one third) is often good enough".
  - "The network tick rate only applies to snapshots, the frequency commands and RPCs is not affected by this setting."
- **Shipped games** [pass]:
  - Valorant runs 128 Hz servers (Riot tech blog, 2020).
  - Overwatch went from 20.8 to 63 Hz in 2016.
  - Fortnite went from 20 to 30 Hz in 2018.
  - Apex runs at 20 Hz.
  - Battlefield went from 45 Hz (2042) to 60 Hz (BF6).
  - Dota 2 runs at 30 Hz.
  - StarCraft II runs 22.4 game loops a second.
  - Age of Empires II used turns that "were typically 200 msec" (Bettner & Terrano 2001).
  - Most of these numbers come from press and packet captures, not the studios.
- **Engine defaults** [pass]:
  - Unreal's `NetServerMaxTickRate` is 30.
  - Unity Netcode for GameObjects' `TickRate` is 30.
  - Source's `cl_interp_ratio` is 2, so interpolation runs two snapshots behind.

### Rendering, XR and audio

- **Meta** [checked]: "The default display refresh rate for apps is 72 Hz." Quest 2 and Quest 3 support 72, 80, 90,
  96, 100 and 120 Hz, and Quest Pro 72, 80 and 90. "An app that misses this budget will judder, which defeats the
  reason to raise the rate at all" (developers.meta.com, mobile-display-refresh-rate).
- **ITU-R BT.1359-1** (1998) [checked]: "detectability thresholds are about +45 ms to -125 ms and acceptability
  thresholds are about +90 ms to -185 ms on the average, a positive value indicates that sound is advanced with respect
  to vision". Late sound is tolerated far more than early sound.
- **Web Audio 1.1** [pass]: the render quantum is 128 frames by default, 2.67 ms at 48 kHz. `latencyHint`
  "interactive" is the default, the "lowest audio output latency possible without glitching".
- **Windows audio** [pass]: "by default all applications … will use 10-ms buffers". **Android** [pass]: its Media
  Performance Class asks for a tap-to-tone latency of 80 ms or less.
- **Denes et al.** (SIGGRAPH 2020) [pass]: "differences above 100 Hz are increasingly more difficult to observe".

### Game AI and animation

- **Human reaction time** [pass]: "Mean SRT latencies were short (231, 213 ms when corrected for hardware delays)",
  over 1,469 subjects (Woods et al., Frontiers in Human Neuroscience, 2015).
- **Source's NPCs** [pass] (`ai_basenpc.cpp`): decision intervals of 0.1, 0.2, 0.4 and 0.6 s by efficiency tier, with
  first thinks staggered over 20 tick-aligned slots.
- **OpenAI Five** [pass] decided at 7.5 Hz, with a reaction of 167–267 ms against a human's 250.
- **Halo** (GDC 2002 talk notes) [pass]: an AI that paused before noticing the player read as a bug, so Bungie removed
  the perception time. A reaction delay should therefore show as behaviour, such as turning to look, not as standing
  still.
- **Animation** [pass]:
  - Unity, Godot and Unreal all evaluate poses at the display's rate by default.
  - Unreal's URO and its Animation Budget Allocator throttle distant poses to 15 Hz or less.
  - Hitboxes that gameplay reads are evaluated on the tick, as with Valorant's per-tick animation history and Source's
    lag compensation.

### The peers ([peer-games.md](peer-games.md), [harvest.md](harvest.md))

- FFD runs a 60 Hz tick. Its bots re-decide on a period with a per-seat offset, and its fire spreads every 27 ticks.
- The-mallow-man's rules run at 30 Hz, its free walk at 60, and its network at 30/30.

These fall inside the ranges above.

## Corrections

- **Quest 3 at 144–207 Hz** came from one pass and is not on Meta's page, which lists 72–120 Hz for Quest 3. It is not
  used.

## Thin or unverified

- **Game AI decision rates are the thinnest evidence here.** No studio source states a decision rate in Hz. The 10 Hz
  default rests on Source's code, machine-learning agents and human reaction time.
- **Unreal's values come from a third-party wiki of 5.4.4's cvars**, because the engine's source is private:
  - `NetServerMaxTickRate` 30, `MaxSubstepDeltaTime` 1/60, `AsyncFixedTimeStepSize` 1/30;
  - `NetUpdateFrequency` 100, with Epic's suggested 10, 5 and 2.

  They are not checked against Epic's source.
- **Unity's 0.02 s default** is read from a project asset, not stated in Unity's docs.
- **Source's `cl_updaterate` 20 and `cl_cmdrate` 30** are from memory, and consistent with its 0.1 s `cl_interp`.
- **Most shipped games' rates** come from press, community wikis and packet captures, not from the studios.
- **Gamepad latency** has no controlled study.

## What this leaves open

- **Frame-phases question 3's numbers, for the owner.** The table's proposed defaults are a recommendation, not a
  decision.
- **Per-genre presets**, such as "competitive" (128 Hz gameplay, 64 Hz send, AI at 16) or "lockstep RTS" (turns of
  about 200 ms). These would be an engine feature or a template, and are KYR-30's to decide.
- **The physics rate under XR.** Meta's 72–120 Hz rendering over 60 Hz physics is interpolated (question 4). Whether
  hand interaction wants physics at 90 or 120 Hz is for the Quest prototype (KYR-4) to answer.
