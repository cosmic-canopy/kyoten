# Input: how the peers and the owner's games turn devices into a game's actions

Gathered 2026-11-21, at the forty-fourth session's readying, for [design/input.md](../design/input.md) and the first
slice's step 8 (KYR-54). Two research passes read the peer engines' documentation and source, and FFD's and
the-mallow-man's code. **Claims a question rests on were re-checked against their source and are marked [checked];**
the rest are the pass's own, marked [pass], with the page each came from.

## Summary

| | Event times, and input across fixed steps | Shaping a value, and recognizing input over time | Contexts and overlapping bindings |
|---|---|---|---|
| Unity Input System 1.19 | Every event keeps its time; in "Process Events in Fixed Update" mode "input events are processed in groups according to whether their timestamp falls within the current fixed time step" [checked] | processors (dead zones, scale, invert, normalize, clamp), binding's then action's, feed interactions (Press, Hold, Tap, SlowTap, MultiTap) [pass] | action maps on or off, no priority; shortcut consumption off by default [pass] |
| Unreal Enhanced Input | evaluated per tick; no split across fixed steps found [pass] | modifiers (DeadZone, Scalar, Negate, Swizzle, curves, Smooth…), mapping's then action's, feed triggers (Down, Pressed, Released, Hold, HoldAndRelease, Tap, Pulse, Chord, Combo) [pass] | mapping contexts with a priority, a higher one consuming its keys; a chord blocks the plain key [pass] |
| Godot 4 | no time on an event; a press is seen by exactly one physics tick, the next [checked] | a dead zone per action; no taps or holds [pass] | no contexts; events propagate until handled [pass] |
| Bevy 0.20 and leafwing 0.22 | no time on an event; Bevy's issue #6183, input missed or doubled under a fixed step, is open; leafwing samples once a frame for the fixed steps [pass] | processors per input (dead zones, sensitivity, invert, bounds) [pass] | a clash strategy, the longest chord first by default [pass] |
| Steam Input | no times found; polled states or change callbacks [pass] | activators in Steam's configurator (Regular, Double, Long, Start, Release, Chorded) [pass] | one action set per controller, layers on top [pass] |
| SDL3 | every event has a time in nanoseconds [pass] | none: a dead zone is the application's [pass] | none |
| OpenXR 1.1 | a boolean action's `lastChangeTime`; edges against the previous sync [pass] | the runtime turns a value into a boolean by a threshold with hysteresis [pass] | an action set's priority suppresses a lower set's bindings of the same source [pass] |

## Event times and fixed steps

- **Unity** splits by timestamp and waits for a step to finish: "Partially elapsed fixed time step periods like this
  aren't processed until the frame after they have fully elapsed" [checked]
  ([timing-optimize-fixed-update](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.19/manual/timing-optimize-fixed-update.html)).
  Read in the wrong update mode, `WasPressedThisFrame` misses an edge or reports it twice [pass]
  ([timing-missed-duplicate-events](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.19/manual/timing-missed-duplicate-events.html)).
- **Godot** stamps a press for the next physics tick: "As input may come in part way through a physics tick, the
  earliest we can react to it is the next physics tick", then `pressed_physics_frame = get_physics_frames() + 1`, and
  `is_action_just_pressed` compares it with the physics frame during a tick [checked]
  ([core/input/input.cpp](https://github.com/godotengine/godot/blob/master/core/input/input.cpp), master, read
  2026-11-21). A press and release within one frame still counts as just pressed [pass].
- **Bevy's** issue #6183, "Inputs can be missed (or duplicated) when using a fixed time step", opened 2022-10-06, is
  open [pass] ([#6183](https://github.com/bevyengine/bevy/issues/6183)). Its example accumulates input before the
  fixed loop and clears it only on a frame where a fixed step ran [pass].
- **SDL3** stamps every event, `SDL_GetTicksNS()` [pass]. In the SDL that `@kama/window` vendors (3.4.18), a
  GameInput pad's button event carries its reading's own time (`SDL_gameinputjoystick.cpp:592`), but only the
  current reading is read at each update (`:939`), and an XInput pad is stamped when it is polled
  (`SDL_xinputjoystick.c:336`) [checked, in `../kama-window/third_party/sdl/`].

## Bindings as data

- **Unity**'s `.inputactions` JSON: a binding is a control path (`<Keyboard>/w`, `<Gamepad>/rightTrigger`) with
  processors and interactions as strings; a composite is a marked entry followed by its parts (`1DAxis`'s `negative`
  and `positive`, `2DVector`'s `up`, `down`, `left`, `right`). A player's rebinding is an override stored apart from
  the file, by binding [pass] ([ActionBindings](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.19/manual/ActionBindings.html)).
- **Unreal**: a mapping context lists key to action with modifiers and triggers; four keys become one 2D action
  through Negate and Swizzle modifiers, with no composite type [pass]
  ([Enhanced Input](https://dev.epicgames.com/documentation/en-us/unreal-engine/enhanced-input-in-unreal-engine)).
- **Godot**: `project.godot`'s `[input]` section, serialized events per action, a dead zone per action [pass].
- **Names:** keys are physical everywhere (Unity's `A` "is always the key to the right of the Caps Lock key"; Godot's
  `physical_keycode`; Bevy's `KeyCode`; SDL's scancode), and a pad's face buttons are named by place (Unity's
  `buttonSouth`, SDL's `SDL_GAMEPAD_BUTTON_SOUTH`, Bevy's `GamepadButton::South`, Unreal's `Gamepad_FaceButton_Bottom`)
  [pass]. `@kama/window` already names both so: a key by the DOM's `KeyboardEvent.code`, a face button by its place.

## Players and devices

- **leafwing**: an input map with no pad of its own reads every pad: "If this is [`None`], input from any connected
  gamepad will be used" [checked] ([src/input_map.rs](https://github.com/Leafwing-Studios/leafwing-input-manager/blob/main/src/input_map.rs)).
- **Godot**: an action matches one device or all of them (`-1`) [pass].
- **Unity**: `PlayerInputManager` joins a player when a button is pressed on an unpaired device, with a maximum count;
  a lost device is paired again when it returns [pass]
  ([PlayerInputManager](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.19/manual/PlayerInputManager.html)).
- **Steam Input**'s handle follows a controller across a reconnect, and SDL's joystick id never does [pass].

## Text, poses and look

- **Typed text is kept apart from actions** in Unity, Godot, Bevy, SDL and Steam; OpenXR's action types are boolean,
  float, vector2, pose and vibration [pass].
- **A pose** is an OpenXR action space, located at whatever time the program asks, predicted when it is ahead [pass].
- **Camera look per frame:** Bevy's fixed-timestep example rotates the camera every frame, since doing it in the fixed
  steps "would sometimes not register player input"; Godot recommends applying mouse motion to the camera directly
  rather than in `_physics_process` [pass].

## The owner's games (read in their trees, 2026-11-21)

Both games' input code is FFD's, forked into the-mallow-man (`engine/src/input/`, and TMM's `play/src/binds.kama`
from FFD's `sim/src/input.kama`).
- **No event carries a time** in either, and neither splits a frame's input across ticks.
- **A bind table in code, two columns per action** (keyboard or mouse, and the pad), rebound by the player: FFD refuses
  a clash and writes `bind.key.<ACTION>` lines; the-mallow-man swaps the two actions and writes only the binds that
  differ from the defaults, in JSON.
- **Edges:** FFD hands every owed tick the same frame of levels and re-derives presses inside the simulation with
  latches; the-mallow-man latches each press until a tick takes it, then hands it to the first tick only, which is
  frame-phases' "edges wait for a step that consumes them".
- **Recorded:** FFD's replay and lockstep carry each tick's `InputFrame`, the actions after binding (24 bytes); the
  mallow-man's network carries a quantized `PlayerInput` with its press bits. A rebind never reaches the world hash.
- **Pads:** one pad, the first mapped; FFD's dead zone fixed at 0.25 per axis; the-mallow-man's radial dead zone,
  trigger threshold and look curve set by the player.
- **Look:** the-mallow-man adds mouse motion, stick and keys each frame and hands the resulting yaw and pitch to each
  tick.
- **Local multiplayer:** neither has it.
