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

## Filters (gathered 2026-11-23, the forty-eighth session)

For the third part of step 8 ([design/input.md](../design/input.md) § Decided, 2026-11-23). Three passes read the
peers' documentation and source and the owner's games; the defaults the two decisions rest on were re-checked in the
source by hand and are marked [checked].

- **Unity Input System 1.11.2**
  ([source](https://github.com/Unity-Technologies/InputSystem/tree/1.11.2/Packages/com.unity.inputsystem/InputSystem)):
  - Every pad stick carries a scaled radial dead zone at the control, so every binding to it gets one:
    `processors = "stickDeadzone"` on `leftStick` and `rightStick` (`Devices/Gamepad.cs` lines 140 and 150), its
    bounds `m_DefaultDeadzoneMin = 0.125f` and `m_DefaultDeadzoneMax = 0.925f` (`InputSettings.cs` 767 and 768); the
    triggers carry none (161, 170) [checked]. The formula rescales min..max to 0..1 on the vector's length
    (`StickDeadzoneProcessor.cs`) [checked]; `axisDeadzone` is the same on one axis, and a parameter of 0 means "the
    default", so 0 cannot be set [pass].
  - A press point with hysteresis on actions: `m_DefaultButtonPressPoint = 0.5f`, `m_ButtonReleaseThreshold = 0.75f`
    (773, 774), the release at `pressPoint * …ReleaseThreshold` (`Actions/InputActionState.cs` 1588) [checked]. A
    control's own `isPressed` has none [pass].
  - `leftStick/up`, `down`, `left` and `right` are synthetic controls, the clamped half of an axis
    (`clampMin=0,clampMax=1` and its mirror, `Controls/StickControl.cs` 71 to 106) [checked].
  - Its processors: Clamp, Invert, InvertVector2/3, Normalize, NormalizeVector2/3, Scale, ScaleVector2/3,
    AxisDeadzone, StickDeadzone; a part binding's, then the composite's, then the action's, each list left to right; a
    player's change is a binding override (`overrideProcessors`), saved as JSON overrides [pass]
    ([Processors](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/Processors.html)).
- **Godot 4.7**: an action's dead zone is 0.2 by default, 0.5 for the `ui_*` actions (`core/input/input_map.h`,
  `DEFAULT_DEADZONE = 0.2f`, `DEFAULT_TOGGLE_DEADZONE = 0.5f`) [checked], 0.5 before 4.4 (PR #97281) [pass]. It is
  both the press point and the start of the rescale (`get_action_strength`), `get_vector`'s dead zone is radial and
  rescaled, and there is no hysteresis, sensitivity, invert or curve [pass].
- **Unreal Enhanced Input**: DeadZone (Axial, Radial, UnscaledRadial; lower and upper, rescaled between), Scalar,
  Negate, SwizzleAxis, ResponseCurveExponential, ResponseCurveUser, Smooth, SmoothDelta, FOVScaling,
  ScaleByDeltaTime and ToWorldSpace; a mapping's modifiers, then the action's, in array order [pass]
  ([Python API](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/InputAction)). The
  defaults could not be read: Epic's headers are not public. Lyra's modifiers read the player's saved settings (dead
  zones, sensitivity presets, inversion) [pass] ([Lyra input settings](https://dev.epicgames.com/documentation/en-us/unreal-engine/lyra-input-settings-in-unreal-engine)).
  A stick's direction is a key (`Gamepad_LeftStick_Up`), pressed past XInput's dead zone with no hysteresis, as UE4's
  source quoted by a blog shows [pass].
- **leafwing-input-manager 0.22 and Bevy**: Digital, Inverted, Sensitivity, ValueBounds, Exclusion (unscaled),
  DeadZone (scaled), their circular forms and Custom, none applied by default ("No processing is applied to raw data
  from the gamepad"); `GamepadControlDirection::LEFT_UP` and its siblings with a threshold and no hysteresis. Bevy
  underneath: ±0.05 per axis, and buttons pressed at 0.75 and released at 0.65 [pass].
- **Steam Input**: a player sets a stick's dead zone (its shape, inner and outer), an anti-dead zone, a response curve
  (Linear, Aggressive, Relaxed, Wide, Extra Wide, Custom), sensitivity and invert per axis; Valve's advice to a game:
  "make the deadzone, acceleration, and sensitivity of the joystick configurable" [pass]
  ([getting started](https://partner.steamgames.com/doc/features/steam_controller/getting_started_for_devs)).
- **The reference on stick dead zones**, Josh Sutphin's "Doing Thumbstick Dead Zones Right" (2013): axial snaps to the
  cardinals, radial jumps from 0 to the dead zone's edge, and the scaled radial
  `normalized * ((magnitude - deadzone) / (1 - deadzone))` is smooth [pass]
  ([post](https://joshsutphin.com/blog/doing-thumbstick-dead-zones-right.html)). Ryan Juckett's INVERSUS adds an outer
  zone past which the magnitude is 1 [pass].
- **The owner's games** (read in their trees): FFD's dead zone is 0.25 per axis, rescaled past it, also its triggers'
  threshold (`engine/src/input/state.kama` 72, 398 to 431), and no sensitivity, invert or curve. The-mallow-man's sticks
  take a scaled radial dead zone, 0.2 by default, and its triggers 0.15, each the player's (0.05 to 0.4 and 0.05 to
  0.6); its look curve is `sign(v)·|v|^2` per axis on the look stick; its rates 0.0008 radians per mouse count, 3.2
  and 2.2 a second at a full push, with the player's mouse and stick multipliers and invert Y, one settings file per
  machine. Its menus press a stick's direction at 0.55 and let it go below 0.35, then repeat. Neither smooths.
- **`@kama/window`**: a pointer's motion is in logical pixels, and raw counts while the cursor is `Locked` (GLFW's raw
  motion where supported, Pointer Lock's `unadjustedMovement` with a fallback); a pad's button is pressed at 30/255
  both ways, with no hysteresis; consecutive moves of a pointer are joined, their motion summed (its SPEC).
